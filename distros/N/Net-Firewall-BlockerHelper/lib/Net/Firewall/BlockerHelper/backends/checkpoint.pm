package Net::Firewall::BlockerHelper::backends::checkpoint;

use 5.006;
use strict;
use warnings;
use base         qw( Error::Helper Net::Firewall::BlockerHelper::Util );
use Regexp::IPv4 qw($IPv4_re);
use Regexp::IPv6 qw($IPv6_re);

=head1 NAME

Net::Firewall::BlockerHelper::backends::checkpoint - Check Point Management (web_api) backend.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 SYNOPSIS

    use Net::Firewall::BlockerHelper;

    my $fw_helper = Net::Firewall::BlockerHelper->new(
        backend => 'checkpoint',
        name    => 'ssh',
        options => {
            host     => 'mgmt.example.org',
            user     => 'automation',
            password => $checkpoint_password,
            group    => 'blocklist',
        },
    );

    $fw_helper->init_backend;
    $fw_helper->ban( ban => '1.2.3.4' );
    $fw_helper->unban( ban => '1.2.3.4' );

=head1 DESCRIPTION

Blocks IPs on a Check Point Security Management server via its C<web_api>. For
each banned IP a host object is created and added as a member of a group object;
a rule in the policy referencing that group then drops the traffic. The group
object (default C<< <prefix>_<name> >>) and the drop rule referencing it must
already exist; this backend creates neither, only the host objects added to the
group.

Authentication is session based. L</init> POSTs to C<< /web_api/login >> with the
configured user and password and stores the returned session id. Every following
call sends that session id in the C<X-chkp-sid> header. All calls are POSTs
carrying JSON bodies.

The management server is reached at C<< https://<host> >> (port 443 by default).

Blocking is per IP; ports and protocols belong on the referencing rule, so
specifying them here is an error.

B<Enforcement note:> C<publish> only saves the change to the management
database. Actually enforcing the block on the gateways additionally requires an
C<install-policy>, which is intentionally out of scope for this backend.

L<LWP::UserAgent> is loaded at run time, so it is only required when this backend
is actually used. For https, L<LWP::Protocol::https> must be present as well.

=head1 NOTES

This backend was written going off the API docs and actual testing is
needed to double check a few things as the exact behavior is not clear.

ban_cidr creates a host object with the CIDR as its ip-address and the
C</> is kept in the generated object name, and it is not clear whether
the web_api will accept either; a network object may be required instead.

=head1 METHODS

=head2 new

    - options :: Backend specific options. See below.
    - prefix :: Prefix to use. Must match /^[a-zA-Z0-9]+$/. Default kur.
    - name :: Name of this instance. Required.

Ports and protocols are not supported and specifying either is an error.

The options hash accepts the following.

    - host :: Check Point management server host. Required.
        - Default :: undef

    - user :: web_api user to log in as. Required.
        - Default :: undef

    - password :: password for the web_api user. Required.
        - Default :: undef

    - group :: group object the host objects are added to.
        - Default :: <prefix>_<name>

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
		sid            => undef,
	};
	bless $self;

	# blocking is per IP; ports/protocols belong on the referencing rule
	if ( defined( $opts{ports} ) && ref( $opts{ports} ) eq 'ARRAY' && defined( $opts{ports}[0] ) ) {
		$self->{perror}      = 1;
		$self->{error}       = 26;
		$self->{errorString} = 'the checkpoint backend blocks whole IPs and does not support ports';
		$self->warn;
	}
	if ( defined( $opts{protocols} ) && ref( $opts{protocols} ) eq 'ARRAY' && defined( $opts{protocols}[0] ) ) {
		$self->{perror}      = 1;
		$self->{error}       = 27;
		$self->{errorString} = 'the checkpoint backend blocks whole IPs and does not support protocols';
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

	# defaults
	$self->{options}{timeout}  = 30 if ( !defined( $self->{options}{timeout} ) );
	$self->{options}{insecure} = 0  if ( !defined( $self->{options}{insecure} ) );
	if ( defined( $self->{name} ) ) {
		$self->{options}{group} = $self->{prefix} . '_' . $self->{name} if ( !defined( $self->{options}{group} ) );
	}

	return $self;
} ## end sub new

