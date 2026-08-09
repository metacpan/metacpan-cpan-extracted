package Net::Firewall::BlockerHelper::backends::fortigate;

use 5.006;
use strict;
use warnings;
use base         qw( Error::Helper Net::Firewall::BlockerHelper::Util );
use Regexp::IPv4 qw($IPv4_re);
use Regexp::IPv6 qw($IPv6_re);

=head1 NAME

Net::Firewall::BlockerHelper::backends::fortigate - Fortinet FortiGate backend via the REST API.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 SYNOPSIS

    use Net::Firewall::BlockerHelper;

    my $fw_helper = Net::Firewall::BlockerHelper->new(
        backend => 'fortigate',
        name    => 'ssh',
        options => {
            host   => 'fw.example.org',
            token  => $fortigate_api_token,
            group4 => 'blocklist',
            group6 => 'blocklist6',
        },
    );

    $fw_helper->init_backend;
    $fw_helper->ban( ban => '1.2.3.4' );
    $fw_helper->unban( ban => '1.2.3.4' );

=head1 DESCRIPTION

Blocks IPs on a Fortinet FortiGate via the FortiOS REST API. For each banned
IP a firewall address object is created and added as a member of a firewall
address group; a firewall policy referencing that group then drops the
traffic. IPv4 addresses use C<firewall/address> and C<firewall/addrgrp>, IPv6
use C<firewall/address6> and C<firewall/addrgrp6>.

This backend manages the address objects and their group membership. The
address group(s) and the policy referencing them must already exist on the
FortiGate.

Auth is via a REST API token (the C<token> option), sent as a bearer token.
An optional C<vdom> scopes the calls to a virtual domain.

Blocking is per IP; ports and protocols belong on the referencing policy, so
specifying them here is an error.

L<LWP::UserAgent> is loaded at run time, so it is only required when this
backend is actually used. For https, L<LWP::Protocol::https> must be present
as well.

=head1 METHODS

=head2 new

Initiates the object. Takes the following.

    - options :: Backend specific options. See below.
    - prefix :: Prefix to use. Must match /^[a-zA-Z0-9]+$/. Default kur.
    - name :: Name of this instance. Required.

Ports and protocols are not supported and specifying either is an error.

The options hash accepts the following.

    - host :: FortiGate host, optionally host:port. Required.
        - Default :: undef

    - token :: REST API token, sent as a bearer token. Required.
        - Default :: undef

    - group4 :: IPv4 firewall address group the banned addresses are added to.
        - Default :: <prefix>_<name>

    - group6 :: IPv6 firewall address group the banned addresses are added to.
        - Default :: <prefix>_<name>

    - vdom :: Optional virtual domain to scope the calls to.
        - Default :: undef

    - scheme :: 'https' or 'http'.
        - Default :: https

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
				31 => 'tokenNotDefined',
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
		$self->{errorString} = 'the fortigate backend blocks whole IPs and does not support ports';
		$self->warn;
	}
	if ( defined( $opts{protocols} ) && ref( $opts{protocols} ) eq 'ARRAY' && defined( $opts{protocols}[0] ) ) {
		$self->{perror}      = 1;
		$self->{error}       = 27;
		$self->{errorString} = 'the fortigate backend blocks whole IPs and does not support protocols';
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
	if ( !defined( $self->{options}{token} ) || $self->{options}{token} eq '' ) {
		$self->{perror}      = 1;
		$self->{error}       = 31;
		$self->{errorString} = 'the option token is undef or blank';
		$self->warn;
	}

	# defaults
	$self->{options}{scheme}   = 'https' if ( !defined( $self->{options}{scheme} ) );
	$self->{options}{insecure} = 0       if ( !defined( $self->{options}{insecure} ) );
	$self->{options}{timeout}  = 30      if ( !defined( $self->{options}{timeout} ) );
	if ( defined( $self->{name} ) ) {
		$self->{options}{group4} = $self->{prefix} . '_' . $self->{name} if ( !defined( $self->{options}{group4} ) );
		$self->{options}{group6} = $self->{prefix} . '_' . $self->{name} if ( !defined( $self->{options}{group6} ) );
	}

	return $self;
} ## end sub new

