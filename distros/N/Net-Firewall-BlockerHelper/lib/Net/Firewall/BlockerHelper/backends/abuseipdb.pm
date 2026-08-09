package Net::Firewall::BlockerHelper::backends::abuseipdb;

use 5.006;
use strict;
use warnings;
use base         qw( Error::Helper Net::Firewall::BlockerHelper::Util );
use Regexp::IPv4 qw($IPv4_re);
use Regexp::IPv6 qw($IPv6_re);

=head1 NAME

Net::Firewall::BlockerHelper::backends::abuseipdb - Report banned IPs to AbuseIPDB.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 SYNOPSIS

    use Net::Firewall::BlockerHelper;

    my $fw_helper = Net::Firewall::BlockerHelper->new(
        backend => 'abuseipdb',
        name    => 'ssh',
        options => {
            key        => $abuseipdb_api_key,
            categories => [ '18', '22' ],
        },
    );

    $fw_helper->init_backend;
    $fw_helper->ban( ban => '1.2.3.4' );

=head1 DESCRIPTION

Reports banned IPs to L<AbuseIPDB|https://www.abuseipdb.com/> via its v2 REST
API, equivalent to the fail2ban abuseipdb action. This backend blocks nothing
itself; it is meant to be used alongside a blocking backend so a ban both
blocks locally and reports upstream.

Reports can not be withdrawn, so unban, flush, and teardown are purely
internal bookkeeping and touch the API not at all. re_init likewise does not
re-report anything, as there is no remote state to restore.

Reporting the same IP again within AbuseIPDB's rate limit window (15 minutes
at the time of writing) is answered with a HTTP 429, which this backend
treats as already reported rather than as an error, so replaying saved ban
state through ban does not error out.

Both IPv4 and IPv6 are supported. Reporting is per IP; ports and protocols are
not supported and specifying them is an error.

The comment sent with each report is publicly visible on AbuseIPDB, so do not
put anything sensitive in the C<comment> option.

L<LWP::UserAgent> is loaded at run time, so it is only required when this
backend is actually used. As the API is https only, L<LWP::Protocol::https>
must be present as well.

=head1 METHODS

=head2 new

Initiates the backend object. No API calls are made until L</init>.

    - options :: Backend specific options. See below.
    - prefix :: Prefix to use. Must match /^[a-zA-Z0-9]+$/. Default kur.
    - name :: Name of this instance. Required.

Ports and protocols are not supported and specifying either is an error.

