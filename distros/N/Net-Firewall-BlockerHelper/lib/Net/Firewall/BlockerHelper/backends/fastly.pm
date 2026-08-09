package Net::Firewall::BlockerHelper::backends::fastly;

use 5.006;
use strict;
use warnings;
use base         qw( Error::Helper Net::Firewall::BlockerHelper::Util );
use Regexp::IPv4 qw($IPv4_re);
use Regexp::IPv6 qw($IPv6_re);

=head1 NAME

Net::Firewall::BlockerHelper::backends::fastly - Fastly Edge ACL backend for Net::Firewall::BlockerHelper.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 SYNOPSIS

    use Net::Firewall::BlockerHelper;

    my $fw_helper = Net::Firewall::BlockerHelper->new(
        backend => 'fastly',
        name    => 'ssh',
        options => {
            token   => $fastly_api_token,
            service => $fastly_service_id,
            acl     => $fastly_acl_id,
        },
    );

    $fw_helper->init_backend;
    $fw_helper->ban( ban => '1.2.3.4' );
    $fw_helper->unban( ban => '1.2.3.4' );

=head1 DESCRIPTION

Blocks IPs remotely via the Fastly API by adding and removing entries in an
Edge ACL. An ACL entry is created per IP, with a /32 subnet for IPv4 and a
/128 subnet for IPv6. A VCL service that references the ACL and takes action
on matching requests must already exist.

Auth is via a Fastly API token, passed in the C<token> option and sent in the
C<Fastly-Key> header.

Blocking is per IP; ports and protocols are not supported and specifying them
is an error.

L<LWP::UserAgent> is only loaded at run time, so it is only required if this
backend is actually used. For https, L<LWP::Protocol::https> must be present
as well.

=head1 NOTES

This backend was written going off the API docs and actual testing is
needed to double check a few things as the exact behavior is not clear.

teardown currently only removes the single IP entries from the ACL,
leaving CIDR entries in place, while flush removes both. A re_init after
a teardown will re-add the CIDR entries, and how the API handles creating
an entry that already exists needs checking.

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

The options hash accepts the following.

    - token :: Fastly API token, sent in the Fastly-Key header.
        - Default :: undef

    - service :: Fastly service ID the ACL belongs to.
        - Default :: undef

    - acl :: Fastly Edge ACL ID to manage entries under.
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
				30 => 'serviceNotDefined',
				31 => 'tokenNotDefined',
				32 => 'aclNotDefined',
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

	# blocking is per IP; the ACL has no concept of ports or protocols
	if ( defined( $opts{ports} ) && ref( $opts{ports} ) eq 'ARRAY' && defined( $opts{ports}[0] ) ) {
		$self->{perror}      = 1;
		$self->{error}       = 26;
		$self->{errorString} = 'the fastly backend blocks whole IPs and does not support ports';
		$self->warn;
	}
	if ( defined( $opts{protocols} ) && ref( $opts{protocols} ) eq 'ARRAY' && defined( $opts{protocols}[0] ) ) {
		$self->{perror}      = 1;
		$self->{error}       = 27;
		$self->{errorString} = 'the fastly backend blocks whole IPs and does not support protocols';
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

	# required options
	if ( !defined( $self->{options}{token} ) || $self->{options}{token} eq '' ) {
		$self->{perror}      = 1;
		$self->{error}       = 31;
		$self->{errorString} = 'the option token is undef or blank';
		$self->warn;
	}
	if ( !defined( $self->{options}{service} ) || $self->{options}{service} eq '' ) {
		$self->{perror}      = 1;
		$self->{error}       = 30;
		$self->{errorString} = 'the option service is undef or blank';
		$self->warn;
	}
	if ( !defined( $self->{options}{acl} ) || $self->{options}{acl} eq '' ) {
		$self->{perror}      = 1;
		$self->{error}       = 32;
		$self->{errorString} = 'the option acl is undef or blank';
		$self->warn;
	}

	# defaults
	$self->{options}{timeout}  = 30 if ( !defined( $self->{options}{timeout} ) );
	$self->{options}{insecure} = 0  if ( !defined( $self->{options}{insecure} ) );

	return $self;
} ## end sub new

# Internal helper. Returns the URL of the ACL's entries collection.
#
# This is the read side of the API: a GET here answers with every entry in the
# ACL, which is how both unban paths find the entry they need to delete. Note
# it is a different path from the single entry endpoint, 'entries' rather than
# 'entry', which is easy to misread.
#
# The ACL is expected to already exist and be referenced by a service
# configuration; this backend does not create it.
#
# Takes no arguments; the service and ACL ids come from the options.
#
# Returns the URL as a string.
#
#     $self->_entries_url;
#     #   https://api.fastly.com/service/<service>/acl/<acl>/entries
sub _entries_url {
	my ($self) = @_;

	return
		  'https://api.fastly.com/service/'
		. $self->{options}{service}
		. '/acl/'
		. $self->{options}{acl}
		. '/entries';
}

