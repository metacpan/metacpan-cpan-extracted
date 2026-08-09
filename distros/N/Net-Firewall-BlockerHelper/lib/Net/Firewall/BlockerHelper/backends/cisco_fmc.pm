package Net::Firewall::BlockerHelper::backends::cisco_fmc;

use 5.006;
use strict;
use warnings;
use base         qw( Error::Helper Net::Firewall::BlockerHelper::Util );
use Regexp::IPv4 qw($IPv4_re);
use Regexp::IPv6 qw($IPv6_re);

=head1 NAME

Net::Firewall::BlockerHelper::backends::cisco_fmc - Cisco Firepower Management Center backend via the REST API.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 SYNOPSIS

    use Net::Firewall::BlockerHelper;

    my $fw_helper = Net::Firewall::BlockerHelper->new(
        backend => 'cisco_fmc',
        name    => 'ssh',
        options => {
            host     => 'fmc.example.org',
            user     => 'apiuser',
            password => $fmc_password,
            group_id => $network_group_object_id,
        },
    );

    $fw_helper->init_backend;
    $fw_helper->ban( ban => '1.2.3.4' );
    $fw_helper->unban( ban => '1.2.3.4' );

=head1 DESCRIPTION

Blocks IPs on a Cisco Firepower Management Center (FMC) via its REST API. A
single Network Group object is managed; its C<literals> list is rendered from
the internal set of banned IPs and CIDR ranges and PUT to the FMC in full on
each change. Both IPv4 and IPv6 addresses are rendered as C<Host> literals
and CIDR ranges as C<Network> literals.

A firewall access control policy referencing the Network Group must already
exist, and after any change a policy deployment is required on the FMC for the
new literal set to actually be enforced. This backend does not trigger the
deployment.

Auth is via a username and password, POSTed to the token generation endpoint;
the returned C<X-auth-access-token> header is then sent on every subsequent
request. The credentials and token are carried as headers only.

Blocking is per IP or CIDR range; ports and protocols are not supported and
specifying them is an error.

L<LWP::UserAgent> is loaded at run time, so it is only required when this
backend is actually used. For https, L<LWP::Protocol::https> must be present
as well.

=head1 METHODS

=head2 new

Initiates the backend object. Arguments are taken as a hash.

    - options :: Backend specific options. See below.
    - prefix :: Prefix to use. Must match /^[a-zA-Z0-9]+$/. Default kur.
    - name :: Name of this instance. Required.

Ports and protocols are not supported and specifying either is an error.

The options hash accepts the following.

    - host :: FMC host, optionally host:port. Required.
        - Default :: undef

    - user :: API username. Required.
        - Default :: undef

    - password :: API password. Required.
        - Default :: undef

    - domain :: FMC domain UUID.
        - Default :: e276abec-e0f2-11e3-8169-6d9ed49b625f

    - group_id :: UUID of the Network Group object to manage. Required.
        - Default :: undef

    - group_name :: Name of the Network Group object.
        - Default :: <prefix>_<name>

    - insecure :: If true, skip TLS certificate verification.
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
				33 => 'groupIdNotDefined',
				34 => 'banCidrFailed',
				35 => 'unbanCidrFailed',
				36 => 'cidrItemNotCidr',
				37 => 'cidrNotSupported',
				38 => 'listCidrFailed',
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
		token          => undef,
	};
	bless $self;

	# blocking is per IP; the Network Group object has no concept of ports or protocols
	if ( defined( $opts{ports} ) && ref( $opts{ports} ) eq 'ARRAY' && defined( $opts{ports}[0] ) ) {
		$self->{perror}      = 1;
		$self->{error}       = 26;
		$self->{errorString} = 'the cisco_fmc backend blocks whole IPs and does not support ports';
		$self->warn;
	}
	if ( defined( $opts{protocols} ) && ref( $opts{protocols} ) eq 'ARRAY' && defined( $opts{protocols}[0] ) ) {
		$self->{perror}      = 1;
		$self->{error}       = 27;
		$self->{errorString} = 'the cisco_fmc backend blocks whole IPs and does not support protocols';
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
	if ( !defined( $self->{options}{group_id} ) || $self->{options}{group_id} eq '' ) {
		$self->{perror}      = 1;
		$self->{error}       = 33;
		$self->{errorString} = 'the option group_id is undef or blank';
		$self->warn;
	}

	# defaults
	$self->{options}{domain}   = 'e276abec-e0f2-11e3-8169-6d9ed49b625f'
		if ( !defined( $self->{options}{domain} ) );
	$self->{options}{insecure} = 0  if ( !defined( $self->{options}{insecure} ) );
	$self->{options}{timeout}  = 30 if ( !defined( $self->{options}{timeout} ) );
	if ( defined( $self->{name} ) ) {
		$self->{options}{group_name} = $self->{prefix} . '_' . $self->{name}
			if ( !defined( $self->{options}{group_name} ) );
	}

	return $self;
} ## end sub new

