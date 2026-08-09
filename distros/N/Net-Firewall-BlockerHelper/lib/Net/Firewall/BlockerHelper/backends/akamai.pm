package Net::Firewall::BlockerHelper::backends::akamai;

use 5.006;
use strict;
use warnings;
use base         qw( Error::Helper Net::Firewall::BlockerHelper::Util );
use Regexp::IPv4 qw($IPv4_re);
use Regexp::IPv6 qw($IPv6_re);

=head1 NAME

Net::Firewall::BlockerHelper::backends::akamai - Akamai Network Lists backend for Net::Firewall::BlockerHelper.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 SYNOPSIS

    use Net::Firewall::BlockerHelper;

    my $fw_helper = Net::Firewall::BlockerHelper->new(
        backend => 'akamai',
        name    => 'ssh',
        options => {
            host            => 'akab-xxxx.luna.akamaiapis.net',
            client_token    => $client_token,
            client_secret   => $client_secret,
            access_token    => $access_token,
            network_list_id => $network_list_id,
        },
    );

    $fw_helper->init_backend;
    $fw_helper->ban( ban => '1.2.3.4' );
    $fw_helper->unban( ban => '1.2.3.4' );

=head1 DESCRIPTION

Blocks IPs remotely via the Akamai Network Lists API v2, adding and removing
elements of an existing network list. Requests are authenticated using
Akamai's EdgeGrid (C<EG1-HMAC-SHA256>) request signing scheme.

The network list identified by the C<network_list_id> option must already
exist. This backend only manages the membership of that list.

Blocking is per IP or CIDR range; ports and protocols are not supported and
specifying them is an error.

B<Note:> Changes to a network list made via the API do not take effect until
the list is activated (staging and/or production). Activation is out of scope
for this backend and must be performed separately, either via the Akamai
control center or the activation endpoints of the Network Lists API.
Similarly, membership in the list does not block anything on its own; the
list must actually be used by a security policy, eg as the block list of a
IP/Geo firewall rule. Wiring the list into a policy is likewise out of scope
for this backend.

L<LWP::UserAgent> is only loaded at run time, so it is only required if this
backend is actually used. For https, L<LWP::Protocol::https> must be present
as well.

=head1 METHODS

=head2 new

Initiates the object.

    - options :: Backend specific options. See below.
        - Default :: {}

    - prefix :: Prefix to use. Must match the regex /^[a-zA-Z0-9]+$/
        - default :: kur

    - name :: Name of this specific instance. This must be specified.
        - default :: undef

Ports and protocols are not supported by this backend and specifying either
is an error.

