package Net::Firewall::BlockerHelper::backends::openwrt;

use 5.006;
use strict;
use warnings;
use base         qw( Error::Helper Net::Firewall::BlockerHelper::Util );
use Regexp::IPv4 qw($IPv4_re);
use Regexp::IPv6 qw($IPv6_re);

=head1 NAME

Net::Firewall::BlockerHelper::backends::openwrt - OpenWrt fw4 backend for Net::Firewall::BlockerHelper.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 SYNOPSIS

    use Net::Firewall::BlockerHelper;

    # driving the local router
    my $fw_helper = Net::Firewall::BlockerHelper->new(
            backend => 'openwrt',
            ports => ['22'],
            protocols => ['tcp'],
            name => 'ssh',
            options => { zone => 'wan' },
        );

    # driving a remote router over ubus JSON-RPC
    my $fw_helper = Net::Firewall::BlockerHelper->new(
            backend => 'openwrt',
            ports => ['22'],
            protocols => ['tcp'],
            name => 'ssh',
            options => {
                zone     => 'wan',
                host     => '192.0.2.1',
                user     => 'blocker',
                password => 'hunter2',
            },
        );

    $fw_helper->init_backend;
    $fw_helper->ban(ban => '1.2.3.4');
    $fw_helper->ban_cidr(ban => '1.2.3.0/24');

    # write the current ban list to flash so it survives a reboot
    $fw_helper->commit;

    $fw_helper->teardown;

=head1 DESCRIPTION

Blocks IPs on OpenWrt via fw4, configured through UCI rather than by writing
firewall rules directly.

Two C<config ipset> sections are added to C</etc/config/firewall>, one per
address family (C<< <prefix>_<name>_4 >> and C<< <prefix>_<name>_6 >>), along
with the C<config rule> sections that drop or reject traffic matching them.
fw4 renders each ipset into an nftables set inside its own C<inet fw4> table.
Because the sets are declared with C<< match 'src_net' >>, they are interval
sets and hold both single addresses and CIDR ranges, so this backend supports
CIDR bans.

Banning does not touch UCI. An IP or range is added straight to the live set
with C<nft add element>, which takes effect immediately and needs no reload.
This matters on a router: an C<fw4 reload> rebuilds the whole ruleset and is
far too expensive to run per ban.

Persisting the ban list is therefore a separate, explicit step. See L</commit>.

The backend runs in one of two modes. With no C<host> option it drives the
local machine, running C<uci>, C<fw4>, and C<nft> directly, which is the mode
to use when this is running on the router itself. With C<host> set it drives a
remote router over ubus JSON-RPC, which is the mode to use from a management
host, and is usually what is wanted given OpenWrt ships no perl.

Local mode requires C<uci>, C<fw4>, and C<nft> in the C<PATH> of a process
with sufficient privileges.

Remote mode requires C<uhttpd-mod-ubus> and C<rpcd-mod-file> on the router,
L<LWP::UserAgent> and L<JSON> locally, and an rpcd ACL granting the
configured user the calls this makes. Nothing grants C<file> C<exec> by
default, so without an ACL every C<nft> and C<fw4> call comes back as ubus
permission denied. Drop the following in
C</usr/share/rpcd/acl.d/net-firewall-blockerhelper.json> and run
C<< /etc/init.d/rpcd reload >>.

    {
        "net-firewall-blockerhelper": {
            "description": "Net::Firewall::BlockerHelper openwrt backend",
            "read": {
                "ubus": { "uci": [ "get" ] },
                "uci": [ "firewall" ]
            },
            "write": {
                "ubus": {
                    "uci": [ "add", "set", "delete", "order", "commit" ],
                    "file": [ "exec" ]
                },
                "uci": [ "firewall" ],
                "file": {
                    "/usr/sbin/nft": [ "exec" ],
                    "/sbin/fw4": [ "exec" ]
                }
            }
        }
    }

C</usr/share/rpcd/acl.d/> is part of the root filesystem, which on OpenWrt is
an overlay whose upper layer lives in flash, so the file survives a reboot.
It is not carried across a sysupgrade, as it is not in the default keep list,
nor across a factory reset. Add its path to C</etc/sysupgrade.conf> to keep
it through firmware upgrades; without it, remote mode starts failing with
permission denied after the upgrade.

=head2 ENABLING KILL SUPPORT

Blocking an address only stops new connections. Anything already established
keeps flowing, because the block rules match the source but the existing
traffic has already been accepted and is tracked. The C<kill> option drops
those connection tracking entries too, which is what actually cuts an
attacker off mid session.

It is off by default and needs a package that OpenWrt does not install on its
own. To turn it on:

=over 4

=item 1.

Install the C<conntrack> package on the router. Note the name: the userspace
tool is packaged as C<conntrack>, not as C<conntrack-tools>, which is the
name of the upstream project rather than of anything installable here.

    apk add conntrack

    # on releases still using opkg
    opkg update && opkg install conntrack

The kernel side, C<kmod-nf-conntrack> and C<kmod-nf-conntrack6>, is already
present on any router running fw4, as fw4 depends on it.

=item 2.

Pass the option.

    my $fw_helper = Net::Firewall::BlockerHelper->new(
            backend   => 'openwrt',
            ports     => ['22'],
            protocols => ['tcp'],
            name      => 'ssh',
            options   => { zone => 'wan', kill => 1 },
        );

=item 3.

In remote mode only, add the binary to the C<file> section of the rpcd ACL
shown above and reload rpcd. Confirm the path first, as it is not the same on
every build:

    command -v conntrack        # usually /usr/sbin/conntrack

    "file": {
        "/usr/sbin/nft": [ "exec" ],
        "/sbin/fw4": [ "exec" ],
        "/usr/sbin/conntrack": [ "exec" ]
    }

=back

Skipping any of that is not an error. conntrack returns a non-zero exit
status whenever it has nothing to delete, which is the common case, so its
status is ignored and a missing binary or a denying ACL is indistinguishable
from a ban with no established connections. The bans still work; the kill
just quietly does nothing. If it matters, verify it rather than assume, by
banning an address with a connection open and watching
C<< conntrack -L -s <address> >> empty out.

The kill is scoped to what is actually being blocked. With protocols
configured, one conntrack call is made per protocol, so blocking only udp
will not drop tcp entries. With none, everything is being blocked and every
entry for the address goes. Protocols conntrack cannot filter by are skipped.

=head1 NOTES

Persistence is not automatic and this is deliberate. C<uci commit> writes to
the overlay filesystem, which on most OpenWrt devices is flash with a finite
erase budget, so committing once per ban would wear it out. Bans are applied
to the live nftables set only, and are lost by anything that rebuilds fw4's
table until L</commit> has been called. L</init> and L</teardown> commit on
their own because they change the UCI config and there is nothing to write
out otherwise.

An C<fw4 reload> preserves the contents of the sets; an C<fw4 restart>, an
C<< /etc/init.d/firewall restart >>, and a reboot all empty them. Whatever
has been committed comes back by itself, as fw4 seeds each set from the
C<entry> list of its C<config ipset> section. Anything banned since the last
L</commit> does not, and is recovered by L</check> noticing and L</re_init>
putting it back, which is what the frontend's self healing does
automatically.

The first L</commit> rewrites C</etc/config/firewall>. This is C<uci commit>
doing what it always does, canonicalising the whole file rather than editing
the lines it changed, and it drops every comment in the file along the way,
including the block of commented out examples a stock config ships with. The
configuration itself is unchanged. Nothing here can avoid it, so take a copy
of the file first if those comments are wanted.

Overlapping CIDR bans do not round trip. fw4 gives the sets the C<auto-merge>
flag, so nftables folds overlapping and adjacent ranges together as they are
added: banning C<10.0.0.0/8> and then C<10.1.0.0/16> leaves one interval, and
a later C<unban_cidr> of the C</16> punches a hole in the C</8> rather than
being the noop it looks like. The ban list this object keeps still says the
C</8> is banned, because as far as it is concerned it is. Ban ranges that do
not overlap and this cannot arise.

C<config rule> sections are created with C<< src '*' >> unless the C<zone>
option says otherwise, which is every zone. Setting C<zone> to C<wan> is
almost always what is actually wanted.

fw4 defaults an unspecified C<proto> to C<< tcp udp >>, not to every protocol.
When neither ports nor protocols are configured this backend therefore writes
C<< proto 'all' >> explicitly, so that blocking everything really does block
everything.

Rules are moved to the front of C</etc/config/firewall> with C<uci reorder>,
because fw4 emits rules in config order and a block rule appended after an
existing accept rule would never be reached. This puts them ahead of the zone
sections as well. fw4 parses the whole config before emitting anything, so
that is expected to be harmless, but it is worth knowing about if the config
is being read by hand. Set the C<reorder> option to 0 to leave the ordering
alone.

Everything that touches a set at runtime, meaning every ban and unban and the
whole of L</check>, assumes fw4 names the nftables set after the C<name> of
the C<config ipset> section it came from and puts it in its own C<inet fw4>
table. Should that ever not hold, bans would fail with nft reporting no such
set.

