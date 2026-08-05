package Net::Firewall::BlockerHelper::backends::opnsense;

use 5.006;
use strict;
use warnings;
use base 'Error::Helper';
use Regexp::IPv4 qw($IPv4_re);
use Regexp::IPv6 qw($IPv6_re);

=head1 NAME

Net::Firewall::BlockerHelper::backends::opnsense - OPNsense firewall alias backend for Net::Firewall::BlockerHelper.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 SYNOPSIS

    use Net::Firewall::BlockerHelper::backends::opnsense;

    my $backend;
    eval {
        $backend = Net::Firewall::BlockerHelper::backends::opnsense->new(
                name    => 'ssh',
                options => {
                        host   => 'fw.example.org',
                        key    => 'someAPIkey',
                        secret => 'someAPIsecret',
                        alias  => 'kur_ssh',
                        },
            );
    };
    if ($@) {
        print 'Error: '
            . $Error::Helper::error
            . "\nError String: "
            . $Error::Helper::errorString
            . "\nError Flag: "
            . $Error::Helper::errorFlag . "\n";
    }

    $backend->init;

    $backend->ban(ban => '1.2.3.4');
    $backend->ban(ban => '4.3.2.1');

    use Data::Dumper;
    print Dumper($backend->list);

    $backend->unban(ban => '4.3.2.1');

    $backend->teardown;

=head1 DESCRIPTION

This backend blocks IPs by adding them to an OPNsense firewall alias via
the C<os-firewall> C<alias_util> REST API, talked to via L<LWP::UserAgent>.

A single alias holds all of the banned IPs. Both IPv4 and IPv6 addresses
are added to the same alias as OPNsense host/network aliases are family
agnostic.

The alias B<must> already exist in OPNsense. It is created in the OPNsense
web UI (Firewall -> Aliases) and referenced by a firewall rule that does
the actual blocking. This backend only manages the contents of the alias,
not the alias itself nor the rule referencing it.

L<LWP::UserAgent> is only loaded at run time, so it is only required if
this backend is actually used. For https, L<LWP::Protocol::https> must be
present as well.

=head1 METHODS

=head2 new

Initiates the the object.

    - options :: Backend specific options. See below for further info.
        - Default :: {}

    - ports :: Not used by this backend but is accepted for parity with
            Net::Firewall::BlockerHelper.
        - Default :: []

    - protocols :: Not used by this backend but is accepted for parity with
            Net::Firewall::BlockerHelper.
        - Default :: []

    - prefix :: Prefix to use when building the default alias name.
        - default :: kur

    - name :: Name of this specific instance. This must be specified.
        - default :: undef

The options hash accepts the following.

    - host :: OPNsense hostname or IP the API is reached at. May include a
            port, eg 'fw.example.org:8443'. This must be specified and can
            not be blank.
        - Default :: undef

    - key :: The OPNsense API key. This must be specified and can not be
            blank.
        - Default :: undef

    - secret :: The OPNsense API secret. This must be specified and can not
            be blank.
        - Default :: undef

    - alias :: The name of the alias the IPs are added to. The alias must
            already exist in OPNsense.
        - Default :: <prefix>_<name>

    - timeout :: HTTP timeout in seconds.
        - Default :: 30

    - insecure :: If true, certificate verification is disabled so
            self-signed certs are accepted.
        - Default :: 0

    - scheme :: The scheme used when building the URL, either 'https' or
            'http'.
        - Default :: https