The options hash accepts the following. The host, client_token,
client_secret, access_token, and network_list_id options are all required.

    - host :: Akamai API hostname, eg akab-xxxx.luna.akamaiapis.net .
        - Default :: undef

    - client_token :: EdgeGrid client token.
        - Default :: undef

    - client_secret :: EdgeGrid client secret.
        - Default :: undef

    - access_token :: EdgeGrid access token.
        - Default :: undef

    - network_list_id :: ID of the network list to manage.
        - Default :: undef

    - timeout :: HTTP timeout in seconds.
        - Default :: 30

    - insecure :: If true, skip TLS certificate verification.
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
				31 => 'clientTokenNotDefined',
				32 => 'clientSecretNotDefined',
				33 => 'accessTokenNotDefined',
				34 => 'networkListIdNotDefined',
				35 => 'banCidrFailed',
				36 => 'unbanCidrFailed',
				37 => 'cidrItemNotCidr',
				38 => 'cidrNotSupported',
				39 => 'listCidrFailed',
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

	# blocking is per IP; the network list has no concept of ports or protocols
	if ( defined( $opts{ports} ) && ref( $opts{ports} ) eq 'ARRAY' && defined( $opts{ports}[0] ) ) {
		$self->{perror}      = 1;
		$self->{error}       = 26;
		$self->{errorString} = 'the akamai backend blocks whole IPs and does not support ports';
		$self->warn;
	}
	if ( defined( $opts{protocols} ) && ref( $opts{protocols} ) eq 'ARRAY' && defined( $opts{protocols}[0] ) ) {
		$self->{perror}      = 1;
		$self->{error}       = 27;
		$self->{errorString} = 'the akamai backend blocks whole IPs and does not support protocols';
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

	# required options
	if ( !defined( $self->{options}{host} ) || $self->{options}{host} eq '' ) {
		$self->{perror}      = 1;
		$self->{error}       = 30;
		$self->{errorString} = 'the option host is undef or blank';
		$self->warn;
	}
	if ( !defined( $self->{options}{client_token} ) || $self->{options}{client_token} eq '' ) {
		$self->{perror}      = 1;
		$self->{error}       = 31;
		$self->{errorString} = 'the option client_token is undef or blank';
		$self->warn;
	}
	if ( !defined( $self->{options}{client_secret} ) || $self->{options}{client_secret} eq '' ) {
		$self->{perror}      = 1;
		$self->{error}       = 32;
		$self->{errorString} = 'the option client_secret is undef or blank';
		$self->warn;
	}
	if ( !defined( $self->{options}{access_token} ) || $self->{options}{access_token} eq '' ) {
		$self->{perror}      = 1;
		$self->{error}       = 33;
		$self->{errorString} = 'the option access_token is undef or blank';
		$self->warn;
	}
	if ( !defined( $self->{options}{network_list_id} ) || $self->{options}{network_list_id} eq '' ) {
		$self->{perror}      = 1;
		$self->{error}       = 34;
		$self->{errorString} = 'the option network_list_id is undef or blank';
		$self->warn;
	}

	# defaults
	$self->{options}{timeout}  = 30 if ( !defined( $self->{options}{timeout} ) );
	$self->{options}{insecure} = 0  if ( !defined( $self->{options}{insecure} ) );

	return $self;
} ## end sub new

# Internal helper. Returns the scheme and host of the Akamai API endpoint,
# which every URL is built on.
#
# The host is the per account API hostname from an EdgeGrid credential set,
# something of the akab-....luna.akamaiapis.net form, not a shared endpoint.
# The scheme is fixed at https, which EdgeGrid requires and which the request
# signing also assumes.
#
# Takes no arguments; the host comes from the options.
#
# Returns the base URL as a string, with no trailing slash.
#
#     $self->_base_url;    # https://akab-xxx.luna.akamaiapis.net
sub _base_url {
	my ($self) = @_;

	return 'https://' . $self->{options}{host};
}

# Internal helper. Returns the URL of the network list this instance manages.
#
# This is the object every ban and unban acts on. It is addressed by the
# network list id, which is Akamai's own identifier rather than a name the
# caller chose, and the list is expected to already exist and be referenced by
# a security configuration; this backend does not create it.
#
# As well as being used directly for reading the list, this is the stem the
# append and element URLs are built on.
#
# Takes no arguments; the network list id comes from the options.
#
# Returns the URL as a string, with no trailing slash.
#
#     $self->_list_url;
#     #   https://akab-xxx.luna.akamaiapis.net/network-list/v2/network-lists/12345_BLOCKLIST
sub _list_url {
	my ($self) = @_;

	return $self->_base_url . '/network-list/v2/network-lists/' . $self->{options}{network_list_id};
}

# Internal helper. Returns the URL that adds elements to the network list.
#
# Akamai's network list API is incremental rather than replace-in-full, which
# is what makes this backend cheaper than the ones that rewrite an entire
# object per ban: appending adds to whatever is already there without needing
# to know the current contents.
#
# Takes no arguments.
#
# Returns the URL as a string, for a POST whose body carries the elements to
# add.
#
#     $self->_append_url;
#     #   https://akab-xxx.luna.akamaiapis.net/network-list/v2/network-lists/12345_BLOCKLIST/append
sub _append_url {
	my ($self) = @_;

	return $self->_list_url . '/append';
}