The C<kill> option shells out to conntrack(8), from the C<conntrack> package,
which is not installed by default. Without it the kill is a silent noop, as
conntrack's exit status is intentionally ignored. See
L</ENABLING KILL SUPPORT>.

=head1 METHODS

=head2 new

Initiates the object.

    - options :: Backend specific options that will be passed to the backend unchecked
            outside of making sure it is a hash ref if defined. See below for further info.
        - Default :: {}

    - ports :: A array of ports to block. Checked to make sure they are ints within the
            range 1 to 65535 or a valid service name via getservbyname. All ports will be
            blocked if non are specified. Duplicates are removed.
        - Default :: []

    - protocols :: A array of protocols to block. This is checked against
            /etc/protocols via the function getprotobyname. Duplicates will be
            discarded. If no protocols are given, all traffic sourced from the
            sets is blocked, unless ports are given, in which case it defaults
            to tcp and udp. Ports are only attached to port-capable protocols
            (tcp/udp/sctp); other protocols are blocked without a port.
        - Default :: [], or ['tcp','udp'] when ports are given

    - prefix :: Prefix to use. Must match the regex /^[a-zA-Z0-9]+$/
        - default :: kur

    - name :: Name of this specific instance. This must be specified. The
            prefix and the name joined by an underscore must come to 250
            characters or fewer, leaving room for the suffixes appended to
            derive the set and rule names within the nftables identifier
            limit.
        - default :: undef

The options hash accepts the following.

    - type :: The drop method to use. 'drop' silently drops. 'reject' sends
            the family-appropriate ICMP unreachable back.
        - Default :: drop

    - zone :: The firewall zone the rules apply to, becoming the rule's src.
            '*' is every zone. Must match /^[a-zA-Z0-9_*-]+$/.
        - Default :: *

    - reorder :: Move the rule sections to the front of the firewall config so
            they are evaluated before any existing accept rules.
        - Default :: 1

    - kill :: Use conntrack(8) to drop existing connection tracking entries
            for the banned IP, scoped to the configured protocols. Requires
            the conntrack package, and in remote mode an ACL allowing it. See
            L</ENABLING KILL SUPPORT>.
        - Default :: 0

    - host :: The router to drive over ubus JSON-RPC. Leaving this undef runs
            everything locally instead.
        - Default :: undef

    - user :: The ubus user to authenticate as. Remote mode only.
        - Default :: root

    - password :: The password for that user. Required in remote mode.
        - Default :: undef

    - http_proto :: 'http' or 'https'. Remote mode only.
        - Default :: http

    - http_port :: The port uhttpd is listening on. Remote mode only.
        - Default :: 80, or 443 when http_proto is https

    - timeout :: HTTP timeout in seconds. Remote mode only.
        - Default :: 30

    - insecure :: Skip TLS certificate verification, which routers with a self
            signed certificate will need. Remote mode only.
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
			all_fatal => 1,
			flags     => {
				1  => 'notInited',
				2  => 'invalidPortSpecified',
				3  => 'portsNotArray',
				4  => 'protocolsNotArray',
				5  => 'invalidPortSpecified',
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
				20 => 'typeInvalid',
				21 => 'nameTooLong',
				23 => 'initFailed',
				24 => 'checkFailed',
				25 => 'flushFailed',
				26 => 'banCidrFailed',
				27 => 'unbanCidrFailed',
				28 => 'cidrItemNotCidr',
				29 => 'cidrNotSupported',
				30 => 'listCidrFailed',
				31 => 'commitFailed',
				32 => 'invalidHost',
				33 => 'noPassword',
				34 => 'invalidZone',
				35 => 'invalidHttpPort',
				36 => 'invalidHttpProto',
			},
			fatal_flags      => {},
			perror_not_fatal => 0,
		},
		options => {
			type       => 'drop',
			zone       => '*',
			reorder    => 1,
			kill       => 0,
			host       => undef,
			user       => 'root',
			password   => undef,
			http_proto => 'http',
			http_port  => undef,
			timeout    => 30,
			insecure   => 0,
		},
		ports          => [],
		protocols      => [],
		testing        => undef,
		test_data      => undef,
		prefix         => 'kur',
		frontend_obj   => undef,
		inited         => 0,
		banned         => {},
		banned_cidr    => {},
		cidr_supported => 1,
		ua             => undef,
		session        => undef,
	};
	bless $self;

	if ( defined( $opts{ports} ) && ref( $opts{ports} ) ne 'ARRAY' ) {
		$self->{perror}      = 1;
		$self->{error}       = 3;
		$self->{errorString} = 'ports is defined and type is not array but "' . ref( $opts{ports} ) . '"';
		$self->warn;
	} elsif ( defined( $opts{ports} ) ) {
		my %ports;
		foreach my $item ( @{ $opts{ports} } ) {
			if ( $item =~ /^[0-9]+$/ && $item >= 1 && $item <= 65535 ) {
				$ports{$item} = 1;
			} elsif ( $item =~ /^[0-9]+$/ ) {
				$self->{perror} = 1;
				$self->{error}  = 2;
				$self->{errorString}
					= $item . ' is not a valid value for a port as it must be a int within the range 1 to 65535';
				$self->warn;
			} else {
				# just using tcp here as protocol must be specified
				my ( $name, $aliases, $port, $proto ) = getservbyname( $item, 'tcp' );
				if ( !defined($port) ) {
					$self->{perror} = 1;
					$self->{error}  = 2;
					$self->{errorString}
						= $item . ' could not be resolved to a port name via getservbyname("' . $item . '", "tcp")';
					$self->warn;
				}
				$ports{$port} = 1;
			} ## end else [ if ( $item =~ /^[0-9]+$/ && $item >= 1 && ...)]
		} ## end foreach my $item ( @{ $opts{ports} } )
		my @port_keys = keys(%ports);
		@port_keys = sort { $a <=> $b } @port_keys;
		push( @{ $self->{ports} }, @port_keys );
	} ## end elsif ( defined( $opts{ports} ) )

	if ( defined( $opts{protocols} ) && ref( $opts{protocols} ) ne 'ARRAY' ) {
		$self->{perror}      = 1;
		$self->{error}       = 4;
		$self->{errorString} = 'protocols is defined and type is not array but "' . ref( $opts{protocols} ) . '"';
		$self->warn;
	} elsif ( defined( $opts{protocols} ) ) {
		my %protocols;
		foreach my $item ( @{ $opts{protocols} } ) {
			my ( $name, $aliases, $proto ) = getprotobyname($item);
			# if this is undef, it means it is not a known protocol
			if ( !defined($proto) ) {
				$self->{perror} = 1;
				$self->{error}  = 5;
				$self->{errorString}
					= $item . ' could not be resolved to a protocol via getprotobyname("' . $item . '")';
				$self->warn;
			}
			$protocols{$item} = 1;
		} ## end foreach my $item ( @{ $opts{protocols} } )
		my @protocols_keys = keys(%protocols);
		@protocols_keys = sort { $a cmp $b } @protocols_keys;
		push( @{ $self->{protocols} }, @protocols_keys );
	} ## end elsif ( defined( $opts{protocols} ) )

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

	# nftables caps identifiers at 256 bytes including the terminating null, so
	# 255 usable. The longest thing derived from the base name is a rule
	# section, base plus "_r" plus the index, so 250 leaves ample room for that
	# and for the "_4"/"_6" the set names take.
	if ( defined( $self->{name} ) ) {
		my $base_length = length( $self->{prefix} ) + 1 + length( $self->{name} );
		if ( $base_length > 250 ) {
			$self->{perror} = 1;
			$self->{error}  = 21;
			$self->{errorString}
				= 'the prefix and name come to ' . $base_length . ' characters joined, which is over the 250 maximum';
			$self->warn;
		}
	} ## end if ( defined( $self->{name} ) )

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

		# merge over the defaults rather than replacing them, so that setting
		# one option does not silently unset the rest
		foreach my $key ( keys( %{ $opts{options} } ) ) {
			$self->{options}{$key} = $opts{options}{$key};
		}

		if ( $self->{options}{type} ne 'drop' && $self->{options}{type} ne 'reject' ) {
			$self->{perror} = 1;
			$self->{error}  = 20;
			$self->{errorString}
				= '$opts{options}{type} is "' . $self->{options}{type} . '" and not "drop" or "reject"';
			$self->warn;
		}

		if ( !defined( $self->{options}{zone} ) || $self->{options}{zone} !~ /^[a-zA-Z0-9_*\-]+$/ ) {
			$self->{perror}      = 1;
			$self->{error}       = 34;
			$self->{errorString} = '$opts{options}{zone} does not match the regexp /^[a-zA-Z0-9_*\-]+$/';
			$self->warn;
		}

		if ( defined( $self->{options}{host} ) && $self->{options}{host} !~ /^[a-zA-Z0-9_.\-\[\]:]+$/ ) {
			$self->{perror} = 1;
			$self->{error}  = 32;
			$self->{errorString}
				= '$opts{options}{host} is "'
				. $self->{options}{host}
				. '" which does not match the regexp /^[a-zA-Z0-9_.\-\[\]:]+$/';
			$self->warn;
		}

		if ( defined( $self->{options}{host} ) && !defined( $self->{options}{password} ) ) {
			$self->{perror}      = 1;
			$self->{error}       = 33;
			$self->{errorString} = 'host is set, putting the backend in remote mode, but no password was given';
			$self->warn;
		}

		if ( $self->{options}{http_proto} ne 'http' && $self->{options}{http_proto} ne 'https' ) {
			$self->{perror} = 1;
			$self->{error}  = 36;
			$self->{errorString}
				= '$opts{options}{http_proto} is "' . $self->{options}{http_proto} . '" and not "http" or "https"';
			$self->warn;
		}

		if (
			defined( $self->{options}{http_port} )
			&& (   $self->{options}{http_port} !~ /^[0-9]+$/
				|| $self->{options}{http_port} < 1
				|| $self->{options}{http_port} > 65535 )
			)
		{
			$self->{perror} = 1;
			$self->{error}  = 35;
			$self->{errorString}
				= '$opts{options}{http_port} is "'
				. $self->{options}{http_port}
				. '" and not an int within the range 1 to 65535';
			$self->warn;
		} ## end if ( defined( $self->{options}{http_port} ...))
	} ## end if ( defined( $opts{options} ) )

	# only worked out once the proto is known to be valid
	if ( !defined( $self->{options}{http_port} ) ) {
		$self->{options}{http_port} = ( $self->{options}{http_proto} eq 'https' ) ? 443 : 80;
	}

	return $self;
} ## end sub new