# Internal helper. Says whether an address is IPv4, which is the branch nearly
# every other helper in this backend turns on.
#
# FortiOS keeps IPv4 and IPv6 in entirely separate parts of its configuration
# tree, with different object menus and different body fields, so almost
# nothing here can be written family agnostically. Rather than repeat the
# match, it lives in one place.
#
# Args:
#
#     ip - The address to test, as a plain string. Expected to be an already
#          validated and lowercased IPv4 or IPv6 address. Matched against
#          $IPv4_re anchored, so anything that is not valid IPv4, including a
#          CIDR range, comes back false. Ranges have their own _cidr_is_v4.
#
# Returns 1 for an IPv4 address and 0 for anything else. Always one of those
# two values, never undef.
#
#     $self->_is_v4('10.0.0.1');      # 1
#     $self->_is_v4('2001:db8::1');   # 0
sub _is_v4 {
	my ( $self, $ip ) = @_;

	return ( $ip =~ /\A$IPv4_re\z/ ) ? 1 : 0;
}

# Internal helper. Returns the name of the FortiOS firewall address object
# that represents one banned address.
#
# FortiOS has no set or list type that simply holds addresses. Each banned
# address has to become a named address object, which is then made a member of
# an address group that the policy references. So every ban creates an object,
# and it needs a name.
#
# The name is derived from the prefix, the instance name, and the address
# rather than stored, so ban and unban independently arrive at the same name
# without any local bookkeeping, and two instances on the same FortiGate do
# not collide. Dots and colons are replaced with hyphens because FortiOS
# rejects them in object names, which is what makes the mangling necessary
# rather than just cosmetic.
#
# Note the substitution is not reversible: 10.0.0.1 and 10-0-0-1 would produce
# the same object name. Nothing in this dist ever bans the latter, so it does
# not arise in practice.
#
# Args:
#
#     ip - The address to name an object for, as a plain string. Expected to
#          be an already validated and lowercased IPv4 or IPv6 address.
#
# Returns the object name as a plain string, safe to use in a FortiOS
# configuration. Still needs percent encoding before going into a URL, which
# the callers do.
#
#     # with prefix "kur" and name "ssh"
#     $self->_addr_name('10.0.0.1');      # kur_ssh_10-0-0-1
#     $self->_addr_name('2001:db8::1');   # kur_ssh_2001-db8--1
sub _addr_name {
	my ( $self, $ip ) = @_;

	my $name = $self->{prefix} . '_' . $self->{name} . '_' . $ip;
	# dots and colons are not valid in FortiOS object names
	$name =~ s/[.:]/-/g;

	return $name;
} ## end sub _addr_name

# Internal helper. Returns which of the two configured address groups an
# address belongs in.
#
# A FortiOS address group is single family, so blocking both means two groups
# on the appliance side, and the caller has to pick the right one for every
# membership change. Both groups are expected to already exist and to be
# referenced by a policy; this backend adds and removes members but does not
# create the groups.
#
# Args:
#
#     ip - The address whose group is wanted, as a plain string. Expected to
#          be an already validated and lowercased IPv4 or IPv6 address.
#
# Returns the group name as a plain string, from either the group4 or the
# group6 option. Returns undef if the relevant option was never set, though
# new rejects that so it should not arise.
#
#     # with group4 'blocklist4' and group6 'blocklist6'
#     $self->_group_name('10.0.0.1');      # blocklist4
#     $self->_group_name('2001:db8::1');   # blocklist6
sub _group_name {
	my ( $self, $ip ) = @_;

	return $self->_is_v4($ip) ? $self->{options}{group4} : $self->{options}{group6};
}