All errors are considered fatal, meaning if new fails it will die.

    my $backend;
    eval {
        $backend = Net::Firewall::BlockerHelper::backends::opnsense->new(
                name    => 'ssh',
                options => {
                        host   => 'fw.example.org',
                        key    => 'someAPIkey',
                        secret => 'someAPIsecret',
                        },
            );
    };
    if ($@) {
        print 'Error: '
            . $Error::Helper::error
            . "\nError String: "
            . $Error::Helper::errorString
            . "\nError Flag: "
            . $Error::Helper::errorFlag . "\n";
    }

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
				24 => 'checkFailed',
				25 => 'flushFailed',
				30 => 'hostNotDefined',
				31 => 'apiKeyNotDefined',
				32 => 'apiSecretNotDefined',
				33 => 'banCidrFailed',
				34 => 'unbanCidrFailed',
				35 => 'cidrItemNotCidr',
				36 => 'cidrNotSupported',
				37 => 'listCidrFailed',
			},
			fatal_flags      => {},
			perror_not_fatal => 0,
		},
		options => {
			timeout  => 30,
			insecure => 0,
			scheme   => 'https',
		},
		ports        => [],
		protocols    => [],
		testing      => undef,
		test_data    => undef,
		prefix         => 'kur',
		frontend_obj   => undef,
		inited         => 0,
		banned         => {},
		banned_cidr    => {},
		cidr_supported => 1,
	};
	bless $self;

	# make sure prefix is sane if defined
	if ( defined( $opts{prefix} ) ) {
		$self->{prefix} = $opts{prefix};
	}

	if ( defined( $opts{name} ) ) {
		$self->{name} = $opts{name};
	}

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
		# merge the passed options over the defaults so unset knobs keep them
		foreach my $key ( keys( %{ $opts{options} } ) ) {
			$self->{options}{$key} = $opts{options}{$key};
		}
	}

	# fill in the defaults for anything not passed
	if ( !defined( $self->{options}{timeout} ) ) {
		$self->{options}{timeout} = 30;
	} elsif ( $self->{options}{timeout} !~ /^[0-9]+$/ ) {
		$self->{perror}      = 1;
		$self->{error}       = 12;
		$self->{errorString} = 'the option timeout, "' . $self->{options}{timeout} . '", is not an int';
		$self->warn;
	}
	if ( !defined( $self->{options}{insecure} ) ) {
		$self->{options}{insecure} = 0;
	}
	if ( !defined( $self->{options}{scheme} ) || $self->{options}{scheme} eq '' ) {
		$self->{options}{scheme} = 'https';
	}
	if ( !defined( $self->{options}{alias} ) || $self->{options}{alias} eq '' ) {
		$self->{options}{alias} = $self->{prefix} . '_' . ( defined( $self->{name} ) ? $self->{name} : '' );
	}

	# host, key, and secret are all required to be able to talk to the API
	if ( !defined( $self->{options}{host} ) || $self->{options}{host} eq '' ) {
		$self->{perror}      = 1;
		$self->{error}       = 30;
		$self->{errorString} = 'host is not defined or is blank';
		$self->warn;
	} elsif ( !defined( $self->{options}{key} ) || $self->{options}{key} eq '' ) {
		$self->{perror}      = 1;
		$self->{error}       = 31;
		$self->{errorString} = 'key is not defined or is blank';
		$self->warn;
	} elsif ( !defined( $self->{options}{secret} ) || $self->{options}{secret} eq '' ) {
		$self->{perror}      = 1;
		$self->{error}       = 32;
		$self->{errorString} = 'secret is not defined or is blank';
		$self->warn;
	}

	return $self;
} ## end sub new

# Internal helper. Returns a canonical JSON::PP encoder/decoder.
sub _json {
	my ($self) = @_;

	require JSON::PP;
	return JSON::PP->new->canonical->utf8;
}

# Internal helper. Returns the URL for the passed method path, appended to
# <scheme>://<host>/api/firewall/.
#
#     my $url = $self->_url( 'alias_util/list/' . $alias );
sub _url {
	my ( $self, $method_path ) = @_;

	return $self->{options}{scheme} . '://' . $self->{options}{host} . '/api/firewall/' . $method_path;
}

# Internal helper. Performs a HTTP request via LWP::UserAgent, authenticated
# via basic auth with the key/secret, returning the decoded JSON on success
# and dying with a explanation on any HTTP level failure. Never called in
# testing mode.
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
		} or die( 'failed to load LWP::UserAgent, which the opnsense backend requires... ' . $@ );
	} ## end if ( !defined( $self->{ua...}))

	require HTTP::Request;
	my $request = HTTP::Request->new( $method, $url, [ 'Content-Type' => 'application/json' ], $body );
	$request->authorization_basic( $self->{options}{key}, $self->{options}{secret} );

	my $response = $self->{ua}->request($request);

	if ( !$response->is_success ) {
		die( $method . ' ' . $url . ' failed... HTTP status... ' . $response->status_line );
	}

	my $decoded;
	local $@;
	eval { $decoded = $self->_json->decode( $response->decoded_content ); };

	return $decoded;
} ## end sub _request

=head2 init

Initiates the backend. This lists the alias via the API, with any
connection or HTTP level failure, bad credentials included, raising an
error.

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

	my $url = $self->_url( 'alias_util/list/' . $self->{options}{alias} );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'GET', url => $url } ];
	} else {
		local $@;
		eval { $self->_request( 'GET', $url ); 1; } or do {
			$self->{error}       = 12;
			$self->{errorString} = 'init failed... listing the alias failed... ' . $@;
			$self->warn;
		};
	}

	$self->{inited} = 1;
} ## end sub init

=head2 ban