The options hash accepts the following.

    - key :: AbuseIPDB API key. Required.
        - Default :: undef

    - categories :: Report categories, as either a array ref of category
            numbers or a comma separated string of them. See
            L<https://www.abuseipdb.com/categories> for the meanings; the
            default, 18, is Brute-Force.
        - Default :: 18

    - comment :: Comment attached to each report. '%%%BAN%%%' is replaced
            with the IP being reported. Publicly visible on AbuseIPDB. If
            blank, no comment is sent.
        - Default :: banned by <prefix>_<name>

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
				30 => 'keyNotDefined',
				31 => 'categoriesInvalid',
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
		frontend_obj => undef,
		inited       => 0,
		banned       => {},
		cidr_supported => 0,
		ua           => undef,
	};
	bless $self;

	# reporting is per IP; ports and protocols have no meaning here
	if ( defined( $opts{ports} ) && ref( $opts{ports} ) eq 'ARRAY' && defined( $opts{ports}[0] ) ) {
		$self->{perror}      = 1;
		$self->{error}       = 26;
		$self->{errorString} = 'the abuseipdb backend reports whole IPs and does not support ports';
		$self->warn;
	}
	if ( defined( $opts{protocols} ) && ref( $opts{protocols} ) eq 'ARRAY' && defined( $opts{protocols}[0] ) ) {
		$self->{perror}      = 1;
		$self->{error}       = 27;
		$self->{errorString} = 'the abuseipdb backend reports whole IPs and does not support protocols';
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

	# required options
	if ( !defined( $self->{options}{key} ) || $self->{options}{key} eq '' ) {
		$self->{perror}      = 1;
		$self->{error}       = 30;
		$self->{errorString} = 'the option key is undef or blank';
		$self->warn;
	}

	# categories may be a array ref of category numbers or a comma separated
	# string of them... normalized to the comma separated string form
	if ( !defined( $self->{options}{categories} ) ) {
		$self->{options}{categories} = '18';
	} elsif ( ref( $self->{options}{categories} ) eq 'ARRAY' ) {
		foreach my $item ( @{ $self->{options}{categories} } ) {
			if ( !defined($item) || ref($item) ne '' || $item !~ /^[0-9]+$/ ) {
				$self->{perror} = 1;
				$self->{error}  = 31;
				$self->{errorString}
					= 'categories contains "'
					. ( defined($item) ? $item : 'undef' )
					. '" which is not a positive int';
				$self->warn;
			}
		}
		$self->{options}{categories} = join( ',', @{ $self->{options}{categories} } );
	} elsif ( ref( $self->{options}{categories} ) ne '' || $self->{options}{categories} !~ /^[0-9]+(,[0-9]+)*$/ ) {
		$self->{perror} = 1;
		$self->{error}  = 31;
		$self->{errorString}
			= 'categories is "'
			. $self->{options}{categories}
			. '" and not a array ref or comma separated string of positive ints';
		$self->warn;
	}

	# defaults
	$self->{options}{timeout} = 30 if ( !defined( $self->{options}{timeout} ) );
	if ( !defined( $self->{options}{comment} ) && defined( $self->{name} ) ) {
		$self->{options}{comment} = 'banned by ' . $self->{prefix} . '_' . $self->{name};
	}

	return $self;
} ## end sub new

# Internal helper. Returns the base URL of the AbuseIPDB v2 API, which the
# other URLs in this backend are built on.
#
# It is a constant rather than an option, since AbuseIPDB is a single hosted
# service with one endpoint; there is no self hosted or per account variant to
# point at.
#
# Takes no arguments.
#
# Returns the base URL as a string, with no trailing slash.
#
#     $self->_api_base;    # https://api.abuseipdb.com/api/v2
sub _api_base {
	my ($self) = @_;

	return 'https://api.abuseipdb.com/api/v2';
}

# Internal helper. Returns the URL of a harmless read only call, used by init
# and check to confirm the service is reachable and the API key works.
#
# This backend is report only: it never blocks anything and creates nothing
# remotely, so there is no setup whose presence could be verified. What can be
# checked is that the API answers and the key is accepted, which is what this
# is for. Nothing parses the response; only success matters.
#
# The address queried is 127.0.0.2, deliberately chosen: it is a loopback
# address that cannot be a real reporter or target, so the probe cannot be
# mistaken for interest in a genuine host. The one day window keeps the
# response small.
#
# Note this consumes a request against the account's daily check quota each
# time it runs, which matters on an instance whose self healing check fires
# often.
#
# Takes no arguments.
#
# Returns the URL as a string, for a GET whose result is only inspected for
# success.
#
#     $self->_check_url;
#     #   https://api.abuseipdb.com/api/v2/check?ipAddress=127.0.0.2&maxAgeInDays=1
sub _check_url {
	my ($self) = @_;

	return $self->_api_base . '/check?ipAddress=127.0.0.2&maxAgeInDays=1';
}