# Internal helper. Returns the URL of the FMC authentication endpoint that
# issues API tokens.
#
# FMC does not accept credentials on the calls that do the work. A short lived
# token has to be obtained first and then sent on every following request, so
# this endpoint is hit once at init and again whenever a token needs
# refreshing. Note it lives under the fmc_platform API rather than the
# fmc_config one the object calls use.
#
# Takes no arguments; the host comes from the options.
#
# Returns the endpoint as a string.
#
#     $self->_token_url;
#     #   https://fmc.example.org/api/fmc_platform/v1/auth/generatetoken
sub _token_url {
	my ($self) = @_;

	return 'https://' . $self->{options}{host} . '/api/fmc_platform/v1/auth/generatetoken';
}

# Internal helper. Returns the URL of the FMC Network Group object this
# instance manages.
#
# This is the single object every ban and unban rewrites; the backend does not
# create it, and it is expected to already exist and be referenced by an
# access control policy. The URL is built from the domain UUID and the group's
# own UUID rather than from names, since that is how the fmc_config API
# addresses objects.
#
# Takes no arguments; the host, domain, and group id all come from the
# options.
#
# Returns the URL as a string, used for both the GET that reads the object and
# the PUT that replaces it.
#
#     $self->_group_url;
#     #   https://fmc.example.org/api/fmc_config/v1/domain/e276abec-.../object/networkgroups/0050568A-...
sub _group_url {
	my ($self) = @_;

	return
		  'https://'
		. $self->{options}{host}
		. '/api/fmc_config/v1/domain/'
		. $self->{options}{domain}
		. '/object/networkgroups/'
		. $self->{options}{group_id};
} ## end sub _group_url

# Internal helper. Renders the complete Network Group object body from the
# current bans, which is what gets PUT back to replace it.
#
# FMC offers no incremental add or remove for group literals, so every ban and
# unban rewrites the whole object. The name and id have to be included in the
# body as well as in the URL, since a PUT replaces the object outright and
# omitting them would blank them.
#
# Single addresses and ranges both become literals but with different types,
# Host for an address and Network for a range, which is why the two internal
# lists are walked separately. They are emitted as two sorted runs rather than
# one merged sorted list, so the hosts come first and the networks after. That
# is stable, which is what matters for the test_data comparisons, just not
# globally sorted.
#
# Takes no arguments; the bans come from the object's banned and banned_cidr
# hashes.
#
# Returns the object body as a JSON string, ready to be the content of a PUT
# to _group_url. With nothing banned the literals array is empty, which is how
# teardown and flush clear the group.
#
#     # with 10.0.0.1 and 10.0.0.0/8 banned
#     $self->_render;
#     #   {"id":"0050568A-...","literals":[{"type":"Host","value":"10.0.0.1"},{"type":"Network","value":"10.0.0.0/8"}],"name":"blocklist"}
#
#     # with nothing banned
#     #   {"id":"0050568A-...","literals":[],"name":"blocklist"}
sub _render {
	my ($self) = @_;

	my @literals;
	foreach my $ip ( sort( keys( %{ $self->{banned} } ) ) ) {
		push( @literals, { type => 'Host', value => $ip } );
	}
	foreach my $cidr ( sort( keys( %{ $self->{banned_cidr} } ) ) ) {
		push( @literals, { type => 'Network', value => $cidr } );
	}

	return $self->_json->encode(
		{
			name     => $self->{options}{group_name},
			id       => $self->{options}{group_id},
			literals => \@literals,
		}
	);
} ## end sub _render

