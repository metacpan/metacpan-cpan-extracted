package Net::Firewall::BlockerHelper::backends::juniper_srx;

use 5.006;
use strict;
use warnings;
use base         qw( Error::Helper Net::Firewall::BlockerHelper::Util );
use Regexp::IPv4 qw($IPv4_re);
use Regexp::IPv6 qw($IPv6_re);

=head1 NAME

Net::Firewall::BlockerHelper::backends::juniper_srx - Juniper SRX backend via the Junos REST API.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 SYNOPSIS

    use Net::Firewall::BlockerHelper;

    my $fw_helper = Net::Firewall::BlockerHelper->new(
        backend => 'juniper_srx',
        name    => 'ssh',
        options => {
            host        => 'srx.example.org',
            user        => 'blocker',
            password    => $password,
            address_set => 'blocklist',
        },
    );

    $fw_helper->init_backend;
    $fw_helper->ban( ban => '1.2.3.4' );
    $fw_helper->unban( ban => '1.2.3.4' );

=head1 DESCRIPTION

Blocks IPs on a Juniper SRX by managing entries in a global address book and a
global address-set through the Junos REST API (the C</rpc> endpoint, which
takes XML RPCs). A security policy referencing the address-set must already
exist on the device.

For each banned IP an address book entry is created and added to the
configured address-set. Changes are applied by loading the configuration in
set format and then committing it, both as POSTs to C<< https://<host>/rpc >>.

Auth is via HTTP basic auth (the C<user> and C<password> options).

Blocking is per IP; ports and protocols belong on the referencing policy, so
specifying them here is an error.

L<LWP::UserAgent> is loaded at run time, so it is only required when this
backend is actually used. For https, L<LWP::Protocol::https> must be present as
well.

=head1 METHODS

=head2 new

    - options :: Backend specific options. See below.
    - prefix :: Prefix to use. Must match /^[a-zA-Z0-9]+$/. Default kur.
    - name :: Name of this instance. Required.

Ports and protocols are not supported and specifying either is an error.

The options hash accepts the following.

    - host :: SRX host, optionally host:port. Required.
        - Default :: undef

    - user :: REST API user for basic auth. Required.
        - Default :: undef

    - password :: REST API password for basic auth. Required.
        - Default :: undef

    - address_set :: Name of the global address-set a security policy
            references and that banned IPs are added to.
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

	# blocking is per IP; ports/protocols belong on the referencing policy
	if ( defined( $opts{ports} ) && ref( $opts{ports} ) eq 'ARRAY' && defined( $opts{ports}[0] ) ) {
		$self->{perror}      = 1;
		$self->{error}       = 26;
		$self->{errorString} = 'the juniper_srx backend blocks whole IPs and does not support ports';
		$self->warn;
	}
	if ( defined( $opts{protocols} ) && ref( $opts{protocols} ) eq 'ARRAY' && defined( $opts{protocols}[0] ) ) {
		$self->{perror}      = 1;
		$self->{error}       = 27;
		$self->{errorString} = 'the juniper_srx backend blocks whole IPs and does not support protocols';
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
	$self->{options}{insecure} = 0  if ( !defined( $self->{options}{insecure} ) );
	$self->{options}{timeout}  = 30 if ( !defined( $self->{options}{timeout} ) );
	if ( defined( $self->{name} ) && !defined( $self->{options}{address_set} ) ) {
		$self->{options}{address_set} = $self->{prefix} . '_' . $self->{name};
	}

	return $self;
} ## end sub new

# Internal helper. Returns the Junos REST API endpoint every request is posted
# to.
#
# There is only one URL. Unlike the REST APIs that expose a resource tree,
# Junos takes an RPC: what to do is carried entirely in the XML body posted
# here, not in the path. That is why this takes no arguments and why nothing
# in this backend ever builds a URL per operation.
#
# The scheme is fixed at https rather than configurable, since the Junos REST
# service is expected to be run over TLS.
#
# Takes no arguments; the host comes from the options.
#
# Returns the endpoint as a string.
#
#     $self->_url;    # https://srx.example.org/rpc
sub _url {
	my ($self) = @_;

	return 'https://' . $self->{options}{host} . '/rpc';
}

