package Net::Firewall::BlockerHelper::backends::f5_bigip;

use 5.006;
use strict;
use warnings;
use base         qw( Error::Helper Net::Firewall::BlockerHelper::Util );
use Regexp::IPv4 qw($IPv4_re);
use Regexp::IPv6 qw($IPv6_re);

=head1 NAME

Net::Firewall::BlockerHelper::backends::f5_bigip - F5 BIG-IP backend using the iControl REST API.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 SYNOPSIS

    use Net::Firewall::BlockerHelper;

    my $fw_helper = Net::Firewall::BlockerHelper->new(
        backend => 'f5_bigip',
        name    => 'ssh',
        options => {
            host     => 'bigip.example.org',
            user     => 'blocker',
            password => $password,
        },
    );

    $fw_helper->init_backend;
    $fw_helper->ban( ban => '1.2.3.4' );
    $fw_helper->unban( ban => '1.2.3.4' );

=head1 DESCRIPTION

Blocks IPs on an F5 BIG-IP via its iControl REST API, managing the membership
of a single firewall address-list. The full membership of the address-list is
rendered from this backend's internal state on every change, so the address
list contains exactly the currently banned IPs and nothing else.

The managed address-list is identified by its C<name> option (defaulting to
C<< <prefix>_<name> >>) within a partition (defaulting to C<Common>). The
address-list object, and any firewall rule referencing it, must already exist
on the BIG-IP.

Blocking is per IP; ports and protocols are not supported and specifying them
is an error.

Auth is via HTTP basic auth using the C<user> and C<password> options.

L<LWP::UserAgent> is loaded at run time, so it is only required when this
backend is actually used. For https, L<LWP::Protocol::https> must be present
as well.

=head1 METHODS

=head2 new

Initiates the object.

    - options :: Backend specific options. See below.
    - prefix :: Prefix to use. Must match /^[a-zA-Z0-9]+$/. Default kur.
    - name :: Name of this instance. Required.

Ports and protocols are not supported and specifying either is an error.

The options hash accepts the following.

    - host :: BIG-IP host, optionally host:port. Required.
        - Default :: undef

    - user :: iControl REST user. Required.
        - Default :: undef

    - password :: iControl REST password. Required.
        - Default :: undef

    - name :: The firewall address-list name to manage.
        - Default :: <prefix>_<name>

    - partition :: The partition the address-list lives in.
        - Default :: Common

    - insecure :: If true, skip TLS certificate verification (BIG-IP ships a
            self-signed certificate).
        - Default :: 0

    - timeout :: HTTP timeout in seconds.
        - Default :: 30

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
				31 => 'userNotDefined',
				32 => 'passwordNotDefined',
				33 => 'banCidrFailed',
				34 => 'unbanCidrFailed',
				35 => 'cidrItemNotCidr',
				36 => 'cidrNotSupported',
				37 => 'listCidrFailed',
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
		name         => undef,
		frontend_obj => undef,
		inited         => 0,
		banned         => {},
		banned_cidr    => {},
		cidr_supported => 1,
		ua             => undef,
	};
	bless $self;

	# blocking is per IP; the address-list has no concept of ports or protocols
	if ( defined( $opts{ports} ) && ref( $opts{ports} ) eq 'ARRAY' && defined( $opts{ports}[0] ) ) {
		$self->{perror}      = 1;
		$self->{error}       = 26;
		$self->{errorString} = 'the f5_bigip backend blocks whole IPs and does not support ports';
		$self->warn;
	}
	if ( defined( $opts{protocols} ) && ref( $opts{protocols} ) eq 'ARRAY' && defined( $opts{protocols}[0] ) ) {
		$self->{perror}      = 1;
		$self->{error}       = 27;
		$self->{errorString} = 'the f5_bigip backend blocks whole IPs and does not support protocols';
		$self->warn;
	}

	# make sure prefix is sane if defined
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

	# required connection options
	if ( !defined( $self->{options}{host} ) || $self->{options}{host} eq '' ) {
		$self->{perror}      = 1;
		$self->{error}       = 30;
		$self->{errorString} = 'the option host is undef or blank';
		$self->warn;
	}
	if ( !defined( $self->{options}{user} ) || $self->{options}{user} eq '' ) {
		$self->{perror}      = 1;
		$self->{error}       = 31;
		$self->{errorString} = 'the option user is undef or blank';
		$self->warn;
	}
	if ( !defined( $self->{options}{password} ) || $self->{options}{password} eq '' ) {
		$self->{perror}      = 1;
		$self->{error}       = 32;
		$self->{errorString} = 'the option password is undef or blank';
		$self->warn;
	}

	# defaults
	$self->{options}{insecure}  = 0        if ( !defined( $self->{options}{insecure} ) );
	$self->{options}{timeout}   = 30       if ( !defined( $self->{options}{timeout} ) );
	$self->{options}{partition} = 'Common' if ( !defined( $self->{options}{partition} ) );
	if ( defined( $self->{name} ) ) {
		$self->{options}{name} = $self->{prefix} . '_' . $self->{name} if ( !defined( $self->{options}{name} ) );
	}

	return $self;
} ## end sub new

