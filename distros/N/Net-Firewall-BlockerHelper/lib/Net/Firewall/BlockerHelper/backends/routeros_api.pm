package Net::Firewall::BlockerHelper::backends::routeros_api;

use 5.006;
use strict;
use warnings;
use base 'Error::Helper';
use Regexp::IPv4 qw($IPv4_re);
use Regexp::IPv6 qw($IPv6_re);

=head1 NAME

Net::Firewall::BlockerHelper::backends::routeros_api - MikroTik RouterOS backend using the REST API.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 SYNOPSIS

    use Net::Firewall::BlockerHelper;

    my $fw_helper = Net::Firewall::BlockerHelper->new(
        backend => 'routeros_api',
        name    => 'ssh',
        options => {
            host     => '10.0.0.1',
            user     => 'blocker',
            password => $password,
        },
    );

    $fw_helper->init_backend;
    $fw_helper->ban( ban => '1.2.3.4' );
    $fw_helper->unban( ban => '1.2.3.4' );

=head1 DESCRIPTION

Blocks IPs on a MikroTik RouterOS device via its REST API (RouterOS 7.1+),
adding and removing entries in a firewall address-list. IPv4 addresses go in
the C<< /ip/firewall/address-list >> and IPv6 in C<< /ipv6/firewall/address-list >>,
under the list names given by the C<list4>/C<list6> options (both defaulting
to C<< <prefix>_<name> >>).

This backend manages only the address-list membership. A firewall filter (or
raw) rule that drops traffic matching the address-list must already exist on
the router. If you would rather have the referencing rules created for you, or
you are on RouterOS 6 without the REST API, use the ssh driven C<routeros>
backend instead.

Blocking is per IP; ports and protocols belong on the referencing rule, so
specifying them here is an error.

L<LWP::UserAgent> is loaded at run time, so it is only required when this
backend is actually used. For https, L<LWP::Protocol::https> must be present
as well.

=head1 NOTES

This backend was written going off the API docs and actual testing is
needed to double check a few things as the exact behavior is not clear.

teardown currently only removes the single IP address-list entries,
leaving CIDR entries on the router, while flush removes both. A re_init
after a teardown will re-add the CIDR entries, and whether RouterOS then
errors or ends up with duplicate entries needs checking.

=head1 METHODS

=head2 new

Initiates the object.

    - options :: Backend specific options. See below.
    - prefix :: Prefix to use. Must match /^[a-zA-Z0-9]+$/. Default kur.
    - name :: Name of this instance. Required.

Ports and protocols are not supported and specifying either is an error.

The options hash accepts the following.

    - host :: RouterOS host, optionally host:port. Required.
        - Default :: undef

    - user :: REST API user. Required.
        - Default :: undef

    - password :: REST API password. Required.
        - Default :: undef

    - scheme :: 'https' or 'http'.
        - Default :: https

    - insecure :: If true, skip TLS certificate verification (RouterOS ships a
            self-signed certificate).
        - Default :: 0

    - list4 :: IPv4 address-list name.
        - Default :: <prefix>_<name>

    - list6 :: IPv6 address-list name.
        - Default :: <prefix>_<name>

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

	# blocking is per IP; ports/protocols belong on the referencing rule
	if ( defined( $opts{ports} ) && ref( $opts{ports} ) eq 'ARRAY' && defined( $opts{ports}[0] ) ) {
		$self->{perror}      = 1;
		$self->{error}       = 26;
		$self->{errorString} = 'the routeros_api backend manages whole IPs and does not support ports';
		$self->warn;
	}
	if ( defined( $opts{protocols} ) && ref( $opts{protocols} ) eq 'ARRAY' && defined( $opts{protocols}[0] ) ) {
		$self->{perror}      = 1;
		$self->{error}       = 27;
		$self->{errorString} = 'the routeros_api backend manages whole IPs and does not support protocols';
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
	$self->{options}{scheme}   = 'https' if ( !defined( $self->{options}{scheme} ) );
	$self->{options}{insecure} = 0       if ( !defined( $self->{options}{insecure} ) );
	$self->{options}{timeout}  = 30      if ( !defined( $self->{options}{timeout} ) );
	if ( defined( $self->{name} ) ) {
		$self->{options}{list4} = $self->{prefix} . '_' . $self->{name} if ( !defined( $self->{options}{list4} ) );
		$self->{options}{list6} = $self->{prefix} . '_' . $self->{name} if ( !defined( $self->{options}{list6} ) );
	}

	return $self;
} ## end sub new