# Internal helper. Returns the URL that removes one element from the network
# list.
#
# The counterpart of _append_url, and incremental in the same way: the element
# to drop is named in the query string, so nothing needs to be read back or
# rewritten. Unlike the routeros_api backend there is no id to look up first,
# since Akamai addresses elements by their value.
#
# The element is percent encoded, which matters for IPv6, whose colons would
# otherwise sit raw in the query string, and for ranges, whose slash would.
#
# Args:
#
#     ip - The element to remove, as a plain string. Expected to be an already
#          validated and lowercased IPv4 or IPv6 address, or a CIDR range;
#          Akamai network lists hold both and this treats them the same.
#
# Returns the URL as a string, for a DELETE that carries no body.
#
#     $self->_element_url('10.0.0.1');
#     #   https://akab-xxx.luna.akamaiapis.net/network-list/v2/network-lists/12345_BLOCKLIST/elements?element=10.0.0.1
#
#     $self->_element_url('2001:db8::1');
#     #   .../elements?element=2001%3Adb8%3A%3A1
sub _element_url {
	my ( $self, $ip ) = @_;

	return $self->_list_url . '/elements?element=' . $self->_uri_escape($ip);
}

# Internal helper. Builds the EdgeGrid Authorization header for one request.
# This is the most intricate piece of this backend and the reason it cannot
# just use HTTP basic auth like the other API backends.
#
# Akamai signs each request rather than sending a standing credential. The
# scheme is EG1-HMAC-SHA256 and works in two stages: a signing key is derived
# by HMACing the timestamp with the client secret, and the request itself is
# then HMACed with that derived key. Signing the timestamp rather than the
# request with the long lived secret is what limits how long any one derived
# key is useful for.
#
# The data to sign is a tab separated canonical form of the request: method,
# scheme, host, path with query, an always empty canonicalized headers field
# since none are signed here, the content hash, and the partial Authorization
# header itself. Getting any field or separator wrong produces a signature the
# API rejects with no useful diagnosis, so the ordering here is not
# rearrangeable.
#
# Two details are easy to get wrong and worth knowing about. Digest::SHA
# returns base64 without the trailing '=' padding, which EdgeGrid requires, so
# every digest is passed through a local padding closure. And the content hash
# is only included for POST requests with a non empty body; sending it for a
# GET or DELETE would change the signed string and fail.
#
# The timestamp is UTC in EdgeGrid's own format, and the nonce is four
# concatenated random 32 bit values, which is enough to keep replay detection
# from tripping on repeated requests.
#
# Never called in testing mode, since nothing is signed when nothing is sent.
#
# Args:
#
#     method - The HTTP method the request will use, as a plain string. Upper
#               cased before signing, and compared against POST to decide
#               whether a content hash is included.
#
#     url    - The full URL the request will go to, as a plain string. The
#              scheme and host are stripped off to leave the path and query,
#              which is what gets signed; an empty remainder becomes '/'.
#
#     body   - The request body, as a plain string, or undef for requests that
#              carry none. Only used for POST, where its SHA-256 becomes the
#              content hash.
#
# Returns the complete Authorization header value as a string, of the form
# 'EG1-HMAC-SHA256 client_token=..;access_token=..;timestamp=..;nonce=..;signature=..'.
# Note the value is single use: it embeds a timestamp and nonce, so it must be
# rebuilt for every request rather than cached.
#
#     my $auth = $self->_edgegrid_auth( 'GET', $self->_list_url );
#
#     my $auth = $self->_edgegrid_auth( 'POST', $self->_append_url, $body );
sub _edgegrid_auth {
	my ( $self, $method, $url, $body ) = @_;

	require Digest::SHA;
	require MIME::Base64;
	require POSIX;

	# EdgeGrid uses a UTC timestamp of the form yyyyMMddTHH:mm:ss+0000
	my $timestamp = POSIX::strftime( '%Y%m%dT%H:%M:%S+0000', gmtime() );

	# simple random hex nonce
	my $nonce = sprintf( '%08x%08x%08x%08x',
		int( rand(0xffffffff) ), int( rand(0xffffffff) ),
		int( rand(0xffffffff) ), int( rand(0xffffffff) ) );

	# split the URL into host and path+query
	my $host = $self->{options}{host};
	my $path_and_query = $url;
	$path_and_query =~ s{^https?://[^/]+}{};
	if ( $path_and_query eq '' ) {
		$path_and_query = '/';
	}

	# base64 helper that pads to a multiple of 4 with '=' as Digest::SHA omits
	# the padding
	my $pad = sub {
		my ($string) = @_;
		while ( length($string) % 4 ) {
			$string .= '=';
		}
		return $string;
	};

	my $auth_header_without_sig
		= 'EG1-HMAC-SHA256 '
		. 'client_token='
		. $self->{options}{client_token} . ';'
		. 'access_token='
		. $self->{options}{access_token} . ';'
		. 'timestamp='
		. $timestamp . ';'
		. 'nonce='
		. $nonce . ';';

	my $signing_key = $pad->( Digest::SHA::hmac_sha256_base64( $timestamp, $self->{options}{client_secret} ) );

	# content hash is only present for POST requests
	my $content_hash = '';
	if ( uc($method) eq 'POST' && defined($body) && $body ne '' ) {
		$content_hash = $pad->( Digest::SHA::sha256_base64($body) );
	}

	my $data_to_sign = join( "\t",
		uc($method),
		'https',
		$host,
		$path_and_query,
		'',              # canonicalized headers, none used here
		$content_hash,
		$auth_header_without_sig,
	);

	my $signature = $pad->( Digest::SHA::hmac_sha256_base64( $data_to_sign, $signing_key ) );

	return $auth_header_without_sig . 'signature=' . $signature;
} ## end sub _edgegrid_auth

# Internal helper. Performs one HTTP request against the Akamai network list
# API. Every call this backend makes goes through here.
#
# The user agent is built on first use and cached on the object, so a run of
# requests shares one agent. LWP::UserAgent is loaded with require at that
# point rather than at compile time, since only the HTTP backends need it;
# failing to load it dies with an explanation naming this backend.
#
# Authentication is an EdgeGrid signature built per request by
# _edgegrid_auth. Unlike the backends using basic auth or a session token,
# nothing here can be cached: the header embeds a timestamp and nonce and
# covers the method, URL, and body, so it has to be recomputed even for a
# repeat of the same call.
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
#     method - The HTTP method, as a plain string: 'GET' to read the list,
#              'POST' to append elements, 'DELETE' to remove one.
#
#     url    - The full URL to request, as a plain string, from _list_url,
#              _append_url, or _element_url.
#
#     body   - Optional request body, as an already encoded JSON string. undef
#              for the reads and deletes, which carry everything in the URL.
#              Note this is also what gets hashed into the signature for a
#              POST, so it must be the exact bytes sent.
#
# Returns the decoded response body as whatever structure the JSON held,
# normally a hashref, or undef when the response body was empty or did not
# parse. Dies on any non success HTTP status.
#
#     my $decoded = $self->_request( 'GET', $self->_list_url );
#
#     # the usual shape at the call sites
#     eval { $self->_request( 'POST', $self->_append_url, $body ); };
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
		} or die( 'failed to load LWP::UserAgent, which the akamai backend requires... ' . $@ );
	}

	my $auth = $self->_edgegrid_auth( $method, $url, $body );

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

