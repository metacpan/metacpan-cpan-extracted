package Net::Firewall::BlockerHelper::backends::cloudflare;

use 5.006;
use strict;
use warnings;
use base 'Error::Helper';
use Regexp::IPv4 qw($IPv4_re);
use Regexp::IPv6 qw($IPv6_re);

=head1 NAME

Net::Firewall::BlockerHelper::backends::cloudflare - Cloudflare IP access rules backend for Net::Firewall::BlockerHelper.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 SYNOPSIS

    use Net::Firewall::BlockerHelper;

    my $fw_helper = Net::Firewall::BlockerHelper->new(
            backend => 'cloudflare',
            name => 'ssh',
            options => {
                token => $cf_api_token,
                zone  => $cf_zone_id,
            },
        );

    $fw_helper->init_backend;
    $fw_helper->ban(ban => '1.2.3.4');
    $fw_helper->unban(ban => '1.2.3.4');

=head1 DESCRIPTION

Blocks IPs remotely via the Cloudflare v4 API using IP access rules,
equivalent to the fail2ban cloudflare and cloudflare-token actions, but
using L<LWP::UserAgent> rather than curl.

Auth is via either a API token (preferred, the C<token> option) or the
legacy email plus global API key (the C<email> and C<key> options). If the
C<zone> option is set the rules are managed zone level, otherwise user
level.

Blocking is per IP; ports and protocols are not supported and specifying
them is an error.

L<LWP::UserAgent> is only loaded at run time, so it is only required if
this backend is actually used. For https, L<LWP::Protocol::https> must be
present as well.

=head1 NOTES

This backend was written going off the API docs and actual testing is
needed to double check a few things as the exact behavior is not clear.

teardown currently only removes the single IP access rules, leaving CIDR
bans in place remotely, while flush removes both. A re_init after a
teardown will re-add the CIDR bans, and how the API handles creating a
rule that already exists needs checking.

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