# Internal helper. Returns the iControl REST URL of the address-list this
# instance manages.
#
# BIG-IP identifies configuration objects by a partition qualified path, which
# in iControl REST is written with tildes in place of slashes:
# ~<partition>~<name>. The whole identifier is then percent encoded so the
# tildes and any awkward characters in the name survive being placed in the
# URL path.
#
# This backend does not create the address-list. It is expected to already
# exist and be referenced by a firewall policy; all this does is rewrite its
# contents.
#
# Takes no arguments; the host, partition, and name come from the options.
#
# Returns the URL as a string, used for both the read and the replace.
#
#     # partition Common, name blocklist
#     $self->_obj_url;
#     #   https://f5.example.org/mgmt/tm/security/firewall/address-list/~Common~blocklist
sub _obj_url {
	my ($self) = @_;

	my $id = '~' . $self->{options}{partition} . '~' . $self->{options}{name};

	return
		  'https://'
		. $self->{options}{host}
		. '/mgmt/tm/security/firewall/address-list/'
		. $self->_uri_escape($id);
} ## end sub _obj_url

# Internal helper. Renders the complete desired contents of the address-list
# from the current bans, which is what gets pushed to replace it.
#
# The address-list is replace-in-full: there is no add or remove one entry
# call, so every ban and unban rewrites the whole membership from the internal
# state.
#
# Each entry is an object with a name key rather than a bare string, which is
# the shape iControl REST expects. Single addresses and CIDR ranges are held
# in two separate internal lists but go into the same list, merged and sorted
# together into one run, since BIG-IP accepts both as address entries and does
# not distinguish them.
#
# Takes no arguments; the bans come from the object's banned and banned_cidr
# hashes.
#
# Returns the body as a JSON string, ready to be the content of the replace
# request. With nothing banned the addresses array is empty, which is how
# teardown and flush clear the list.
#
#     # with 10.0.0.1 and 10.0.0.0/8 banned
#     $self->_render;
#     #   {"addresses":[{"name":"10.0.0.0/8"},{"name":"10.0.0.1"}]}
#
#     # with nothing banned
#     #   {"addresses":[]}
sub _render {
	my ($self) = @_;

	# the address-list holds both single IPs and CIDR ranges as address entries
	my @addresses
		= map { { name => $_ } } sort( keys( %{ $self->{banned} } ), keys( %{ $self->{banned_cidr} } ) );

	return $self->_json->encode( { addresses => \@addresses } );
} ## end sub _render