# Internal helper. Returns the scheme and host of the Check Point management
# server, which every web_api endpoint is built on.
#
# The Check Point web_api is a flat set of POST endpoints under /web_api/
# rather than a resource tree, so the callers append the specific command
# themselves rather than there being a URL builder per operation.
#
# The scheme is fixed at https rather than configurable, since the management
# API is expected to be run over TLS.
#
# Takes no arguments; the host comes from the options.
#
# Returns the base URL as a string, with no trailing slash.
#
#     $self->_base_url;                          # https://mgmt.example.org
#     $self->_base_url . '/web_api/add-host';    # the usual shape
sub _base_url {
	my ($self) = @_;

	return 'https://' . $self->{options}{host};
}

# Internal helper. Returns the name of the Check Point host object
# representing one banned address.
#
# Check Point has no set type that simply holds addresses. Each ban becomes a
# named host object that is made a member of a group the policy references, so
# every ban needs a name.
#
# The name is derived from the prefix, the instance name, and the address
# rather than stored, so ban and unban independently arrive at the same name
# without local bookkeeping, and two instances against the same management
# server do not collide. Dots and colons are replaced with hyphens because
# Check Point rejects them in object names.
#
# Args:
#
#     ip - The address to name an object for, as a plain string. Expected to
#          be an already validated and lowercased IPv4 or IPv6 address.
#
# Returns the object name as a plain string, valid as a Check Point object
# name.
#
#     # with prefix "kur" and name "ssh"
#     $self->_obj_name('10.0.0.1');      # kur_ssh_10-0-0-1
#     $self->_obj_name('2001:db8::1');   # kur_ssh_2001-db8--1
sub _obj_name {
	my ( $self, $ip ) = @_;

	my $name = $self->{prefix} . '_' . $self->{name} . '_' . $ip;
	# dots and colons are not valid in Check Point object names
	$name =~ s/[.:]/-/g;

	return $name;
} ## end sub _obj_name