# Internal helper. Returns the URL of the single entry endpoint, either the
# collection it is created through or one specific entry.
#
# The optional id is what makes this serve both halves of the lifecycle. With
# no id it is where a new entry is POSTed; with one it addresses an existing
# entry for deletion. Keeping them in one helper is reasonable because Fastly
# uses the same 'entry' stem for both, unlike the plural 'entries' used for
# reading the whole ACL.
#
# Args:
#
#     id - Optional entry id, as a plain string, from a previous lookup
#          against _entries_url. When omitted or undef the collection URL is
#          returned instead. Appended as is, so it is expected to be an id
#          Fastly issued rather than anything needing encoding.
#
# Returns the URL as a string.
#
#     # for creating an entry
#     $self->_entry_url;
#     #   https://api.fastly.com/service/<service>/acl/<acl>/entry
#
#     # for deleting a specific one
#     $self->_entry_url('7i6HN3TK9wS159v2xAZOSj');
#     #   https://api.fastly.com/service/<service>/acl/<acl>/entry/7i6HN3TK9wS159v2xAZOSj
sub _entry_url {
	my ( $self, $id ) = @_;

	my $url
		= 'https://api.fastly.com/service/'
		. $self->{options}{service}
		. '/acl/'
		. $self->{options}{acl}
		. '/entry';

	if ( defined($id) ) {
		$url .= '/' . $id;
	}

	return $url;
}

# Internal helper. Performs one HTTP request against the Fastly API. Every
# call this backend makes goes through here.
#
# The user agent is built on first use and cached on the object, so a run of
# requests shares one agent. LWP::UserAgent is loaded with require at that
# point rather than at compile time, since only the HTTP backends need it;
# failing to load it dies with an explanation naming this backend.
#
# Authentication is the API token in a Fastly-Key header rather than basic
# auth or a bearer token.
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
#     method - The HTTP method, as a plain string: 'GET' to read the entries,
#              'POST' to create one, 'DELETE' to remove one.
#
#     url    - The full URL to request, as a plain string, from _entries_url
#              or _entry_url.
#
#     body   - Optional request body, as an already encoded JSON string. undef
#              for the reads and deletes.
#
# Returns the decoded response body as whatever structure the JSON held. Note
# that a GET of the entries collection yields an arrayref rather than a
# hashref, which is why the callers check the reference type. undef when the
# body was empty or did not parse. Dies on any non success HTTP status.
#
#     my $decoded = $self->_request( 'GET', $self->_entries_url );
#
#     # the usual shape at the call sites
#     eval { $self->_request( 'POST', $self->_entry_url, $body ); };
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
		} or die( 'failed to load LWP::UserAgent, which the fastly backend requires... ' . $@ );
	}

	my @headers = ( 'Content-Type' => 'application/json', 'Fastly-Key' => $self->{options}{token} );

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

Initiates the backend. Verifies the credentials and endpoint by fetching a
single ACL entry.

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

	my $url = $self->_entries_url . '?per_page=1';

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'GET', url => $url } ];
	} else {
		local $@;
		eval { $self->_request( 'GET', $url ); 1; } or do {
			$self->{error}       = 23;
			$self->{errorString} = 'init failed. probing the ACL entries endpoint failed... ' . $@;
			$self->warn;
		};
	}

	$self->{inited} = 1;
} ## end sub init

=head2 ban