# Internal helper. Performs one HTTP request against the FMC configuration
# API. Every call this backend makes other than the token fetch itself goes
# through here.
#
# Authentication is the token obtained by _generate_token, sent in the
# X-auth-access-token header. The header is only added when a token is
# actually set, so a request made before authentication simply goes out
# unauthenticated and fails at the server rather than dying on an undef here.
#
# Note there is no automatic token refresh. FMC tokens expire, and when one
# does the next call fails like any other error rather than being retried, so
# a long lived process relies on the self heal path to re-init and
# reauthenticate.
#
# The user agent is normally already built and cached on the object by
# _generate_token, since that runs first; it is built here on first use if
# not. LWP::UserAgent is loaded with require rather than at compile time,
# since only the HTTP backends need it. The insecure option turns off
# certificate verification, which is there because an FMC commonly presents a
# self signed certificate.
#
# Any HTTP level failure dies rather than setting an error. The callers wrap
# this in eval and turn the exception into the appropriate error code, which
# is what lets one helper serve paths that report ban, unban, and teardown
# failures differently.
#
# A body that fails to decode as JSON is not fatal; the decode runs inside its
# own eval and leaves the result undef.
#
# Never called in testing mode; those paths record the request instead.
#
# Args:
#
#     method - The HTTP method, as a plain string: 'GET' to read the Network
#              Group, 'PUT' to replace it.
#
#     url    - The full URL to request, as a plain string, normally
#              _group_url.
#
#     body   - Optional request body, as an already encoded JSON string,
#              normally from _render. undef for a GET.
#
# Returns the decoded response body as whatever structure the JSON held,
# normally a hashref, or undef when the response body was empty or did not
# parse. Dies on any non success HTTP status.
#
#     my $decoded = $self->_request( 'GET', $self->_group_url );
#
#     # the usual shape at the call sites
#     eval { $self->_request( 'PUT', $self->_group_url, $self->_render ); };
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
		} or die( 'failed to load LWP::UserAgent, which the cisco_fmc backend requires... ' . $@ );
	}

	my @headers = ( 'Content-Type' => 'application/json' );
	if ( defined( $self->{token} ) ) {
		push( @headers, 'X-auth-access-token' => $self->{token} );
	}

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

# Internal helper. Authenticates against FMC and stores the resulting API
# token on the object for the following requests to use.
#
# FMC's authentication is unusual in two ways worth knowing. The credentials
# go up as HTTP basic auth, but only to this one endpoint, and the token comes
# back in a response header rather than in the body, so there is nothing to
# parse: the X-auth-access-token header is the whole answer.
#
# The user agent is built here on first use and cached on the object, since
# this normally runs before any other request. LWP::UserAgent is loaded with
# require at that point rather than at compile time, since only the HTTP
# backends need it; failing to load it dies with an explanation naming this
# backend. The insecure option turns off certificate verification, which is
# there because an FMC commonly presents a self signed certificate.
#
# MIME::Base64 is required at call time for the same reason. Note the second
# argument to encode_base64 is an empty string, which suppresses the line
# wrapping it would otherwise insert and which would corrupt the header.
#
# A response that succeeds but carries no token is treated as a failure rather
# than being allowed through, since storing an empty token would turn one
# clear error here into an authentication failure on every following call.
#
# Dies on any failure rather than setting an error; the callers wrap it in
# eval. Never called in testing mode.
#
# Takes no arguments; the credentials come from the options.
#
# Returns nothing. The result is the side effect of setting the token
# attribute on the object, which _request then sends as X-auth-access-token.
#
#     $self->_generate_token;
#     # $self->{token} is now set
#
#     # the usual shape at the call sites
#     eval { $self->_generate_token; };
#     if ($@) { ... raise backendInitError ... }
sub _generate_token {
	my ($self) = @_;

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
		} or die( 'failed to load LWP::UserAgent, which the cisco_fmc backend requires... ' . $@ );
	}

	require MIME::Base64;
	my $basic = MIME::Base64::encode_base64( $self->{options}{user} . ':' . $self->{options}{password}, '' );

	require HTTP::Request;
	my $request = HTTP::Request->new( 'POST', $self->_token_url, [ 'Authorization' => 'Basic ' . $basic ] );

	my $response = $self->{ua}->request($request);

	if ( !$response->is_success ) {
		my $detail = $response->decoded_content;
		$detail = defined($detail) ? ( ' body... ' . $detail ) : '';
		die( 'POST ' . $self->_token_url . ' failed... HTTP status... ' . $response->status_line . $detail );
	}

	my $token = $response->header('X-auth-access-token');
	if ( !defined($token) || $token eq '' ) {
		die( 'POST ' . $self->_token_url . ' returned no X-auth-access-token header' );
	}

	$self->{token} = $token;

	return;
} ## end sub _generate_token

