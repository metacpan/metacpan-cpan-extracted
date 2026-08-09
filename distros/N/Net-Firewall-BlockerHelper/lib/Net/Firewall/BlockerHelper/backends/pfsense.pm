package Net::Firewall::BlockerHelper::backends::pfsense;

use 5.006;
use strict;
use warnings;
use base         qw( Error::Helper Net::Firewall::BlockerHelper::Util );
use Regexp::IPv4 qw($IPv4_re);
use Regexp::IPv6 qw($IPv6_re);

=head1 NAME

Net::Firewall::BlockerHelper::backends::pfsense - pfSense firewall alias backend for Net::Firewall::BlockerHelper.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 SYNOPSIS

    use Net::Firewall::BlockerHelper;

    my $fw_helper = Net::Firewall::BlockerHelper->new(
            backend => 'pfsense',
            name    => 'ssh',
            options => {
                host => 'fw.example.org',
                key  => 'someAPIkey',
            },
        );

    $fw_helper->init_backend;
    $fw_helper->ban(ban => '1.2.3.4');
    $fw_helper->unban(ban => '1.2.3.4');

=head1 DESCRIPTION

This backend blocks IPs by managing the membership of a pfSense firewall
alias via the pfSense REST API package (jaredhendrickson13's pfSense-API),
using its v2 endpoints and L<LWP::UserAgent>.

A single host type alias holds all of the banned IPs. Both IPv4 and IPv6
addresses are added to the same alias, as a pfSense host alias holds an
array of IP address strings regardless of family.

The alias membership is rendered from state: the full set of banned IPs is
sent on every change, followed by a firewall apply so pfSense reloads the
running configuration.

The alias B<must> already exist in pfSense and be referenced by a firewall
rule that does the actual blocking. This backend only manages the contents
of the alias, not the alias itself nor the rule referencing it.

Auth is via the C<X-API-Key> header, set from the C<key> option.

L<LWP::UserAgent> is only loaded at run time, so it is only required if
this backend is actually used. For https, L<LWP::Protocol::https> must be
present as well.

=head1 NOTES

This backend was written going off the API docs and actual testing is
needed to double check a few things as the exact behavior is not clear.

ban_cidr sends the alias update with the type still set to host and it is
not clear whether the API will accept CIDR entries in a host type alias
or if a network type alias is required, in which case the type used will
need changing.

=head1 METHODS

=head2 new

Initiates the the object.

    - options :: Backend specific options. See below.
        - Default :: {}

    - prefix :: Prefix to use. Must match the regex /^[a-zA-Z0-9]+$/
        - default :: kur

    - name :: Name of this specific instance. This must be specified.
        - default :: undef

Ports and protocols are not supported by this backend and specifying either
is an error.

The options hash accepts the following.

    - host :: pfSense hostname or IP the API is reached at. May include a
            port, eg 'fw.example.org:8443'. This must be specified.
        - Default :: undef

    - key :: The pfSense REST API key, sent via the X-API-Key header. This
            must be specified.
        - Default :: undef

    - alias :: The name of the alias the IPs are added to. The alias must
            already exist in pfSense.
        - Default :: <prefix>_<name>

    - timeout :: HTTP timeout in seconds.
        - Default :: 30

    - insecure :: If true, certificate verification is disabled so
            self-signed certs are accepted.
        - Default :: 0

All errors are considered fatal, meaning if new fails it will die.

=cut

sub new {
	my ( $blank, %opts ) = @_;

	my $self = {
		perror        => undef,
		error         => undef,
		errorLine     => undef,
		errorFilename => undef,
		errorString   => "",
		errorExtra    => {
			all_errors_fatal => 1,
			# all_fatal is what Error::Helper 2.1.0 actually checks; all_errors_fatal
			# is kept for the name documented in its POD
			all_fatal        => 1,
			flags            => {
				1  => 'notInited',
				6  => 'invalidPrefixSpecified',
				7  => 'invalidName',
				8  => 'optionsNotHash',
				9  => 'noBanItem',
				10 => 'banItemNotIP',
				12 => 'backendInitError',
				13 => 'banFailed',
				14 => 'unbanFailed',
				15 => 'listFailed',
				16 => 'reInitFailed',
				17 => 'teardownFailed',
				18 => 'alreadyInited',
				23 => 'initFailed',
				24 => 'checkFailed',
				25 => 'flushFailed',
				26 => 'portsNotSupported',
				27 => 'protocolsNotSupported',
				30 => 'hostNotDefined',
				31 => 'keyNotDefined',
				32 => 'banCidrFailed',
				33 => 'unbanCidrFailed',
				34 => 'cidrItemNotCidr',
				35 => 'cidrNotSupported',
				36 => 'listCidrFailed',
			},
			fatal_flags      => {},
			perror_not_fatal => 0,
		},
		options      => {},
		ports        => [],
		protocols    => [],
		testing      => undef,
		test_data    => undef,
		prefix       => 'kur',
		frontend_obj => undef,
		inited         => 0,
		banned         => {},
		banned_cidr    => {},
		cidr_supported => 1,
		ua             => undef,
	};
	bless $self;

	# blocking is per IP; the alias has no concept of ports or protocols
	if ( defined( $opts{ports} ) && ref( $opts{ports} ) eq 'ARRAY' && defined( $opts{ports}[0] ) ) {
		$self->{perror}      = 1;
		$self->{error}       = 26;
		$self->{errorString} = 'the pfsense backend blocks whole IPs and does not support ports';
		$self->warn;
	}
	if ( defined( $opts{protocols} ) && ref( $opts{protocols} ) eq 'ARRAY' && defined( $opts{protocols}[0] ) ) {
		$self->{perror}      = 1;
		$self->{error}       = 27;
		$self->{errorString} = 'the pfsense backend blocks whole IPs and does not support protocols';
		$self->warn;
	}

	# make sure prefix is sane if defiend
	if ( defined( $opts{prefix} ) && $opts{prefix} !~ /^[a-zA-Z0-9]+$/ ) {
		$self->{perror} = 1;
		$self->{error}  = 6;
		$self->{errorString}
			= '"' . $opts{prefix} . '" is not a valid prefix as it does not match the regex /^[a-zA-Z0-9]+$/';
		$self->warn;
	} elsif ( defined( $opts{prefix} ) ) {
		$self->{prefix} = $opts{prefix};
	}

	# make sure we have a name and that it is valid
	if ( !defined( $opts{name} ) ) {
		$self->{perror}      = 1;
		$self->{error}       = 7;
		$self->{errorString} = 'name is undef';
		$self->warn;
	} elsif ( $opts{name} !~ /^[a-zA-Z0-9\-]+$/ ) {
		$self->{perror}      = 1;
		$self->{error}       = 7;
		$self->{errorString} = 'name set to "' . $opts{name} . '" which does not match the regexp  /^[a-zA-Z0-9\-]+$/';
		$self->warn;
	}
	$self->{name} = $opts{name};

	# used internally for testing
	if ( defined( $opts{testing} ) ) {
		$self->{testing} = $opts{testing};
	}
	if ( defined( $opts{frontend_obj} ) ) {
		$self->{frontend_obj} = $opts{frontend_obj};
	}

	if ( defined( $opts{options} ) ) {
		if ( ref( $opts{options} ) ne 'HASH' ) {
			$self->{perror}      = 1;
			$self->{error}       = 8;
			$self->{errorString} = 'ref for options is "' . ref( $opts{options} ) . '" and not HASH';
			$self->warn;
		}
		$self->{options} = $opts{options};
	}

	# host and key are both required to be able to talk to the API
	if ( !defined( $self->{options}{host} ) || $self->{options}{host} eq '' ) {
		$self->{perror}      = 1;
		$self->{error}       = 30;
		$self->{errorString} = 'host is not defined or is blank';
		$self->warn;
	}
	if ( !defined( $self->{options}{key} ) || $self->{options}{key} eq '' ) {
		$self->{perror}      = 1;
		$self->{error}       = 31;
		$self->{errorString} = 'key is not defined or is blank';
		$self->warn;
	}

	# default the alias name to <prefix>_<name>
	if ( !defined( $self->{options}{alias} ) || $self->{options}{alias} eq '' ) {
		$self->{options}{alias} = $self->{prefix} . '_' . ( defined( $self->{name} ) ? $self->{name} : '' );
	}

	if ( !defined( $self->{options}{insecure} ) ) {
		$self->{options}{insecure} = 0;
	}

	if ( !defined( $self->{options}{timeout} ) ) {
		$self->{options}{timeout} = 30;
	} elsif ( $self->{options}{timeout} !~ /^[0-9]+$/ ) {
		$self->{perror}      = 1;
		$self->{error}       = 12;
		$self->{errorString} = 'the option timeout, "' . $self->{options}{timeout} . '", is not an int';
		$self->warn;
	}

	return $self;
} ## end sub new

# Internal helper. Returns the scheme and host of the pfSense box, which every
# API URL is built on.
#
# The scheme is fixed at https rather than configurable, since the pfSense API
# is expected to be run over TLS.
#
# Takes no arguments; the host comes from the options.
#
# Returns the base URL as a string, with no trailing slash.
#
#     $self->_base;    # https://pf.example.org
sub _base {
	my ($self) = @_;

	return 'https://' . $self->{options}{host};
}

# Internal helper. Returns the URL that reads back the alias, used by init and
# check to confirm it is there.
#
# Since this backend creates nothing, the alias existing is the whole of its
# setup, and an alias deleted out from under a running process is what this
# detects. init runs it so a misconfigured alias name fails immediately rather
# than at the first ban, and check runs it to decide whether the self heal
# path should re-push the current bans.
#
# The alias name is percent encoded going into the query string, as it is a
# configured value rather than something derived.
#
# Takes no arguments; the alias name comes from the options.
#
# Returns the URL as a string, for a GET whose exit is only inspected for
# success.
#
#     $self->_probe_url;
#     #   https://pf.example.org/api/v2/firewall/alias?name=blocklist
sub _probe_url {
	my ($self) = @_;

	return $self->_base . '/api/v2/firewall/alias?name=' . $self->_uri_escape( $self->{options}{alias} );
}

# Internal helper. Renders the complete pfSense alias body from the current
# bans, which is what gets pushed to replace the alias contents.
#
# The alias is replace-in-full: there is no add or remove one entry call, so
# every ban and unban rewrites the whole membership from the internal state.
#
# Single addresses and CIDR ranges are held in two separate internal lists but
# go into the same alias, since pfSense does not distinguish them here. Unlike
# most of the other backends they are merged and sorted together into one run
# rather than emitted as two, so the ordering is a single lexical sort across
# both.
#
# Note the type is sent as 'host' even when the alias holds ranges. That is
# what the alias is configured as, and pfSense accepts CIDR entries in it.
#
# Args:
#
#     ips - Optional arrayref of entries to render instead of the current
#           state. Each entry is a plain string, an address or a CIDR range.
#           Pass an empty arrayref to render an empty alias, which is how
#           teardown and flush clear it. When omitted or undef, the current
#           bans are used, which is what every normal call does.
#
# Returns the alias body as a JSON string, ready to be the content of the
# update request.
#
#     # with 10.0.0.1 and 10.0.0.0/8 banned
#     $self->_render;
#     #   {"address":["10.0.0.0/8","10.0.0.1"],"id":"blocklist","type":"host"}
#
#     # explicitly empty, as teardown does
#     $self->_render( [] );
#     #   {"address":[],"id":"blocklist","type":"host"}
sub _render {
	my ( $self, $ips ) = @_;

	if ( !defined($ips) ) {
		# the alias holds both single IPs and CIDR ranges
		$ips = [ sort( keys( %{ $self->{banned} } ), keys( %{ $self->{banned_cidr} } ) ) ];
	}

	return $self->_json->encode(
		{
			id      => $self->{options}{alias},
			type    => 'host',
			address => $ips,
		}
	);
} ## end sub _render

# Internal helper. Performs one HTTP request against the pfSense API. Every
# call this backend makes to the box goes through here.
#
# The user agent is built on first use and cached on the object, so a run of
# requests shares one agent. LWP::UserAgent is loaded with require at that
# point rather than at compile time, since only the HTTP backends need it;
# failing to load it dies with an explanation naming this backend. The
# insecure option turns off certificate verification, which is there because a
# pfSense box commonly presents a self signed certificate.
#
# Any HTTP level failure dies rather than setting an error. The callers wrap
# this in eval and turn the exception into the appropriate error code, which
# is what lets one helper serve paths that report ban, unban, and teardown
# failures differently.
#
# Never called in testing mode; those paths record the request instead.
#
# Args:
#
#     method - The HTTP method, as a plain string, such as 'GET' or 'PATCH'.
#
#     url    - The full URL to request, as a plain string, built on _base.
#
#     body   - Optional request body, as an already encoded JSON string,
#              normally from _render. undef for methods that carry no body.
#
# Returns the decoded response body as whatever structure the JSON held,
# normally a hashref. Dies on any non success HTTP status.
#
#     $self->_request( 'GET', $self->_probe_url );
#
#     # the usual shape at the call sites
#     eval { $self->_request( 'PATCH', $url, $self->_render ); };
#     if ($@) { ... raise banFailed ... }
sub _request {
	my ( $self, $method, $url, $body ) = @_;

	if ( !defined( $self->{ua} ) ) {
		local $@;
		eval {
			require LWP::UserAgent;
			my %ua_opts = (
				agent   => 'Net::Firewall::BlockerHelper/' . $VERSION,
				timeout => $self->{options}{timeout},
			);
			if ( $self->{options}{insecure} ) {
				$ua_opts{ssl_opts} = { verify_hostname => 0, SSL_verify_mode => 0 };
			}
			$self->{ua} = LWP::UserAgent->new(%ua_opts);
			1;
		} or die( 'failed to load LWP::UserAgent, which the pfsense backend requires... ' . $@ );
	} ## end if ( !defined( $self->{ua...}))

	my @headers = ( 'Content-Type' => 'application/json', 'X-API-Key' => $self->{options}{key} );

	require HTTP::Request;
	my $request = HTTP::Request->new( $method, $url, \@headers, $body );

	my $response = $self->{ua}->request($request);

	my $decoded;
	local $@;
	eval { $decoded = $self->_json->decode( $response->decoded_content ); };

	if ( !$response->is_success ) {
		die( $method . ' ' . $url . ' failed... HTTP status... ' . $response->status_line );
	}

	return $decoded;
} ## end sub _request

=head2 init

Initiates the backend. Verifies the alias exists by fetching it.

No arguments are taken.

May called a second time, it will error.

    $backend->init;

=cut

sub init {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( $self->{inited} ) {
		$self->{error}       = 18;
		$self->{errorString} = 'backend has already been inited';
		$self->warn;
	}

	my $url = $self->_probe_url;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'GET', url => $url } ];
	} else {
		local $@;
		eval { $self->_request( 'GET', $url ); 1; } or do {
			$self->{error}       = 23;
			$self->{errorString} = 'init failed. probing the alias failed... ' . $@;
			$self->warn;
		};
	}

	$self->{inited} = 1;
} ## end sub init