# Internal helper. Performs one HTTP request against the Check Point web_api.
# Every call this backend makes to the management server goes through here.
#
# Authentication is by session rather than by credential or standing token.
# init POSTs to /web_api/login and stores the session id, which this then
# sends in the X-chkp-sid header on every following call. The header is only
# added when a session id is set, which is what lets the login request itself
# go through this same helper before there is one.
#
# The user agent is built on first use and cached on the object, so a run of
# requests shares one agent. LWP::UserAgent is loaded with require at that
# point rather than at compile time, since only the HTTP backends need it;
# failing to load it dies with an explanation naming this backend. The
# insecure option turns off certificate verification, which is there because a
# management server commonly presents a self signed certificate.
#
# Any HTTP level failure dies rather than setting an error. The callers wrap
# this in eval and turn the exception into the appropriate error code, which
# is what lets one helper serve paths that report ban, unban, and teardown
# failures differently.
#
# A body that fails to decode as JSON is not fatal; the decode runs inside its
# own eval and leaves the result undef.
#
# Never called in testing mode; those paths record the request descriptors
# instead.
#
# Args:
#
#     method - The HTTP method, as a plain string. In practice always 'POST',
#              since the web_api exposes everything as POST endpoints.
#
#     url    - The full URL to request, as a plain string, normally
#              _base_url with a /web_api/ command appended.
#
#     body   - The request body, as an already encoded JSON string. Note the
#              web_api expects a JSON object even where there is nothing to
#              say, so callers pass the literal '{}' rather than undef for
#              those.
#
# Returns the decoded response body as whatever structure the JSON held,
# normally a hashref, or undef when the response body was empty or did not
# parse. Dies on any non success HTTP status.
#
#     $self->_request( 'POST', $self->_base_url . '/web_api/publish', '{}' );
#
#     # the usual shape at the call sites
#     eval { $self->_request( $r->{method}, $r->{url}, $r->{content} ); };
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
		} or die( 'failed to load LWP::UserAgent, which the checkpoint backend requires... ' . $@ );
	}

	my @headers = ('Content-Type' => 'application/json');
	if ( defined( $self->{sid} ) ) {
		push( @headers, 'X-chkp-sid' => $self->{sid} );
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

# Internal helper. Returns the pair of requests that ban one address.
#
# Unlike the fortigate backend, creating the object and putting it in the
# group is a single call here: add-host takes a groups list, so the membership
# comes along with the creation.
#
# The second call is the one that is easy to overlook. Check Point changes
# land in a private session and have no effect until published, so a ban
# without the publish would appear to succeed while blocking nothing. That is
# why the two are returned together rather than being sequenced by the caller.
#
# Returning descriptors rather than performing the requests is what lets the
# testing paths record exactly what would have been sent without a management
# server being present.
#
# Args:
#
#     ip - The address to ban, as a plain string. Expected to be an already
#          validated and lowercased IPv4 or IPv6 address. Note the address
#          goes into the ip-address field for both families; Check Point does
#          not split hosts by family the way FortiOS does.
#
# Returns a two element list of hashrefs, in the order they must be performed,
# each with method, url, and content keys.
#
#     my @requests = $self->_ban_requests('10.0.0.1');
#
#     # first, create the host and put it in the group
#     #   POST https://mgmt.example.org/web_api/add-host
#     #     {"groups":["blocklist"],"ip-address":"10.0.0.1","name":"kur_ssh_10-0-0-1"}
#
#     # then, publish so it takes effect
#     #   POST https://mgmt.example.org/web_api/publish
#     #     {}
sub _ban_requests {
	my ( $self, $ip ) = @_;

	my $add_host = $self->_json->encode(
		{
			name         => $self->_obj_name($ip),
			'ip-address' => $ip,
			groups       => [ $self->{options}{group} ],
		}
	);

	return (
		{ method => 'POST', url => $self->_base_url . '/web_api/add-host', content => $add_host },
		{ method => 'POST', url => $self->_base_url . '/web_api/publish',  content => '{}' },
	);
} ## end sub _ban_requests

# Internal helper. Returns the pair of requests that unban one address, the
# inverse of _ban_requests.
#
# Deleting the host object also removes it from the group, so there is no
# separate membership call, mirroring the way the ban created both at once.
# The publish is required here for exactly the same reason it is on the ban:
# without it the deletion stays in the private session and the address remains
# blocked.
#
# The delete identifies the object by name alone, which is why the object name
# has to be derivable rather than stored.
#
# Args:
#
#     ip - The address to unban, as a plain string. Expected to be an already
#          validated and lowercased IPv4 or IPv6 address, and to produce the
#          same object name it did when banned.
#
# Returns a two element list of hashrefs, in the order they must be performed,
# each with method, url, and content keys.
#
#     my @requests = $self->_unban_requests('10.0.0.1');
#
#     # first, delete the host object
#     #   POST https://mgmt.example.org/web_api/delete-host
#     #     {"name":"kur_ssh_10-0-0-1"}
#
#     # then, publish so it takes effect
#     #   POST https://mgmt.example.org/web_api/publish
#     #     {}
sub _unban_requests {
	my ( $self, $ip ) = @_;

	my $delete_host = $self->_json->encode( { name => $self->_obj_name($ip) } );

	return (
		{ method => 'POST', url => $self->_base_url . '/web_api/delete-host', content => $delete_host },
		{ method => 'POST', url => $self->_base_url . '/web_api/publish',     content => '{}' },
	);
} ## end sub _unban_requests

=head2 init

Initiates the backend. Logs into the web_api by POSTing the configured user and
password to C<< /web_api/login >> and stores the returned session id, which is
sent in the C<X-chkp-sid> header on every following call.

Note that nothing is created remotely by this; the group object must already
exist. See L</DESCRIPTION>.

=cut

sub init {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( $self->{inited} ) {
		$self->{error}       = 18;
		$self->{errorString} = 'backend has already been inited';
		$self->warn;
	}

	my $url = $self->_base_url . '/web_api/login';

	if ( $self->{testing} ) {
		# the login body carries the password, so it is intentionally not recorded
		$self->{frontend_obj}->{test_data} = [ { method => 'POST', url => $url } ];
	} else {
		my $body = $self->_json->encode(
			{
				user     => $self->{options}{user},
				password => $self->{options}{password},
			}
		);
		local $@;
		eval {
			my $decoded = $self->_request( 'POST', $url, $body );
			if ( !defined($decoded) || !defined( $decoded->{sid} ) ) {
				die('login response did not contain a session id (sid)');
			}
			$self->{sid} = $decoded->{sid};
			1;
		} or do {
			$self->{error}       = 23;
			$self->{errorString} = 'init failed. logging into the web_api failed... ' . $@;
			$self->warn;
		};
	} ## end else [ if ( $self->{testing} ) ]

	$self->{inited} = 1;
} ## end sub init

=head2 ban

Bans an IP. The value of ban is validated as being a IPv4 or IPv6 address and
lowercased. A host object named C<< <prefix>_<name>_<ip> >> (dots and colons
replaced with C<->) is created via C<< /web_api/add-host >> with the group as a
member group, then the change is saved via C<< /web_api/publish >>. Banning an
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

	my @requests = $self->_ban_requests( $opts{ban} );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@requests;
	} else {
		local $@;
		eval {
			foreach my $req (@requests) {
				$self->_request( $req->{method}, $req->{url}, $req->{content} );
			}
			1;
		} or do {
			$self->{error}       = 13;
			$self->{errorString} = 'banning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	} ## end else [ if ( $self->{testing} ) ]

	$self->{banned}{ $opts{ban} } = 1;
} ## end sub ban

=head2 unban

Unbans an IP. The value of ban is validated as being a IPv4 or IPv6 address and
lowercased. The host object created by L</ban> is deleted via
C<< /web_api/delete-host >>, then the change is saved via
C<< /web_api/publish >>. Unbanning an IP that is not banned is a noop.

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

	my @requests = $self->_unban_requests( $opts{ban} );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@requests;
	} else {
		local $@;
		eval {
			foreach my $req (@requests) {
				$self->_request( $req->{method}, $req->{url}, $req->{content} );
			}
			1;
		} or do {
			$self->{error}       = 14;
			$self->{errorString} = 'unbanning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	} ## end else [ if ( $self->{testing} ) ]

	delete( $self->{banned}{ $opts{ban} } );
} ## end sub unban

=head2 ban_cidr

Bans a CIDR range. The value of ban is validated as being a IPv4 or IPv6 CIDR
range and lowercased, then handled the same way as L</ban>, a host object with
the CIDR as its ip-address being created via C<< /web_api/add-host >> with the
group as a member group and the change saved via C<< /web_api/publish >>.
Banning an already banned CIDR range is a noop.

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

	my @requests = $self->_ban_requests( $opts{ban} );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@requests;
	} else {
		local $@;
		eval {
			foreach my $req (@requests) {
				$self->_request( $req->{method}, $req->{url}, $req->{content} );
			}
			1;
		} or do {
			$self->{error}       = 33;
			$self->{errorString} = 'banning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	} ## end else [ if ( $self->{testing} ) ]

	$self->{banned_cidr}{ $opts{ban} } = 1;
} ## end sub ban_cidr

=head2 unban_cidr

Unbans a CIDR range. The value of ban is validated as being a IPv4 or IPv6 CIDR
range and lowercased. The host object created by L</ban_cidr> is deleted via
C<< /web_api/delete-host >>, then the change is saved via
C<< /web_api/publish >>. Unbanning a CIDR range that is not banned is a noop.

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

	my @requests = $self->_unban_requests( $opts{ban} );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@requests;
	} else {
		local $@;
		eval {
			foreach my $req (@requests) {
				$self->_request( $req->{method}, $req->{url}, $req->{content} );
			}
			1;
		} or do {
			$self->{error}       = 34;
			$self->{errorString} = 'unbanning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	} ## end else [ if ( $self->{testing} ) ]

	delete( $self->{banned_cidr}{ $opts{ban} } );
} ## end sub unban_cidr

=head2 list_cidr

List banned CIDR ranges. Returns an array of the currently banned CIDR ranges
from internal state; nothing is queried from the management server. Single IPs
are not included; for those see L</list>.

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
internal state; nothing is queried from the management server. CIDR ranges are
not included; for those see L</list_cidr>.

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

Tears down and re-inits. L</teardown> is called best effort, a new session is
logged in via L</init>, and then the host object and group membership is
re-created for every retained single IP and CIDR ban.

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

	# both single IPs and CIDR ranges are re-added the same way
	my @to_ban = ( keys( %{ $self->{banned} } ), keys( %{ $self->{banned_cidr} } ) );

	my @re_init_test_data;
	foreach my $item (@to_ban) {
		my @requests = $self->_ban_requests($item);

		if ( $self->{testing} ) {
			push( @re_init_test_data, @requests );
		} else {
			local $@;
			eval {
				foreach my $req (@requests) {
					$self->_request( $req->{method}, $req->{url}, $req->{content} );
				}
				1;
			} or do {
				$self->{error}       = 13;
				$self->{errorString} = 'banning "' . $item . '" failed... ' . $@;
				$self->warn;
			};
		} ## end else [ if ( $self->{testing} ) ]
	} ## end foreach my $item ( keys( %{ ...}))

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@re_init_test_data;
	}

	$self->{inited} = 1;
} ## end sub re_init