=head2 init

Initiates the backend. POSTs the configured user and password via HTTP Basic
auth to the token generation endpoint,
C</api/fmc_platform/v1/auth/generatetoken>, and stores the returned
C<X-auth-access-token> header for use on all subsequent requests. Nothing is
done to the Network Group object itself.

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
		$self->{frontend_obj}->{test_data} = [ { method => 'POST', url => $self->_token_url } ];
	} else {
		local $@;
		eval { $self->_generate_token; 1; } or do {
			$self->{error}       = 23;
			$self->{errorString} = 'init failed. generating an auth token failed... ' . $@;
			$self->warn;
		};
	}

	$self->{inited} = 1;
} ## end sub init

=head2 ban

Bans an IP. The value of ban is validated as being a IPv4 or IPv6 address and
lowercased, then added to the ban list. The full Network Group object,
containing every current ban as a C<Host> literal, is rendered and PUT to the
networkgroups endpoint. Banning an already banned IP is a noop. If the PUT
fails, the IP is removed from the ban list again.

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
		$self->{frontend_obj}->{test_data} = [ { method => 'PUT', url => $self->_group_url, content => $body } ];
	} else {
		local $@;
		eval { $self->_request( 'PUT', $self->_group_url, $body ); 1; } or do {
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
and lowercased, then removed from the ban list. The full Network Group object
is re-rendered without it and PUT to the networkgroups endpoint. Unbanning an
IP that is not banned is a noop. If the PUT fails, the IP is restored to the
ban list.

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
		$self->{frontend_obj}->{test_data} = [ { method => 'PUT', url => $self->_group_url, content => $body } ];
	} else {
		local $@;
		eval { $self->_request( 'PUT', $self->_group_url, $body ); 1; } or do {
			$self->{banned}{ $opts{ban} } = 1;
			$self->{error}       = 14;
			$self->{errorString} = 'unbanning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	}
} ## end sub unban

=head2 ban_cidr

Bans a CIDR range. The value of ban is validated as being a IPv4 or IPv6 CIDR
range and lowercased, then added to the CIDR ban list. The full Network Group
object, with the range as a C<Network> literal, is rendered and PUT to the
networkgroups endpoint. Banning an already banned range is a noop. If the PUT
fails, the range is removed from the ban list again.

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
		$self->{error}       = 36;
		$self->{errorString} = 'Bad ref type for ban... ref is "' . ref( $opts{ban} ) . '"';
		$self->warn;
		return;
	} elsif ( !$self->_valid_cidr( $opts{ban} ) ) {
		$self->{error}       = 36;
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
		$self->{frontend_obj}->{test_data} = [ { method => 'PUT', url => $self->_group_url, content => $body } ];
	} else {
		local $@;
		eval { $self->_request( 'PUT', $self->_group_url, $body ); 1; } or do {
			delete( $self->{banned_cidr}{ $opts{ban} } );
			$self->{error}       = 34;
			$self->{errorString} = 'banning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	}
} ## end sub ban_cidr

=head2 unban_cidr

Unbans a CIDR range. The value of ban is validated as being a IPv4 or IPv6
CIDR range and lowercased, then removed from the CIDR ban list. The full
Network Group object is re-rendered without it and PUT to the networkgroups
endpoint. Unbanning a range that is not banned is a noop. If the PUT fails,
the range is restored to the ban list.

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
		$self->{error}       = 36;
		$self->{errorString} = 'Bad ref type for ban... ref is "' . ref( $opts{ban} ) . '"';
		$self->warn;
		return;
	} elsif ( !$self->_valid_cidr( $opts{ban} ) ) {
		$self->{error}       = 36;
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
		$self->{frontend_obj}->{test_data} = [ { method => 'PUT', url => $self->_group_url, content => $body } ];
	} else {
		local $@;
		eval { $self->_request( 'PUT', $self->_group_url, $body ); 1; } or do {
			$self->{banned_cidr}{ $opts{ban} } = 1;
			$self->{error}       = 35;
			$self->{errorString} = 'unbanning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	}
} ## end sub unban_cidr

=head2 list_cidr

List banned CIDR ranges. Returns an array of the currently banned ranges from
internal state; the FMC is not queried. Single IPs are not included; for those
see L</list>.

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

List banned IPs. Returns an array of the currently banned single IPs from
internal state; the FMC is not queried. CIDR ranges are not included; for
those see L</list_cidr>.

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

Tears down and re-inits, then re-adds all previously added bans by rendering
and PUTing the full Network Group object.

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
		$self->{frontend_obj}->{test_data} = [ { method => 'PUT', url => $self->_group_url, content => $body } ];
	} else {
		local $@;
		eval { $self->_request( 'PUT', $self->_group_url, $body ); 1; } or do {
			$self->{error}       = 16;
			$self->{errorString} = 're_init failed rendering the group... ' . $@;
			$self->warn;
		};
	}

	$self->{inited} = 1;
} ## end sub re_init

