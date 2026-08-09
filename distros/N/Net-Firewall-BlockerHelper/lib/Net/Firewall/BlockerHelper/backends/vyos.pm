package Net::Firewall::BlockerHelper::backends::vyos;

use 5.006;
use strict;
use warnings;
use base         qw( Error::Helper Net::Firewall::BlockerHelper::Util );
use Regexp::IPv4 qw($IPv4_re);
use Regexp::IPv6 qw($IPv6_re);

=head1 NAME

Net::Firewall::BlockerHelper::backends::vyos - VyOS backend using the HTTP API.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 SYNOPSIS

    use Net::Firewall::BlockerHelper;

    my $fw_helper = Net::Firewall::BlockerHelper->new(
        backend => 'vyos',
        name    => 'ssh',
        options => {
            host => '10.0.0.1',
            key  => $vyos_api_key,
        },
    );

    $fw_helper->init_backend;
    $fw_helper->ban( ban => '1.2.3.4' );
    $fw_helper->unban( ban => '1.2.3.4' );

=head1 DESCRIPTION

Blocks IPs on a VyOS device via its HTTP API, adding and removing entries in a
firewall address-group. IPv4 addresses are managed under the config path
C<< firewall group address-group <group> address <ip> >> and IPv6 under
C<< firewall group ipv6-address-group <group> address <ip> >>, using the group
name given by the C<group> option (defaulting to C<< <prefix>_<name> >>).

The VyOS HTTP API takes C<application/x-www-form-urlencoded> POSTs where the
body is C<< data=<url-escaped JSON>&key=<apikey> >>. Configuration changes are
POSTed to C<< https://<host>/configure >> and are auto-committed. The banned
addresses are managed only here; a firewall rule referencing the address-group
must already exist on the device.

Blocking is per IP; ports and protocols belong on the referencing rule, so
specifying them here is an error.

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

    - host :: VyOS host, optionally host:port. Required.
        - Default :: undef

    - key :: VyOS HTTP API key. Required.
        - Default :: undef

    - group :: Firewall address-group name the banned addresses are added to.
            The same name is used for the IPv4 address-group and the IPv6
            ipv6-address-group.
        - Default :: <prefix>_<name>

    - insecure :: If true, skip TLS certificate verification (VyOS ships a
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
		name         => undef,
		frontend_obj   => undef,
		inited         => 0,
		banned         => {},
		banned_cidr    => {},
		cidr_supported => 1,
		ua             => undef,
	};
	bless $self;

	# blocking is per IP; ports/protocols belong on the referencing rule
	if ( defined( $opts{ports} ) && ref( $opts{ports} ) eq 'ARRAY' && defined( $opts{ports}[0] ) ) {
		$self->{perror}      = 1;
		$self->{error}       = 26;
		$self->{errorString} = 'the vyos backend manages whole IPs and does not support ports';
		$self->warn;
	}
	if ( defined( $opts{protocols} ) && ref( $opts{protocols} ) eq 'ARRAY' && defined( $opts{protocols}[0] ) ) {
		$self->{perror}      = 1;
		$self->{error}       = 27;
		$self->{errorString} = 'the vyos backend manages whole IPs and does not support protocols';
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
	if ( !defined( $self->{options}{key} ) || $self->{options}{key} eq '' ) {
		$self->{perror}      = 1;
		$self->{error}       = 31;
		$self->{errorString} = 'the option key is undef or blank';
		$self->warn;
	}

	# defaults
	$self->{options}{insecure} = 0  if ( !defined( $self->{options}{insecure} ) );
	$self->{options}{timeout}  = 30 if ( !defined( $self->{options}{timeout} ) );
	if ( defined( $self->{name} ) ) {
		$self->{options}{group} = $self->{prefix} . '_' . $self->{name} if ( !defined( $self->{options}{group} ) );
	}

	return $self;
} ## end sub new