# Internal helper. Returns the name of the Junos address book object
# representing one banned address or range.
#
# Junos has no set type that simply holds addresses. Each ban becomes a named
# address object in the global address book, which is then added to an
# address-set that a security policy references. So every ban needs a name.
#
# The name is derived from the prefix, the instance name, and the target
# rather than stored, so ban and unban independently arrive at the same name
# without local bookkeeping, and two instances on the same SRX do not collide.
# Dots, colons, and slashes are replaced with hyphens because none of them are
# valid in a Junos identifier.
#
# Unlike the fortigate backend, one sub serves both single addresses and
# ranges, since the mangling already covers the slash a range carries.
#
# Args:
#
#     ip - The address or CIDR range to name an object for, as a plain string.
#          Expected to be already validated and lowercased. Both
#          "10.0.0.1" and "10.0.0.0/8" are fine.
#
# Returns the object name as a plain string, valid as a Junos identifier.
#
#     # with prefix "kur" and name "ssh"
#     $self->_obj_name('10.0.0.1');       # kur_ssh_10-0-0-1
#     $self->_obj_name('2001:db8::1');    # kur_ssh_2001-db8--1
#     $self->_obj_name('10.0.0.0/8');     # kur_ssh_10-0-0-0-8
sub _obj_name {
	my ( $self, $ip ) = @_;

	my $obj = $self->{prefix} . '_' . $self->{name} . '_' . $ip;
	$obj =~ s/[.:\/]/-/g;

	return $obj;
}

# Internal helper. Wraps a batch of Junos set commands into the
# load-configuration RPC that applies them.
#
# Junos configuration changes go in as an RPC rather than as REST calls
# against a resource tree. Using set/text format means the payload is the same
# set commands an operator would type at the CLI, which is far easier to
# generate and to read back in test_data than the equivalent XML
# configuration tree would be.
#
# The lines are newline joined into one configuration-set element, so a batch
# loads as a single change. That matters for the ban path, which creates the
# address object and adds it to the address-set together.
#
# Note this only loads the change into the candidate configuration. Nothing
# takes effect until a separate commit, which is what _commit_body is for.
#
# Args:
#
#     setlines - An arrayref of Junos set command lines, as plain strings with
#                no trailing newline, such as those from _ban_setlines. May
#                hold a single line. Emitted in the order given.
#
# Returns the RPC as an XML string, ready to be the body of a post to _url.
#
#     $self->_load_body( $self->_ban_setlines('10.0.0.1') );
#     #   <load-configuration action="set" format="text"><configuration-set>set security address-book global address kur_ssh_10-0-0-1 10.0.0.1/32
#     #   set security address-book global address-set blocklist address kur_ssh_10-0-0-1</configuration-set></load-configuration>
sub _load_body {
	my ( $self, $setlines ) = @_;

	return
		  '<load-configuration action="set" format="text"><configuration-set>'
		. join( "\n", @{$setlines} )
		. '</configuration-set></load-configuration>';
}

# Internal helper. Returns the RPC that commits the candidate configuration.
#
# Junos is a two phase configuration system: a load only stages changes into
# the candidate configuration, and nothing takes effect until it is committed.
# Every path that loads something therefore posts this immediately afterwards;
# skipping it would leave the ban staged and inert, and would also leave the
# candidate dirty for whoever logs in next.
#
# It is a bare RPC with no arguments and no options, so it is a constant
# rather than something built.
#
# Takes no arguments.
#
# Returns the RPC as an XML string, ready to be the body of a post to _url.
#
#     $self->_commit_body;    # <commit-configuration/>
#
#     # the usual shape: load then commit
#     $self->_request( $self->_load_body($setlines) );
#     $self->_request( $self->_commit_body );
sub _commit_body {
	my ($self) = @_;

	return '<commit-configuration/>';
}

# Internal helper. Returns the Junos set commands that ban one address.
#
# Two lines are needed, and they belong together: the address book object has
# to be created before it can be referenced by the address-set. Both go into a
# single load, so the change is applied as one unit.
#
# The address is written with an explicit host prefix, /32 or /128 by family,
# because a Junos address book entry is always a prefix; there is no bare host
# form.
#
# Args:
#
#     ip - The address to ban, as a plain string. Expected to be an already
#          validated and lowercased IPv4 or IPv6 address. The family is
#          decided by matching against $IPv4_re and only selects the mask.
#
# Returns an arrayref of set command lines, in the order they must be applied,
# ready to hand to _load_body.
#
#     $self->_ban_setlines('10.0.0.1');
#     #   [
#     #     'set security address-book global address kur_ssh_10-0-0-1 10.0.0.1/32',
#     #     'set security address-book global address-set blocklist address kur_ssh_10-0-0-1',
#     #   ]
#
#     $self->_ban_setlines('2001:db8::1');
#     #   [
#     #     'set security address-book global address kur_ssh_2001-db8--1 2001:db8::1/128',
#     #     'set security address-book global address-set blocklist address kur_ssh_2001-db8--1',
#     #   ]
sub _ban_setlines {
	my ( $self, $ip ) = @_;

	my $obj  = $self->_obj_name($ip);
	my $mask = ( $ip =~ /\A$IPv4_re\z/ ) ? '32' : '128';

	return [
		'set security address-book global address ' . $obj . ' ' . $ip . '/' . $mask,
		'set security address-book global address-set ' . $self->{options}{address_set} . ' address ' . $obj,
	];
} ## end sub _ban_setlines