# Internal helper. Builds the full URL for a FortiOS cmdb REST endpoint. Every
# request this backend makes goes through here.
#
# The cmdb tree is FortiOS's configuration API, so all the object and group
# manipulation lives under /api/v2/cmdb/. The vdom query parameter is appended
# only when the option is set; on an appliance with virtual domains enabled,
# leaving it off means the request lands in whichever vdom the token's account
# defaults to, which may not be the intended one.
#
# The vdom is percent encoded, as it is a configured name rather than
# something derived.
#
# Args:
#
#     path - The cmdb path below /api/v2/cmdb/, as a plain string, such as
#            'firewall/address' or
#            'firewall/addrgrp/blocklist4/member/kur_ssh_10-0-0-1'. Appended
#            as is, so any object names embedded in it are expected to have
#            been percent encoded by the caller already.
#
# Returns the complete URL as a string. The scheme and host come from the
# options.
#
#     $self->_cmdb_url('firewall/address');
#     #   https://fw.example.org/api/v2/cmdb/firewall/address
#
#     # with the vdom option set to root
#     #   https://fw.example.org/api/v2/cmdb/firewall/address?vdom=root
sub _cmdb_url {
	my ( $self, $path ) = @_;

	my $url = $self->{options}{scheme} . '://' . $self->{options}{host} . '/api/v2/cmdb/' . $path;

	if ( defined( $self->{options}{vdom} ) && $self->{options}{vdom} ne '' ) {
		$url .= '?vdom=' . $self->_uri_escape( $self->{options}{vdom} );
	}

	return $url;
} ## end sub _cmdb_url

# Internal helper. Returns the cmdb path of the address object menu for an
# address's family.
#
# FortiOS keeps IPv4 and IPv6 address objects in two separate menus rather
# than in one menu with a family field, so the path itself differs. Creating
# an IPv6 object under the IPv4 menu is rejected.
#
# Args:
#
#     ip - The address whose menu is wanted, as a plain string. Expected to be
#          an already validated and lowercased IPv4 or IPv6 address.
#
# Returns the path as a plain string, relative to the cmdb root, ready to be
# handed to _cmdb_url.
#
#     $self->_address_path('10.0.0.1');      # firewall/address
#     $self->_address_path('2001:db8::1');   # firewall/address6
sub _address_path {
	my ( $self, $ip ) = @_;

	return $self->_is_v4($ip) ? 'firewall/address' : 'firewall/address6';
}

# Internal helper. Returns the cmdb path of the address group menu for an
# address's family.
#
# The group menus are split by family for the same reason the address object
# menus are, and an IPv6 group cannot be reached through the IPv4 menu.
#
# Args:
#
#     ip - The address whose group menu is wanted, as a plain string. Expected
#          to be an already validated and lowercased IPv4 or IPv6 address.
#
# Returns the path as a plain string, relative to the cmdb root. Callers
# append the group name and the member path to it before handing it to
# _cmdb_url.
#
#     $self->_addrgrp_path('10.0.0.1');      # firewall/addrgrp
#     $self->_addrgrp_path('2001:db8::1');   # firewall/addrgrp6
sub _addrgrp_path {
	my ( $self, $ip ) = @_;

	return $self->_is_v4($ip) ? 'firewall/addrgrp' : 'firewall/addrgrp6';
}

# Internal helper. Builds the JSON body that creates the FortiOS address
# object for one banned address.
#
# The address is written as a host prefix, /32 or /128, because a FortiOS
# address object of this kind is always a subnet; there is no single host
# type. The field it goes in differs by family, subnet for IPv4 and ip6 for
# IPv6, which is why this cannot be written once.
#
# Note the JSON comes back with its keys sorted, since the encoder is
# canonical, so the ip6 form has its fields in the opposite order to what the
# code reads.
#
# Args:
#
#     ip - The address to build the body for, as a plain string. Expected to
#          be an already validated and lowercased IPv4 or IPv6 address.
#
# Returns the body as a JSON string, ready to be the content of a POST to the
# family's address menu.
#
#     $self->_address_body('10.0.0.1');
#     #   {"name":"kur_ssh_10-0-0-1","subnet":"10.0.0.1/32"}
#
#     $self->_address_body('2001:db8::1');
#     #   {"ip6":"2001:db8::1/128","name":"kur_ssh_2001-db8--1"}
sub _address_body {
	my ( $self, $ip ) = @_;

	if ( $self->_is_v4($ip) ) {
		return $self->_json->encode( { name => $self->_addr_name($ip), subnet => $ip . '/32' } );
	}

	return $self->_json->encode( { name => $self->_addr_name($ip), ip6 => $ip . '/128' } );
} ## end sub _address_body