# Internal helper. Returns the VyOS configuration path identifying one
# address's membership in the firewall group.
#
# The VyOS API addresses configuration by path, an ordered list of nodes
# walking down the configuration tree, rather than by URL. Setting or deleting
# that path is what adds or removes the address, so this one path serves both
# operations.
#
# The node differs by family, since VyOS keeps IPv4 and IPv6 in separate group
# types. Note the family test here matches against $IPv6_re and treats
# everything else as IPv4, the opposite way round to most of the dist, which
# tests for IPv4 and falls back to IPv6.
#
# Args:
#
#     ip - The address whose path is wanted, as a plain string. Expected to be
#          an already validated and lowercased IPv4 or IPv6 address.
#
# Returns the path as an arrayref of node strings, ready to be the path value
# of an operation. The group name comes from the group option.
#
#     $self->_group_path('10.0.0.1');
#     #   [ 'firewall', 'group', 'address-group', 'kur_ssh', 'address', '10.0.0.1' ]
#
#     $self->_group_path('2001:db8::1');
#     #   [ 'firewall', 'group', 'ipv6-address-group', 'kur_ssh', 'address', '2001:db8::1' ]
sub _group_path {
	my ( $self, $ip ) = @_;

	my $node = ( $ip =~ /\A$IPv6_re\z/ ) ? 'ipv6-address-group' : 'address-group';

	return [ 'firewall', 'group', $node, $self->{options}{group}, 'address', $ip ];
}

# Internal helper. Builds the JSON operation describing a configuration change
# for one address, which is what the VyOS API's data parameter carries.
#
# Splitting this out from _form_body is what keeps the API key out of
# test_data. This half holds everything about the operation and nothing
# secret, so the testing paths record it directly; the key is only added by
# _form_body, which testing mode never calls. A test can therefore assert on
# exactly what would be configured without the recorded data carrying a
# credential.
#
# Args:
#
#     op - The operation, as a plain string: 'set' to add the address to the
#          group or 'delete' to remove it. Passed through to the API as is, so
#          anything else would be rejected there rather than here.
#
#     ip - The address to operate on, as a plain string. Expected to be an
#          already validated and lowercased IPv4 or IPv6 address. The family
#          selects the group node via _group_path.
#
# Returns the operation as a JSON string, ready to become the data value.
#
#     $self->_op_json( 'set', '10.0.0.1' );
#     #   {"op":"set","path":["firewall","group","address-group","kur_ssh","address","10.0.0.1"]}
#
#     $self->_op_json( 'delete', '10.0.0.1' );
#     #   {"op":"delete","path":["firewall","group","address-group","kur_ssh","address","10.0.0.1"]}
sub _op_json {
	my ( $self, $op, $ip ) = @_;

	return $self->_json->encode( { op => $op, path => $self->_group_path($ip) } );
}

# Internal helper. Builds the complete form encoded request body for a
# configuration change, the JSON operation plus the API key.
#
# The VyOS API takes both as form fields rather than the key going in a
# header, so the credential is part of the body. That is precisely why this is
# separate from _op_json and why testing mode never calls it: keeping the key
# confined to this sub is what stops it reaching test_data.
#
# Both values are percent encoded, which matters for the JSON in particular
# since it is full of braces, quotes, and colons.
#
# Args:
#
#     op - The operation, as a plain string, 'set' or 'delete'. Passed
#          straight to _op_json.
#
#     ip - The address to operate on, as a plain string. Expected to be an
#          already validated and lowercased IPv4 or IPv6 address.
#
# Returns the body as a form urlencoded string, ready to POST to _base_url.
#
#     $self->_form_body( 'set', '10.0.0.1' );
#     #   data=%7B%22op%22%3A%22set%22%2C%22path%22%3A%5B...%5D%7D&key=secret
sub _form_body {
	my ( $self, $op, $ip ) = @_;

	return
		  'data='
		. $self->_uri_escape( $self->_op_json( $op, $ip ) )
		. '&key='
		. $self->_uri_escape( $self->{options}{key} );
} ## end sub _form_body