# Internal helper. Returns the three names this instance owns: the base name,
# which every UCI section is derived from, and the two set names.
#
# All of them come from the prefix and the name rather than being stored, so
# every part of the backend agrees on what to create, reference, and tear down
# without threading the names around. The prefix and name pair is unique per
# instance, so two instances can share a router without colliding.
#
# The set names double as the names of the UCI ipset sections that declare
# them, which is what lets check confirm a set's config is still present from
# the set name alone. Rule sections are named separately, by _rule_specs.
#
# There are two sets rather than one because an nftables set is typed and fw4
# renders one set per ipset section per family: the _4 set is ipv4_addr and the
# _6 set ipv6_addr, and neither will hold the other's addresses.
#
# Takes no arguments.
#
# Returns a three element list of the base name, the IPv4 set name, and the
# IPv6 set name, in that order.
#
#     my ( $base, $set4, $set6 ) = $self->_names;
#
#     # with prefix "kur" and name "ssh"
#     #   $base is 'kur_ssh'
#     #   $set4 is 'kur_ssh_4'
#     #   $set6 is 'kur_ssh_6'
sub _names {
	my ($self) = @_;

	my $base = $self->{prefix} . '_' . $self->{name};
	return ( $base, $base . '_4', $base . '_6' );
}

# Internal helper. Returns the UCI ipset sections this instance needs, one per
# address family.
#
# fw4 turns each of these into an nftables set inside its inet fw4 table. The
# match is src_net rather than src_ip on purpose: src_net gives an interval
# set, which holds CIDR ranges as well as single addresses, and is what lets
# this backend support CIDR bans off the same two sets that hold the single IP
# bans. An interval set takes a bare address as a singleton interval, so
# nothing extra is needed for the single IP case.
#
# The entry list is deliberately not set here. Entries are the ban list, which
# is written out by commit rather than at init, so that a ban does not cause a
# flash write.
#
# Takes no arguments.
#
# Returns a two element list of section hashrefs, the IPv4 one first, each
# with:
#
#     - name :: the UCI section name, which is also the set name
#     - type :: always 'ipset'
#     - kv   :: an arrayref of [ option, value ] pairs in the order they should
#               be written, values being either a scalar or an arrayref for a
#               list option
#
#     my @sections = $self->_ipset_sections;
#
#     # with prefix "kur" and name "ssh", the first is
#     #   {
#     #     name => 'kur_ssh_4',
#     #     type => 'ipset',
#     #     kv   => [ [ 'name', 'kur_ssh_4' ], [ 'family', 'ipv4' ],
#     #               [ 'match', ['src_net'] ], [ 'enabled', '1' ] ],
#     #   }
sub _ipset_sections {
	my ($self) = @_;

	my ( $base, $set4, $set6 ) = $self->_names;

	my @sections;
	foreach my $item ( [ $set4, 'ipv4' ], [ $set6, 'ipv6' ] ) {
		push(
			@sections,
			{
				name => $item->[0],
				type => 'ipset',
				kv   =>
					[ [ 'name', $item->[0] ], [ 'family', $item->[1] ], [ 'match', ['src_net'] ], [ 'enabled', '1' ], ],
			}
		);
	} ## end foreach my $item ( [ $set4, 'ipv4' ], [ $set6, ...])

	return @sections;
} ## end sub _ipset_sections

# Internal helper. Works out the full cross product of family, protocol, and
# ports this instance needs to block and returns it as UCI rule sections, along
# with a record of which sets those rules actually reference. Essentially all
# of the backend's rule logic lives here.
#
# The second return value exists for check. Verifying the setup is still intact
# means confirming the sets the rules depend on are present, and which sets
# those are is not always both of them: a configuration whose protocols are all
# one family, say icmp only, produces rules referencing just the IPv4 set, and
# demanding the IPv6 set exist would then report a healthy setup as broken.
# Rather than have check re-derive that, it is recorded here where the decision
# is actually made.
#
# Protocols belonging to the wrong family are skipped, so icmp never lands in
# an ipv6 rule and the various spellings of IPv6 ICMP never land in an ipv4
# one. Ports are only attached to protocols that have them.
#
# One rule section is emitted per protocol per family rather than collapsing
# the protocols into a single rule's proto list, matching how the iptables and
# nftables backends lay their rules out and keeping the port handling simple,
# as a rule mixing a port-capable protocol with one that has no ports would be
# rejected by fw4.
#
# The proto of a rule blocking everything is written as 'all' rather than being
# left out. fw4 defaults an absent proto to tcp and udp, so omitting it would
# quietly block far less than asked for.
#
# Takes no arguments; family, protocols, ports, type, and zone all come from
# the object.
#
# Returns a two element list:
#
#     - an arrayref of section hashrefs, in the same shape _ipset_sections
#       returns, with type 'rule' and names of the form <base>_r<N> where N
#       counts up from 0 across both families
#     - a hashref keyed by the set names those rules reference, values all 1,
#       for check to confirm
#
#     my ( $sections, $referenced ) = $self->_rule_specs;
#
#     # ports 22, protocols tcp, zone wan, type drop: two sections, the first
#     #   {
#     #     name => 'kur_ssh_r0',
#     #     type => 'rule',
#     #     kv   => [ [ 'name', 'kur_ssh_r0' ], [ 'family', 'ipv4' ],
#     #               [ 'src', 'wan' ], [ 'ipset', 'kur_ssh_4' ],
#     #               [ 'proto', 'tcp' ], [ 'dest_port', ['22'] ],
#     #               [ 'target', 'DROP' ] ],
#     #   }
#     #   $referenced is { kur_ssh_4 => 1, kur_ssh_6 => 1 }
#
#     # no protocols and no ports: one rule per family with proto 'all' and no
#     # dest_port
#
#     # ports 22 with no protocols: two rules per family, tcp and udp
sub _rule_specs {
	my ($self) = @_;

	my ( $base, $set4, $set6 ) = $self->_names;

	my @ports  = @{ $self->{ports} };
	my @protos = @{ $self->{protocols} };

	my $target = ( $self->{options}{type} eq 'reject' ) ? 'REJECT' : 'DROP';

	# protocols that accept a port specification
	my %port_ok = ( tcp => 1, udp => 1, sctp => 1 );

	# the various names the IPv6 ICMP protocol may go by
	my %v6_icmp = ( 'ipv6-icmp' => 1, 'icmp6' => 1, 'icmpv6' => 1 );

	my @families
		= ( { set => $set4, family => 'ipv4', number => 4 }, { set => $set6, family => 'ipv6', number => 6 }, );

	my @sections;
	my %referenced;
	my $index = 0;
	foreach my $fam (@families) {
		my @fam_protos;
		if ( !@protos && !@ports ) {
			# fw4 would read a missing proto as tcp and udp, so say all
			@fam_protos = ('all');
		} elsif ( !@protos && @ports ) {
			# ports require a protocol, default to tcp and udp
			@fam_protos = ( 'tcp', 'udp' );
		} else {
			foreach my $proto (@protos) {
				# skip protocols that do not belong to this family
				if ( $fam->{number} == 6 ) {
					next if ( $proto eq 'icmp' );
				} else {
					next if ( $v6_icmp{$proto} );
				}
				push( @fam_protos, $proto );
			}
		} ## end else [ if ( !@protos && !@ports ) ]

		foreach my $proto (@fam_protos) {
			my $section = $base . '_r' . $index;
			$index++;

			my @kv = (
				[ 'name',   $section ],
				[ 'family', $fam->{family} ],
				[ 'src',    $self->{options}{zone} ],
				[ 'ipset',  $fam->{set} ],
				[ 'proto',  $proto ],
			);
			if ( @ports && $port_ok{$proto} ) {
				push( @kv, [ 'dest_port', [@ports] ] );
			}
			push( @kv, [ 'target', $target ] );

			push( @sections, { name => $section, type => 'rule', kv => \@kv } );
			$referenced{ $fam->{set} } = 1;
		} ## end foreach my $proto (@fam_protos)
	} ## end foreach my $fam (@families)

	return ( \@sections, \%referenced );
} ## end sub _rule_specs