# Internal helper. Performs one HTTP request against the FortiOS REST API.
# Every call this backend makes to the appliance goes through here.
#
# The user agent is built on first use and then cached on the object, so a run
# of requests shares one agent and its connection rather than building a new
# one each time. LWP::UserAgent is loaded with require at that point rather
# than at compile time, since only the HTTP backends need it and it is a
# recommends rather than a hard prereq; failing to load it dies with an
# explanation naming this backend.
#
# The insecure option turns off certificate verification, which is there
# because FortiGates very commonly present a self signed certificate.
#
# Authentication is a bearer token on every request; there is no session to
# establish, unlike the checkpoint and cisco_fmc backends.
#
# Any HTTP level failure dies rather than setting an error, with the method,
# URL, status line, and response body in the message. The callers wrap this in
# eval and turn the exception into the appropriate error code, which is what
# lets one helper serve paths that need to report ban, unban, and teardown
# failures differently.
#
# A body that fails to decode as JSON is not fatal. The decode runs inside its
# own eval and leaves the result undef, because several FortiOS endpoints
# answer with an empty body on success and there is nothing to parse.
#
# Never called in testing mode; those paths record the request descriptors
# instead.
#
# Args:
#
#     method - The HTTP method, as a plain string, such as 'GET', 'POST', or
#              'DELETE'.
#
#     url    - The full URL to request, as a plain string, normally from
#              _cmdb_url.
#
#     body   - Optional request body, as an already encoded JSON string.
#              Passed straight to HTTP::Request, so undef is fine for methods
#              that carry no body.
#
# Returns the decoded response body as whatever structure the JSON held,
# normally a hashref, or undef when the response body was empty or did not
# parse. Dies on any non success HTTP status.
#
#     my $decoded = $self->_request( 'GET', $self->_cmdb_url('firewall/addrgrp') );
#
#     $self->_request( 'POST', $self->_cmdb_url('firewall/address'),
#         $self->_address_body($ip) );
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
		} or die( 'failed to load LWP::UserAgent, which the fortigate backend requires... ' . $@ );
	}

	my @headers = (
		'Content-Type'  => 'application/json',
		'Authorization' => 'Bearer ' . $self->{options}{token},
	);

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
# Banning takes two calls because FortiOS separates the address object from
# group membership: the object has to exist before it can be made a member, so
# the order matters and the two are returned together rather than being
# sequenced by the caller.
#
# Returning descriptors rather than performing the requests is what lets the
# testing paths record exactly what would have been sent without a FortiGate
# being present.
#
# Args:
#
#     ip - The address to ban, as a plain string. Expected to be an already
#          validated and lowercased IPv4 or IPv6 address. The family selects
#          the menus and the group.
#
# Returns a two element list of hashrefs, in the order they must be performed,
# each of the form:
#
#     {
#         method  => 'POST',
#         url     => 'https://fw.example.org/api/v2/cmdb/firewall/address',
#         content => '{"name":"kur_ssh_10-0-0-1","subnet":"10.0.0.1/32"}',
#     }
#
#     my @requests = $self->_ban_requests('10.0.0.1');
#
#     # first, create the address object
#     #   POST https://fw.example.org/api/v2/cmdb/firewall/address
#     #     {"name":"kur_ssh_10-0-0-1","subnet":"10.0.0.1/32"}
#
#     # then, add it to the group
#     #   POST https://fw.example.org/api/v2/cmdb/firewall/addrgrp/blocklist4/member
#     #     {"name":"kur_ssh_10-0-0-1"}
sub _ban_requests {
	my ( $self, $ip ) = @_;

	my $member = $self->_json->encode( { name => $self->_addr_name($ip) } );

	return (
		{ method => 'POST', url => $self->_cmdb_url( $self->_address_path($ip) ), content => $self->_address_body($ip) },
		{
			method  => 'POST',
			url     => $self->_cmdb_url( $self->_addrgrp_path($ip) . '/' . $self->_uri_escape( $self->_group_name($ip) ) . '/member' ),
			content => $member,
		},
	);
} ## end sub _ban_requests