# Internal helper. Returns the URL of the VyOS HTTP API.
#
# There is a single endpoint. Everything the API does is decided by the
# operation in the posted body rather than by the path, so unlike the REST
# backends there is no URL to build per operation.
#
# The scheme is fixed at https rather than configurable, since the VyOS API is
# expected to be run over TLS.
#
# Takes no arguments; the host comes from the options.
#
# Returns the URL as a string, with no trailing slash.
#
#     $self->_base_url;    # https://vyos.example.org
sub _base_url {
	my ($self) = @_;

	return 'https://' . $self->{options}{host};
}

# Internal helper. Builds the JSON operation that reads back the firewall
# group's configuration, used by init and check.
#
# Since this backend creates nothing, the group existing is the whole of its
# setup, and a group deleted out from under a running process is what this
# detects. init runs it so a misconfigured group name fails immediately rather
# than at the first ban, and check runs it to decide whether the self heal
# path should re-push the current bans.
#
# The path stops at the group rather than descending to an address, and the op
# is showConfig rather than set or delete, so nothing is modified.
#
# Note the path is hardcoded to the IPv4 address-group node. An instance
# banning only IPv6 addresses would still have its health checked against the
# IPv4 group.
#
# As with _op_json, this holds nothing secret and is what the testing paths
# record; the key is only added by _retrieve_form_body.
#
# Takes no arguments; the group name comes from the options.
#
# Returns the operation as a JSON string, ready to become the data value.
#
#     $self->_retrieve_body;
#     #   {"op":"showConfig","path":["firewall","group","address-group","kur_ssh"]}
sub _retrieve_body {
	my ($self) = @_;

	return $self->_json->encode(
		{ op => 'showConfig', path => [ 'firewall', 'group', 'address-group', $self->{options}{group} ] } );
}

# Internal helper. Builds the complete form encoded request body for the
# configuration read, the retrieve operation plus the API key.
#
# This is to _retrieve_body what _form_body is to _op_json, and exists for the
# same reason: it is the only place the key is attached to a read, so testing
# mode can record the operation without the credential.
#
# Takes no arguments.
#
# Returns the body as a form urlencoded string, ready to POST to _base_url.
#
#     $self->_retrieve_form_body;
#     #   data=%7B%22op%22%3A%22showConfig%22%2C%22path%22%3A%5B...%5D%7D&key=secret
sub _retrieve_form_body {
	my ($self) = @_;

	return
		  'data='
		. $self->_uri_escape( $self->_retrieve_body )
		. '&key='
		. $self->_uri_escape( $self->{options}{key} );
} ## end sub _retrieve_form_body

# Internal helper. Performs one HTTP request against the VyOS API. Every call
# this backend makes to the router goes through here.
#
# The user agent is built on first use and cached on the object, so a run of
# requests shares one agent. LWP::UserAgent is loaded with require at that
# point rather than at compile time, since only the HTTP backends need it;
# failing to load it dies with an explanation naming this backend. The
# insecure option turns off certificate verification, which is there because a
# VyOS router commonly presents a self signed certificate.
#
# There is no authentication handling here. The API key travels in the form
# body rather than in a header, so it is already part of what the caller
# passes.
#
# Any HTTP level failure dies rather than setting an error. The callers wrap
# this in eval and turn the exception into the appropriate error code, which
# is what lets one helper serve paths that report ban, unban, and teardown
# failures differently.
#
# Never called in testing mode; those paths record the operation JSON instead,
# which is what keeps the API key out of test_data.
#
# Args:
#
#     method - The HTTP method, as a plain string. In practice always 'POST',
#              since the VyOS API exposes everything as a POST to one
#              endpoint.
#
#     url    - The full URL to request, as a plain string, normally
#              _base_url with the API path appended.
#
#     body   - The form urlencoded request body, as a plain string, from
#              _form_body or _retrieve_form_body. Carries the API key.
#
# Returns the raw response body as a string. Dies on any non success HTTP
# status.
#
#     $self->_request( 'POST', $url, $self->_form_body( 'set', $ip ) );
#
#     # the usual shape at the call sites
#     eval { $self->_request( 'POST', $url, $body ); };
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
		} or die( 'failed to load LWP::UserAgent, which the vyos backend requires... ' . $@ );
	}

	my @headers = ( 'Content-Type' => 'application/x-www-form-urlencoded' );

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

