package Net::Firewall::BlockerHelper::backends::netscaler;

use 5.006;
use strict;
use warnings;
use base 'Error::Helper';
use Regexp::IPv4 qw($IPv4_re);
use Regexp::IPv6 qw($IPv6_re);

=head1 NAME

Net::Firewall::BlockerHelper::backends::netscaler - Citrix NetScaler/ADC backend for Net::Firewall::BlockerHelper.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 SYNOPSIS

    use Net::Firewall::BlockerHelper;

    my $fw_helper = Net::Firewall::BlockerHelper->new(
            backend => 'netscaler',
            name => 'ssh',
            options => {
                host    => 'netscaler.foo.bar',
                user    => 'nsroot',
                pass    => $password,
                dataset => 'fail2ban',
            },
        );

    $fw_helper->init_backend;
    $fw_helper->ban(ban => '1.2.3.4');
    $fw_helper->unban(ban => '1.2.3.4');

=head1 DESCRIPTION

Blocks IPs remotely by binding them into a policy dataset on a Citrix
NetScaler/ADC via the NITRO REST API, equivalent to the fail2ban netscaler
action, but using L<LWP::UserAgent> rather than curl. The dataset can then
be used to block the IPs via responder policies at a vserver or global
level.

The dataset must already exist on the NetScaler, as must a responder or
similar policy referencing it, as binding IPs into the dataset does nothing
by itself; init and check only verify the API is reachable and auth works.

Blocking is per IP; ports and protocols are not supported and specifying
them is an error.

L<LWP::UserAgent> is only loaded at run time, so it is only required if
this backend is actually used. For https, L<LWP::Protocol::https> must be
present as well.

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

The options hash accepts the following. host must be specified, as must
either auth or both user and pass.

    - host :: Hostname or IP of the NetScaler appliance.
        - Default :: undef

    - user :: Username for basic auth.
        - Default :: undef

    - pass :: Password for basic auth.
        - Default :: undef

    - auth :: Pre-base64ed basic auth value to use instead of user/pass,
            for parity with the fail2ban ns_auth option.
        - Default :: undef

    - dataset :: The policy dataset holding the blocked IPs.
        - Default :: <prefix>_<name>

    - scheme :: http or https.
        - Default :: https

    - ssl_verify :: Verify the TLS certificate. The fail2ban action uses
            curl -k, so this defaults to off; set to 1 if the appliance has
            a valid certificate.
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
				28 => 'optionInvalid',
				29 => 'banCidrFailed',
				30 => 'unbanCidrFailed',
				31 => 'cidrItemNotCidr',
				32 => 'cidrNotSupported',
				33 => 'listCidrFailed',
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
		inited       => 0,
		banned       => {},
		cidr_supported => 0,
		ua           => undef,
	};
	bless $self;

	# blocking is per IP; the dataset has no concept of ports or protocols
	if ( defined( $opts{ports} ) && ref( $opts{ports} ) eq 'ARRAY' && defined( $opts{ports}[0] ) ) {
		$self->{perror}      = 1;
		$self->{error}       = 26;
		$self->{errorString} = 'the netscaler backend blocks whole IPs and does not support ports';
		$self->warn;
	}
	if ( defined( $opts{protocols} ) && ref( $opts{protocols} ) eq 'ARRAY' && defined( $opts{protocols}[0] ) ) {
		$self->{perror}      = 1;
		$self->{error}       = 27;
		$self->{errorString} = 'the netscaler backend blocks whole IPs and does not support protocols';
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

	if ( !defined( $self->{options}{host} ) || $self->{options}{host} !~ /^[a-zA-Z0-9.\-\[\]:]+$/ ) {
		$self->{perror} = 1;
		$self->{error}  = 28;
		$self->{errorString}
			= 'the option host is '
			. ( defined( $self->{options}{host} ) ? '"' . $self->{options}{host} . '" and not a valid host' : 'undef' );
		$self->warn;
	}

	if ( !defined( $self->{options}{auth} )
		&& ( !defined( $self->{options}{user} ) || !defined( $self->{options}{pass} ) ) )
	{
		$self->{perror} = 1;
		$self->{error}  = 28;
		$self->{errorString}
			= 'either the option auth, or both the options user and pass, must be specified for auth';
		$self->warn;
	}

	if ( !defined( $self->{options}{dataset} ) && defined( $self->{name} ) ) {
		$self->{options}{dataset} = $self->{prefix} . '_' . $self->{name};
	}
	if ( defined( $self->{options}{dataset} ) && $self->{options}{dataset} !~ /^[a-zA-Z0-9_\-]+$/ ) {
		$self->{perror} = 1;
		$self->{error}  = 28;
		$self->{errorString}
			= 'the option dataset, "' . $self->{options}{dataset} . '", does not match /^[a-zA-Z0-9_\-]+$/';
		$self->warn;
	}

	if ( defined( $self->{options}{scheme} )
		&& $self->{options}{scheme} ne 'http'
		&& $self->{options}{scheme} ne 'https' )
	{
		$self->{perror}      = 1;
		$self->{error}       = 28;
		$self->{errorString} = 'the option scheme, "' . $self->{options}{scheme} . '", is not "http" or "https"';
		$self->warn;
	} elsif ( !defined( $self->{options}{scheme} ) ) {
		$self->{options}{scheme} = 'https';
	}

	if ( !defined( $self->{options}{ssl_verify} ) ) {
		$self->{options}{ssl_verify} = 0;
	}

	if ( !defined( $self->{options}{timeout} ) ) {
		$self->{options}{timeout} = 30;
	} elsif ( $self->{options}{timeout} !~ /^[0-9]+$/ ) {
		$self->{perror}      = 1;
		$self->{error}       = 28;
		$self->{errorString} = 'the option timeout, "' . $self->{options}{timeout} . '", is not an int';
		$self->warn;
	}

	return $self;
} ## end sub new