# Internal helper. Performs one HTTP request against the BIG-IP iControl REST
# API. Every call this backend makes to the appliance goes through here.
#
# The user agent is built on first use and cached on the object, so a run of
# requests shares one agent. LWP::UserAgent is loaded with require at that
# point rather than at compile time, since only the HTTP backends need it;
# failing to load it dies with an explanation naming this backend. The
# insecure option turns off certificate verification, which is there because a
# BIG-IP commonly presents a self signed certificate.
#
# Authentication is HTTP basic, encoded per request; there is no session or
# token to establish. MIME::Base64 is required at call time for the same
# reason LWP is. Note the second argument to encode_base64 is an empty string,
# which suppresses the line wrapping it would otherwise insert and which would
# corrupt the header.
#
# Any HTTP level failure dies rather than setting an error. The callers wrap
# this in eval and turn the exception into the appropriate error code.
#
# A body that fails to decode as JSON is not fatal; the decode runs inside its
# own eval and leaves the result undef.
#
# Never called in testing mode; those paths record the request instead.
#
# Args:
#
#     method - The HTTP method, as a plain string, such as 'GET' or 'PATCH'.
#
#     url    - The full URL to request, as a plain string, normally
#              _obj_url.
#
#     body   - Optional request body, as an already encoded JSON string,
#              normally from _render. undef for methods that carry no body.
#
# Returns the decoded response body as whatever structure the JSON held,
# normally a hashref, or undef when the response body was empty or did not
# parse. Dies on any non success HTTP status.
#
#     $self->_request( 'GET', $self->_obj_url );
#
#     # the usual shape at the call sites
#     eval { $self->_request( 'PATCH', $self->_obj_url, $self->_render ); };
#     if ($@) { ... raise banFailed ... }
sub _request {
	my ( $self, $method, $url, $body ) = @_;

	if ( !defined( $self->{ua} ) ) {
		local $@;
		eval {
			require LWP::UserAgent;
			my %args = (
				agent   => 'Net::Firewall::BlockerHelper/' . $VERSION,
				timeout => $self->{options}{timeout},
			);
			if ( $self->{options}{insecure} ) {
				$args{ssl_opts} = { verify_hostname => 0, SSL_verify_mode => 0 };
			}
			$self->{ua} = LWP::UserAgent->new(%args);
			1;
		} or die( 'failed to load LWP::UserAgent, which the f5_bigip backend requires... ' . $@ );
	}

	require MIME::Base64;
	my $auth = 'Basic ' . MIME::Base64::encode_base64( $self->{options}{user} . ':' . $self->{options}{password}, '' );

	my @headers = ( 'Content-Type' => 'application/json', 'Authorization' => $auth );

	require HTTP::Request;
	my $request = HTTP::Request->new( $method, $url, \@headers, $body );

	my $response = $self->{ua}->request($request);

	if ( !$response->is_success ) {
		my $detail = $response->decoded_content;
		$detail = defined($detail) ? ( ' body... ' . $detail ) : '';
		die( $method . ' ' . $url . ' failed... HTTP status... ' . $response->status_line . $detail );
	}

	my $decoded;
	my $content = $response->decoded_content;
	if ( defined($content) && $content ne '' ) {
		local $@;
		eval { $decoded = $self->_json->decode($content); };
	}

	return $decoded;
} ## end sub _request

=head2 init

Initiates the backend. Verifies the credentials, reachability, and that the
address-list object exists by fetching it.

=cut

sub init {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( $self->{inited} ) {
		$self->{error}       = 18;
		$self->{errorString} = 'backend has already been inited';
		$self->warn;
	}

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'GET', url => $self->_obj_url } ];
	} else {
		local $@;
		eval { $self->_request( 'GET', $self->_obj_url ); 1; } or do {
			$self->{error}       = 23;
			$self->{errorString} = 'init failed. probing the address-list object failed... ' . $@;
			$self->warn;
		};
	}

	$self->{inited} = 1;
} ## end sub init

=head2 ban

Bans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then added to the internal ban list and the full rendered
membership is pushed to the address-list via a PUT. Banning an already
banned IP is a noop. If the PUT fails, the IP is removed from the internal
list again.

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
		$self->{frontend_obj}->{test_data} = [ { method => 'PUT', url => $self->_obj_url, content => $body } ];
	} else {
		local $@;
		eval { $self->_request( 'PUT', $self->_obj_url, $body ); 1; } or do {
			delete( $self->{banned}{ $opts{ban} } );
			$self->{error}       = 13;
			$self->{errorString} = 'banning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	}
} ## end sub ban

=head2 unban

Unbans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then removed from the internal ban list and the full
rendered membership is pushed to the address-list via a PUT. Unbanning an
IP that is not banned is a noop. If the PUT fails, the IP is re-added to
the internal list.

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
		$self->{frontend_obj}->{test_data} = [ { method => 'PUT', url => $self->_obj_url, content => $body } ];
	} else {
		local $@;
		eval { $self->_request( 'PUT', $self->_obj_url, $body ); 1; } or do {
			$self->{banned}{ $opts{ban} } = 1;
			$self->{error}       = 14;
			$self->{errorString} = 'unbanning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	}
} ## end sub unban

=head2 ban_cidr

Bans a CIDR range by adding it to the internal list and pushing the full
rendered membership to the address-list via a PUT. The value of ban is
validated as being a IPv4 or IPv6 CIDR range and lowercased. Banning an
already banned range is a noop.

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
		$self->{error}       = 35;
		$self->{errorString} = 'Bad ref type for ban... ref is "' . ref( $opts{ban} ) . '"';
		$self->warn;
		return;
	} elsif ( !$self->_valid_cidr( $opts{ban} ) ) {
		$self->{error}       = 35;
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
		$self->{frontend_obj}->{test_data} = [ { method => 'PUT', url => $self->_obj_url, content => $body } ];
	} else {
		local $@;
		eval { $self->_request( 'PUT', $self->_obj_url, $body ); 1; } or do {
			delete( $self->{banned_cidr}{ $opts{ban} } );
			$self->{error}       = 33;
			$self->{errorString} = 'banning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	}
} ## end sub ban_cidr

=head2 unban_cidr

Unbans a CIDR range by removing it from the internal list and pushing the
full rendered membership to the address-list via a PUT. The value of ban is
validated as being a IPv4 or IPv6 CIDR range and lowercased. Unbanning a
range that is not banned is a noop.

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
		$self->{error}       = 35;
		$self->{errorString} = 'Bad ref type for ban... ref is "' . ref( $opts{ban} ) . '"';
		$self->warn;
		return;
	} elsif ( !$self->_valid_cidr( $opts{ban} ) ) {
		$self->{error}       = 35;
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
		$self->{frontend_obj}->{test_data} = [ { method => 'PUT', url => $self->_obj_url, content => $body } ];
	} else {
		local $@;
		eval { $self->_request( 'PUT', $self->_obj_url, $body ); 1; } or do {
			$self->{banned_cidr}{ $opts{ban} } = 1;
			$self->{error}       = 34;
			$self->{errorString} = 'unbanning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	}
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

Tears down and re-inits, then re-renders the full membership in a single PUT.

=cut

sub re_init {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	# teardown is best effort here as a partially or fully wiped setup is
	# exactly what re_init needs to recover from
	{
		local $@;
		eval { $self->teardown; };
	}
	$self->init;

	my $body = $self->_render;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'PUT', url => $self->_obj_url, content => $body } ];
	} else {
		local $@;
		eval { $self->_request( 'PUT', $self->_obj_url, $body ); 1; } or do {
			$self->{error}       = 13;
			$self->{errorString} = 're_init failed re-rendering the address-list membership... ' . $@;
			$self->warn;
		};
	}

	$self->{inited} = 1;
} ## end sub re_init