Initiates the backend. Verifies the credentials and endpoint by GETing the
network list at C</network-list/v2/network-lists/$network_list_id>. Nothing
is created remotely; the list must already exist.

Note that for bans to have an effect the list must also be activated and in
use by a security policy. See L</DESCRIPTION>.

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

	my $url = $self->_list_url;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'GET', url => $url } ];
	} else {
		local $@;
		eval { $self->_request( 'GET', $url ); 1; } or do {
			$self->{error}       = 23;
			$self->{errorString} = 'init failed. probing the network list endpoint failed... ' . $@;
			$self->warn;
		};
	}

	$self->{inited} = 1;
} ## end sub init

=head2 ban

Bans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then appended to the network list via a POST to the list's
C</append> endpoint. Banning an already banned IP is a noop.

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

	my $body = $self->_json->encode( { list => [ $opts{ban} ] } );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'POST', url => $self->_append_url, content => $body } ];
	} else {
		local $@;
		eval { $self->_request( 'POST', $self->_append_url, $body ); 1; } or do {
			$self->{error}       = 13;
			$self->{errorString} = 'banning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	}

	$self->{banned}{ $opts{ban} } = 1;
} ## end sub ban

=head2 unban

Unbans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then removed from the network list via a DELETE of its
element at the list's C</elements> endpoint. Unbanning an IP that is not
banned is a noop.

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

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'DELETE', url => $self->_element_url( $opts{ban} ) } ];
	} else {
		local $@;
		eval { $self->_request( 'DELETE', $self->_element_url( $opts{ban} ) ); 1; } or do {
			$self->{error}       = 14;
			$self->{errorString} = 'unbanning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	}

	delete( $self->{banned}{ $opts{ban} } );
} ## end sub unban

=head2 ban_cidr

Bans a CIDR range. The value of ban is validated as being a IPv4 or IPv6
CIDR and lowercased, then appended to the network list via a POST to the
list's C</append> endpoint; Akamai network lists accept a CIDR range as a
list element in the same manner as a single address. Banning an already
banned range is a noop.

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
		$self->{error}       = 37;
		$self->{errorString} = 'Bad ref type for ban... ref is "' . ref( $opts{ban} ) . '"';
		$self->warn;
		return;
	} elsif ( !$self->_valid_cidr( $opts{ban} ) ) {
		$self->{error}       = 37;
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

	my $body = $self->_json->encode( { list => [ $opts{ban} ] } );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'POST', url => $self->_append_url, content => $body } ];
	} else {
		local $@;
		eval { $self->_request( 'POST', $self->_append_url, $body ); 1; } or do {
			$self->{error}       = 35;
			$self->{errorString} = 'banning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	}

	$self->{banned_cidr}{ $opts{ban} } = 1;
} ## end sub ban_cidr

=head2 unban_cidr

Unbans a CIDR range. The value of ban is validated as being a IPv4 or IPv6
CIDR and lowercased, then removed from the network list via a DELETE of its
element at the list's C</elements> endpoint. Unbanning a range that is not
banned is a noop.

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
		$self->{error}       = 37;
		$self->{errorString} = 'Bad ref type for ban... ref is "' . ref( $opts{ban} ) . '"';
		$self->warn;
		return;
	} elsif ( !$self->_valid_cidr( $opts{ban} ) ) {
		$self->{error}       = 37;
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

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'DELETE', url => $self->_element_url( $opts{ban} ) } ];
	} else {
		local $@;
		eval { $self->_request( 'DELETE', $self->_element_url( $opts{ban} ) ); 1; } or do {
			$self->{error}       = 36;
			$self->{errorString} = 'unbanning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	}

	delete( $self->{banned_cidr}{ $opts{ban} } );
} ## end sub unban_cidr

=head2 list_cidr

List banned CIDR ranges. Returns an array of the currently banned CIDR
ranges from internal state; the network list is not fetched. Single IPs are
not included; for those see L</list>.

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
internal state; the network list is not fetched. CIDR ranges are not
included; for those see L</list_cidr>.

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

Tears down and re-initiates the backend. teardown is called best effort,
then init, after which every previously banned single IP and CIDR range is
re-added to the network list via POSTs to the list's C</append> endpoint.

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

	# single IPs and CIDR ranges are both re-added as list elements
	my @to_ban = ( sort( keys( %{ $self->{banned} } ) ), sort( keys( %{ $self->{banned_cidr} } ) ) );

	my @re_init_test_data;
	foreach my $item (@to_ban) {
		my $body = $self->_json->encode( { list => [$item] } );

		if ( $self->{testing} ) {
			push( @re_init_test_data, { method => 'POST', url => $self->_append_url, content => $body } );
		} else {
			local $@;
			eval { $self->_request( 'POST', $self->_append_url, $body ); 1; } or do {
				$self->{error}       = 13;
				$self->{errorString} = 'banning "' . $item . '" failed... ' . $@;
				$self->warn;
			};
		}
	} ## end foreach my $item (@to_ban)

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@re_init_test_data;
	}

	$self->{inited} = 1;
} ## end sub re_init