=head2 ban

Bans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then the full alias membership including it is rendered and
sent via a PATCH to C</api/v2/firewall/alias>, followed by a POST to
C</api/v2/firewall/apply>. If the API calls fail, the IP is removed from
the internal ban list again. Banning an already banned IP is a noop.

    $backend->ban(ban => $ip);

=cut

sub ban {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( !$self->{inited} ) {
		$self->{error}       = 1;
		$self->{errorString} = 'backend has not been inited';
		$self->warn;
		return;
	}

	if ( !defined( $opts{ban} ) ) {
		$self->{error}       = 9;
		$self->{errorString} = 'Nothing specified for the value ban';
		$self->warn;
		return;
	} elsif ( ref( $opts{ban} ) ne '' ) {
		$self->{error}       = 10;
		$self->{errorString} = 'Bad ref type for ban... ref is "' . ref( $opts{ban} ) . '"';
		$self->warn;
		return;
	} elsif ( $opts{ban} !~ /\A$IPv4_re\z/
		&& $opts{ban} !~ /\A$IPv6_re\z/ )
	{
		$self->{error}       = 10;
		$self->{errorString} = 'ban item,"' . $opts{ban} . '", does not appear to be a IPv4 or IPv6 IP';
		$self->warn;
		return;
	}

	# lowercase so the same IPv6 IP in differing cases can't result in duplicate entries
	$opts{ban} = lc( $opts{ban} );

	if ( $self->{banned}{ $opts{ban} } ) {
		if ( $self->{testing} ) {
			$self->{frontend_obj}->{test_data} = 'already banned';
		}
		return;
	}

	$self->{banned}{ $opts{ban} } = 1;

	my $body = $self->_render;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [
			{ method => 'PATCH', url => $self->_base . '/api/v2/firewall/alias', content => $body },
			{ method => 'POST',  url => $self->_base . '/api/v2/firewall/apply' },
		];
	} else {
		local $@;
		eval {
			$self->_request( 'PATCH', $self->_base . '/api/v2/firewall/alias', $body );
			$self->_request( 'POST', $self->_base . '/api/v2/firewall/apply', '' );
			1;
		} or do {
			delete( $self->{banned}{ $opts{ban} } );
			$self->{error}       = 13;
			$self->{errorString} = 'banning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	} ## end else [ if ( $self->{testing} )]
} ## end sub ban

=head2 unban

Unbans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then the alias membership is re-rendered without it and
sent via a PATCH to C</api/v2/firewall/alias>, followed by a POST to
C</api/v2/firewall/apply>. If the API calls fail, the IP is restored to the
internal ban list. Unbanning an IP that is not banned is a noop.

    $backend->unban(ban => $ip);

=cut

sub unban {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( !$self->{inited} ) {
		$self->{error}       = 1;
		$self->{errorString} = 'backend has not been inited';
		$self->warn;
		return;
	}

	if ( !defined( $opts{ban} ) ) {
		$self->{error}       = 9;
		$self->{errorString} = 'Nothing specified for the value ban';
		$self->warn;
		return;
	} elsif ( ref( $opts{ban} ) ne '' ) {
		$self->{error}       = 10;
		$self->{errorString} = 'Bad ref type for ban... ref is "' . ref( $opts{ban} ) . '"';
		$self->warn;
		return;
	} elsif ( $opts{ban} !~ /\A$IPv4_re\z/
		&& $opts{ban} !~ /\A$IPv6_re\z/ )
	{
		$self->{error}       = 10;
		$self->{errorString} = 'ban item,"' . $opts{ban} . '", does not appear to be a IPv4 or IPv6 IP';
		$self->warn;
		return;
	}

	# lowercase so the same IPv6 IP in differing cases can't result in duplicate entries
	$opts{ban} = lc( $opts{ban} );

	if ( !$self->{banned}{ $opts{ban} } ) {
		if ( $self->{testing} ) {
			$self->{frontend_obj}->{test_data} = 'not banned';
		}
		return;
	}

	delete( $self->{banned}{ $opts{ban} } );

	my $body = $self->_render;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [
			{ method => 'PATCH', url => $self->_base . '/api/v2/firewall/alias', content => $body },
			{ method => 'POST',  url => $self->_base . '/api/v2/firewall/apply' },
		];
	} else {
		local $@;
		eval {
			$self->_request( 'PATCH', $self->_base . '/api/v2/firewall/alias', $body );
			$self->_request( 'POST', $self->_base . '/api/v2/firewall/apply', '' );
			1;
		} or do {
			$self->{banned}{ $opts{ban} } = 1;
			$self->{error}       = 14;
			$self->{errorString} = 'unbanning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	} ## end else [ if ( $self->{testing} )]
} ## end sub unban

=head2 ban_cidr

Bans a CIDR range by adding it to the alias membership and applying the
change via the same PATCH and apply calls used by L</ban>. A pfSense host
alias holds CIDR ranges in the same manner as single addresses. The value
of ban is validated as being a IPv4 or IPv6 CIDR range and lowercased.
Banning an already banned range is a noop.

    $backend->ban_cidr(ban => '1.2.3.0/24');

=cut

sub ban_cidr {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( !$self->{inited} ) {
		$self->{error}       = 1;
		$self->{errorString} = 'backend has not been inited';
		$self->warn;
		return;
	}

	if ( !defined( $opts{ban} ) ) {
		$self->{error}       = 9;
		$self->{errorString} = 'Nothing specified for the value ban';
		$self->warn;
		return;
	} elsif ( ref( $opts{ban} ) ne '' ) {
		$self->{error}       = 34;
		$self->{errorString} = 'Bad ref type for ban... ref is "' . ref( $opts{ban} ) . '"';
		$self->warn;
		return;
	} elsif ( !$self->_valid_cidr( $opts{ban} ) ) {
		$self->{error}       = 34;
		$self->{errorString} = 'ban item,"' . $opts{ban} . '", does not appear to be a IPv4 or IPv6 CIDR';
		$self->warn;
		return;
	}

	# lowercase so the same IPv6 CIDR in differing cases can't result in duplicate entries
	$opts{ban} = lc( $opts{ban} );

	if ( $self->{banned_cidr}{ $opts{ban} } ) {
		if ( $self->{testing} ) {
			$self->{frontend_obj}->{test_data} = 'already banned';
		}
		return;
	}

	$self->{banned_cidr}{ $opts{ban} } = 1;

	my $body = $self->_render;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [
			{ method => 'PATCH', url => $self->_base . '/api/v2/firewall/alias', content => $body },
			{ method => 'POST',  url => $self->_base . '/api/v2/firewall/apply' },
		];
	} else {
		local $@;
		eval {
			$self->_request( 'PATCH', $self->_base . '/api/v2/firewall/alias', $body );
			$self->_request( 'POST', $self->_base . '/api/v2/firewall/apply', '' );
			1;
		} or do {
			delete( $self->{banned_cidr}{ $opts{ban} } );
			$self->{error}       = 32;
			$self->{errorString} = 'banning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	} ## end else [ if ( $self->{testing} )]
} ## end sub ban_cidr

=head2 unban_cidr

Unbans a CIDR range by removing it from the alias membership and applying
the change. The value of ban is validated as being a IPv4 or IPv6 CIDR
range and lowercased. Unbanning a range that is not banned is a noop.

    $backend->unban_cidr(ban => '1.2.3.0/24');

=cut

sub unban_cidr {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( !$self->{inited} ) {
		$self->{error}       = 1;
		$self->{errorString} = 'backend has not been inited';
		$self->warn;
		return;
	}

	if ( !defined( $opts{ban} ) ) {
		$self->{error}       = 9;
		$self->{errorString} = 'Nothing specified for the value ban';
		$self->warn;
		return;
	} elsif ( ref( $opts{ban} ) ne '' ) {
		$self->{error}       = 34;
		$self->{errorString} = 'Bad ref type for ban... ref is "' . ref( $opts{ban} ) . '"';
		$self->warn;
		return;
	} elsif ( !$self->_valid_cidr( $opts{ban} ) ) {
		$self->{error}       = 34;
		$self->{errorString} = 'ban item,"' . $opts{ban} . '", does not appear to be a IPv4 or IPv6 CIDR';
		$self->warn;
		return;
	}

	# lowercase so the same IPv6 CIDR in differing cases can't result in duplicate entries
	$opts{ban} = lc( $opts{ban} );

	if ( !$self->{banned_cidr}{ $opts{ban} } ) {
		if ( $self->{testing} ) {
			$self->{frontend_obj}->{test_data} = 'not banned';
		}
		return;
	}

	delete( $self->{banned_cidr}{ $opts{ban} } );

	my $body = $self->_render;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [
			{ method => 'PATCH', url => $self->_base . '/api/v2/firewall/alias', content => $body },
			{ method => 'POST',  url => $self->_base . '/api/v2/firewall/apply' },
		];
	} else {
		local $@;
		eval {
			$self->_request( 'PATCH', $self->_base . '/api/v2/firewall/alias', $body );
			$self->_request( 'POST', $self->_base . '/api/v2/firewall/apply', '' );
			1;
		} or do {
			$self->{banned_cidr}{ $opts{ban} } = 1;
			$self->{error}       = 33;
			$self->{errorString} = 'unbanning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	} ## end else [ if ( $self->{testing} )]
} ## end sub unban_cidr

=head2 list_cidr

List banned CIDR ranges. Returns an array of the currently banned CIDR
ranges. Single IPs are not included; for those see L</list>.

    my @banned_cidrs = $backend->list_cidr;

=cut

sub list_cidr {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = 'list_cidr';
	}

	return keys( %{ $self->{banned_cidr} } );
}

=head2 list

List banned IPs. Returns an array of the currently banned single IPs. CIDR
ranges are not included; for those see L</list_cidr>.

    my @banned = $backend->list;

=cut

sub list {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = 'list';
	}

	return keys( %{ $self->{banned} } );
}

=head2 re_init

Tells the backend to re-init it's self.

This will call teardown and init again. After that it will re-add all
previously added bans by rendering the full alias membership and applying.

    $backend->re_init;

=cut

sub re_init {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	# teardown is best effort here as a partially or fully wiped setup is
	# exactly what re_init needs to recover from; init cleans up any remnants
	{
		local $@;
		eval { $self->teardown; };
	}
	$self->init;

	my $body = $self->_render;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [
			{ method => 'PATCH', url => $self->_base . '/api/v2/firewall/alias', content => $body },
			{ method => 'POST',  url => $self->_base . '/api/v2/firewall/apply' },
		];
	} else {
		local $@;
		eval {
			$self->_request( 'PATCH', $self->_base . '/api/v2/firewall/alias', $body );
			$self->_request( 'POST', $self->_base . '/api/v2/firewall/apply', '' );
			1;
		} or do {
			$self->{error}       = 16;
			$self->{errorString} = 're_init failed re-adding the bans... ' . $@;
			$self->warn;
		};
	} ## end else [ if ( $self->{testing} )]

	$self->{inited} = 1;
} ## end sub re_init

=head2 teardown

Tears down the setup for the backend by rendering the alias with an empty
membership and applying. The internal list of bans is kept, so a following
re_init will re-add them. The alias itself and the rule referencing it are
left in place.

    $backend->teardown;

=cut

sub teardown {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{inited} = 0;

	my $body = $self->_render( [] );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [
			{ method => 'PATCH', url => $self->_base . '/api/v2/firewall/alias', content => $body },
			{ method => 'POST',  url => $self->_base . '/api/v2/firewall/apply' },
		];
	} else {
		local $@;
		eval {
			$self->_request( 'PATCH', $self->_base . '/api/v2/firewall/alias', $body );
			$self->_request( 'POST', $self->_base . '/api/v2/firewall/apply', '' );
			1;
		} or do {
			$self->{error}       = 17;
			$self->{errorString} = 'teardown failed clearing the alias... ' . $@;
			$self->warn;
		};
	} ## end else [ if ( $self->{testing} )]
} ## end sub teardown