# Internal helper. Returns the NITRO config API base URL.
sub _base_url {
	my ($self) = @_;

	return $self->{options}{scheme} . '://' . $self->{options}{host} . '/nitro/v1/config';
}

# Internal helper. Minimal percent encoder so URI::Escape is not needed.
sub _uri_escape {
	my ( $self, $string ) = @_;

	$string =~ s/([^A-Za-z0-9\-._~])/sprintf('%%%02X', ord($1))/ge;

	return $string;
}

# Internal helper. Performs a HTTP request via LWP::UserAgent, dying with a
# explanation on any HTTP level failure. Never called in testing mode.
sub _request {
	my ( $self, $method, $url, $body ) = @_;

	if ( !defined( $self->{ua} ) ) {
		local $@;
		eval {
			require LWP::UserAgent;
			my %new_opts = (
				agent   => 'Net::Firewall::BlockerHelper/' . $VERSION,
				timeout => $self->{options}{timeout},
			);
			if ( !$self->{options}{ssl_verify} ) {
				$new_opts{ssl_opts} = { verify_hostname => 0, SSL_verify_mode => 0 };
			}
			$self->{ua} = LWP::UserAgent->new(%new_opts);
			1;
		} or die( 'failed to load LWP::UserAgent, which the netscaler backend requires... ' . $@ );
	} ## end if ( !defined( $self->{ua} ) )

	my $auth = $self->{options}{auth};
	if ( !defined($auth) ) {
		require MIME::Base64;
		$auth = MIME::Base64::encode_base64( $self->{options}{user} . ':' . $self->{options}{pass}, '' );
	}

	my @headers = (
		'Content-Type'  => 'application/json',
		'Authorization' => 'Basic ' . $auth,
	);

	require HTTP::Request;
	my $request  = HTTP::Request->new( $method, $url, \@headers, $body );
	my $response = $self->{ua}->request($request);

	if ( !$response->is_success ) {
		die(      $method . ' '
				. $url
				. ' failed... HTTP status... '
				. $response->status_line
				. '... content... '
				. $response->decoded_content );
	}

	return $response;
} ## end sub _request

=head2 init

Initiates the backend. Verifies the NITRO API is reachable and auth works
via a GET of C</nitro/v1/config>. Nothing is created on the NetScaler; the
dataset is expected to already exist.

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

	my $url = $self->_base_url;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = { requests => [ { method => 'GET', url => $url } ] };
	} else {
		local $@;
		eval { $self->_request( 'GET', $url ); 1; } or do {
			$self->{error}       = 23;
			$self->{errorString} = 'init failed. probing the NITRO API failed... ' . $@;
			$self->warn;
		};
	}

	$self->{inited} = 1;
} ## end sub init

=head2 ban