# Internal helper. Returns the name of the set an address or range belongs in,
# picked by address family.
#
# Both the single IP and the CIDR methods need this and the CIDR ones can not
# match the whole value against the address regexps, as a range has a prefix
# length on the end, so the family test is done on the address portion only.
# Splitting on "/" is harmless for a bare address, which simply has no "/" to
# split on.
#
# Args:
#
#     item - The address or range, as a plain string. Expected to be an already
#            validated and lowercased IPv4 or IPv6 address, or such an address
#            followed by "/" and a prefix length.
#
# Returns the set name as a string. The IPv4 set is returned for anything that
# matches the IPv4 regexp and the IPv6 set for everything else, so a value that
# is neither lands in the IPv6 set rather than erroring; callers validate
# before getting here.
#
#     $self->_set_for('10.0.0.1');       # kur_ssh_4
#     $self->_set_for('10.0.0.0/8');     # kur_ssh_4
#     $self->_set_for('2001:db8::1');    # kur_ssh_6
#     $self->_set_for('2001:db8::/32');  # kur_ssh_6
sub _set_for {
	my ( $self, $item ) = @_;

	my ( $base, $set4, $set6 ) = $self->_names;

	my ($address) = split( m!/!, $item );

	return ( $address =~ /\A$IPv4_re\z/ ) ? $set4 : $set6;
}

# Internal helper. Splits the current ban list into the two per family entry
# lists that commit writes into the UCI ipset sections.
#
# Single IP bans and CIDR bans are held in separate hashes but share a set per
# family, as the sets are interval sets and hold both, so this merges them back
# together. Both hashes are sorted so that the same ban list always produces
# the same config, which keeps a commit that changes nothing from rewriting the
# file and keeps the test data comparable against a fixed expected list.
#
# Takes no arguments.
#
# Returns a two element list of arrayrefs, the IPv4 entries and then the IPv6
# entries. Within each, the single IPs come before the ranges, each group
# sorted as strings. Either or both may be empty, which is what an instance
# with no bans yet, or one that has just been flushed, produces.
#
#     my ( $v4, $v6 ) = $self->_entry_lists;
#
#     # having banned 10.0.0.1, 2001:db8::1, and 10.0.0.0/8
#     #   $v4 is [ '10.0.0.1', '10.0.0.0/8' ]
#     #   $v6 is [ '2001:db8::1' ]
sub _entry_lists {
	my ($self) = @_;

	my ( $base, $set4, $set6 ) = $self->_names;

	my @v4;
	my @v6;
	foreach my $hash ( $self->{banned}, $self->{banned_cidr} ) {
		foreach my $item ( sort( keys( %{$hash} ) ) ) {
			if ( $self->_set_for($item) eq $set4 ) {
				push( @v4, $item );
			} else {
				push( @v6, $item );
			}
		}
	}

	return ( \@v4, \@v6 );
} ## end sub _entry_lists

# Internal helper. Quotes a single argv token for the shell, used when
# rendering an operation into a local command line.
#
# The local runner uses backticks, so everything goes through /bin/sh and every
# token that holds anything the shell would act on has to be protected. Tokens
# made up entirely of characters the shell leaves alone are returned bare,
# which is the overwhelming majority of them and keeps the rendered commands
# readable. Everything else is wrapped in single quotes, with any single quote
# inside ended, escaped, and reopened, which is the only fully safe form as
# nothing is special within single quotes.
#
# Args:
#
#     token - The argv token to quote, as a plain string. Expected to be
#             defined; undef warns and is treated as the empty string, which
#             renders as ''.
#
# Returns the token in a form safe to paste into a command line, either
# unchanged or single quoted.
#
#     $self->_shell_quote('firewall.kur_ssh_4=ipset');    # unchanged
#     $self->_shell_quote('{ 10.0.0.1 }');                # '{ 10.0.0.1 }'
#     $self->_shell_quote("firewall.x.y=a b");            # 'firewall.x.y=a b'
#     $self->_shell_quote("it's");                        # 'it'\''s'
sub _shell_quote {
	my ( $self, $token ) = @_;

	$token = '' if ( !defined($token) );

	return $token if ( $token =~ m!\A[A-Za-z0-9_.:/=,@+\-]+\z! );

	$token =~ s/'/'\\''/g;

	return "'" . $token . "'";
} ## end sub _shell_quote

# Internal helper. Renders the abstract operations the methods build into local
# shell command lines.
#
# The operations are kept abstract because the two transports need genuinely
# different things from them: creating a section is one ubus call but several
# uci invocations, and there is no uci command that sets a whole list at once.
# Expanding them here rather than at the point they are built is what keeps the
# methods identical in both modes.
#
# Operations are arrayrefs whose first element names the kind:
#
#     [ 'section', $name, $type, \@kv ]  create a named section and set its
#                                        options, list values being arrayrefs
#     [ 'del_section', $name ]           delete a named section
#     [ 'get_section', $name ]           probe for a named section
#     [ 'set_list', $name, $opt, \@v ]   replace a list option wholesale
#     [ 'reorder', \@names ]             move sections to the front, in order
#     [ 'commit' ]                       write the staged changes out
#     [ 'exec', $command, @params ]      run a command
#
# The deletes and the delete half of set_list use uci -q, as they are also used
# on setups that may be partly or wholly gone already and an "Entry not found"
# on stderr would be noise rather than information.
#
# Args:
#
#     ops - An arrayref of operations in the form above. An unrecognised kind
#           is skipped rather than erroring, as the only source of operations
#           is this module.
#
# Returns the command lines as a list of strings, ready to hand to the runner.
# One operation may produce several, so the returned list is generally longer
# than the one passed in.
#
#     $self->_render_local( [ [ 'exec', 'fw4', 'reload' ] ] );
#     #   fw4 reload
#
#     $self->_render_local( [ [ 'commit' ] ] );
#     #   uci commit firewall
#
#     $self->_render_local( [ [ 'section', 'kur_ssh_4', 'ipset',
#         [ [ 'family', 'ipv4' ], [ 'match', ['src_net'] ] ] ] ] );
#     #   uci set firewall.kur_ssh_4=ipset
#     #   uci set firewall.kur_ssh_4.family=ipv4
#     #   uci add_list firewall.kur_ssh_4.match=src_net
sub _render_local {
	my ( $self, $ops ) = @_;

	my @commands;
	foreach my $op ( @{$ops} ) {
		my $kind = $op->[0];

		if ( $kind eq 'section' ) {
			my ( undef, $name, $type, $kv ) = @{$op};
			push( @commands, 'uci set ' . $self->_shell_quote( 'firewall.' . $name . '=' . $type ) );
			foreach my $pair ( @{$kv} ) {
				my ( $option, $value ) = @{$pair};
				if ( ref($value) eq 'ARRAY' ) {
					foreach my $item ( @{$value} ) {
						push( @commands,
							'uci add_list '
								. $self->_shell_quote( 'firewall.' . $name . '.' . $option . '=' . $item ) );
					}
				} else {
					push( @commands,
						'uci set ' . $self->_shell_quote( 'firewall.' . $name . '.' . $option . '=' . $value ) );
				}
			} ## end foreach my $pair ( @{$kv} )
		} elsif ( $kind eq 'del_section' ) {
			push( @commands, 'uci -q delete ' . $self->_shell_quote( 'firewall.' . $op->[1] ) );
		} elsif ( $kind eq 'get_section' ) {
			push( @commands, 'uci -q get ' . $self->_shell_quote( 'firewall.' . $op->[1] ) );
		} elsif ( $kind eq 'del_option' ) {
			my ( undef, $name, $option ) = @{$op};
			push( @commands, 'uci -q delete ' . $self->_shell_quote( 'firewall.' . $name . '.' . $option ) );
		} elsif ( $kind eq 'set_list' ) {
			my ( undef, $name, $option, $values ) = @{$op};
			foreach my $item ( @{$values} ) {
				push( @commands,
					'uci add_list ' . $self->_shell_quote( 'firewall.' . $name . '.' . $option . '=' . $item ) );
			}
		} elsif ( $kind eq 'reorder' ) {
			my $index = 0;
			foreach my $name ( @{ $op->[1] } ) {
				push( @commands, 'uci reorder ' . $self->_shell_quote( 'firewall.' . $name . '=' . $index ) );
				$index++;
			}
		} elsif ( $kind eq 'commit' ) {
			push( @commands, 'uci commit firewall' );
		} elsif ( $kind eq 'exec' ) {
			my ( undef, @parts ) = @{$op};
			push( @commands, join( ' ', map { $self->_shell_quote($_) } @parts ) );
		}
	} ## end foreach my $op ( @{$ops} )

	return @commands;
} ## end sub _render_local