# Internal helper. Returns the Junos set commands that unban one address.
#
# Only one line is needed, unlike the two the ban takes. Deleting an address
# book object also removes it from any address-set referencing it, so an
# explicit membership removal would be redundant. This is the opposite of the
# fortigate backend, where the membership has to be dropped first.
#
# Args:
#
#     ip - The address to unban, as a plain string. Expected to be an already
#          validated and lowercased IPv4 or IPv6 address, and to produce the
#          same object name it did when banned. Note the family is not
#          consulted at all here, since the object name is all that is needed.
#
# Returns an arrayref holding the single delete command, ready to hand to
# _load_body.
#
#     $self->_unban_setlines('10.0.0.1');
#     #   [ 'delete security address-book global address kur_ssh_10-0-0-1' ]
sub _unban_setlines {
	my ( $self, $ip ) = @_;

	return [ 'delete security address-book global address ' . $self->_obj_name($ip) ];
}

# Internal helper. Posts one XML RPC to the Junos REST API. Every call this
# backend makes to the appliance goes through here.
#
# Because Junos takes an RPC rather than exposing a resource tree, this needs
# no method or URL argument: it is always a POST to the one endpoint, and what
# happens is decided entirely by the body.
#
# The user agent is built on first use and cached on the object, so a run of
# requests shares one agent rather than building a new one each time.
# LWP::UserAgent is loaded with require at that point rather than at compile
# time, since only the HTTP backends need it; failing to load it dies with an
# explanation naming this backend. The insecure option turns off certificate
# verification, which is there because an SRX commonly presents a self signed
# certificate.
#
# Authentication is HTTP basic, encoded per request. MIME::Base64 is required
# at call time for the same reason LWP is. Note the second argument to
# encode_base64 is an empty string, which suppresses the line wrapping it
# would otherwise insert and which would corrupt the header.
#
# Any HTTP level failure dies rather than setting an error. The callers wrap
# this in eval and turn the exception into the appropriate error code, which
# is what lets one helper serve paths that report ban, unban, and teardown
# failures differently.
#
# Never called in testing mode; those paths record the bodies instead.
#
# Args:
#
#     body - The complete XML RPC to post, as a plain string, normally from
#            _load_body or _commit_body.
#
# Returns the raw response body as a string. Note it is not parsed, unlike the
# JSON backends: callers that care inspect the XML themselves.
#
#     # load a change, then commit it
#     $self->_request( $self->_load_body( $self->_ban_setlines($ip) ) );
#     $self->_request( $self->_commit_body );
#
#     # the usual shape at the call sites
#     eval { $self->_request( $self->_commit_body ); };
#     if ($@) { ... raise banFailed ... }
sub _request {
	my ( $self, $body ) = @_;

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
		} or die( 'failed to load LWP::UserAgent, which the juniper_srx backend requires... ' . $@ );
	}

	require MIME::Base64;
	my $auth = 'Basic '
		. MIME::Base64::encode_base64( $self->{options}{user} . ':' . $self->{options}{password}, '' );

	my @headers = ( 'Content-Type' => 'application/xml', 'Authorization' => $auth );

	require HTTP::Request;
	my $request = HTTP::Request->new( 'POST', $self->_url, \@headers, $body );

	my $response = $self->{ua}->request($request);

	if ( !$response->is_success ) {
		my $detail = $response->decoded_content;
		$detail = defined($detail) ? ( ' body... ' . $detail ) : '';
		die( 'POST ' . $self->_url . ' failed... HTTP status... ' . $response->status_line . $detail );
	}

	return $response->decoded_content;
} ## end sub _request

=head2 init

Initiates the backend. Verifies the credentials and connectivity with a
get-software-information RPC.

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
		$self->{frontend_obj}->{test_data}
			= [ { method => 'POST', url => $self->_url, content => '<get-software-information/>' } ];
	} else {
		local $@;
		eval { $self->_request('<get-software-information/>'); 1; } or do {
			$self->{error}       = 23;
			$self->{errorString} = 'init failed. probing the API failed... ' . $@;
			$self->warn;
		};
	}

	$self->{inited} = 1;
} ## end sub init

=head2 ban