=head2 teardown

Tears down the setup by deleting the host object for each currently banned IP
and CIDR range and publishing. The internal list of bans is kept, so a
following re_init will re-add them.

=cut

sub teardown {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{inited} = 0;

	# both single IPs and CIDR ranges have host objects that need removing
	my @to_remove = ( keys( %{ $self->{banned} } ), keys( %{ $self->{banned_cidr} } ) );

	my @requests;
	foreach my $item ( sort(@to_remove) ) {
		if ( $self->{testing} ) {
			push( @requests, $self->_unban_requests($item) );
		} else {
			local $@;
			eval {
				foreach my $req ( $self->_unban_requests($item) ) {
					$self->_request( $req->{method}, $req->{url}, $req->{content} );
				}
				1;
			} or do {
				$self->{error}       = 17;
				$self->{errorString} = 'teardown failed removing "' . $item . '"... ' . $@;
				$self->warn;
			};
		} ## end else [ if ( $self->{testing} ) ]
	} ## end foreach my $item ( sort(@to_remove) )

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

Verifies the session is still usable by POSTing to C<< /web_api/keepalive >>.
Returns a true value if so and a false value otherwise.

=cut

sub check {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	my $url = $self->_base_url . '/web_api/keepalive';

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'POST', url => $url, content => '{}' } ];
		return 1;
	}

	local $@;
	eval { $self->_request( 'POST', $url, '{}' ); 1; } or return 0;

	return 1;
} ## end sub check