# Internal helper. Returns the pair of requests that unban one address, the
# inverse of _ban_requests.
#
# The order is reversed from the ban: membership is removed first, then the
# object is deleted. FortiOS refuses to delete an address object that is still
# a member of a group, so deleting first would simply fail.
#
# Neither request carries a body, since both identify what to act on entirely
# through the URL. The object and group names are percent encoded going into
# the path.
#
# Args:
#
#     ip - The address to unban, as a plain string. Expected to be an already
#          validated and lowercased IPv4 or IPv6 address, and to produce the
#          same object name it did when banned.
#
# Returns a two element list of hashrefs, in the order they must be performed,
# each with a method and a url key and no content key.
#
#     my @requests = $self->_unban_requests('10.0.0.1');
#
#     # first, drop the group membership
#     #   DELETE https://fw.example.org/api/v2/cmdb/firewall/addrgrp/blocklist4/member/kur_ssh_10-0-0-1
#
#     # then, delete the address object
#     #   DELETE https://fw.example.org/api/v2/cmdb/firewall/address/kur_ssh_10-0-0-1
sub _unban_requests {
	my ( $self, $ip ) = @_;

	return (
		{
			method => 'DELETE',
			url    => $self->_cmdb_url(
				      $self->_addrgrp_path($ip) . '/'
					. $self->_uri_escape( $self->_group_name($ip) )
					. '/member/'
					. $self->_uri_escape( $self->_addr_name($ip) )
			),
		},
		{ method => 'DELETE', url => $self->_cmdb_url( $self->_address_path($ip) . '/' . $self->_uri_escape( $self->_addr_name($ip) ) ) },
	);
} ## end sub _unban_requests

# Internal helper. Says whether a CIDR range is IPv4, the range counterpart of
# _is_v4.
#
# A separate sub is needed rather than passing a range to _is_v4 because a
# range always carries a "/" and a prefix length, which would never match the
# anchored IPv4 regexp, so every range would come back as IPv6. The prefix is
# stripped off first and only the address is matched.
#
# Args:
#
#     cidr - The range to test, as a plain string. Expected to be an already
#            validated CIDR range such as "10.0.0.0/8" or "2001:db8::/32". A
#            bare address with no prefix also works, since the strip is a no
#            op then.
#
# Returns 1 for a range whose address is IPv4 and 0 for anything else. Always
# one of those two values, never undef.
#
#     $self->_cidr_is_v4('10.0.0.0/8');      # 1
#     $self->_cidr_is_v4('2001:db8::/32');   # 0
sub _cidr_is_v4 {
	my ( $self, $cidr ) = @_;

	my $addr = $cidr;
	$addr =~ s!/[0-9]+\z!!;

	return ( $addr =~ /\A$IPv4_re\z/ ) ? 1 : 0;
} ## end sub _cidr_is_v4

# Internal helper. Returns which of the two configured address groups a CIDR
# range belongs in, the range counterpart of _group_name.
#
# Ranges go into the same two groups the single addresses do; FortiOS does not
# distinguish a host object from a subnet object at the group level.
#
# Args:
#
#     cidr - The range whose group is wanted, as a plain string. Expected to
#            be an already validated CIDR range.
#
# Returns the group name as a plain string, from either the group4 or the
# group6 option.
#
#     # with group4 'blocklist4' and group6 'blocklist6'
#     $self->_cidr_group_name('10.0.0.0/8');      # blocklist4
#     $self->_cidr_group_name('2001:db8::/32');   # blocklist6
sub _cidr_group_name {
	my ( $self, $cidr ) = @_;

	return $self->_cidr_is_v4($cidr) ? $self->{options}{group4} : $self->{options}{group6};
}

# Internal helper. Returns the cmdb path of the address object menu for a CIDR
# range's family, the range counterpart of _address_path.
#
# The menus are the same ones single addresses use; only the way the family is
# determined differs.
#
# Args:
#
#     cidr - The range whose menu is wanted, as a plain string. Expected to be
#            an already validated CIDR range.
#
# Returns the path as a plain string, relative to the cmdb root, ready to be
# handed to _cmdb_url.
#
#     $self->_cidr_address_path('10.0.0.0/8');      # firewall/address
#     $self->_cidr_address_path('2001:db8::/32');   # firewall/address6
sub _cidr_address_path {
	my ( $self, $cidr ) = @_;

	return $self->_cidr_is_v4($cidr) ? 'firewall/address' : 'firewall/address6';
}