# Internal helper. Returns the address-list name for the passed IP's family.
sub _list_name {
	my ( $self, $ip ) = @_;

	return ( $ip =~ /\A$IPv4_re\z/ ) ? $self->{options}{list4} : $self->{options}{list6};
}

# Internal helper. Returns the address-list REST endpoint for the passed IP's
# family (or IPv4 if no IP is given).
sub _list_url {
	my ( $self, $ip ) = @_;

	my $menu = ( defined($ip) && $ip =~ /\A$IPv6_re\z/ ) ? 'ipv6' : 'ip';

	return $self->{options}{scheme} . '://' . $self->{options}{host} . '/rest/' . $menu . '/firewall/address-list';
}

# Internal helper. Minimal percent encoder so URI::Escape is not needed.
sub _uri_escape {
	my ( $self, $string ) = @_;

	$string =~ s/([^A-Za-z0-9\-._~])/sprintf('%%%02X', ord($1))/ge;

	return $string;
}

# Internal helper. Returns a canonical JSON::PP encoder/decoder.
sub _json {
	my ($self) = @_;

	require JSON::PP;
	return JSON::PP->new->canonical->utf8;
}

# Internal helper. Performs a HTTP request via LWP::UserAgent using HTTP basic
# auth, returning the decoded JSON body (or undef for an empty body) and dying
# with an explanation on any HTTP level failure. Never called in testing mode.
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
		} or die( 'failed to load LWP::UserAgent, which the routeros_api backend requires... ' . $@ );
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

Initiates the backend. Verifies the credentials and reachability by
performing a GET against the IPv4 address-list endpoint. Nothing is created
on the router; the referencing firewall rule must already exist.

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

	my $url = $self->_list_url . '?list=' . $self->_uri_escape( $self->{options}{list4} );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'GET', url => $url } ];
	} else {
		local $@;
		eval { $self->_request( 'GET', $url ); 1; } or do {
			$self->{error}       = 23;
			$self->{errorString} = 'init failed. probing the address-list endpoint failed... ' . $@;
			$self->warn;
		};
	}

	$self->{inited} = 1;
} ## end sub init

=head2 ban