=head2 teardown

Tears down the setup for the backend by DELETEing the element for each
currently banned single IP from the network list. Banned CIDR ranges are
left in place. The internal list of bans is kept, so a following re_init
will re-add them.

    $backend->teardown;

=cut

sub teardown {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{inited} = 0;

	my @requests;
	foreach my $item ( sort( keys( %{ $self->{banned} } ) ) ) {
		if ( $self->{testing} ) {
			push( @requests, { method => 'DELETE', url => $self->_element_url($item) } );
		} else {
			local $@;
			eval { $self->_request( 'DELETE', $self->_element_url($item) ); 1; } or do {
				$self->{error}       = 17;
				$self->{errorString} = 'teardown failed removing the element for "' . $item . '"... ' . $@;
				$self->warn;
			};
		}
	} ## end foreach my $item ( sort( keys( %{ $self->{banned...})))

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@requests;
	}
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

Verifies the endpoint and credentials are still usable by fetching the
network list. Returns a true value if so and a false value otherwise. This is
the equivalent of fail2ban's C<actioncheck>.

    if ( !$backend->check ) {
        $backend->re_init;
    }

=cut

sub check {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	my $url = $self->_list_url;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'GET', url => $url } ];
		return 1;
	}

	local $@;
	eval { $self->_request( 'GET', $url ); 1; } or return 0;

	return 1;
} ## end sub check