Bans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then an ACL entry is created for it via a POST, with a /32
subnet for IPv4 and a /128 subnet for IPv6. Banning an already banned IP is
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

	my $subnet = ( $opts{ban} =~ /\A$IPv4_re\z/ ) ? 32 : 128;
	my $body = $self->_json->encode( { ip => $opts{ban}, subnet => $subnet } );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'POST', url => $self->_entry_url, content => $body } ];
	} else {
		local $@;
		eval { $self->_request( 'POST', $self->_entry_url, $body ); 1; } or do {
			$self->{error}       = 13;
			$self->{errorString} = 'banning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	}

	$self->{banned}{ $opts{ban} } = 1;
} ## end sub ban

# Internal helper. Performs the full two step unban of one address: find its
# ACL entry, then delete it by id.
#
# Fastly entries are addressed by an opaque id rather than by their contents,
# so the id has to be found before anything can be deleted. Unlike the
# cloudflare and routeros_api backends there is no server side filter for
# this: the whole entries collection is fetched and walked locally looking for
# a matching ip field. That means the cost of an unban grows with the size of
# the ACL rather than staying constant.
#
# Matching is on the ip field alone, since a single address entry carries no
# subnet. The search stops at the first match.
#
# An entry that is not found is treated as success rather than as an error.
# The entry having already gone means the address is not banned, which is what
# the caller wanted; erroring would make an unban fail for having already
# achieved its goal.
#
# Never called in testing mode; that path records the request instead.
#
# Args:
#
#     ip - The address to unban, as a plain string. Expected to be an already
#          validated and lowercased IPv4 or IPv6 address, matched exactly
#          against the stored entry, so it must be spelled the same way it was
#          when banned.
#
# Returns nothing. Dies if either request fails, which the caller catches and
# turns into unbanFailed.
#
#     $self->_unban_ip('10.0.0.1');
#
#     # the usual shape at the call site
#     eval { $self->_unban_ip( $opts{ban} ); };
#     if ($@) { ... raise unbanFailed ... }
sub _unban_ip {
	my ( $self, $ip ) = @_;

	my $decoded = $self->_request( 'GET', $self->_entries_url );

	my $id;
	if ( ref($decoded) eq 'ARRAY' ) {
		foreach my $entry ( @{$decoded} ) {
			if ( ref($entry) eq 'HASH' && defined( $entry->{ip} ) && $entry->{ip} eq $ip ) {
				$id = $entry->{id};
				last;
			}
		}
	}

	# no entry found means something else removed it already, which is fine
	if ( !defined($id) ) {
		return;
	}

	$self->_request( 'DELETE', $self->_entry_url($id) );

	return;
} ## end sub _unban_ip

=head2 unban

Unbans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then the ACL entries are fetched, the entry for the IP is
found, and it is deleted by its ID. An entry that can not be found is
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
			{ method => 'GET',    url => $self->_entries_url },
			{ method => 'DELETE', url => $self->_entry_url('<id>') },
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

=head2 ban_cidr

Bans a CIDR range by creating an ACL entry for it. The range is split into its
address and prefix length, sent as the ACL entry's ip and subnet, mirroring how
a single IP is banned as a /32 or /128 entry. The value of ban is validated
as being a IPv4 or IPv6 CIDR range and lowercased. Banning an already
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

	my ( $cidr_ip, $cidr_subnet ) = split( m!/!, $opts{ban}, 2 );
	# numify the prefix length so it is encoded as a JSON number, matching how
	# ban() sends the /32 or /128 subnet
	$cidr_subnet += 0;
	my $body = $self->_json->encode( { ip => $cidr_ip, subnet => $cidr_subnet } );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'POST', url => $self->_entry_url, content => $body } ];
	} else {
		local $@;
		eval { $self->_request( 'POST', $self->_entry_url, $body ); 1; } or do {
			$self->{error}       = 33;
			$self->{errorString} = 'banning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	}

	$self->{banned_cidr}{ $opts{ban} } = 1;
} ## end sub ban_cidr

# Internal helper. Performs the full two step unban of one CIDR range, the
# range counterpart of _unban_ip.
#
# The shape is the same, fetch the entries collection and walk it for a match,
# and a missing entry is treated as success for the same reason.
#
# The difference is what a match means. Fastly stores a range as two separate
# fields, the network address in ip and the prefix length in subnet, so the
# range is split at the slash and both halves must match. Comparing against
# the ip field alone would match the single address entry for the same network
# address, and deleting that would unban the wrong thing.
#
# Never called in testing mode; that path records the request instead.
#
# Args:
#
#     cidr - The range to unban, as a plain string. Expected to be an already
#            validated and lowercased CIDR range such as "10.0.0.0/8". Split
#            on the first slash, so the address goes to ip and everything
#            after to subnet. Both halves are compared as strings, so the
#            spelling must match what was stored at ban time.
#
# Returns nothing. Dies if either request fails, which the caller catches and
# turns into unbanCidrFailed.
#
#     $self->_unban_cidr_range('10.0.0.0/8');
#     #   looks for an entry with ip '10.0.0.0' and subnet '8'
sub _unban_cidr_range {
	my ( $self, $cidr ) = @_;

	my ( $cidr_ip, $cidr_subnet ) = split( m!/!, $cidr, 2 );

	my $decoded = $self->_request( 'GET', $self->_entries_url );

	my $id;
	if ( ref($decoded) eq 'ARRAY' ) {
		foreach my $entry ( @{$decoded} ) {
			if (   ref($entry) eq 'HASH'
				&& defined( $entry->{ip} )
				&& $entry->{ip} eq $cidr_ip
				&& defined( $entry->{subnet} )
				&& $entry->{subnet} eq $cidr_subnet )
			{
				$id = $entry->{id};
				last;
			}
		}
	}

	# no entry found means something else removed it already, which is fine
	if ( !defined($id) ) {
		return;
	}

	$self->_request( 'DELETE', $self->_entry_url($id) );

	return;
} ## end sub _unban_cidr_range

=head2 unban_cidr

Unbans a CIDR range. The value of ban is validated as being a IPv4 or IPv6
CIDR range and lowercased, then the ACL entries are fetched, the entry
matching its address and prefix length is found, and it is deleted by its
ID. An entry that can not be found is treated as already unbanned.
Unbanning a range that is not banned is a noop.

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

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [
			{ method => 'GET',    url => $self->_entries_url },
			{ method => 'DELETE', url => $self->_entry_url('<id>') },
		];
	} else {
		local $@;
		eval { $self->_unban_cidr_range( $opts{ban} ); 1; } or do {
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

=head2 re_init

Tells the backend to re-init it's self.

This will call teardown and init again. After that it will re-add all
previously added bans, POSTing an ACL entry for each retained IP and CIDR
range.

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

	my @re_init_test_data;
	foreach my $item ( keys( %{ $self->{banned} } ) ) {
		my $subnet = ( $item =~ /\A$IPv4_re\z/ ) ? 32 : 128;
		my $body   = $self->_json->encode( { ip => $item, subnet => $subnet } );

		if ( $self->{testing} ) {
			push( @re_init_test_data, { method => 'POST', url => $self->_entry_url, content => $body } );
		} else {
			local $@;
			eval { $self->_request( 'POST', $self->_entry_url, $body ); 1; } or do {
				$self->{error}       = 13;
				$self->{errorString} = 'banning "' . $item . '" failed... ' . $@;
				$self->warn;
			};
		}
	} ## end foreach my $item ( keys( %{ ...}))

	# re-add the CIDR ranges as well, splitting each into its ip and subnet the
	# same way ban_cidr does
	foreach my $item ( keys( %{ $self->{banned_cidr} } ) ) {
		my ( $cidr_ip, $cidr_subnet ) = split( m!/!, $item, 2 );
		$cidr_subnet += 0;
		my $body = $self->_json->encode( { ip => $cidr_ip, subnet => $cidr_subnet } );

		if ( $self->{testing} ) {
			push( @re_init_test_data, { method => 'POST', url => $self->_entry_url, content => $body } );
		} else {
			local $@;
			eval { $self->_request( 'POST', $self->_entry_url, $body ); 1; } or do {
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

Tears down the setup for the backend by removing the ACL entry for each
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
				{ method => 'GET',    url => $self->_entries_url },
				{ method => 'DELETE', url => $self->_entry_url('<id>') }
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

Alias for L</teardown>, provided for parity with the fail2ban C<actionstop>
concept.

    $backend->stop;

=cut

sub stop {
	my ( $self, %opts ) = @_;

	return $self->teardown(%opts);
}

=head2 check

Verifies the endpoint and credentials are still usable by fetching a single
ACL entry. Returns a true value if so and a false value otherwise. This is the
equivalent of fail2ban's C<actioncheck>.

    if ( !$backend->check ) {
        $backend->re_init;
    }

=cut

sub check {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	my $url = $self->_entries_url . '?per_page=1';

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'GET', url => $url } ];
		return 1;
	}

	local $@;
	eval { $self->_request( 'GET', $url ); 1; } or return 0;

	return 1;
} ## end sub check

=head2 flush

Removes all currently banned IPs at once by removing their ACL entries and
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
		if ( $self->{testing} ) {
			push(
				@requests,
				{ method => 'GET',    url => $self->_entries_url },
				{ method => 'DELETE', url => $self->_entry_url('<id>') }
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

	# remove the CIDR entries the same way
	foreach my $item ( sort( keys( %{ $self->{banned_cidr} } ) ) ) {
		if ( $self->{testing} ) {
			push(
				@requests,
				{ method => 'GET',    url => $self->_entries_url },
				{ method => 'DELETE', url => $self->_entry_url('<id>') }
			);
		} else {
			local $@;
			eval { $self->_unban_cidr_range($item); 1; } or do {
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

Init failed. Probing the ACL entries endpoint failed.

=head2 24, checkFailed

The backend check raised an error.

=head2 25, flushFailed

Failed to flush the bans.

=head2 26, portsNotSupported

The fastly backend blocks whole IPs and does not support ports.

=head2 27, protocolsNotSupported

The fastly backend blocks whole IPs and does not support protocols.

=head2 30, serviceNotDefined

The option service is undef or blank.

=head2 31, tokenNotDefined

The option token is undef or blank.

=head2 32, aclNotDefined

The option acl is undef or blank.

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
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Firewall-BlockerHelper>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999


=cut

1;    # End of Net::Firewall::BlockerHelper