Bans an IP. The value of ban is validated as being a IPv4 or IPv6 address and
lowercased. A global address book entry named C<< <prefix>_<name>_<ip> >>
(dots and colons replaced with '-') is created with a /32 or /128 mask as
appropriate and added to the configured address-set, via a load-configuration
RPC in set format followed by a commit-configuration RPC, both POSTed to the
REST API. Banning an already banned IP is a noop.

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

	my $setlines = $self->_ban_setlines( $opts{ban} );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [
			{ method => 'POST', url => $self->_url, content => $self->_load_body($setlines) },
			{ method => 'POST', url => $self->_url, content => $self->_commit_body },
		];
	} else {
		local $@;
		eval {
			$self->_request( $self->_load_body($setlines) );
			$self->_request( $self->_commit_body );
			1;
		} or do {
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
and lowercased. The IP's address book object is deleted via a
load-configuration RPC followed by a commit-configuration RPC; deleting the
address also removes it from the address-set. Unbanning an IP that is not
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

	my $setlines = $self->_unban_setlines( $opts{ban} );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [
			{ method => 'POST', url => $self->_url, content => $self->_load_body($setlines) },
			{ method => 'POST', url => $self->_url, content => $self->_commit_body },
		];
	} else {
		local $@;
		eval {
			$self->_request( $self->_load_body($setlines) );
			$self->_request( $self->_commit_body );
			1;
		} or do {
			$self->{error}       = 14;
			$self->{errorString} = 'unbanning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	}

	delete( $self->{banned}{ $opts{ban} } );
} ## end sub unban

# Internal helper. Returns the Junos set commands that ban one CIDR range, the
# range counterpart of _ban_setlines.
#
# The two line shape and its ordering are the same: the address book object
# has to exist before the address-set can reference it.
#
# The one difference is that no mask is appended. A range already carries its
# own prefix length, which is exactly what a Junos address book entry holds,
# so it goes in as it stands rather than being given a host /32 or /128.
#
# There is no matching _unban_cidr_setlines, because _unban_setlines already
# covers ranges: it only needs the object name, and _obj_name handles ranges
# as well as addresses.
#
# Args:
#
#     cidr - The range to ban, as a plain string. Expected to be an already
#            validated and lowercased CIDR range such as "10.0.0.0/8" or
#            "2001:db8::/32".
#
# Returns an arrayref of set command lines, in the order they must be applied,
# ready to hand to _load_body.
#
#     $self->_ban_cidr_setlines('10.0.0.0/8');
#     #   [
#     #     'set security address-book global address kur_ssh_10-0-0-0-8 10.0.0.0/8',
#     #     'set security address-book global address-set blocklist address kur_ssh_10-0-0-0-8',
#     #   ]
sub _ban_cidr_setlines {
	my ( $self, $cidr ) = @_;

	my $obj = $self->_obj_name($cidr);

	return [
		'set security address-book global address ' . $obj . ' ' . $cidr,
		'set security address-book global address-set ' . $self->{options}{address_set} . ' address ' . $obj,
	];
} ## end sub _ban_cidr_setlines

=head2 ban_cidr

Bans a CIDR range. The value of ban is validated as being a IPv4 or IPv6 CIDR
and lowercased. An address book object is created the same way as for a single
IP, but with the CIDR used verbatim as the address prefix, and is added to the
address-set, then the change is committed. Banning an already banned CIDR
range is a noop.

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

	my $setlines = $self->_ban_cidr_setlines( $opts{ban} );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [
			{ method => 'POST', url => $self->_url, content => $self->_load_body($setlines) },
			{ method => 'POST', url => $self->_url, content => $self->_commit_body },
		];
	} else {
		local $@;
		eval {
			$self->_request( $self->_load_body($setlines) );
			$self->_request( $self->_commit_body );
			1;
		} or do {
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
CIDR and lowercased. The range's address book object is deleted, then the
change is committed; deleting the address also removes it from the
address-set. Unbanning a CIDR range that is not banned is a noop.

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

	my $setlines = $self->_unban_setlines( $opts{ban} );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [
			{ method => 'POST', url => $self->_url, content => $self->_load_body($setlines) },
			{ method => 'POST', url => $self->_url, content => $self->_commit_body },
		];
	} else {
		local $@;
		eval {
			$self->_request( $self->_load_body($setlines) );
			$self->_request( $self->_commit_body );
			1;
		} or do {
			$self->{error}       = 34;
			$self->{errorString} = 'unbanning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	}

	delete( $self->{banned_cidr}{ $opts{ban} } );
} ## end sub unban_cidr

=head2 list_cidr

List banned CIDR ranges. Returns an array of the currently banned CIDR ranges
from internal state; the device is not queried. Single IPs are not included;
for those see L</list>.

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
internal state; the device is not queried. CIDR ranges are not included; for
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

Tears down and re-inits, then re-adds all previously added bans. Teardown is
best effort, as a partially or fully wiped setup is what re_init recovers
from. Each retained IP and CIDR range is then re-added via its own
load-configuration and commit-configuration RPC pair.

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

	my @re_init_test_data;
	foreach my $item ( keys( %{ $self->{banned} } ) ) {
		my $setlines = $self->_ban_setlines($item);

		if ( $self->{testing} ) {
			push(
				@re_init_test_data,
				{ method => 'POST', url => $self->_url, content => $self->_load_body($setlines) },
				{ method => 'POST', url => $self->_url, content => $self->_commit_body },
			);
		} else {
			local $@;
			eval {
				$self->_request( $self->_load_body($setlines) );
				$self->_request( $self->_commit_body );
				1;
			} or do {
				$self->{error}       = 13;
				$self->{errorString} = 'banning "' . $item . '" failed... ' . $@;
				$self->warn;
			};
		}
	} ## end foreach my $item ( keys( %{ ...}))

	# CIDR ranges carry their own prefix, so they use the CIDR set lines
	foreach my $item ( keys( %{ $self->{banned_cidr} } ) ) {
		my $setlines = $self->_ban_cidr_setlines($item);

		if ( $self->{testing} ) {
			push(
				@re_init_test_data,
				{ method => 'POST', url => $self->_url, content => $self->_load_body($setlines) },
				{ method => 'POST', url => $self->_url, content => $self->_commit_body },
			);
		} else {
			local $@;
			eval {
				$self->_request( $self->_load_body($setlines) );
				$self->_request( $self->_commit_body );
				1;
			} or do {
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

Tears down the setup by deleting the address book object of each currently
banned IP and CIDR range, committing after each deletion. The internal list of
bans is kept, so a following re_init will re-add them.

=cut

sub teardown {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{inited} = 0;

	my @requests;
	foreach my $item ( sort( keys( %{ $self->{banned} } ), keys( %{ $self->{banned_cidr} } ) ) ) {
		my $setlines = $self->_unban_setlines($item);
		if ( $self->{testing} ) {
			push(
				@requests,
				{ method => 'POST', url => $self->_url, content => $self->_load_body($setlines) },
				{ method => 'POST', url => $self->_url, content => $self->_commit_body },
			);
		} else {
			local $@;
			eval {
				$self->_request( $self->_load_body($setlines) );
				$self->_request( $self->_commit_body );
				1;
			} or do {
				$self->{error}       = 17;
				$self->{errorString} = 'teardown failed removing "' . $item . '"... ' . $@;
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

Verifies the credentials and connectivity are still usable with a
get-software-information RPC. Returns a true value if so and a false value
otherwise.

=cut

sub check {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data}
			= [ { method => 'POST', url => $self->_url, content => '<get-software-information/>' } ];
		return 1;
	}

	local $@;
	eval { $self->_request('<get-software-information/>'); 1; } or return 0;

	return 1;
} ## end sub check

=head2 flush

Removes all currently banned IPs and CIDR ranges at once by deleting their
address book objects, committing after each deletion, and clearing the
internal ban lists.

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
	foreach my $item ( sort( keys( %{ $self->{banned} } ), keys( %{ $self->{banned_cidr} } ) ) ) {
		my $setlines = $self->_unban_setlines($item);
		if ( $self->{testing} ) {
			push(
				@requests,
				{ method => 'POST', url => $self->_url, content => $self->_load_body($setlines) },
				{ method => 'POST', url => $self->_url, content => $self->_commit_body },
			);
		} else {
			local $@;
			eval {
				$self->_request( $self->_load_body($setlines) );
				$self->_request( $self->_commit_body );
				1;
			} or do {
				$self->{error}       = 25;
				$self->{errorString} = 'flush failed removing "' . $item . '"... ' . $@;
				$self->warn;
			};
		}
	} ## end foreach my $item ( sort( keys( %{ $self->{banned...})))

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

Probing the API during init failed.

=head2 24, checkFailed

The backend check raised an error.

=head2 25, flushFailed

Failed to flush the bans.

=head2 26, portsNotSupported

The juniper_srx backend blocks whole IPs and does not support ports.

=head2 27, protocolsNotSupported

The juniper_srx backend blocks whole IPs and does not support protocols.

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

1;    # End of Net::Firewall::BlockerHelper::backends::juniper_srx