=head2 stop

Alias for L</teardown>, provided for parity with the fail2ban C<actionstop>
concept.

    $backend->stop;

=cut

sub stop {
	my ( $self, %opts ) = @_;

	return $self->teardown(%opts);
}

=head2 check

Verifies the alias is still reachable by fetching it. Returns a true value
if so and a false value otherwise. This is the equivalent of fail2ban's
C<actioncheck>.

    if ( !$backend->check ) {
        $backend->re_init;
    }

=cut

sub check {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	my $url = $self->_probe_url;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'GET', url => $url } ];
		return 1;
	}

	local $@;
	eval { $self->_request( 'GET', $url ); 1; } or return 0;

	return 1;
} ## end sub check

=head2 flush

Removes all currently banned IPs at once by rendering the alias with an
empty membership, applying, and forgetting them. The alias and the rule
referencing it are left in place. This is the equivalent of fail2ban's
C<actionflush>.

    $backend->flush;

=cut

sub flush {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( !$self->{inited} ) {
		$self->{error}       = 1;
		$self->{errorString} = 'backend has not been inited';
		$self->warn;
		return;
	}

	my $body = $self->_render( [] );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [
			{ method => 'PATCH', url => $self->_base . '/api/v2/firewall/alias', content => $body },
			{ method => 'POST',  url => $self->_base . '/api/v2/firewall/apply' },
		];
	} else {
		local $@;
		eval {
			$self->_request( 'PATCH', $self->_base . '/api/v2/firewall/alias', $body );
			$self->_request( 'POST', $self->_base . '/api/v2/firewall/apply', '' );
			1;
		} or do {
			$self->{error}       = 25;
			$self->{errorString} = 'flush failed clearing the alias... ' . $@;
			$self->warn;
		};
	} ## end else [ if ( $self->{testing} )]

	$self->{banned}      = {};
	$self->{banned_cidr} = {};
} ## end sub flush