# Internal helper. Builds the form encoded body that reports one address to
# AbuseIPDB.
#
# The categories are sent as the configured value, which is normalized to a
# comma separated list at new whether it was given as an arrayref or a string.
# They are what tell AbuseIPDB what kind of abuse is being reported.
#
# The comment is optional and is left out entirely when unset or empty, rather
# than being sent blank. Every occurrence of the %%%BAN%%% placeholder in it
# is replaced with the address, so a configured comment can name what was
# blocked.
#
# One thing worth keeping in mind when setting that comment: it is published
# on AbuseIPDB and visible to anyone, so it must not carry hostnames,
# usernames, log fragments, or anything else internal.
#
# Args:
#
#     ip - The address to report, as a plain string. Expected to be an already
#          validated and lowercased IPv4 or IPv6 address. Percent encoded into
#          the body, and also substituted into the comment where the
#          placeholder appears.
#
# Returns the body as a form urlencoded string, ready to POST to the report
# endpoint.
#
#     # with categories 18 and 22 and a comment
#     $self->_report_body('10.0.0.1');
#     #   ip=10.0.0.1&categories=18%2C22&comment=banned%2010.0.0.1%20by%20fail2ban
#
#     # with no comment configured
#     $self->_report_body('10.0.0.1');
#     #   ip=10.0.0.1&categories=18%2C22
sub _report_body {
	my ( $self, $ip ) = @_;

	my $body = 'ip=' . $self->_uri_escape($ip) . '&categories=' . $self->_uri_escape( $self->{options}{categories} );

	if ( defined( $self->{options}{comment} ) && $self->{options}{comment} ne '' ) {
		my $comment = $self->{options}{comment};
		$comment =~ s/\%\%\%BAN\%\%\%/$ip/g;
		$body .= '&comment=' . $self->_uri_escape($comment);
	}

	return $body;
} ## end sub _report_body

# Internal helper. Performs one HTTP request against the AbuseIPDB API. Every
# call this backend makes goes through here.
#
# What makes this different from the other HTTP helpers in the dist is the
# tolerate argument. AbuseIPDB rate limits reports, and a report rejected for
# exceeding the daily quota is a normal operating condition rather than a
# failure: the ban itself has already been applied by whatever blocking
# backend is paired with this one, and failing the ban because the reporting
# service was busy would be the wrong call. So the report path tolerates 429
# and carries on.
#
# The user agent is built on first use and cached on the object, so a run of
# requests shares one agent. LWP::UserAgent is loaded with require at that
# point rather than at compile time, since only the HTTP backends need it;
# failing to load it dies with an explanation naming this backend.
#
# Authentication is the API key in a Key header.
#
# Any untolerated HTTP failure dies rather than setting an error. The callers
# wrap this in eval and turn the exception into the appropriate error code.
#
# Never called in testing mode; those paths record the request instead.
#
# Args:
#
#     method   - The HTTP method, as a plain string: 'GET' for the check
#                probe, 'POST' for a report.
#
#     url      - The full URL to request, as a plain string, built on
#                _api_base.
#
#     body     - Optional request body, as a form urlencoded string from
#                _report_body. undef for the check probe.
#
#     tolerate - Optional hashref of HTTP status codes to treat as
#                non fatal, keyed by the numeric code with any true value,
#                such as { 429 => 1 }. A response with one of those codes
#                returns undef instead of dying. Omitted by callers that want
#                every failure to be fatal.
#
# Returns the decoded response body on success, or undef when the status was
# one of the tolerated ones. Dies on any other non success status.
#
#     # the check probe, where any failure is fatal
#     $self->_request( 'GET', $self->_check_url );
#
#     # a report, tolerating the rate limit
#     $self->_request( 'POST', $url, $body, { 429 => 1 } );
#
#     # the usual shape at the call sites
#     eval { $self->_request( 'GET', $self->_check_url ); 1; } or do { ... };
sub _request {
	my ( $self, $method, $url, $body, $tolerate ) = @_;

	if ( !defined( $self->{ua} ) ) {
		local $@;
		eval {
			require LWP::UserAgent;
			$self->{ua} = LWP::UserAgent->new(
				agent   => 'Net::Firewall::BlockerHelper/' . $VERSION,
				timeout => $self->{options}{timeout},
			);
			1;
		} or die( 'failed to load LWP::UserAgent, which the abuseipdb backend requires... ' . $@ );
	}

	my @headers = ( 'Key' => $self->{options}{key}, 'Accept' => 'application/json' );
	if ( defined($body) ) {
		push( @headers, 'Content-Type' => 'application/x-www-form-urlencoded' );
	}

	require HTTP::Request;
	my $request = HTTP::Request->new( $method, $url, \@headers, $body );

	my $response = $self->{ua}->request($request);

	if ( !$response->is_success ) {
		if ( defined($tolerate) && $tolerate->{ $response->code } ) {
			return undef;
		}
		my $detail = $response->decoded_content;
		$detail = defined($detail) ? ( ' body... ' . $detail ) : '';
		die( $method . ' ' . $url . ' failed... HTTP status... ' . $response->status_line . $detail );
	}

	return $response->decoded_content;
} ## end sub _request