=head2 teardown

Tears down the setup by PUTing the Network Group object with an empty literal
set. The internal list of bans is kept, so a following re_init will re-add
them.

=cut

sub teardown {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{inited} = 0;

	# render an empty literal set without disturbing the internal ban list
	my $body = $self->_json->encode(
		{
			name     => $self->{options}{group_name},
			id       => $self->{options}{group_id},
			literals => [],
		}
	);

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'PUT', url => $self->_group_url, content => $body } ];
	} else {
		local $@;
		eval { $self->_request( 'PUT', $self->_group_url, $body ); 1; } or do {
			$self->{error}       = 17;
			$self->{errorString} = 'teardown failed clearing the group... ' . $@;
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

Verifies the endpoint and token are still usable by fetching the Network Group
object. Returns a true value if so and a false value otherwise.

=cut

sub check {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'GET', url => $self->_group_url } ];
		return 1;
	}

	local $@;
	eval { $self->_request( 'GET', $self->_group_url ); 1; } or return 0;

	return 1;
} ## end sub check

=head2 flush

Removes all currently banned IPs and CIDR ranges at once by PUTing the
Network Group object with an empty literal set and forgetting them.

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

	$self->{banned}      = {};
	$self->{banned_cidr} = {};

	my $body = $self->_render;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'PUT', url => $self->_group_url, content => $body } ];
	} else {
		local $@;
		eval { $self->_request( 'PUT', $self->_group_url, $body ); 1; } or do {
			$self->{error}       = 25;
			$self->{errorString} = 'flush failed clearing the group... ' . $@;
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

init failed. Generating an auth token failed.

=head2 24, checkFailed

The backend check raised an error.

=head2 25, flushFailed

Failed to flush the bans.

=head2 26, portsNotSupported

The cisco_fmc backend blocks whole IPs and does not support ports.

=head2 27, protocolsNotSupported

The cisco_fmc backend blocks whole IPs and does not support protocols.

=head2 30, hostNotDefined

The option host is undef or blank.

=head2 31, userNotDefined

The option user is undef or blank.

=head2 32, passwordNotDefined

The option password is undef or blank.

=head2 33, groupIdNotDefined

The option group_id is undef or blank.

=head2 34, banCidrFailed

Failed to ban the CIDR range.

=head2 35, unbanCidrFailed

Failed to unban the CIDR range.

=head2 36, cidrItemNotCidr

The item to ban is not a CIDR range. Either wrong ref type or it is not an
IPv4 or IPv6 address followed by a prefix length valid for its family.

=head2 37, cidrNotSupported

The backend does not support CIDR bans.

=head2 38, listCidrFailed

Failed to get a list of CIDR bans.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.ent> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut

1;    # End of Net::Firewall::BlockerHelper::backends::cisco_fmc