Initiates the backend. Verifies the credentials and reachability by POSTing
a C<showConfig> operation for the address-group to C<< /retrieve >>.
Nothing is created on the device; the referencing firewall rule must
already exist.

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

	my $url = $self->_base_url . '/retrieve';

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data}
			= [ { method => 'POST', url => $url, content => $self->_retrieve_body } ];
	} else {
		local $@;
		eval { $self->_request( 'POST', $url, $self->_retrieve_form_body ); 1; } or do {
			$self->{error}       = 23;
			$self->{errorString} = 'init failed. probing the address-group config failed... ' . $@;
			$self->warn;
		};
	}

	$self->{inited} = 1;
} ## end sub init

=head2 ban

Bans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then a C<set> operation for
C<< firewall group address-group <group> address <ip> >> (or the
C<ipv6-address-group> equivalent) is POSTed to C<< /configure >>. Banning
an already banned IP is a noop.

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

	my $url = $self->_base_url . '/configure';

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data}
			= [ { method => 'POST', url => $url, content => $self->_op_json( 'set', $opts{ban} ) } ];
	} else {
		local $@;
		eval { $self->_request( 'POST', $url, $self->_form_body( 'set', $opts{ban} ) ); 1; } or do {
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
and lowercased, then a C<delete> operation for its address-group entry is
POSTed to C<< /configure >>. Unbanning an IP that is not banned is a noop.

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

	my $url = $self->_base_url . '/configure';

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data}
			= [ { method => 'POST', url => $url, content => $self->_op_json( 'delete', $opts{ban} ) } ];
	} else {
		local $@;
		eval { $self->_request( 'POST', $url, $self->_form_body( 'delete', $opts{ban} ) ); 1; } or do {
			$self->{error}       = 14;
			$self->{errorString} = 'unbanning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	}

	delete( $self->{banned}{ $opts{ban} } );
} ## end sub unban

=head2 ban_cidr

Bans a CIDR range by POSTing a C<set> operation for it to C<< /configure >>,
adding it to the address-group in the same manner as a single IP. The value
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

	my $url = $self->_base_url . '/configure';

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data}
			= [ { method => 'POST', url => $url, content => $self->_op_json( 'set', $opts{ban} ) } ];
	} else {
		local $@;
		eval { $self->_request( 'POST', $url, $self->_form_body( 'set', $opts{ban} ) ); 1; } or do {
			$self->{error}       = 32;
			$self->{errorString} = 'banning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	}

	$self->{banned_cidr}{ $opts{ban} } = 1;
} ## end sub ban_cidr

=head2 unban_cidr

Unbans a CIDR range by POSTing a C<delete> operation for its address-group
entry to C<< /configure >>. The value of ban is validated as being a IPv4
or IPv6 CIDR range and lowercased. Unbanning a range that is not banned is
a noop.

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

	my $url = $self->_base_url . '/configure';

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data}
			= [ { method => 'POST', url => $url, content => $self->_op_json( 'delete', $opts{ban} ) } ];
	} else {
		local $@;
		eval { $self->_request( 'POST', $url, $self->_form_body( 'delete', $opts{ban} ) ); 1; } or do {
			$self->{error}       = 33;
			$self->{errorString} = 'unbanning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	}

	delete( $self->{banned_cidr}{ $opts{ban} } );
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

Tears down and re-inits, then re-adds all previously added bans. teardown
is best effort, as a partially or fully wiped setup is what this needs to
recover from. Each retained single IP and CIDR ban is re-added via a C<set>
operation POSTed to C<< /configure >>.

    $backend->re_init;

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

	my $url = $self->_base_url . '/configure';

	# single IPs and CIDR ranges are both re-added as address-group set ops
	my @to_ban = ( sort( keys( %{ $self->{banned} } ) ), sort( keys( %{ $self->{banned_cidr} } ) ) );

	my @re_init_test_data;
	foreach my $item (@to_ban) {
		if ( $self->{testing} ) {
			push( @re_init_test_data, { method => 'POST', url => $url, content => $self->_op_json( 'set', $item ) } );
		} else {
			local $@;
			eval { $self->_request( 'POST', $url, $self->_form_body( 'set', $item ) ); 1; } or do {
				$self->{error}       = 13;
				$self->{errorString} = 'banning "' . $item . '" failed... ' . $@;
				$self->warn;
			};
		}
	} ## end foreach my $item ( sort( keys...))

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@re_init_test_data;
	}

	$self->{inited} = 1;
} ## end sub re_init