# Internal helper. Renders the abstract operations the methods build into ubus
# JSON-RPC calls.
#
# The operation forms are the ones documented on _render_local. Where that
# expands a section into several uci invocations this produces a single call,
# because the ubus uci object takes the whole set of values at once, and where
# that has to delete and rebuild a list this simply sets it, because a JSON
# array is a list.
#
# The set_list case does mean the ban list is sent in full on every commit
# rather than as a delta. That is intentional. There is no ubus equivalent of
# add_list, and the alternative of reading the list back, editing it, and
# writing it again would race with anything else touching the config for no
# gain, as commit is rare.
#
# Commands go through the file object's exec method, which needs rpcd-mod-file
# on the router and an ACL that allows the command. There is no shell involved,
# so the parameters are passed as a list rather than as a command line and
# nothing needs quoting.
#
# Args:
#
#     ops - An arrayref of operations, as described on _render_local. An
#           unrecognised kind is skipped.
#
# Returns the calls as a list of hashrefs, each with:
#
#     - object :: the ubus object to call, 'uci' or 'file'
#     - method :: the method on it
#     - params :: a hashref of the arguments
#
# These are what the testing paths record, rather than the full JSON-RPC
# envelope, as the envelope adds only a request id and the session token and
# neither is worth asserting on. The session token in particular never appears,
# which is what keeps the credential out of the test data.
#
#     $self->_render_remote( [ [ 'commit' ] ] );
#     #   { object => 'uci', method => 'commit',
#     #     params => { config => 'firewall' } }
#
#     $self->_render_remote( [ [ 'exec', 'fw4', 'reload' ] ] );
#     #   { object => 'file', method => 'exec',
#     #     params => { command => 'fw4', params => ['reload'] } }
#
#     $self->_render_remote( [ [ 'section', 'kur_ssh_4', 'ipset',
#         [ [ 'family', 'ipv4' ], [ 'match', ['src_net'] ] ] ] ] );
#     #   { object => 'uci', method => 'add',
#     #     params => { config => 'firewall', type => 'ipset',
#     #                 name => 'kur_ssh_4',
#     #                 values => { family => 'ipv4', match => ['src_net'] } } }
sub _render_remote {
	my ( $self, $ops ) = @_;

	my @calls;
	foreach my $op ( @{$ops} ) {
		my $kind = $op->[0];

		if ( $kind eq 'section' ) {
			my ( undef, $name, $type, $kv ) = @{$op};
			my %values;
			foreach my $pair ( @{$kv} ) {
				$values{ $pair->[0] } = $pair->[1];
			}
			push(
				@calls,
				{
					object => 'uci',
					method => 'add',
					params => { config => 'firewall', type => $type, name => $name, values => \%values },
				}
			);
		} elsif ( $kind eq 'del_section' ) {
			push(
				@calls,
				{
					object => 'uci',
					method => 'delete',
					params => { config => 'firewall', section => $op->[1] },
				}
			);
		} elsif ( $kind eq 'get_section' ) {
			push(
				@calls,
				{
					object => 'uci',
					method => 'get',
					params => { config => 'firewall', section => $op->[1] },
				}
			);
		} elsif ( $kind eq 'del_option' ) {
			my ( undef, $name, $option ) = @{$op};
			push(
				@calls,
				{
					object => 'uci',
					method => 'delete',
					params => { config => 'firewall', section => $name, option => $option },
				}
			);
		} elsif ( $kind eq 'set_list' ) {
			my ( undef, $name, $option, $values ) = @{$op};
			push(
				@calls,
				{
					object => 'uci',
					method => 'set',
					params => { config => 'firewall', section => $name, values => { $option => $values } },
				}
			);
		} elsif ( $kind eq 'reorder' ) {
			push(
				@calls,
				{
					object => 'uci',
					method => 'order',
					params => { config => 'firewall', sections => $op->[1] },
				}
			);
		} elsif ( $kind eq 'commit' ) {
			push(
				@calls,
				{
					object => 'uci',
					method => 'commit',
					params => { config => 'firewall' },
				}
			);
		} elsif ( $kind eq 'exec' ) {
			my ( undef, $command, @params ) = @{$op};
			push(
				@calls,
				{
					object => 'file',
					method => 'exec',
					params => { command => $command, params => \@params },
				}
			);
		} ## end elsif ( $kind eq 'exec' )
	} ## end foreach my $op ( @{$ops} )

	return @calls;
} ## end sub _render_remote

# Internal helper. Posts one JSON-RPC envelope to the router's ubus endpoint
# and hands back the result, doing no interpretation of what the result means.
#
# LWP::UserAgent is loaded with require on first use and the agent is cached on
# the object, so a run that never touches remote mode never loads it and the
# dist keeps it as a recommends rather than a hard prereq. HTTPS additionally
# needs LWP::Protocol::https, which LWP loads itself.
#
# This deliberately takes the session as an argument instead of fetching it,
# because it is what the login call itself goes through and there is no session
# at that point. Callers other than _session pass what _session returns.
#
# Errors are raised by dying rather than through Error::Helper, as this sits
# below the methods and they wrap their calls in eval so that a transport
# failure comes out as the error for the operation the caller asked for.
#
# Args:
#
#     session - The ubus session token, as a string. The all zeroes token is
#               what an unauthenticated call, meaning the login, uses.
#
#     object  - The ubus object to call, as a string, such as 'uci' or 'file'.
#
#     method  - The method on that object, as a string.
#
#     params  - A hashref of arguments for the method. Pass an empty hashref
#               rather than undef for a method that takes none.
#
# Returns the JSON-RPC result, which for a ubus call is a two element arrayref
# of the ubus status code and, for the calls that return anything, a hashref of
# the returned data. Note that a non-zero status is returned rather than raised;
# deciding what to do about it is _run_rpc's job. A result of [0] with no second
# element is normal for the calls that return no data.
#
# Dies on a transport level failure: LWP not being installed, a non-2xx HTTP
# status, a body that is not JSON, or a JSON-RPC error object in the response.
#
#     my $result = $self->_rpc_raw( $session, 'uci', 'commit',
#         { config => 'firewall' } );
#     #   [ 0 ]
#
#     my $result = $self->_rpc_raw( $session, 'file', 'exec',
#         { command => 'fw4', params => ['reload'] } );
#     #   [ 0, { code => 0, stdout => '', stderr => '' } ]
sub _rpc_raw {
	my ( $self, $session, $object, $method, $params ) = @_;

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
		} or die( 'failed to load LWP::UserAgent, which the openwrt backend requires in remote mode... ' . $@ );
	} ## end if ( !defined( $self->{ua} ) )

	my $url
		= $self->{options}{http_proto} . '://' . $self->{options}{host} . ':' . $self->{options}{http_port} . '/ubus';

	my $body = $self->_json->encode(
		{
			jsonrpc => '2.0',
			id      => 1,
			method  => 'call',
			params  => [ $session, $object, $method, $params ],
		}
	);

	require HTTP::Request;
	my $request = HTTP::Request->new( 'POST', $url, [ 'Content-Type' => 'application/json' ], $body );

	my $response = $self->{ua}->request($request);

	if ( !$response->is_success ) {
		die( 'POST ' . $url . ' failed... HTTP status... ' . $response->status_line );
	}

	my $decoded;
	{
		local $@;
		eval { $decoded = $self->_json->decode( $response->decoded_content ); };
		if ($@) {
			die( 'POST ' . $url . ' returned a body that is not JSON... ' . $@ );
		}
	}

	if ( defined( $decoded->{error} ) ) {
		die(      'ubus '
				. $object . '.'
				. $method
				. ' returned a JSON-RPC error... '
				. $self->_json->encode( $decoded->{error} ) );
	}

	if ( ref( $decoded->{result} ) ne 'ARRAY' ) {
		die( 'ubus ' . $object . '.' . $method . ' returned no result array' );
	}

	return $decoded->{result};
} ## end sub _rpc_raw

# Internal helper. Returns a ubus session token, logging in if there is not
# already a usable one cached on the object.
#
# ubus sessions expire, five minutes after the last use by default, which a
# long lived banning process will certainly outlive. Rather than track the
# expiry, the token is cached and used until something rejects it, at which
# point _run_rpc clears it and asks for another, so a re-login only happens
# when one is actually needed.
#
# Takes no arguments; the credentials come from the user and password options.
#
# Returns the session token as a string, suitable to pass to _rpc_raw.
#
# Dies if the login fails, either at the transport level or by ubus refusing
# the credentials, and on a login that succeeds but hands back no token.
#
#     my $session = $self->_session;
#     #   a 32 character hex string
sub _session {
	my ($self) = @_;

	return $self->{session} if ( defined( $self->{session} ) );

	my $result = $self->_rpc_raw(
		'00000000000000000000000000000000',
		'session',
		'login',
		{
			username => $self->{options}{user},
			password => $self->{options}{password},
		}
	);

	if ( $result->[0] != 0 ) {
		die( 'ubus login as "' . $self->{options}{user} . '" failed with ubus status ' . $result->[0] );
	}

	my $session = $result->[1]{ubus_rpc_session};
	if ( !defined($session) ) {
		die('ubus login succeeded but returned no ubus_rpc_session');
	}

	$self->{session} = $session;

	return $session;
} ## end sub _session