# Internal helper. Returns the cmdb path of the address group menu for a CIDR
# range's family, the range counterpart of _addrgrp_path.
#
# Args:
#
#     cidr - The range whose group menu is wanted, as a plain string. Expected
#            to be an already validated CIDR range.
#
# Returns the path as a plain string, relative to the cmdb root. Callers
# append the group name and the member path to it.
#
#     $self->_cidr_addrgrp_path('10.0.0.0/8');      # firewall/addrgrp
#     $self->_cidr_addrgrp_path('2001:db8::/32');   # firewall/addrgrp6
sub _cidr_addrgrp_path {
	my ( $self, $cidr ) = @_;

	return $self->_cidr_is_v4($cidr) ? 'firewall/addrgrp' : 'firewall/addrgrp6';
}

# Internal helper. Returns the name of the FortiOS address object representing
# one banned CIDR range, the range counterpart of _addr_name.
#
# Same reasoning as for single addresses: each banned range becomes a named
# object that is then made a group member, and the name is derived rather than
# stored so ban and unban independently agree on it.
#
# The mangling has to cover one more character than _addr_name does. As well
# as dots and colons, the slash separating the address from the prefix length
# is replaced with a hyphen, since FortiOS rejects it in an object name too.
#
# Note this makes the name ambiguous in a way worth being aware of: the range
# 10.0.0.0/8 and a hypothetical address 10.0.0.0.8 would both mangle to the
# same object name. Ranges and addresses are validated separately upstream, so
# nothing in this dist produces such a collision.
#
# Args:
#
#     cidr - The range to name an object for, as a plain string. Expected to
#            be an already validated CIDR range.
#
# Returns the object name as a plain string, safe to use in a FortiOS
# configuration. Still needs percent encoding before going into a URL.
#
#     # with prefix "kur" and name "ssh"
#     $self->_cidr_addr_name('10.0.0.0/8');      # kur_ssh_10-0-0-0-8
#     $self->_cidr_addr_name('2001:db8::/32');   # kur_ssh_2001-db8---32
sub _cidr_addr_name {
	my ( $self, $cidr ) = @_;

	my $name = $self->{prefix} . '_' . $self->{name} . '_' . $cidr;
	# dots, colons, and slashes are not valid in FortiOS object names
	$name =~ s/[.:\/]/-/g;

	return $name;
} ## end sub _cidr_addr_name

# Internal helper. Builds the JSON body that creates the FortiOS address
# object for one banned CIDR range, the range counterpart of _address_body.
#
# The difference from the single address version is that no prefix has to be
# appended: a range already is a subnet, which is exactly what a FortiOS
# address object of this kind holds, so it goes in as it stands. The field
# still differs by family, subnet for IPv4 and ip6 for IPv6.
#
# Note the JSON comes back with its keys sorted, since the encoder is
# canonical, so the ip6 form has its fields in the opposite order to what the
# code reads.
#
# Args:
#
#     cidr - The range to build the body for, as a plain string. Expected to
#            be an already validated CIDR range.
#
# Returns the body as a JSON string, ready to be the content of a POST to the
# family's address menu.
#
#     $self->_cidr_address_body('10.0.0.0/8');
#     #   {"name":"kur_ssh_10-0-0-0-8","subnet":"10.0.0.0/8"}
#
#     $self->_cidr_address_body('2001:db8::/32');
#     #   {"ip6":"2001:db8::/32","name":"kur_ssh_2001-db8---32"}
sub _cidr_address_body {
	my ( $self, $cidr ) = @_;

	if ( $self->_cidr_is_v4($cidr) ) {
		return $self->_json->encode( { name => $self->_cidr_addr_name($cidr), subnet => $cidr } );
	}

	return $self->_json->encode( { name => $self->_cidr_addr_name($cidr), ip6 => $cidr } );
} ## end sub _cidr_address_body