=head2 init

Initiates the backend. Verifies the API key and reachability via a minimal
GET to the v2 C</check> endpoint. Nothing is created remotely; there is no
remote state to set up.

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
		$self->{frontend_obj}->{test_data} = [ { method => 'GET', url => $self->_check_url } ];
	} else {
		local $@;
		eval { $self->_request( 'GET', $self->_check_url ); 1; } or do {
			$self->{error}       = 23;
			$self->{errorString} = 'init failed. probing the check endpoint failed... ' . $@;
			$self->warn;
		};
	}

	$self->{inited} = 1;
} ## end sub init

=head2 ban

Bans the IP by reporting it. The value of ban is validated as being a IPv4 or
IPv6 address and lowercased, then reported via a POST to the v2 C</report>
endpoint with the configured categories and comment. A HTTP 429, AbuseIPDB's
answer to reporting the same IP again inside its rate limit window, is
treated as already reported rather than as an error. Banning an already
banned IP is a noop.

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

	my $url  = $self->_api_base . '/report';
	my $body = $self->_report_body( $opts{ban} );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'POST', url => $url, content => $body } ];
	} else {
		local $@;
		eval { $self->_request( 'POST', $url, $body, { 429 => 1 } ); 1; } or do {
			$self->{error}       = 13;
			$self->{errorString} = 'reporting "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	}

	$self->{banned}{ $opts{ban} } = 1;
} ## end sub ban

=head2 unban

Unbans the IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then removed from the internal ban list. Reports can not be
withdrawn, so no API call is made. Unbanning an IP that is not banned is a
noop.

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
		$self->{frontend_obj}->{test_data} = 'unban is internal only';
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

	$self->{error}       = 35;
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

	$self->{error}       = 35;
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

List banned IPs. Returns an array of the IPs reported since init, from the
internal ban list; no API call is made.

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

Tears down and re-inits. Unlike the blocking backends nothing is re-added, as
reports are fire and forget and there is no remote state to restore.

=cut

sub re_init {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	# teardown is best effort here for parity with the other backends, even
	# though for this backend it can not fail
	{
		local $@;
		eval { $self->teardown; };
	}
	$self->init;

	$self->{inited} = 1;
} ## end sub re_init

=head2 teardown

Tears down the backend. Reports can not be withdrawn, so no API calls are
made. The internal list of bans is kept.

    $backend->teardown;

=cut

sub teardown {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{inited} = 0;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = 'teardown is internal only';
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

Verifies the API key and reachability are still usable via a minimal GET to
the v2 C</check> endpoint. Returns a true value if so and a false value
otherwise. This is the
equivalent of fail2ban's C<actioncheck>.

    if ( !$backend->check ) {
        $backend->re_init;
    }

=cut

sub check {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'GET', url => $self->_check_url } ];
		return 1;
	}

	local $@;
	eval { $self->_request( 'GET', $self->_check_url ); 1; } or return 0;

	return 1;
} ## end sub check

=head2 flush

Removes all currently banned IPs at once by forgetting them. Reports can not
be withdrawn, so no API calls are made. This is the equivalent of fail2ban's
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

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = 'flush is internal only';
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

init failed. Probing the check endpoint failed.

=head2 24, checkFailed

The backend check raised an error.

=head2 25, flushFailed

Failed to flush the bans.

=head2 26, portsNotSupported

The abuseipdb backend reports whole IPs and does not support ports.

=head2 27, protocolsNotSupported

The abuseipdb backend reports whole IPs and does not support protocols.

=head2 30, keyNotDefined

The option key is undef or blank.

=head2 31, categoriesInvalid

The option categories is not an array ref of positive ints or a comma
separated string of positive ints.

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

1;    # End of Net::Firewall::BlockerHelper::backends::abuseipdb