Bans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then bound into the policy dataset via a PUT to
C</nitro/v1/config/policydataset_value_binding>. Banning an already banned
IP is a noop.

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

	my $url = $self->_base_url . '/policydataset_value_binding';
	my $body
		= '{"policydataset_value_binding":{"name":"'
		. $self->{options}{dataset}
		. '","value":"'
		. $opts{ban} . '"}}';

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'PUT', url => $url, content => $body } ];
	} else {
		local $@;
		eval { $self->_request( 'PUT', $url, $body ); 1; } or do {
			$self->{error}       = 13;
			$self->{errorString} = 'banning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	}

	$self->{banned}{ $opts{ban} } = 1;
} ## end sub ban

# Internal helper. Returns the URL used to remove the binding for the passed
# IP.
sub _unban_url {
	my ( $self, $ip ) = @_;

	return
		  $self->_base_url
		. '/policydataset_value_binding/'
		. $self->{options}{dataset}
		. '?args=value:'
		. $self->_uri_escape($ip);
} ## end sub _unban_url

=head2 unban

Unbans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then its binding is removed from the policy dataset via a
DELETE of C</nitro/v1/config/policydataset_value_binding/E<lt>datasetE<gt>?args=value:E<lt>ipE<gt>>.
Unbanning an IP that is not banned is a noop.

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

	my $url = $self->_unban_url( $opts{ban} );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'DELETE', url => $url } ];
	} else {
		local $@;
		eval { $self->_request( 'DELETE', $url ); 1; } or do {
			$self->{error}       = 14;
			$self->{errorString} = 'unbanning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	}

	delete( $self->{banned}{ $opts{ban} } );
} ## end sub unban

=head2 ban_cidr

CIDR bans are not supported by this backend; this always sets the
cidrNotSupported error.

    $backend->ban_cidr(ban => '1.2.3.0/24');

=cut

sub ban_cidr {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{error}       = 32;
	$self->{errorString} = 'the ' . __PACKAGE__ . ' backend does not support CIDR bans';
	$self->warn;

	return;
} ## end sub ban_cidr

=head2 unban_cidr

CIDR bans are not supported by this backend; this always sets the
cidrNotSupported error.

    $backend->unban_cidr(ban => '1.2.3.0/24');

=cut

sub unban_cidr {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{error}       = 32;
	$self->{errorString} = 'the ' . __PACKAGE__ . ' backend does not support CIDR bans';
	$self->warn;

	return;
} ## end sub unban_cidr

=head2 list_cidr

CIDR bans are not supported by this backend, so this always returns an empty
list.

    my @banned_cidrs = $backend->list_cidr;

=cut

sub list_cidr {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	return ();
}

=head2 list

List banned IPs. Returns an array of the currently banned IPs from the
internal ban list; the NetScaler is not queried.

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

This will call teardown, best effort as a partially wiped setup is what it
is recovering from, then init again. After that every IP in the retained
ban list is re-banned by PUTing its dataset binding back.

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

	my @to_ban = keys( %{ $self->{banned} } );

	my @re_init_test_data;
	foreach my $item (@to_ban) {
		my $url = $self->_base_url . '/policydataset_value_binding';
		my $body
			= '{"policydataset_value_binding":{"name":"' . $self->{options}{dataset} . '","value":"' . $item . '"}}';

		if ( $self->{testing} ) {
			push( @re_init_test_data, { method => 'PUT', url => $url, content => $body } );
		} else {
			local $@;
			eval { $self->_request( 'PUT', $url, $body ); 1; } or do {
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

Tears down the setup for the backend by removing the binding for each
currently banned IP. The internal list of bans is kept, so a following
re_init will re-add them.

    $backend->teardown;

=cut

sub teardown {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{inited} = 0;

	my @requests;
	foreach my $item ( sort( keys( %{ $self->{banned} } ) ) ) {
		my $url = $self->_unban_url($item);
		if ( $self->{testing} ) {
			push( @requests, { method => 'DELETE', url => $url } );
		} else {
			local $@;
			eval { $self->_request( 'DELETE', $url ); 1; } or do {
				$self->{error}       = 17;
				$self->{errorString} = 'teardown failed removing the binding for "' . $item . '"... ' . $@;
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

Verifies the NITRO API is still reachable and auth still works. Returns a
true value if so and a false value otherwise. This is the equivalent of
fail2ban's C<actioncheck>.

    if ( !$backend->check ) {
        $backend->re_init;
    }

=cut

sub check {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	my $url = $self->_base_url;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'GET', url => $url } ];
		return 1;
	}

	local $@;
	eval { $self->_request( 'GET', $url ); 1; } or return 0;

	return 1;
} ## end sub check

=head2 flush

Removes all currently banned IPs at once by removing their bindings and
forgetting them. This is the equivalent of fail2ban's C<actionflush>.

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
		my $url = $self->_unban_url($item);
		if ( $self->{testing} ) {
			push( @requests, { method => 'DELETE', url => $url } );
		} else {
			local $@;
			eval { $self->_request( 'DELETE', $url ); 1; } or do {
				$self->{error}       = 25;
				$self->{errorString} = 'flush failed removing the binding for "' . $item . '"... ' . $@;
				$self->warn;
			};
		}
	} ## end foreach my $item ( sort( keys( %{ $self->{banned...})))

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@requests;
	}

	$self->{banned} = {};
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

No IP specified to ban or unban.

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

Probing the NITRO API during init failed.

=head2 24, checkFailed

The backend check raised an error.

=head2 25, flushFailed

Failed to flush the bans.

=head2 26, portsNotSupported

The netscaler backend blocks whole IPs and does not support ports.

=head2 27, protocolsNotSupported

The netscaler backend blocks whole IPs and does not support protocols.

=head2 28, optionInvalid

One of the options, such as host, auth, dataset, scheme, or timeout, is
invalid or missing.

=head2 29, banCidrFailed

Failed to ban the CIDR range.

=head2 30, unbanCidrFailed

Failed to unban the CIDR range.

=head2 31, cidrItemNotCidr

The item to ban is not a CIDR range. Either wrong ref type or it is not an
IPv4 or IPv6 address followed by a prefix length valid for its family.

=head2 32, cidrNotSupported

The backend does not support CIDR bans.

=head2 33, listCidrFailed

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