# Internal helper. Returns the pair of requests that ban one CIDR range, the
# range counterpart of _ban_requests.
#
# The two step shape and its ordering are the same: the address object has to
# exist before it can be added to the group.
#
# Args:
#
#     cidr - The range to ban, as a plain string. Expected to be an already
#            validated CIDR range. The family selects the menus and the group.
#
# Returns a two element list of hashrefs, in the order they must be performed,
# each with method, url, and content keys.
#
#     my @requests = $self->_ban_cidr_requests('10.0.0.0/8');
#
#     # first, create the address object
#     #   POST https://fw.example.org/api/v2/cmdb/firewall/address
#     #     {"name":"kur_ssh_10-0-0-0-8","subnet":"10.0.0.0/8"}
#
#     # then, add it to the group
#     #   POST https://fw.example.org/api/v2/cmdb/firewall/addrgrp/blocklist4/member
#     #     {"name":"kur_ssh_10-0-0-0-8"}
sub _ban_cidr_requests {
	my ( $self, $cidr ) = @_;

	my $member = $self->_json->encode( { name => $self->_cidr_addr_name($cidr) } );

	return (
		{
			method  => 'POST',
			url     => $self->_cmdb_url( $self->_cidr_address_path($cidr) ),
			content => $self->_cidr_address_body($cidr),
		},
		{
			method  => 'POST',
			url     => $self->_cmdb_url(
				$self->_cidr_addrgrp_path($cidr) . '/' . $self->_uri_escape( $self->_cidr_group_name($cidr) ) . '/member'
			),
			content => $member,
		},
	);
} ## end sub _ban_cidr_requests

# Internal helper. Returns the pair of requests that unban one CIDR range, the
# range counterpart of _unban_requests.
#
# As with single addresses the order is reversed from the ban, membership
# first and then the object, because FortiOS will not delete an address object
# that is still a group member.
#
# Neither request carries a body. The object and group names are percent
# encoded going into the path.
#
# Args:
#
#     cidr - The range to unban, as a plain string. Expected to be an already
#            validated CIDR range, and to produce the same object name it did
#            when banned.
#
# Returns a two element list of hashrefs, in the order they must be performed,
# each with a method and a url key and no content key.
#
#     my @requests = $self->_unban_cidr_requests('10.0.0.0/8');
#
#     # first, drop the group membership
#     #   DELETE https://fw.example.org/api/v2/cmdb/firewall/addrgrp/blocklist4/member/kur_ssh_10-0-0-0-8
#
#     # then, delete the address object
#     #   DELETE https://fw.example.org/api/v2/cmdb/firewall/address/kur_ssh_10-0-0-0-8
sub _unban_cidr_requests {
	my ( $self, $cidr ) = @_;

	return (
		{
			method => 'DELETE',
			url    => $self->_cmdb_url(
				      $self->_cidr_addrgrp_path($cidr) . '/'
					. $self->_uri_escape( $self->_cidr_group_name($cidr) )
					. '/member/'
					. $self->_uri_escape( $self->_cidr_addr_name($cidr) )
			),
		},
		{
			method => 'DELETE',
			url    => $self->_cmdb_url(
				$self->_cidr_address_path($cidr) . '/' . $self->_uri_escape( $self->_cidr_addr_name($cidr) )
			),
		},
	);
} ## end sub _unban_cidr_requests

=head2 init

Initiates the backend. Verifies the token and reachability by fetching the
IPv4 address group.

=cut

sub init {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( $self->{inited} ) {
		$self->{error}       = 18;
		$self->{errorString} = 'backend has already been inited';
		$self->warn;
	}

	my $url = $self->_cmdb_url( 'firewall/addrgrp/' . $self->_uri_escape( $self->{options}{group4} ) );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'GET', url => $url } ];
	} else {
		local $@;
		eval { $self->_request( 'GET', $url ); 1; } or do {
			$self->{error}       = 23;
			$self->{errorString} = 'init failed. probing the address group failed... ' . $@;
			$self->warn;
		};
	}

	$self->{inited} = 1;
} ## end sub init

=head2 ban

Bans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased. A firewall address object named
C<E<lt>prefixE<gt>_E<lt>nameE<gt>_E<lt>ipE<gt>> (dots and colons replaced
with dashes) is created via a POST to C<firewall/address> (IPv4) or
C<firewall/address6> (IPv6) and then added as a member of the family's
address group via a POST to the group's C<member> endpoint. Banning an
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

Unbans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased. The IP's address object is removed from the family's address
group via a DELETE on the group's C<member> endpoint and then the address
object itself is deleted via a DELETE on C<firewall/address> (IPv4) or
C<firewall/address6> (IPv6). Unbanning an IP that is not banned is a noop.

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