=head2 flush

Removes all currently banned IPs and CIDR ranges at once by deleting their
host objects and publishing, then forgetting them.

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

	# both single IPs and CIDR ranges have host objects that need removing
	my @to_remove = ( keys( %{ $self->{banned} } ), keys( %{ $self->{banned_cidr} } ) );

	my @requests;
	foreach my $item ( sort(@to_remove) ) {
		if ( $self->{testing} ) {
			push( @requests, $self->_unban_requests($item) );
		} else {
			local $@;
			eval {
				foreach my $req ( $self->_unban_requests($item) ) {
					$self->_request( $req->{method}, $req->{url}, $req->{content} );
				}
				1;
			} or do {
				$self->{error}       = 25;
				$self->{errorString} = 'flush failed removing "' . $item . '"... ' . $@;
				$self->warn;
			};
		} ## end else [ if ( $self->{testing} ) ]
	} ## end foreach my $item ( sort(@to_remove) )

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

init failed. Logging into the web_api failed.

=head2 24, checkFailed

The backend check raised an error.

=head2 25, flushFailed

Failed to flush the bans.

=head2 26, portsNotSupported

The checkpoint backend blocks whole IPs and does not support ports.

=head2 27, protocolsNotSupported

The checkpoint backend blocks whole IPs and does not support protocols.

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

1;    # End of Net::Firewall::BlockerHelper::backends::checkpoint