=head1 ERROR CODES / FLAGS

Error handling is provided by L<Error::Helper>. All
errors are considered fatal.

=head2 1, notInited

The backend has not been inited yet.

=head2 6, invalidPrefixSpecified

The specified prefix did not match /^[a-zA-Z0-9]+$/.

=head2 7, invalidName

The name is either undef or does not match /^[a-zA-Z0-9\-]+$/.

=head2 8, optionsNotHash

The item passed to new for options is not a hash.

=head2 9, noBanItem

No IP or CIDR range specified to ban or unban.

=head2 10, banItemNotIP

The item to ban is not an IP. Either wrong ref type or regexp
test using L<Regexp::IPv4> and L<Regexp::IPv6> failed.

=head2 12, backendInitError

Failed to init the backend.

=head2 13, banFailed

Failed to ban the item.

=head2 14, unbanFailed

Failed to unban the item.

=head2 15, listFailed

Failed to get a list of bans.

=head2 16, reInitFailed

Failed to re_init the backend.

=head2 17, teardownFailed

Failed to teardown the backend.

=head2 18, alreadyInited

init called, but the backend has already been inited.

=head2 23, initFailed

init failed. Probing the alias failed.

=head2 24, checkFailed

The backend check raised an error.

=head2 25, flushFailed

Failed to flush the bans.

=head2 26, portsNotSupported

Ports were specified, but the backend does not support ports.

=head2 27, protocolsNotSupported

Protocols were specified, but the backend does not support protocols.

=head2 30, hostNotDefined

The option host is undef or blank.

=head2 31, keyNotDefined

The option key is undef or blank.

=head2 32, banCidrFailed

Failed to ban the CIDR range.

=head2 33, unbanCidrFailed

Failed to unban the CIDR range.

=head2 34, cidrItemNotCidr

The item to ban is not a CIDR range. Either wrong ref type or it is not an
IPv4 or IPv6 address followed by a prefix length valid for its family.

=head2 35, cidrNotSupported

The backend does not support CIDR bans.

=head2 36, listCidrFailed

Failed to get a list of CIDR bans.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.ent> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-firewall-blockerhelper at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Firewall-BlockerHelper>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999


=cut

1;    # End of Net::Firewall::BlockerHelper