=head2 teardown

Tears down the setup by rendering an empty membership to the address-list. The
internal list of bans is kept, so a following re_init will re-add them.

=cut

sub teardown {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{inited} = 0;

	# render an empty membership without disturbing the internal ban list
	my $body = $self->_json->encode( { addresses => [] } );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'PUT', url => $self->_obj_url, content => $body } ];
	} else {
		local $@;
		eval { $self->_request( 'PUT', $self->_obj_url, $body ); 1; } or do {
			$self->{error}       = 17;
			$self->{errorString} = 'teardown failed emptying the address-list... ' . $@;
			$self->warn;
		};
	}
} ## end sub teardown

=head2 stop

Alias for L</teardown>.

=cut

sub stop {
	my ( $self, %opts ) = @_;

	return $self->teardown(%opts);
}

=head2 check

Verifies the endpoint and credentials are still usable by fetching the
address-list object. Returns a true value if so and a false value otherwise.

=cut

sub check {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'GET', url => $self->_obj_url } ];
		return 1;
	}

	local $@;
	eval { $self->_request( 'GET', $self->_obj_url ); 1; } or return 0;

	return 1;
} ## end sub check

=head2 flush

Removes all currently banned IPs at once by rendering an empty membership to
the address-list and forgetting them.

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

	# the rendered empty membership below removes both single IPs and CIDR ranges
	$self->{banned}      = {};
	$self->{banned_cidr} = {};

	my $body = $self->_render;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'PUT', url => $self->_obj_url, content => $body } ];
	} else {
		local $@;
		eval { $self->_request( 'PUT', $self->_obj_url, $body ); 1; } or do {
			$self->{error}       = 25;
			$self->{errorString} = 'flush failed emptying the address-list... ' . $@;
			$self->warn;
		};
	}
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

Init failed. Probing the address-list object failed.

=head2 24, checkFailed

The backend check raised an error.

=head2 25, flushFailed

Failed to flush the bans.

=head2 26, portsNotSupported

The f5_bigip backend blocks whole IPs and does not support ports.

=head2 27, protocolsNotSupported

The f5_bigip backend blocks whole IPs and does not support protocols.

=head2 30, hostNotDefined

The option host is undef or blank.

=head2 31, userNotDefined

The option user is undef or blank.

=head2 32, passwordNotDefined

The option password is undef or blank.

=head2 33, banCidrFailed

Failed to ban the CIDR range.

=head2 34, unbanCidrFailed

Failed to unban the CIDR range.

=head2 35, cidrItemNotCidr

The item to ban is not a CIDR range. Either wrong ref type or it is not an
IPv4 or IPv6 address followed by a prefix length valid for its family.

=head2 36, cidrNotSupported

The backend does not support CIDR bans.

=head2 37, listCidrFailed

Failed to get a list of CIDR bans.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.ent> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut

1;    # End of Net::Firewall::BlockerHelper::backends::f5_bigip