# Internal helper. Runs one rendered remote call and reports whether it worked,
# which is the remote half of what _run does per operation.
#
# Two layers of failure have to be unpicked. The ubus status code says whether
# the call itself was accepted, and for file.exec a zero status only means the
# command was started, so the exit code inside the returned data has to be
# checked as well or a failing nft would look like a success.
#
# A permission denied is retried once with a fresh session. That status is what
# an expired session comes back as, and re-logging in is cheap, so the retry
# turns what would otherwise be a spurious failure every five idle minutes into
# a non-event. A second permission denied is a real one and is reported.
#
# Args:
#
#     call - One call hashref as produced by _render_remote, with object,
#            method, and params keys.
#
# Returns a two element list of a boolean for whether it succeeded and the
# output as a string. The output is the command's stdout with its stderr
# appended for a file.exec, and the JSON encoded returned data for anything
# else, so that a failure has something to report and check has something to
# match against. A call that dies at the transport level comes back as a
# failure whose output is the exception.
#
#     my ( $ok, $output ) = $self->_run_rpc(
#         { object => 'file', method => 'exec',
#           params => { command => 'nft', params => [ 'list', 'ruleset' ] } } );
sub _run_rpc {
	my ( $self, $call ) = @_;

	my $result;
	my $tries = 0;
	while ( $tries < 2 ) {
		$tries++;

		local $@;
		eval { $result = $self->_rpc_raw( $self->_session, $call->{object}, $call->{method}, $call->{params} ); };
		if ($@) {
			return ( 0, $@ );
		}

		# an expired session comes back as permission denied, so drop it and
		# try once more with a fresh one
		if ( $result->[0] == 6 && $tries < 2 ) {
			$self->{session} = undef;
			next;
		}

		last;
	} ## end while ( $tries < 2 )

	if ( $result->[0] != 0 ) {
		return ( 0, 'ubus status ' . $result->[0] );
	}

	my $data = $result->[1];

	if ( $call->{object} eq 'file' && $call->{method} eq 'exec' ) {
		my $output = '';
		$output .= $data->{stdout} if ( defined( $data->{stdout} ) );
		$output .= $data->{stderr} if ( defined( $data->{stderr} ) );
		return ( ( defined( $data->{code} ) && $data->{code} == 0 ) ? 1 : 0, $output );
	}

	return ( 1, defined($data) ? $self->_json->encode($data) : '' );
} ## end sub _run_rpc

# Internal helper. Renders a list of abstract operations for whichever mode the
# backend is in, runs them unless this is a test, and reports any failure
# through Error::Helper.
#
# Every method goes through here rather than running anything itself, which is
# what keeps them free of the local versus remote split: they build operations,
# hand them over, and store what comes back in test_data when testing.
#
# Nothing is run at all in testing mode. The rendered operations are still
# returned, so a test asserts on exactly what would have been done, in the form
# the mode under test would have done it in: command line strings locally,
# call hashrefs remotely.
#
# Args:
#
#     ops - An arrayref of abstract operations, as described on _render_local.
#
#     %args - The rest, all optional:
#
#         error  - The error number to raise if an operation fails. Leaving
#                  this out, or passing 0, makes the whole batch best effort,
#                  which is what the stale state cleanup at init and the
#                  deletes at teardown want, as they are routinely run against
#                  a setup that is already partly gone.
#
#         action - The word naming the operation in the error string, such as
#                  'init' or 'ban'. Only used when error is set.
#
#         tolerate - A regexp. A failed operation whose output matches it is
#                  treated as having succeeded. This is for the failures that
#                  mean the caller's goal was already met rather than that
#                  something went wrong, specifically nft reporting "element
#                  does not exist" when unbanning something the set has
#                  already lost. Unlike leaving error out, this only forgives
#                  the matching failure and still raises on everything else.
#
# Returns a two element list of an arrayref of the rendered operations and an
# arrayref of their outputs. The outputs are in the same order and are empty in
# testing mode. Note that with errors being fatal by default, a failure raised
# here does not return at all.
#
#     my ( $rendered, $outputs ) = $self->_run(
#         [ [ 'exec', 'fw4', 'reload' ] ], error => 23, action => 'init' );
#
#     # best effort, failures ignored
#     my ($rendered) = $self->_run( [ [ 'del_section', $section ] ] );
sub _run {
	my ( $self, $ops, %args ) = @_;

	my @rendered
		= defined( $self->{options}{host} )
		? $self->_render_remote($ops)
		: $self->_render_local($ops);

	my @outputs;

	if ( !$self->{testing} ) {
		foreach my $item (@rendered) {
			my ( $ok, $output );
			if ( defined( $self->{options}{host} ) ) {
				( $ok, $output ) = $self->_run_rpc($item);
			} else {
				$output = `$item 2>&1`;
				$ok     = ( $? == 0 ) ? 1 : 0;
			}
			push( @outputs, $output );

			# a failure the caller said to expect is not a failure
			if ( !$ok && $args{tolerate} && defined($output) && $output =~ $args{tolerate} ) {
				$ok = 1;
			}

			if ( !$ok && $args{error} ) {
				$self->{error} = $args{error};
				$self->{errorString}
					= $args{action}
					. ' failed. the operation... "'
					. $self->_describe($item)
					. '"... failed... output... '
					. $output;
				$self->warn;
			} ## end if ( !$ok && $args{error} )
		} ## end foreach my $item (@rendered)
	} ## end if ( !$self->{testing} )

	return ( \@rendered, \@outputs );
} ## end sub _run

# Internal helper. Turns a rendered operation back into something printable, so
# that an error string can say which one failed regardless of the mode.
#
# A locally rendered operation is already a command line string and is returned
# as is. A remotely rendered one is a hashref, so it is encoded as JSON, which
# keeps the object, method, and arguments legible in one line.
#
# Args:
#
#     item - One rendered operation, either a string from _render_local or a
#            hashref from _render_remote.
#
# Returns a single line string describing it.
#
#     $self->_describe('uci commit firewall');
#     #   uci commit firewall
#
#     $self->_describe( { object => 'uci', method => 'commit',
#                         params => { config => 'firewall' } } );
#     #   {"method":"commit","object":"uci","params":{"config":"firewall"}}
sub _describe {
	my ( $self, $item ) = @_;

	return $item if ( ref($item) eq '' );

	return $self->_json->encode($item);
}

=head2 init

Initiates the backend. A best effort delete of this instance's UCI sections
is run first to clear any stale copy of them, then the two C<config ipset>
sections and the C<config rule> sections are created, the rules are moved to
the front of the config unless the C<reorder> option says otherwise, the
changes are committed via L</commit>, and C<fw4 reload> is run to bring the
new ruleset up.

Existing bans are not re-applied here. See L</re_init> for that.

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

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = {};
	}

	my @ipsets = $self->_ipset_sections;
	my ($rules) = $self->_rule_specs;

	# stale state cleanup, allowed to fail
	my @fail_okay_ops;
	foreach my $section ( @{$rules}, @ipsets ) {
		push( @fail_okay_ops, [ 'del_section', $section->{name} ] );
	}

	my ($fail_okay_rendered) = $self->_run( \@fail_okay_ops );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data}{fail_okay_commands} = $fail_okay_rendered;
	}

	my @ops;
	foreach my $section ( @ipsets, @{$rules} ) {
		push( @ops, [ 'section', $section->{name}, $section->{type}, $section->{kv} ] );
	}

	if ( $self->{options}{reorder} && @{$rules} ) {
		push( @ops, [ 'reorder', [ map { $_->{name} } @{$rules} ] ] );
	}

	my ($rendered) = $self->_run( \@ops, error => 23, action => 'init' );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data}{commands} = $rendered;
	}

	$self->commit;
	my ($reload) = $self->_run( [ [ 'exec', 'fw4', 'reload' ] ], error => 23, action => 'init' );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data}{reload} = $reload;
	}

	$self->{inited} = 1;
} ## end sub init

=head2 commit

Writes the current ban list into the UCI ipset sections and commits the
staged firewall config to persistent storage.

Banning and unbanning only touch the live nftables sets, so a ban is in
effect the moment it is made but does not survive a firewall restart or a
reboot. This is what makes it survive. It is separate, and not run
automatically, because C<uci commit> writes to the overlay filesystem, which
on most OpenWrt devices is flash; committing per ban would wear it out. Call
it as often as the durability of the ban list warrants and no more.

L</init> and L</teardown> call this themselves, as both change the config and
would otherwise leave it staged and unwritten.

Note that L</flush> does not commit, so the emptied ban list is not persisted
until this is called.

This is the only backend that implements this method.

    $fw_helper->ban(ban => '1.2.3.4');
    $fw_helper->ban(ban => '5.6.7.8');
    $fw_helper->commit;

=cut