Bans a CIDR range. The value of ban is validated as being a IPv4 or IPv6
CIDR and lowercased. A subnet firewall address object named
C<E<lt>prefixE<gt>_E<lt>nameE<gt>_E<lt>cidrE<gt>> (dots, colons, and slashes
replaced with dashes) is created via a POST to C<firewall/address> (IPv4) or
C<firewall/address6> (IPv6) and then added as a member of the family's
address group. Banning an already banned CIDR is a noop.

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

	my @requests = $self->_ban_cidr_requests( $opts{ban} );

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
			$self->{error}       = 32;
			$self->{errorString} = 'banning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	} ## end else [ if ( $self->{testing} ) ]

	$self->{banned_cidr}{ $opts{ban} } = 1;
} ## end sub ban_cidr

=head2 unban_cidr

Unbans a CIDR range. The value of ban is validated as being a IPv4 or IPv6
CIDR and lowercased. The CIDR's address object is removed from the family's
address group via a DELETE on the group's C<member> endpoint and then the
address object itself is deleted. Unbanning a CIDR that is not banned is a
noop.

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

	my @requests = $self->_unban_cidr_requests( $opts{ban} );

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
			$self->{errorString} = 'unbanning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	} ## end else [ if ( $self->{testing} ) ]

	delete( $self->{banned_cidr}{ $opts{ban} } );
} ## end sub unban_cidr

=head2 list_cidr

List banned CIDR ranges. Returns an array of the currently banned CIDRs from
internal state; the FortiGate is not queried. Single IPs are not included;
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
internal state; the FortiGate is not queried. CIDR ranges are not included;
for those see L</list_cidr>.

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
from. Each retained IP and CIDR ban is then re-applied by recreating its
address object and group membership.

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

	foreach my $item ( keys( %{ $self->{banned_cidr} } ) ) {
		my @requests = $self->_ban_cidr_requests($item);

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

Tears down the setup by removing the group membership and address object for
each currently banned IP and CIDR. The internal list of bans is kept, so a
following re_init will re-add them.

=cut

sub teardown {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{inited} = 0;

	my @requests;
	foreach my $item ( sort( keys( %{ $self->{banned} } ) ), sort( keys( %{ $self->{banned_cidr} } ) ) ) {
		my @item_requests
			= $self->{banned_cidr}{$item} ? $self->_unban_cidr_requests($item) : $self->_unban_requests($item);
		if ( $self->{testing} ) {
			push( @requests, @item_requests );
		} else {
			local $@;
			eval {
				foreach my $req (@item_requests) {
					$self->_request( $req->{method}, $req->{url}, $req->{content} );
				}
				1;
			} or do {
				$self->{error}       = 17;
				$self->{errorString} = 'teardown failed removing "' . $item . '"... ' . $@;
				$self->warn;
			};
		} ## end else [ if ( $self->{testing} ) ]
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

Verifies the endpoint and token are still usable by fetching the IPv4 address
group. Returns a true value if so and a false value otherwise.

=cut

sub check {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	my $url = $self->_cmdb_url( 'firewall/addrgrp/' . $self->_uri_escape( $self->{options}{group4} ) );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'GET', url => $url } ];
		return 1;
	}

	local $@;
	eval { $self->_request( 'GET', $url ); 1; } or return 0;

	return 1;
} ## end sub check

=head2 flush

Removes all currently banned IPs and CIDRs at once by removing their group
membership and address objects and forgetting them.

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
		my @item_requests
			= $self->{banned_cidr}{$item} ? $self->_unban_cidr_requests($item) : $self->_unban_requests($item);
		if ( $self->{testing} ) {
			push( @requests, @item_requests );
		} else {
			local $@;
			eval {
				foreach my $req (@item_requests) {
					$self->_request( $req->{method}, $req->{url}, $req->{content} );
				}
				1;
			} or do {
				$self->{error}       = 25;
				$self->{errorString} = 'flush failed removing "' . $item . '"... ' . $@;
				$self->warn;
			};
		} ## end else [ if ( $self->{testing} ) ]
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

Init failed. Probing the address group failed.

=head2 24, checkFailed

The backend check raised an error.

=head2 25, flushFailed

Failed to flush the bans.

=head2 26, portsNotSupported

The fortigate backend blocks whole IPs and does not support ports.

=head2 27, protocolsNotSupported

The fortigate backend blocks whole IPs and does not support protocols.

=head2 30, hostNotDefined

The option host is undef or blank.

=head2 31, tokenNotDefined

The option token is undef or blank.

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

1;    # End of Net::Firewall::BlockerHelper::backends::fortigate