Bans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then added to the alias via a POST to the
C<alias_util/add> API endpoint. Banning an already banned IP is
a noop.

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

	my $url  = $self->_url( 'alias_util/add/' . $self->{options}{alias} );
	my $body = $self->_json->encode( { address => $opts{ban} } );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'POST', url => $url, content => $body } ];
	} else {
		local $@;
		eval { $self->_request( 'POST', $url, $body ); 1; } or do {
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
and lowercased, then removed from the alias via a POST to the
C<alias_util/delete> API endpoint. Unbanning an IP that is not
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

	my $url  = $self->_url( 'alias_util/delete/' . $self->{options}{alias} );
	my $body = $self->_json->encode( { address => $opts{ban} } );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'POST', url => $url, content => $body } ];
	} else {
		local $@;
		eval { $self->_request( 'POST', $url, $body ); 1; } or do {
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

=head2 ban_cidr

Bans a CIDR range by adding it to the alias via the C<alias_util/add> API
endpoint. OPNsense aliases accept a network in the same manner as a single
address. The value of ban is validated as being a IPv4 or IPv6 CIDR range
and lowercased. Banning an already banned range is a noop.

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

	my $url  = $self->_url( 'alias_util/add/' . $self->{options}{alias} );
	my $body = $self->_json->encode( { address => $opts{ban} } );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'POST', url => $url, content => $body } ];
	} else {
		local $@;
		eval { $self->_request( 'POST', $url, $body ); 1; } or do {
			$self->{error}       = 33;
			$self->{errorString} = 'banning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	}

	$self->{banned_cidr}{ $opts{ban} } = 1;
} ## end sub ban_cidr

=head2 unban_cidr

Unbans a CIDR range by removing it from the alias via the
C<alias_util/delete> API endpoint. The value of ban is validated as being a
IPv4 or IPv6 CIDR range and lowercased. Unbanning a range that is not
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

	my $url  = $self->_url( 'alias_util/delete/' . $self->{options}{alias} );
	my $body = $self->_json->encode( { address => $opts{ban} } );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'POST', url => $url, content => $body } ];
	} else {
		local $@;
		eval { $self->_request( 'POST', $url, $body ); 1; } or do {
			$self->{error}       = 34;
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

Tells the backend to re-init it's self.

This will call teardown and init again. After that it will
re-add all previously added bans.

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
	# exactly what re_init needs to recover from; init cleans up any remnants
	{
		local $@;
		eval { $self->teardown; };
	}
	$self->init;

	my @to_re_ban = ( keys( %{ $self->{banned} } ), keys( %{ $self->{banned_cidr} } ) );

	my @re_init_test_data;
	foreach my $item (@to_re_ban) {
		my $url  = $self->_url( 'alias_util/add/' . $self->{options}{alias} );
		my $body = $self->_json->encode( { address => $item } );

		if ( $self->{testing} ) {
			push( @re_init_test_data, { method => 'POST', url => $url, content => $body } );
		} else {
			local $@;
			eval { $self->_request( 'POST', $url, $body ); 1; } or do {
				$self->{error}       = 13;
				$self->{errorString} = 'banning "' . $item . '" failed... ' . $@;
				$self->warn;
			};
		}
	} ## end foreach my $item (@to_re_ban)

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@re_init_test_data;
	}

	$self->{inited} = 1;
} ## end sub re_init

=head2 teardown

Tears down the setup for the backend.

This flushes the alias, removing all of the banned IPs from it. The alias
itself and the rule referencing it are left in place.

    $backend->teardown;

=cut

sub teardown {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{inited} = 0;

	my $url = $self->_url( 'alias_util/flush/' . $self->{options}{alias} );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'POST', url => $url, content => '{}' } ];
	} else {
		local $@;
		eval { $self->_request( 'POST', $url, '{}' ); 1; } or do {
			$self->{error}       = 17;
			$self->{errorString} = 'teardown failed... flushing the alias failed... ' . $@;
			$self->warn;
		};
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

Verifies the alias is still reachable by listing it via the API. A
successful request is treated as healthy. This is the equivalent of
fail2ban's C<actioncheck>.

    if ( !$backend->check ) {
        $backend->re_init;
    }

=cut

sub check {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	my $url = $self->_url( 'alias_util/list/' . $self->{options}{alias} );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'GET', url => $url } ];
		return 1;
	}

	local $@;
	return eval { $self->_request( 'GET', $url ); 1; } ? 1 : 0;
} ## end sub check

=head2 flush

Removes all currently banned IPs at once by flushing the alias, leaving the
alias and the rule referencing it in place. This is the equivalent of
fail2ban's C<actionflush>.

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

	my $url = $self->_url( 'alias_util/flush/' . $self->{options}{alias} );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'POST', url => $url, content => '{}' } ];
	} else {
		local $@;
		eval { $self->_request( 'POST', $url, '{}' ); 1; } or do {
			$self->{error}       = 25;
			$self->{errorString} = 'flush failed... flushing the alias failed... ' . $@;
			$self->warn;
			return;
		};
	}

	$self->{banned}      = {};
	$self->{banned_cidr} = {};
} ## end sub flush

=head1 ERROR CODES / FLAGS

Error handling is provided by L<Error::Helper>. All
errors are considered fatal.

=head2 1, notInited

The backend has not been inited yet.

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

=head2 24, checkFailed

The backend check raised an error.

=head2 25, flushFailed

Failed to flush the bans.

=head2 30, hostNotDefined

The option host is undef or blank.

=head2 31, apiKeyNotDefined

The option key is undef or blank.

=head2 32, apiSecretNotDefined

The option secret is undef or blank.

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

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-firewall-blockerhelper at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Firewall-BlockerHelper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Firewall::BlockerHelper


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Firewall-BlockerHelper>

=item * Search CPAN

L<https://metacpan.org/release/Net-Firewall-BlockerHelper>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999


=cut

1;    # End of Net::Firewall::BlockerHelper