The options hash accepts the following. Either token or both email and key
must be specified.

    - token :: Cloudflare API token, used as a bearer token. Ideally
            restricted to just the needed permissions.
        - Default :: undef

    - email :: Account email for legacy global API key auth.
        - Default :: undef

    - key :: Legacy global API key.
        - Default :: undef

    - zone :: Zone ID to manage the rules under. If not set, the rules are
            managed at the user level.
        - Default :: undef

    - mode :: What Cloudflare should do with matching requests. One of
            'block', 'challenge', 'js_challenge', or 'managed_challenge'.
        - Default :: block

    - notes :: Note attached to created rules, also used to find them again
            for removal.
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
				20 => 'modeInvalid',
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
		inited         => 0,
		banned         => {},
		banned_cidr    => {},
		cidr_supported => 1,
		ua             => undef,
	};
	bless $self;

	# blocking is per IP; the API has no concept of ports or protocols
	if ( defined( $opts{ports} ) && ref( $opts{ports} ) eq 'ARRAY' && defined( $opts{ports}[0] ) ) {
		$self->{perror}      = 1;
		$self->{error}       = 26;
		$self->{errorString} = 'the cloudflare backend blocks whole IPs and does not support ports';
		$self->warn;
	}
	if ( defined( $opts{protocols} ) && ref( $opts{protocols} ) eq 'ARRAY' && defined( $opts{protocols}[0] ) ) {
		$self->{perror}      = 1;
		$self->{error}       = 27;
		$self->{errorString} = 'the cloudflare backend blocks whole IPs and does not support protocols';
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

	# needs a token, or a email + key for legacy auth
	if ( !defined( $self->{options}{token} )
		&& ( !defined( $self->{options}{email} ) || !defined( $self->{options}{key} ) ) )
	{
		$self->{perror} = 1;
		$self->{error}  = 28;
		$self->{errorString}
			= 'either the option token, or both the options email and key, must be specified for auth';
		$self->warn;
	}

	if ( defined( $self->{options}{zone} ) && $self->{options}{zone} !~ /^[a-fA-F0-9]+$/ ) {
		$self->{perror}      = 1;
		$self->{error}       = 28;
		$self->{errorString} = 'the option zone, "' . $self->{options}{zone} . '", does not look like a zone ID';
		$self->warn;
	}

	if ( defined( $self->{options}{mode} )
		&& $self->{options}{mode} ne 'block'
		&& $self->{options}{mode} ne 'challenge'
		&& $self->{options}{mode} ne 'js_challenge'
		&& $self->{options}{mode} ne 'managed_challenge' )
	{
		$self->{perror} = 1;
		$self->{error}  = 20;
		$self->{errorString}
			= '$opts{options}{mode} is "'
			. $self->{options}{mode}
			. '" and not "block", "challenge", "js_challenge", or "managed_challenge"';
		$self->warn;
	} elsif ( !defined( $self->{options}{mode} ) ) {
		$self->{options}{mode} = 'block';
	}

	if ( !defined( $self->{options}{notes} ) && defined( $self->{name} ) ) {
		$self->{options}{notes} = $self->{prefix} . '_' . $self->{name};
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

# Internal helper. Returns the access rules endpoint, zone level if the zone
# option is set and user level otherwise.
sub _endpoint {
	my ($self) = @_;

	if ( defined( $self->{options}{zone} ) ) {
		return 'https://api.cloudflare.com/client/v4/zones/' . $self->{options}{zone} . '/firewall/access_rules/rules';
	}
	return 'https://api.cloudflare.com/client/v4/user/firewall/access_rules/rules';
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

# Internal helper. Performs a HTTP request via LWP::UserAgent, returning the
# decoded JSON on success and dying with a explanation on any HTTP or API
# level failure. Never called in testing mode.
sub _request {
	my ( $self, $method, $url, $body ) = @_;

	if ( !defined( $self->{ua} ) ) {
		local $@;
		eval {
			require LWP::UserAgent;
			$self->{ua} = LWP::UserAgent->new(
				agent   => 'Net::Firewall::BlockerHelper/' . $VERSION,
				timeout => $self->{options}{timeout},
			);
			1;
		} or die( 'failed to load LWP::UserAgent, which the cloudflare backend requires... ' . $@ );
	}

	my @headers = ( 'Content-Type' => 'application/json' );
	if ( defined( $self->{options}{token} ) ) {
		push( @headers, 'Authorization' => 'Bearer ' . $self->{options}{token} );
	} else {
		push( @headers, 'X-Auth-Email' => $self->{options}{email}, 'X-Auth-Key' => $self->{options}{key} );
	}

	require HTTP::Request;
	my $request = HTTP::Request->new( $method, $url, \@headers, $body );

	my $response = $self->{ua}->request($request);

	my $decoded;
	local $@;
	eval { $decoded = $self->_json->decode( $response->decoded_content ); };

	if ( !$response->is_success || !defined($decoded) || !$decoded->{success} ) {
		my $api_errors = '';
		if ( defined($decoded) && ref( $decoded->{errors} ) eq 'ARRAY' ) {
			$api_errors = ' API errors... ' . join(
				', ',
				map {
					( defined( $_->{code} ) ? $_->{code} : '?' ) . ': '
						. ( defined( $_->{message} ) ? $_->{message} : '?' )
				} @{ $decoded->{errors} }
			);
		}
		die(      $method . ' '
				. $url
				. ' failed... HTTP status... '
				. $response->status_line
				. $api_errors );
	} ## end if ( !$response->is_success || !defined($decoded...))

	return $decoded;
} ## end sub _request

=head2 init

Initiates the backend. Verifies the credentials and endpoint by listing a
few rules.

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

	my $url = $self->_endpoint . '?per_page=5';

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = { requests => [ { method => 'GET', url => $url } ] };
	} else {
		local $@;
		eval { $self->_request( 'GET', $url ); 1; } or do {
			$self->{error}       = 23;
			$self->{errorString} = 'init failed. probing the access rules endpoint failed... ' . $@;
			$self->warn;
		};
	}

	$self->{inited} = 1;
} ## end sub init

=head2 ban

Bans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then an access rule is created for it via a POST to the
access rules endpoint, using the configured mode and notes. Banning an
already banned IP is a noop.

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

	my $target = ( $opts{ban} =~ /\A$IPv4_re\z/ ) ? 'ip' : 'ip6';
	my $body   = $self->_json->encode(
		{
			mode          => $self->{options}{mode},
			configuration => { target => $target, value => $opts{ban} },
			notes         => $self->{options}{notes},
		}
	);

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'POST', url => $self->_endpoint, content => $body } ];
	} else {
		local $@;
		eval { $self->_request( 'POST', $self->_endpoint, $body ); 1; } or do {
			$self->{error}       = 13;
			$self->{errorString} = 'banning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	}

	$self->{banned}{ $opts{ban} } = 1;
} ## end sub ban

# Internal helper. Returns the lookup URL used to find the rule ID for the
# passed IP.
sub _unban_lookup_url {
	my ( $self, $ip ) = @_;

	my $target = ( $ip =~ /\A$IPv4_re\z/ ) ? 'ip' : 'ip6';

	return
		  $self->_endpoint
		. '?mode='
		. $self->{options}{mode}
		. '&notes='
		. $self->_uri_escape( $self->{options}{notes} )
		. '&configuration.target='
		. $target
		. '&configuration.value='
		. $self->_uri_escape($ip);
} ## end sub _unban_lookup_url

# Internal helper. Looks the rule for the IP up and deletes it. Dies on
# failure. A rule that can not be found is treated as already unbanned.
# Never called in testing mode.
sub _unban_ip {
	my ( $self, $ip ) = @_;

	my $decoded = $self->_request( 'GET', $self->_unban_lookup_url($ip) );

	my $id;
	if ( ref( $decoded->{result} ) eq 'ARRAY' && defined( $decoded->{result}[0] ) ) {
		$id = $decoded->{result}[0]{id};
	}

	# no rule found means something else removed it already, which is fine
	if ( !defined($id) ) {
		return;
	}

	$self->_request( 'DELETE', $self->_endpoint . '/' . $id );

	return;
} ## end sub _unban_ip

=head2 unban

Unbans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased. The matching access rule is then found via a GET filtering
on mode, notes, and the IP, and deleted by its ID. A rule that can not be
found is treated as already unbanned. Unbanning an IP that is not banned is
a noop.

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
			{ method => 'DELETE', url => $self->_endpoint . '/<id>' },
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

=head2 ban_cidr

Bans a CIDR range by creating an access rule for it. Cloudflare access rules
accept a network prefix as the configuration value in the same manner as a
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
		$self->{error}       = 31;
		$self->{errorString} = 'Bad ref type for ban... ref is "' . ref( $opts{ban} ) . '"';
		$self->warn;
		return;
	} elsif ( !$self->_valid_cidr( $opts{ban} ) ) {
		$self->{error}       = 31;
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

	# the address portion of the CIDR determines the family, and thus the target
	my $target = ( $opts{ban} =~ m!\A$IPv4_re/! ) ? 'ip' : 'ip6';
	my $body   = $self->_json->encode(
		{
			mode          => $self->{options}{mode},
			configuration => { target => $target, value => $opts{ban} },
			notes         => $self->{options}{notes},
		}
	);

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'POST', url => $self->_endpoint, content => $body } ];
	} else {
		local $@;
		eval { $self->_request( 'POST', $self->_endpoint, $body ); 1; } or do {
			$self->{error}       = 29;
			$self->{errorString} = 'banning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	}

	$self->{banned_cidr}{ $opts{ban} } = 1;
} ## end sub ban_cidr

# Internal helper. Returns the lookup URL used to find the rule ID for the
# passed CIDR range.
sub _unban_cidr_lookup_url {
	my ( $self, $cidr ) = @_;

	my $target = ( $cidr =~ m!\A$IPv4_re/! ) ? 'ip' : 'ip6';

	return
		  $self->_endpoint
		. '?mode='
		. $self->{options}{mode}
		. '&notes='
		. $self->_uri_escape( $self->{options}{notes} )
		. '&configuration.target='
		. $target
		. '&configuration.value='
		. $self->_uri_escape($cidr);
} ## end sub _unban_cidr_lookup_url

=head2 unban_cidr

Unbans a CIDR range by finding and deleting its access rule, the same way
L</unban> does for a single IP. A rule that can not be found is treated as
already unbanned. Unbanning a range that is not banned is a noop.

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
		$self->{error}       = 31;
		$self->{errorString} = 'Bad ref type for ban... ref is "' . ref( $opts{ban} ) . '"';
		$self->warn;
		return;
	} elsif ( !$self->_valid_cidr( $opts{ban} ) ) {
		$self->{error}       = 31;
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
		$self->{frontend_obj}->{test_data} = [
			{ method => 'GET',    url => $self->_unban_cidr_lookup_url( $opts{ban} ) },
			{ method => 'DELETE', url => $self->_endpoint . '/<id>' },
		];
	} else {
		local $@;
		eval {
			my $decoded = $self->_request( 'GET', $self->_unban_cidr_lookup_url( $opts{ban} ) );

			my $id;
			if ( ref( $decoded->{result} ) eq 'ARRAY' && defined( $decoded->{result}[0] ) ) {
				$id = $decoded->{result}[0]{id};
			}

			# no rule found means something else removed it already, which is fine
			if ( defined($id) ) {
				$self->_request( 'DELETE', $self->_endpoint . '/' . $id );
			}
			1;
		} or do {
			$self->{error}       = 30;
			$self->{errorString} = 'unbanning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	} ## end else [ if ( $self->{testing} ) ]

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
re-added all previously added bans.

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
		my $target = ( $item =~ /\A$IPv4_re\z/ ) ? 'ip' : 'ip6';
		my $body   = $self->_json->encode(
			{
				mode          => $self->{options}{mode},
				configuration => { target => $target, value => $item },
				notes         => $self->{options}{notes},
			}
		);

		if ( $self->{testing} ) {
			push( @re_init_test_data, { method => 'POST', url => $self->_endpoint, content => $body } );
		} else {
			local $@;
			eval { $self->_request( 'POST', $self->_endpoint, $body ); 1; } or do {
				$self->{error}       = 13;
				$self->{errorString} = 'banning "' . $item . '" failed... ' . $@;
				$self->warn;
			};
		}
	} ## end foreach my $item (@to_ban)

	# CIDR ranges are re-added the same way, the address portion of the CIDR
	# determining the target
	my @to_ban_cidr = keys( %{ $self->{banned_cidr} } );

	foreach my $item (@to_ban_cidr) {
		my $target = ( $item =~ m!\A$IPv4_re/! ) ? 'ip' : 'ip6';
		my $body   = $self->_json->encode(
			{
				mode          => $self->{options}{mode},
				configuration => { target => $target, value => $item },
				notes         => $self->{options}{notes},
			}
		);

		if ( $self->{testing} ) {
			push( @re_init_test_data, { method => 'POST', url => $self->_endpoint, content => $body } );
		} else {
			local $@;
			eval { $self->_request( 'POST', $self->_endpoint, $body ); 1; } or do {
				$self->{error}       = 29;
				$self->{errorString} = 'banning "' . $item . '" failed... ' . $@;
				$self->warn;
			};
		}
	} ## end foreach my $item (@to_ban_cidr)

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@re_init_test_data;
	}

	$self->{inited} = 1;
} ## end sub re_init