Bans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then added to the relevant address-list via a PUT to
C<< /rest/ip/firewall/address-list >> or
C<< /rest/ipv6/firewall/address-list >>. Banning an already banned IP is a
noop.

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

	my $body = $self->_json->encode( { list => $self->_list_name( $opts{ban} ), address => $opts{ban} } );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'PUT', url => $self->_list_url( $opts{ban} ), content => $body } ];
	} else {
		local $@;
		eval { $self->_request( 'PUT', $self->_list_url( $opts{ban} ), $body ); 1; } or do {
			$self->{error}       = 13;
			$self->{errorString} = 'banning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	}

	$self->{banned}{ $opts{ban} } = 1;
} ## end sub ban

# Internal helper. Returns the lookup URL used to find the address-list entry
# ID for the passed IP.
sub _unban_lookup_url {
	my ( $self, $ip ) = @_;

	return
		  $self->_list_url($ip)
		. '?list='
		. $self->_uri_escape( $self->_list_name($ip) )
		. '&address='
		. $self->_uri_escape($ip);
} ## end sub _unban_lookup_url

# Internal helper. Looks up the address-list entry for the IP and deletes it by
# its ".id". An entry that can not be found is treated as already unbanned.
# Dies on failure. Never called in testing mode.
sub _unban_ip {
	my ( $self, $ip ) = @_;

	my $decoded = $self->_request( 'GET', $self->_unban_lookup_url($ip) );

	my $id;
	if ( ref($decoded) eq 'ARRAY' && defined( $decoded->[0] ) ) {
		$id = $decoded->[0]{'.id'};
	}

	# no entry found means something else removed it already, which is fine
	if ( !defined($id) ) {
		return;
	}

	$self->_request( 'DELETE', $self->_list_url($ip) . '/' . $id );

	return;
} ## end sub _unban_ip

=head2 unban

Unbans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased. The address-list entry is looked up via a GET to find its
C<.id> and then removed via a DELETE. An entry that can not be found is
treated as already unbanned. Unbanning an IP that is not banned is a noop.

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
		$self->{frontend_obj}->{test_data} = [
			{ method => 'GET',    url => $self->_unban_lookup_url( $opts{ban} ) },
			{ method => 'DELETE', url => $self->_list_url( $opts{ban} ) . '/<id>' },
		];
	} else {
		local $@;
		eval { $self->_unban_ip( $opts{ban} ); 1; } or do {
			$self->{error}       = 14;
			$self->{errorString} = 'unbanning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	}

	delete( $self->{banned}{ $opts{ban} } );
} ## end sub unban

# Internal helper. Returns a true value if the passed scalar is a valid IPv4 or
# IPv6 CIDR range, that is an address followed by "/" and a prefix length that
# is within the range valid for its family (0 to 32 for IPv4, 0 to 128 for
# IPv6). Returns false otherwise.
sub _valid_cidr {
	my ( $self, $cidr ) = @_;

	return 0 if ( !defined($cidr) || ref($cidr) ne '' );

	if ( $cidr =~ m!\A(.+)/([0-9]{1,3})\z! ) {
		my ( $addr, $prefix ) = ( $1, $2 );
		return 1 if ( $addr =~ /\A$IPv4_re\z/ && $prefix <= 32 );
		return 1 if ( $addr =~ /\A$IPv6_re\z/ && $prefix <= 128 );
	}

	return 0;
} ## end sub _valid_cidr

# Internal helper. Returns the address portion of a CIDR range so its family can
# be determined via the same helpers used for single IPs.
sub _cidr_addr {
	my ( $self, $cidr ) = @_;

	if ( $cidr =~ m!\A(.+)/[0-9]{1,3}\z! ) {
		return $1;
	}

	return $cidr;
} ## end sub _cidr_addr

=head2 ban_cidr

Bans a CIDR range by adding it to the relevant address-list via a PUT.
RouterOS address-lists accept a network prefix in the same manner as a
single address. The value of ban is validated as being a IPv4 or IPv6 CIDR
range and lowercased. Banning an already banned range is a noop.

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

	my $addr = $self->_cidr_addr( $opts{ban} );
	my $body = $self->_json->encode( { list => $self->_list_name($addr), address => $opts{ban} } );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'PUT', url => $self->_list_url($addr), content => $body } ];
	} else {
		local $@;
		eval { $self->_request( 'PUT', $self->_list_url($addr), $body ); 1; } or do {
			$self->{error}       = 33;
			$self->{errorString} = 'banning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	}

	$self->{banned_cidr}{ $opts{ban} } = 1;
} ## end sub ban_cidr

=head2 unban_cidr

Unbans a CIDR range. The value of ban is validated as being a IPv4 or IPv6
CIDR range and lowercased. Its address-list entry is looked up via a GET to
find its C<.id> and then removed via a DELETE. An entry that can not be
found is treated as already unbanned. Unbanning a range that is not banned
is a noop.

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

	my $addr = $self->_cidr_addr( $opts{ban} );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [
			{ method => 'GET',    url => $self->_unban_lookup_url($addr) . '&address=' . $self->_uri_escape( $opts{ban} ) },
			{ method => 'DELETE', url => $self->_list_url($addr) . '/<id>' },
		];
	} else {
		local $@;
		eval { $self->_unban_cidr_entry( $opts{ban} ); 1; } or do {
			$self->{error}       = 34;
			$self->{errorString} = 'unbanning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	}

	delete( $self->{banned_cidr}{ $opts{ban} } );
} ## end sub unban_cidr

# Internal helper. Looks up the address-list entry for the CIDR range and deletes
# it by its ".id". An entry that can not be found is treated as already
# unbanned. Dies on failure. Never called in testing mode.
sub _unban_cidr_entry {
	my ( $self, $cidr ) = @_;

	my $addr = $self->_cidr_addr($cidr);

	my $url
		= $self->_list_url($addr)
		. '?list='
		. $self->_uri_escape( $self->_list_name($addr) )
		. '&address='
		. $self->_uri_escape($cidr);

	my $decoded = $self->_request( 'GET', $url );

	my $id;
	if ( ref($decoded) eq 'ARRAY' && defined( $decoded->[0] ) ) {
		$id = $decoded->[0]{'.id'};
	}

	# no entry found means something else removed it already, which is fine
	if ( !defined($id) ) {
		return;
	}

	$self->_request( 'DELETE', $self->_list_url($addr) . '/' . $id );

	return;
} ## end sub _unban_cidr_entry

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
recover from. Each retained single IP and CIDR ban is re-added via a PUT to
the relevant address-list endpoint.

    $backend->re_init;

=cut

sub re_init {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( !$self->{inited} ) {
		$self->{error}       = 1;
		$self->{errorString} = 'backend has not been inited';
		$self->warn;
		return;
	}

	# teardown is best effort here as a partially or fully wiped setup is
	# exactly what re_init needs to recover from
	{
		local $@;
		eval { $self->teardown; };
	}
	$self->init;

	my @re_init_test_data;
	foreach my $item ( keys( %{ $self->{banned} } ) ) {
		my $body = $self->_json->encode( { list => $self->_list_name($item), address => $item } );

		if ( $self->{testing} ) {
			push( @re_init_test_data, { method => 'PUT', url => $self->_list_url($item), content => $body } );
		} else {
			local $@;
			eval { $self->_request( 'PUT', $self->_list_url($item), $body ); 1; } or do {
				$self->{error}       = 13;
				$self->{errorString} = 'banning "' . $item . '" failed... ' . $@;
				$self->warn;
			};
		}
	} ## end foreach my $item ( keys( %{ ...}))

	# CIDR ranges are re-added the same way, keyed off the family of the address
	foreach my $item ( keys( %{ $self->{banned_cidr} } ) ) {
		my $addr = $self->_cidr_addr($item);
		my $body = $self->_json->encode( { list => $self->_list_name($addr), address => $item } );

		if ( $self->{testing} ) {
			push( @re_init_test_data, { method => 'PUT', url => $self->_list_url($addr), content => $body } );
		} else {
			local $@;
			eval { $self->_request( 'PUT', $self->_list_url($addr), $body ); 1; } or do {
				$self->{error}       = 33;
				$self->{errorString} = 'banning "' . $item . '" failed... ' . $@;
				$self->warn;
			};
		}
	} ## end foreach my $item ( keys( %{ ...}))

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@re_init_test_data;
	}

	$self->{inited} = 1;
} ## end sub re_init