sub commit {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	my ( $base, $set4, $set6 ) = $self->_names;

	my ( $v4, $v6 ) = $self->_entry_lists;

	# clearing the old list out is best effort, as there is no entry option at
	# all until a commit has written one and ubus reports deleting an option
	# that is not there as a failure
	my @clear_ops = ( [ 'del_option', $set4, 'entry' ], [ 'del_option', $set6, 'entry' ], );

	my ($cleared) = $self->_run( \@clear_ops );

	# a family with no bans is left with no entry option rather than an empty
	# one, as ubus rejects an empty list outright
	my @ops;
	push( @ops, [ 'set_list', $set4, 'entry', $v4 ] ) if ( @{$v4} );
	push( @ops, [ 'set_list', $set6, 'entry', $v6 ] ) if ( @{$v6} );
	push( @ops, ['commit'] );

	my ($rendered) = $self->_run( \@ops, error => 31, action => 'commit' );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data}{commit} = [ @{$cleared}, @{$rendered} ];
	}

	return;
} ## end sub commit

# Internal helper. Writes the staged UCI changes out without touching the
# entry lists first, which is the half of commit that teardown wants.
#
# teardown deletes this instance's sections and then has to make that stick,
# but it can not go through commit to do it. commit's first job is to write
# the ban list into the ipset sections, and by that point those sections are
# gone, so it would be setting an option on something that no longer exists.
# ubus reports that as a plain failure and the teardown dies having already
# removed the config it was committing.
#
# The ban list is deliberately not cleared to make commit safe to call here
# instead. teardown keeps the bans so that a following re_init can put them
# back, which is the documented behaviour and what the frontend's self healing
# relies on.
#
# Args:
#
#     error  - The error number to raise if the commit fails, passed straight
#              through to _run. Callers pass their own so the failure is
#              reported as theirs.
#
#     action - The word naming the operation in the error string, likewise
#              passed through.
#
# Returns the rendered operations as an arrayref, the single commit, so that a
# caller in testing mode can record it.
#
#     my $committed = $self->_commit_config( 17, 'teardown' );
sub _commit_config {
	my ( $self, $error, $action ) = @_;

	my ($rendered) = $self->_run( [ ['commit'] ], error => $error, action => $action );

	return $rendered;
}

=head2 ban

Bans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then added to the family-appropriate set via
C<nft add element>. If the C<kill> option is set, conntrack(8) is then used
to drop existing connection tracking entries for the IP. Banning an already
banned IP is a noop.

The UCI config is not touched and nothing is committed, so the ban is in
effect immediately but is lost by a firewall restart or a reboot until
L</commit> is called.

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

	my @ops = ( $self->_element_op( 'add', $opts{ban} ) );
	push( @ops, $self->_kill_ops( $opts{ban} ) );

	my ($rendered) = $self->_run( \@ops, error => 13, action => 'ban' );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $rendered;
	}

	$self->{banned}{ $opts{ban} } = 1;
} ## end sub ban

=head2 unban

Unbans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then removed from the family-appropriate set via
C<nft delete element>. Unbanning an IP that is not banned is a noop.

As with L</ban>, nothing is committed; call L</commit> to persist the change.

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

	my ($rendered) = $self->_run(
		[ $self->_element_op( 'delete', $opts{ban} ) ],
		error    => 14,
		action   => 'unban',
		tolerate => qr/does not exist/,
	);

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $rendered;
	}

	delete( $self->{banned}{ $opts{ban} } );
} ## end sub unban

=head2 ban_cidr

Bans a CIDR range by adding it to the family-appropriate set via
C<nft add element>. The value of ban is validated as being a IPv4 or IPv6
CIDR range and lowercased. Banning an already banned range is a noop.

The sets are interval sets, so ranges share the sets the single IP bans use
and need no separate setup. Host bits do not need zeroing; nftables takes the
range as given.

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
		$self->{error}       = 28;
		$self->{errorString} = 'Bad ref type for ban... ref is "' . ref( $opts{ban} ) . '"';
		$self->warn;
		return;
	} elsif ( !$self->_valid_cidr( $opts{ban} ) ) {
		$self->{error}       = 28;
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

	my ($rendered) = $self->_run( [ $self->_element_op( 'add', $opts{ban} ) ], error => 26, action => 'ban_cidr' );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $rendered;
	}

	$self->{banned_cidr}{ $opts{ban} } = 1;
} ## end sub ban_cidr

=head2 unban_cidr

Unbans a CIDR range by removing it from the family-appropriate set via
C<nft delete element>. The value of ban is validated as being a IPv4 or IPv6
CIDR range and lowercased. Unbanning a range that is not banned is a noop.

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
		$self->{error}       = 28;
		$self->{errorString} = 'Bad ref type for ban... ref is "' . ref( $opts{ban} ) . '"';
		$self->warn;
		return;
	} elsif ( !$self->_valid_cidr( $opts{ban} ) ) {
		$self->{error}       = 28;
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

	my ($rendered) = $self->_run(
		[ $self->_element_op( 'delete', $opts{ban} ) ],
		error    => 27,
		action   => 'unban_cidr',
		tolerate => qr/does not exist/,
	);

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $rendered;
	}

	delete( $self->{banned_cidr}{ $opts{ban} } );
} ## end sub unban_cidr

# Internal helper. Returns the operation that adds an address or range to, or
# removes it from, the live nftables set it belongs in.
#
# Everything that changes what is blocked goes through here, which is what
# keeps ban, unban, ban_cidr, unban_cidr, and re_init all producing the same
# command shape and all agreeing on which set an item belongs in.
#
# The set lives in fw4's own inet fw4 table rather than in a table of this
# backend's own, because it was fw4 that created it from the UCI ipset section.
# That is also why the element is added rather than the config being changed:
# the config only comes into it at commit time.
#
# The braces are kept in one parameter rather than being split out as their
# own. Locally that renders as a single quoted argument, which is legible and
# safe, and remotely it is passed to nft as one argv entry, which nft joins
# with the rest before parsing anyway.
#
# Args:
#
#     action - 'add' or 'delete'. Passed to nft as is, so anything else would
#              be an nft syntax error rather than caught here.
#
#     item   - The address or range, as a plain string. Expected to be already
#              validated and lowercased. The family picks the set.
#
# Returns one exec operation, ready to put in a list for _run.
#
#     $self->_element_op( 'add', '10.0.0.1' );
#     #   local:  nft add element inet fw4 kur_ssh_4 '{ 10.0.0.1 }'
#     #   remote: file.exec nft
#     #           [ add, element, inet, fw4, kur_ssh_4, "{ 10.0.0.1 }" ]
#
#     $self->_element_op( 'delete', '2001:db8::/32' );
#     #   local:  nft delete element inet fw4 kur_ssh_6 '{ 2001:db8::/32 }'
sub _element_op {
	my ( $self, $action, $item ) = @_;

	return [ 'exec', 'nft', $action, 'element', 'inet', 'fw4', $self->_set_for($item), '{ ' . $item . ' }' ];
}

# Internal helper. Returns the operations that tear down an IP's existing
# connections, or nothing at all when the kill option is off.
#
# The commands themselves come from Util's _kill_commands, which every
# conntrack using backend shares and which handles scoping the kill to the
# configured protocols and the address family. Those come back as command line
# strings, which suits the backends that only ever run things locally, so this
# splits them back into a command and its parameters for the abstract operation
# form both of this backend's modes are built on.
#
# Splitting on whitespace is safe because everything _kill_commands emits is
# option flags, protocol names, and an address, none of which can contain a
# space.
#
# Args:
#
#     ip - The address whose connections should be dropped, as a plain string.
#          Expected to be an already validated and lowercased IPv4 or IPv6
#          address. Only ever a single address; conntrack is not asked to drop
#          a whole range, so the CIDR methods do not call this.
#
# Returns the operations as a list, empty when the kill option is off and also
# when every configured protocol was one conntrack can not filter by.
#
#     # kill off
#     $self->_kill_ops('10.0.0.1');    # ()
#
#     # kill on, protocols tcp
#     $self->_kill_ops('10.0.0.1');
#     #   [ 'exec', 'conntrack', '-D', '-p', 'tcp', '-s', '10.0.0.1' ]
sub _kill_ops {
	my ( $self, $ip ) = @_;

	return () if ( !$self->{options}{kill} );

	my @ops;
	foreach my $command ( $self->_kill_commands($ip) ) {
		my @parts = split( /\s+/, $command );
		push( @ops, [ 'exec', @parts ] );
	}

	return @ops;
} ## end sub _kill_ops

=head2 list

List banned IPs. Returns an array of the currently banned single IPs from the
retained in-memory state; the sets are not queried. CIDR range bans are not
included; for those see L</list_cidr>.

    my @banned = $backend->list;

=cut

sub list {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = 'list';
	}

	return keys( %{ $self->{banned} } );
} ## end sub list

=head2 list_cidr

List banned CIDR ranges. Returns an array of the currently banned ranges from
the retained in-memory state; the sets are not queried.

    my @banned_cidrs = $backend->list_cidr;

=cut

sub list_cidr {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = 'list_cidr';
	}

	return keys( %{ $self->{banned_cidr} } );
} ## end sub list_cidr

=head2 re_init

Tears down and re-initiates the backend, recreating the UCI sections and
reloading fw4, then re-adds every previously banned IP and CIDR range to the
relevant set via C<nft add element>. The teardown is best effort as a
partially or fully wiped setup is exactly what this needs to recover from.