=head2 teardown

Tears down the setup by deleting the address-group entry for each currently
banned IP and CIDR range. The internal list of bans is kept, so a following
re_init will re-add them.

=cut

sub teardown {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{inited} = 0;

	my $url = $self->_base_url . '/configure';

	my @requests;
	foreach my $item ( sort( keys( %{ $self->{banned} } ) ), sort( keys( %{ $self->{banned_cidr} } ) ) ) {
		if ( $self->{testing} ) {
			push( @requests, { method => 'POST', url => $url, content => $self->_op_json( 'delete', $item ) } );
		} else {
			local $@;
			eval { $self->_request( 'POST', $url, $self->_form_body( 'delete', $item ) ); 1; } or do {
				$self->{error}       = 17;
				$self->{errorString} = 'teardown failed removing the entry for "' . $item . '"... ' . $@;
				$self->warn;
			};
		}
	} ## end foreach my $item ( sort( keys...))

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@requests;
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

Verifies the endpoint and credentials are still usable by retrieving the
address-group config. Returns a true value if so and a false value otherwise.

=cut

sub check {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	my $url = $self->_base_url . '/retrieve';

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data}
			= [ { method => 'POST', url => $url, content => $self->_retrieve_body } ];
		return 1;
	}

	local $@;
	eval { $self->_request( 'POST', $url, $self->_retrieve_form_body ); 1; } or return 0;

	return 1;
} ## end sub check

=head2 flush

Removes all currently banned IPs and CIDR ranges at once by deleting their
address-group entries and forgetting them.

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

	my $url = $self->_base_url . '/configure';

	my @requests;
	foreach my $item ( sort( keys( %{ $self->{banned} } ) ), sort( keys( %{ $self->{banned_cidr} } ) ) ) {
		if ( $self->{testing} ) {
			push( @requests, { method => 'POST', url => $url, content => $self->_op_json( 'delete', $item ) } );
		} else {
			local $@;
			eval { $self->_request( 'POST', $url, $self->_form_body( 'delete', $item ) ); 1; } or do {
				$self->{error}       = 25;
				$self->{errorString} = 'flush failed removing the entry for "' . $item . '"... ' . $@;
				$self->warn;
			};
		}
	} ## end foreach my $item ( sort( keys...))

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

init failed. Probing the address-group config failed.

=head2 24, checkFailed

The backend check raised an error.

=head2 25, flushFailed

Failed to flush the bans.

=head2 26, portsNotSupported

Ports were specified, but this backend manages whole IPs and does not
support ports.

=head2 27, protocolsNotSupported

Protocols were specified, but this backend manages whole IPs and does not
support protocols.

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

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut

1;    # End of Net::Firewall::BlockerHelper::backends::vyos