=head2 teardown

Tears down the setup by removing the address-list entry for each currently
banned IP. The internal list of bans is kept, so a following re_init will
re-add them.

=cut

sub teardown {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{inited} = 0;

	my @requests;
	foreach my $item ( sort( keys( %{ $self->{banned} } ) ) ) {
		if ( $self->{testing} ) {
			push(
				@requests,
				{ method => 'GET',    url => $self->_unban_lookup_url($item) },
				{ method => 'DELETE', url => $self->_list_url($item) . '/<id>' }
			);
		} else {
			local $@;
			eval { $self->_unban_ip($item); 1; } or do {
				$self->{error}       = 17;
				$self->{errorString} = 'teardown failed removing the entry for "' . $item . '"... ' . $@;
				$self->warn;
			};
		}
	} ## end foreach my $item ( sort( keys( %{ $self->{banned...})))

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

Verifies the endpoint and credentials are still usable by fetching the
address-list. Returns a true value if so and a false value otherwise.

=cut

sub check {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	my $url = $self->_list_url . '?list=' . $self->_uri_escape( $self->{options}{list4} );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'GET', url => $url } ];
		return 1;
	}

	local $@;
	eval { $self->_request( 'GET', $url ); 1; } or return 0;

	return 1;
} ## end sub check

=head2 flush

Removes all currently banned IPs and CIDR ranges at once by removing their
address-list entries and forgetting them.

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
	foreach my $item ( sort( keys( %{ $self->{banned} } ) ) ) {
		if ( $self->{testing} ) {
			push(
				@requests,
				{ method => 'GET',    url => $self->_unban_lookup_url($item) },
				{ method => 'DELETE', url => $self->_list_url($item) . '/<id>' }
			);
		} else {
			local $@;
			eval { $self->_unban_ip($item); 1; } or do {
				$self->{error}       = 25;
				$self->{errorString} = 'flush failed removing the entry for "' . $item . '"... ' . $@;
				$self->warn;
			};
		}
	} ## end foreach my $item ( sort( keys( %{ $self->{banned...})))

	# CIDR ranges are removed the same way as single IPs
	foreach my $item ( sort( keys( %{ $self->{banned_cidr} } ) ) ) {
		my $addr = $self->_cidr_addr($item);
		if ( $self->{testing} ) {
			push(
				@requests,
				{
					method => 'GET',
					url    => $self->_list_url($addr)
						. '?list='
						. $self->_uri_escape( $self->_list_name($addr) )
						. '&address='
						. $self->_uri_escape($item)
				},
				{ method => 'DELETE', url => $self->_list_url($addr) . '/<id>' }
			);
		} else {
			local $@;
			eval { $self->_unban_cidr_entry($item); 1; } or do {
				$self->{error}       = 25;
				$self->{errorString} = 'flush failed removing the entry for "' . $item . '"... ' . $@;
				$self->warn;
			};
		}
	} ## end foreach my $item ( sort( keys( %{ $self->{banned_cidr...})))

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

init failed. Probing the address-list endpoint failed.

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

1;    # End of Net::Firewall::BlockerHelper::backends::routeros_api