This is what recovers the live sets after a firewall restart or a reboot,
which empty them of everything that had not been committed.

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

	my @ops;
	foreach my $item ( sort( keys( %{ $self->{banned} } ) ), sort( keys( %{ $self->{banned_cidr} } ) ) ) {
		push( @ops, $self->_element_op( 'add', $item ) );
	}

	my ($rendered) = $self->_run( \@ops, error => 13, action => 're_init' );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $rendered;
	}

	$self->{inited} = 1;
} ## end sub re_init

=head2 teardown

Tears down the setup for the backend by deleting this instance's C<config
rule> and C<config ipset> sections, committing that, running C<fw4 reload> to
drop the rules, and then deleting the two sets outright.

The commit here is a bare one and does not go through L</commit>, as the
ipset sections the ban list would be written into have just been deleted. The
ban list itself is kept, so a following L</re_init> restores it.

The sets need deleting explicitly because C<fw4 reload> is incremental: it
removes the rules that are no longer in the config but leaves behind a set
whose C<config ipset> section has gone, so without this each teardown would
strand an orphaned set in the live ruleset. C<fw4 restart> would clear them,
but at the cost of emptying every other set in the table, including those of
any other instance sharing the router, so the sets are removed by name
instead. This is also why they are deleted after the reload rather than
before: nftables will not remove a set a rule still refers to.

The section deletes and the set deletes are best effort, as tearing down a
setup that is already partly gone is normal, but a failure to commit or to
reload is raised.

    $backend->teardown;

=cut

sub teardown {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{inited} = 0;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = {};
	}

	my @ipsets = $self->_ipset_sections;
	my ($rules) = $self->_rule_specs;

	my @ops;
	foreach my $section ( @{$rules}, @ipsets ) {
		push( @ops, [ 'del_section', $section->{name} ] );
	}

	my ($rendered) = $self->_run( \@ops );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data}{fail_okay_commands} = $rendered;
	}

	my $committed = $self->_commit_config( 17, 'teardown' );
	my ($reload) = $self->_run( [ [ 'exec', 'fw4', 'reload' ] ], error => 17, action => 'teardown' );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data}{commit} = $committed;
		$self->{frontend_obj}->{test_data}{reload} = $reload;
	}

	# the reload has taken the rules, so nothing refers to the sets any more
	# and they can be removed; best effort, as they are already gone after a
	# firewall restart or if init never got as far as creating them
	my ( $base, $set4, $set6 ) = $self->_names;
	my ($dropped) = $self->_run(
		[
			[ 'exec', 'nft', 'delete', 'set', 'inet', 'fw4', $set4 ],
			[ 'exec', 'nft', 'delete', 'set', 'inet', 'fw4', $set6 ],
		]
	);

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data}{drop_sets} = $dropped;
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

Verifies that the setup is still intact, at the config level, the runtime
level, and the contents level. The UCI sections for each set the rules use,
and for every rule, are probed; fw4's table is listed and checked for each of
those sets being both defined and referenced by a rule; and any set whose
family currently has bans is confirmed to actually hold something. Returns a
true value if all of that holds and a false value if any of it does not. This
is the equivalent of fail2ban's C<actioncheck>.

Checking the contents as well is what catches the case that matters most
here. An C<fw4 restart>, an C<< /etc/init.d/firewall restart >>, or a reboot
empties the sets of everything that was not committed, while leaving the
config and the rules perfectly intact, so nothing but the emptiness gives it
away. Only emptiness is treated as broken, not a mismatch against the ban
list, because nftables merges and splits the intervals in an interval set and
what comes back is often not what went in.

An C<fw4 reload>, as opposed to a restart, preserves set contents and so is
not something this needs to catch.

    if ( !$backend->check ) {
        $backend->re_init;
    }

=cut

sub check {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	my ( $base, $set4, $set6 ) = $self->_names;

	my ( $rules, $referenced ) = $self->_rule_specs;

	my @sets = sort( keys( %{$referenced} ) );

	# which families currently have something that ought to be in their set,
	# so that an emptied set can be told from a legitimately empty one
	my ( $v4, $v6 ) = $self->_entry_lists;
	my %expected = ( $set4 => scalar( @{$v4} ), $set6 => scalar( @{$v6} ) );

	my @ops;
	foreach my $set (@sets) {
		push( @ops, [ 'get_section', $set ] );
	}
	foreach my $section ( @{$rules} ) {
		push( @ops, [ 'get_section', $section->{name} ] );
	}
	push( @ops, [ 'exec', 'nft', 'list', 'table', 'inet', 'fw4' ] );

	if ( $self->{testing} ) {
		my ($rendered) = $self->_run( \@ops );
		$self->{frontend_obj}->{test_data} = $rendered;
		return 1;
	}

	my @rendered
		= defined( $self->{options}{host} )
		? $self->_render_remote( \@ops )
		: $self->_render_local( \@ops );

	# everything but the table listing is a presence probe, where a failure is
	# the whole answer and there is nothing to read
	my $listing = pop(@rendered);

	foreach my $item (@rendered) {
		my $ok;
		if ( defined( $self->{options}{host} ) ) {
			($ok) = $self->_run_rpc($item);
		} else {
			my $output = `$item 2>&1`;
			$ok = ( $? == 0 ) ? 1 : 0;
		}
		return 0 if ( !$ok );
	} ## end foreach my $item (@rendered)

	my ( $ok, $output );
	if ( defined( $self->{options}{host} ) ) {
		( $ok, $output ) = $self->_run_rpc($listing);
	} else {
		$output = `$listing 2>&1`;
		$ok     = ( $? == 0 ) ? 1 : 0;
	}
	return 0 if ( !$ok );

	foreach my $set (@sets) {
		# the set itself, then a rule matching against it
		return 0 if ( $output !~ /\bset\s+\Q$set\E\s*\{(.*?)\n\t\}/s );
		my $body = $1;
		return 0 if ( $output !~ /\@\Q$set\E\b/ );

		# a set that should hold bans but holds nothing was emptied out from
		# under us, which is what a firewall restart or a reboot does
		if ( $expected{$set} && $body !~ /\belements\s*=/ ) {
			return 0;
		}
	} ## end foreach my $set (@sets)

	return 1;
} ## end sub check

=head2 flush

Removes all currently banned IPs and CIDR ranges at once by flushing both
sets, leaving the UCI config and the rules in place. This is the equivalent
of fail2ban's C<actionflush>.

Nothing is committed, so the emptied list is not persisted until L</commit>
is called.

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

	my ( $base, $set4, $set6 ) = $self->_names;

	my @ops = (
		[ 'exec', 'nft', 'flush', 'set', 'inet', 'fw4', $set4 ],
		[ 'exec', 'nft', 'flush', 'set', 'inet', 'fw4', $set6 ],
	);

	my ($rendered) = $self->_run( \@ops, error => 25, action => 'flush' );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $rendered;
	}

	$self->{banned}      = {};
	$self->{banned_cidr} = {};
} ## end sub flush

=head1 ERROR CODES / FLAGS

Error handling is provided by L<Error::Helper>. All
errors are considered fatal.

=head2 1, notInited

The backend has not been inited yet.

=head2 2, invalidPortSpecified

Port is either not an int within the range 1 to 65535 or a name that can be resolved by getservbyname.

=head2 3, portsNotArray

The data passed to new for ports is not an array.

=head2 4, protocolsNotArray

The data passed to new for protocols is not an array.

=head2 5, invalidPortSpecified

Port is either not an int within the range 1 to 65535 or a name that can be resolved by getservbyname.

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

=head2 20, typeInvalid

The option type is not "drop" or "reject".

=head2 21, nameTooLong

The prefix and name joined by an underscore come to more than 250 characters,
which does not leave room for the set and rule name suffixes within the
nftables identifier limit.

=head2 23, initFailed

One of the required operations for init failed.

=head2 24, checkFailed

The backend check raised an error.

=head2 25, flushFailed

Failed to flush the bans.

=head2 26, banCidrFailed

Failed to ban the CIDR range.

=head2 27, unbanCidrFailed

Failed to unban the CIDR range.

=head2 28, cidrItemNotCidr

The item to ban is not a CIDR range. Either wrong ref type or it is not an
IPv4 or IPv6 address followed by a prefix length valid for its family.

=head2 29, cidrNotSupported

The backend does not support CIDR bans. Unused here, as this backend does.

=head2 30, listCidrFailed

Failed to get a list of CIDR bans.

=head2 31, commitFailed

Failed to write the ban list out or to commit the staged UCI config.

=head2 32, invalidHost

The option host does not match /^[a-zA-Z0-9_.\-\[\]:]+$/.

=head2 33, noPassword

The option host is set, putting the backend in remote mode, but no password
was given.

=head2 34, invalidZone

The option zone does not match /^[a-zA-Z0-9_*\-]+$/.

=head2 35, invalidHttpPort

The option http_port is not an int within the range 1 to 65535.

=head2 36, invalidHttpProto

The option http_proto is not "http" or "https".

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.ent> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-firewall-blockerhelper at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Firewall-BlockerHelper>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999


=cut

1;    # End of Net::Firewall::BlockerHelper