=head2 teardown

Tears down the setup for the backend by removing the access rule for each
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
		if ( $self->{testing} ) {
			push(
				@requests,
				{ method => 'GET',    url => $self->_unban_lookup_url($item) },
				{ method => 'DELETE', url => $self->_endpoint . '/<id>' }
			);
		} else {
			local $@;
			eval { $self->_unban_ip($item); 1; } or do {
				$self->{error}       = 17;
				$self->{errorString} = 'teardown failed removing the rule for "' . $item . '"... ' . $@;
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

Verifies the endpoint and credentials are still usable by listing a few
rules. Returns a true value if so and a false value otherwise. This is the
equivalent of fail2ban's C<actioncheck>.

    if ( !$backend->check ) {
        $backend->re_init;
    }

=cut

sub check {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	my $url = $self->_endpoint . '?per_page=5';

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
access rules and forgetting them. This is the equivalent of fail2ban's
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

	my @requests;
	foreach my $item ( sort( keys( %{ $self->{banned} } ) ) ) {
		if ( $self->{testing} ) {
			push(
				@requests,
				{ method => 'GET',    url => $self->_unban_lookup_url($item) },
				{ method => 'DELETE', url => $self->_endpoint . '/<id>' }
			);
		} else {
			local $@;
			eval { $self->_unban_ip($item); 1; } or do {
				$self->{error}       = 25;
				$self->{errorString} = 'flush failed removing the rule for "' . $item . '"... ' . $@;
				$self->warn;
			};
		}
	} ## end foreach my $item ( sort( keys( %{ $self->{banned...})))

	# CIDR ranges are removed the same way, looked up by their own lookup URL
	foreach my $item ( sort( keys( %{ $self->{banned_cidr} } ) ) ) {
		if ( $self->{testing} ) {
			push(
				@requests,
				{ method => 'GET',    url => $self->_unban_cidr_lookup_url($item) },
				{ method => 'DELETE', url => $self->_endpoint . '/<id>' }
			);
		} else {
			local $@;
			eval {
				my $decoded = $self->_request( 'GET', $self->_unban_cidr_lookup_url($item) );

				my $id;
				if ( ref( $decoded->{result} ) eq 'ARRAY' && defined( $decoded->{result}[0] ) ) {
					$id = $decoded->{result}[0]{id};
				}

				if ( defined($id) ) {
					$self->_request( 'DELETE', $self->_endpoint . '/' . $id );
				}
				1;
			} or do {
				$self->{error}       = 25;
				$self->{errorString} = 'flush failed removing the rule for "' . $item . '"... ' . $@;
				$self->warn;
			};
		} ## end else [ if ( $self->{testing} ) ]
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

=head2 20, modeInvalid

The option mode is not 'block', 'challenge', 'js_challenge', or
'managed_challenge'.

=head2 23, initFailed

init failed. Probing the access rules endpoint failed.

=head2 24, checkFailed

The backend check raised an error.

=head2 25, flushFailed

Failed to flush the bans.

=head2 26, portsNotSupported

The cloudflare backend blocks whole IPs and does not support ports.

=head2 27, protocolsNotSupported

The cloudflare backend blocks whole IPs and does not support protocols.

=head2 28, optionInvalid

An option is invalid. Auth requires either the option token or both the
options email and key, zone must be a zone ID, and timeout must be an int.

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