=head2 flush

Removes all currently banned IPs and CIDR ranges at once by DELETEing their
elements from the network list and forgetting them. This is the equivalent
of fail2ban's C<actionflush>.

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

	my @requests;
	foreach my $item ( sort( keys( %{ $self->{banned} } ) ), sort( keys( %{ $self->{banned_cidr} } ) ) ) {
		if ( $self->{testing} ) {
			push( @requests, { method => 'DELETE', url => $self->_element_url($item) } );
		} else {
			local $@;
			eval { $self->_request( 'DELETE', $self->_element_url($item) ); 1; } or do {
				$self->{error}       = 25;
				$self->{errorString} = 'flush failed removing the element for "' . $item . '"... ' . $@;
				$self->warn;
			};
		}
	} ## end foreach my $item ( sort( keys( %{ $self...}))...)

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@requests;
	}

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

init failed. Probing the network list endpoint failed.

=head2 24, checkFailed

The backend check raised an error.

=head2 25, flushFailed

Failed to flush the bans.

=head2 26, portsNotSupported

The akamai backend blocks whole IPs and does not support ports.

=head2 27, protocolsNotSupported

The akamai backend blocks whole IPs and does not support protocols.

=head2 30, hostNotDefined

The option host is undef or blank.

=head2 31, clientTokenNotDefined

The option client_token is undef or blank.

=head2 32, clientSecretNotDefined

The option client_secret is undef or blank.

=head2 33, accessTokenNotDefined

The option access_token is undef or blank.

=head2 34, networkListIdNotDefined

The option network_list_id is undef or blank.

=head2 35, banCidrFailed

Failed to ban the CIDR range.

=head2 36, unbanCidrFailed

Failed to unban the CIDR range.

=head2 37, cidrItemNotCidr

The item to ban is not a CIDR range. Either wrong ref type or it is not an
IPv4 or IPv6 address followed by a prefix length valid for its family.

=head2 38, cidrNotSupported

The backend does not support CIDR bans.

=head2 39, listCidrFailed

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

1;    # End of Net::Firewall::BlockerHelper::backends::akamai
