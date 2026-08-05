package Net::Firewall::BlockerHelper::backends::bgp_rtbh;

use 5.006;
use strict;
use warnings;
use base 'Error::Helper';
use Regexp::IPv4 qw($IPv4_re);
use Regexp::IPv6 qw($IPv6_re);

=head1 NAME

Net::Firewall::BlockerHelper::backends::bgp_rtbh - BGP Remote Triggered Black Hole backend (via ExaBGP, GoBGP, or FRR).

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 SYNOPSIS

    use Net::Firewall::BlockerHelper;

    my $fw_helper = Net::Firewall::BlockerHelper->new(
        backend => 'bgp_rtbh',
        name    => 'rtbh',
        options => {
            next_hop  => '192.0.2.1',
            community => '65535:666',
        },
    );

    $fw_helper->init_backend;
    $fw_helper->ban( ban => '1.2.3.4' );
    $fw_helper->unban( ban => '1.2.3.4' );
    $fw_helper->teardown;

=head1 DESCRIPTION

Blocks IPs with BGP Remote Triggered Black Holing. Rather than filtering
locally, each banned IP is announced to the network as a host route
(C<< /32 >> for IPv4, C<< /128 >> for IPv6) carrying the well-known
BLACKHOLE community (C<65535:666>, RFC 7999). Upstream routers that honor it
then drop the traffic, moving the drop off this host and, with a transit
provider that accepts blackhole announcements, off the local link entirely.

Announcements are driven through one of three drivers, selected with the
C<driver> option: ExaBGP's C<exabgpcli> (the default), C<gobgp>, or C<frr>.
The exabgp and gobgp drivers talk to a running daemon that holds the BGP
session(s) to the routers, while the frr driver injects a blackhole static
route via C<vtysh> for a running bgpd to redistribute. This backend does not
manage that session, it only announces and withdraws routes.

Whether the announced prefix blackholes the traffic's B<source> or
B<destination> depends on the receiving router: destination based RTBH drops
traffic toward the prefix, while source based RTBH (loose uRPF plus the
blackhole community) drops traffic B<from> it. As this tool bans attacker
source addresses, a source based RTBH setup is the usual pairing.

Requires the configured driver's binary in the C<PATH> (C<exabgpcli>,
C<gobgp>, or C<vtysh>) and a running, configured daemon behind it (C<exabgp>,
C<gobgpd>, or FRR's C<bgpd>).

=head1 METHODS

=head2 new

Initiates the object. Errors are fatal with this method.

    - options :: A hash of options. See below.
    - name :: Required by Net::Firewall::BlockerHelper, otherwise unused.

The options hash accepts the following.

    - driver :: Which BGP daemon to drive, 'exabgp', 'gobgp', or 'frr'. The
            frr driver injects a blackhole static route via vtysh (which a
            redistribute-static route-map on the router tags with the blackhole
            community for BGP); it does not use next_hop/community directly.
        - Default :: exabgp

    - announce_type :: 'rtbh' (announce a blackholed host route) or 'flowspec'
            (announce a FlowSpec rule discarding traffic from the source IP).
            flowspec is supported by the exabgp and gobgp drivers only.
        - Default :: rtbh

    - exabgpcli_cmd :: Path to the exabgpcli binary (driver 'exabgp').
        - Default :: exabgpcli

    - gobgp_cmd :: Path to the gobgp binary (driver 'gobgp').
        - Default :: gobgp

    - vtysh_cmd :: Path to the vtysh binary (driver 'frr').
        - Default :: vtysh

    - community :: BGP community attached to every announced route. The
            default is the RFC 7999 well-known BLACKHOLE community.
        - Default :: 65535:666

    - next_hop :: Next hop for IPv4 announcements. On the receiving router
            this is what maps to the discard interface.
        - Default :: 192.0.2.1

    - next_hop6 :: Next hop for IPv6 announcements.
        - Default :: 100::1

    - mask4 :: Prefix length used for IPv4 announcements.
        - Default :: 32

    - mask6 :: Prefix length used for IPv6 announcements.
        - Default :: 128

    - extra :: Optional extra attributes appended verbatim to each announce.
            The syntax is driver specific (exabgp 'local-preference 50' vs
            gobgp 'local-pref 50').
        - Default :: undef

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
				20 => 'driverInvalid',
				21 => 'announceTypeInvalid',
				24 => 'checkFailed',
				25 => 'flushFailed',
				26 => 'banCidrFailed',
				27 => 'unbanCidrFailed',
				28 => 'cidrItemNotCidr',
				29 => 'cidrNotSupported',
				30 => 'listCidrFailed',
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
	};
	bless $self;

	if ( defined( $opts{testing} ) ) {
		$self->{testing} = $opts{testing};
	}
	if ( defined( $opts{frontend_obj} ) ) {
		$self->{frontend_obj} = $opts{frontend_obj};
	}
	if ( defined( $opts{prefix} ) ) {
		$self->{prefix} = $opts{prefix};
	}
	if ( defined( $opts{name} ) ) {
		$self->{name} = $opts{name};
	}

	if ( defined( $opts{options} ) && ref( $opts{options} ) ne 'HASH' ) {
		$self->{perror}      = 1;
		$self->{error}       = 8;
		$self->{errorString} = 'ref for options is "' . ref( $opts{options} ) . '" and not HASH';
		$self->warn;
	} elsif ( defined( $opts{options} ) ) {
		$self->{options} = $opts{options};
	}

	# defaults
	$self->{options}{driver}        = 'exabgp'    if ( !defined( $self->{options}{driver} ) );
	$self->{options}{announce_type} = 'rtbh'      if ( !defined( $self->{options}{announce_type} ) );
	$self->{options}{exabgpcli_cmd} = 'exabgpcli' if ( !defined( $self->{options}{exabgpcli_cmd} ) );
	$self->{options}{gobgp_cmd}     = 'gobgp'     if ( !defined( $self->{options}{gobgp_cmd} ) );
	$self->{options}{vtysh_cmd}     = 'vtysh'     if ( !defined( $self->{options}{vtysh_cmd} ) );
	$self->{options}{community}     = '65535:666' if ( !defined( $self->{options}{community} ) );
	$self->{options}{next_hop}      = '192.0.2.1' if ( !defined( $self->{options}{next_hop} ) );
	$self->{options}{next_hop6}     = '100::1'    if ( !defined( $self->{options}{next_hop6} ) );
	$self->{options}{mask4}         = 32          if ( !defined( $self->{options}{mask4} ) );
	$self->{options}{mask6}         = 128         if ( !defined( $self->{options}{mask6} ) );

	my %valid_drivers = ( exabgp => 1, gobgp => 1, frr => 1 );
	if ( !$valid_drivers{ $self->{options}{driver} } ) {
		$self->{perror}      = 1;
		$self->{error}       = 20;
		$self->{errorString} = 'driver is "' . $self->{options}{driver} . '" and not "exabgp", "gobgp", or "frr"';
		$self->warn;
	}

	if ( $self->{options}{announce_type} ne 'rtbh' && $self->{options}{announce_type} ne 'flowspec' ) {
		$self->{perror}      = 1;
		$self->{error}       = 21;
		$self->{errorString} = 'announce_type is "' . $self->{options}{announce_type} . '" and not "rtbh" or "flowspec"';
		$self->warn;
	} elsif ( $self->{options}{announce_type} eq 'flowspec' && $self->{options}{driver} eq 'frr' ) {
		# frr's vtysh driver only injects blackhole routes, not flowspec rules
		$self->{perror}      = 1;
		$self->{error}       = 21;
		$self->{errorString} = 'announce_type flowspec is not supported by the frr driver';
		$self->warn;
	}

	return $self;
} ## end sub new

# Internal helper. Builds the announce/withdraw command for the given verb
# ('announce' or 'withdraw') and IP, in the syntax of the configured driver
# (exabgp via exabgpcli or gobgp), picking the family-appropriate next
# hop and prefix length and attaching the blackhole community.
sub _route_command {
	my ( $self, $verb, $ip ) = @_;

	my $is_v4 = ( $ip =~ /\A$IPv4_re\z/ ) ? 1 : 0;
	my $mask  = $is_v4 ? $self->{options}{mask4}    : $self->{options}{mask6};
	my $nh    = $is_v4 ? $self->{options}{next_hop} : $self->{options}{next_hop6};
	my $extra = ( defined( $self->{options}{extra} ) && $self->{options}{extra} ne '' ) ? $self->{options}{extra} : '';
	my $prefix     = $ip . '/' . $mask;
	my $is_flowspec = ( $self->{options}{announce_type} eq 'flowspec' ) ? 1 : 0;

	if ( $self->{options}{driver} eq 'frr' ) {
		# frr injects a blackhole static route via vtysh; a redistribute-static
		# route-map on the router tags it with the blackhole community for BGP
		my $keyword = $is_v4 ? 'ip route' : 'ipv6 route';
		my $line = ( $verb eq 'announce' ? '' : 'no ' ) . $keyword . ' ' . $prefix . ' blackhole';
		return $self->{options}{vtysh_cmd} . " -c 'configure terminal' -c '" . $line . "'";
	}

	if ( $self->{options}{driver} eq 'gobgp' ) {
		my $op = ( $verb eq 'announce' ) ? 'add' : 'del';

		if ($is_flowspec) {
			# gobgp global rib add|del -a ipv4-flowspec match source <prefix> then discard
			my $afi = $is_v4 ? 'ipv4-flowspec' : 'ipv6-flowspec';
			return
				  $self->{options}{gobgp_cmd}
				. ' global rib '
				. $op
				. ' -a '
				. $afi
				. ' match source '
				. $prefix
				. ' then discard';
		} ## end if ($is_flowspec)

		# gobgp global rib add|del <prefix> [nexthop ..] [community ..] -a <afi>
		my $afi = $is_v4 ? 'ipv4' : 'ipv6';
		my $cmd = $self->{options}{gobgp_cmd} . ' global rib ' . $op . ' ' . $prefix;

		# a withdrawal matches on prefix alone; attributes are only needed to add
		if ( $op eq 'add' ) {
			$cmd .= ' nexthop ' . $nh . ' community ' . $self->{options}{community};
			$cmd .= ' ' . $extra if ( $extra ne '' );
		}
		$cmd .= ' -a ' . $afi;

		return $cmd;
	} ## end if ( $self->{options}{driver...})

	# exabgp driver; the command is passed single quoted as the braces and
	# semicolons of the flow syntax are shell syntax when left bare
	if ($is_flowspec) {
		# exabgpcli 'announce|withdraw flow route { match { source <prefix>; } then { discard; } }'
		return
			  $self->{options}{exabgpcli_cmd} . " '"
			. $verb
			. ' flow route { match { source '
			. $prefix
			. "; } then { discard; } }'";
	} ## end if ($is_flowspec)

	# exabgp rtbh: exabgpcli 'announce|withdraw route <prefix> next-hop .. community [..]'
	my $route
		= $verb
		. ' route '
		. $prefix
		. ' next-hop '
		. $nh
		. ' community [' . $self->{options}{community} . ']';
	$route .= ' ' . $extra if ( $extra ne '' );

	# single quoted so the community's [..] can not glob against the cwd
	return $self->{options}{exabgpcli_cmd} . " '" . $route . "'";
} ## end sub _route_command

# Internal helper. Like _route_command but for a CIDR range. The passed
# value is already an address/prefix, so it is announced/withdrawn verbatim
# rather than having a host mask appended, with the family determined from the
# address portion of the range.
sub _route_command_cidr {
	my ( $self, $verb, $cidr ) = @_;

	my $addr = ( $cidr =~ m!\A(.+)/[0-9]{1,3}\z! ) ? $1 : $cidr;
	my $is_v4 = ( $addr =~ /\A$IPv4_re\z/ ) ? 1 : 0;
	my $nh    = $is_v4 ? $self->{options}{next_hop} : $self->{options}{next_hop6};
	my $extra = ( defined( $self->{options}{extra} ) && $self->{options}{extra} ne '' ) ? $self->{options}{extra} : '';
	my $prefix      = $cidr;
	my $is_flowspec = ( $self->{options}{announce_type} eq 'flowspec' ) ? 1 : 0;

	if ( $self->{options}{driver} eq 'frr' ) {
		# frr injects a blackhole static route via vtysh; a redistribute-static
		# route-map on the router tags it with the blackhole community for BGP
		my $keyword = $is_v4 ? 'ip route' : 'ipv6 route';
		my $line = ( $verb eq 'announce' ? '' : 'no ' ) . $keyword . ' ' . $prefix . ' blackhole';
		return $self->{options}{vtysh_cmd} . " -c 'configure terminal' -c '" . $line . "'";
	}

	if ( $self->{options}{driver} eq 'gobgp' ) {
		my $op = ( $verb eq 'announce' ) ? 'add' : 'del';

		if ($is_flowspec) {
			# gobgp global rib add|del -a ipv4-flowspec match source <prefix> then discard
			my $afi = $is_v4 ? 'ipv4-flowspec' : 'ipv6-flowspec';
			return
				  $self->{options}{gobgp_cmd}
				. ' global rib '
				. $op
				. ' -a '
				. $afi
				. ' match source '
				. $prefix
				. ' then discard';
		} ## end if ($is_flowspec)

		# gobgp global rib add|del <prefix> [nexthop ..] [community ..] -a <afi>
		my $afi = $is_v4 ? 'ipv4' : 'ipv6';
		my $cmd = $self->{options}{gobgp_cmd} . ' global rib ' . $op . ' ' . $prefix;

		# a withdrawal matches on prefix alone; attributes are only needed to add
		if ( $op eq 'add' ) {
			$cmd .= ' nexthop ' . $nh . ' community ' . $self->{options}{community};
			$cmd .= ' ' . $extra if ( $extra ne '' );
		}
		$cmd .= ' -a ' . $afi;

		return $cmd;
	} ## end if ( $self->{options}{driver...})

	# exabgp driver; the command is passed single quoted as the braces and
	# semicolons of the flow syntax are shell syntax when left bare
	if ($is_flowspec) {
		# exabgpcli 'announce|withdraw flow route { match { source <prefix>; } then { discard; } }'
		return
			  $self->{options}{exabgpcli_cmd} . " '"
			. $verb
			. ' flow route { match { source '
			. $prefix
			. "; } then { discard; } }'";
	} ## end if ($is_flowspec)

	# exabgp rtbh: exabgpcli 'announce|withdraw route <prefix> next-hop .. community [..]'
	my $route
		= $verb
		. ' route '
		. $prefix
		. ' next-hop '
		. $nh
		. ' community [' . $self->{options}{community} . ']';
	$route .= ' ' . $extra if ( $extra ne '' );

	# single quoted so the community's [..] can not glob against the cwd
	return $self->{options}{exabgpcli_cmd} . " '" . $route . "'";
} ## end sub _route_command_cidr

# Internal helper. Returns the driver-appropriate command used by check to
# confirm the BGP daemon is reachable.
sub _check_command {
	my ($self) = @_;

	if ( $self->{options}{driver} eq 'frr' ) {
		return $self->{options}{vtysh_cmd} . " -c 'show ip bgp summary'";
	}
	if ( $self->{options}{driver} eq 'gobgp' ) {
		return $self->{options}{gobgp_cmd} . ' neighbor';
	}

	return $self->{options}{exabgpcli_cmd} . ' show neighbor summary';
} ## end sub _check_command

=head2 init

Initiates the backend. The BGP session is owned by the running BGP daemon
(exabgp, gobgpd, or FRR), so there is nothing to set up; this only flips the
inited flag.

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
		$self->{frontend_obj}->{test_data} = [];
	}

	$self->{inited} = 1;
} ## end sub init

=head2 ban

Bans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then announced via the configured driver: a
C<exabgpcli announce route> or C<gobgp global rib add> of the host route
(C<mask4>/C<mask6> prefix length) with the family-appropriate next hop and
the blackhole community, a FlowSpec discard rule when announce_type is
C<flowspec>, or a C<vtysh> injected blackhole static route for the frr
driver. Banning an already banned IP is a noop.

    $fw_helper->ban( ban => $ip );

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

	my $command = $self->_route_command( 'announce', $opts{ban} );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $command;
	} else {
		my $output = `$command 2>&1`;
		if ( $? != 0 ) {
			$self->{error} = 13;
			$self->{errorString}
				= 'ban failed. non-zero exit code for the command... "' . $command . '"... output... ' . $output;
			$self->warn;
		}
	}

	$self->{banned}{ $opts{ban} } = 1;
} ## end sub ban

=head2 unban

Unbans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then the route announced for it by L</ban> is withdrawn via
the configured driver (C<exabgpcli withdraw>, C<gobgp global rib del>, or a
C<vtysh> C<no ... blackhole> for frr). Unbanning an IP that is not banned is
a noop.

    $fw_helper->unban( ban => $ip );

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

	my $command = $self->_route_command( 'withdraw', $opts{ban} );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $command;
	} else {
		my $output = `$command 2>&1`;
		if ( $? != 0 ) {
			$self->{error} = 14;
			$self->{errorString}
				= 'unban failed. non-zero exit code for the command... "' . $command . '"... output... ' . $output;
			$self->warn;
		}
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

Bans a CIDR range. The value of ban is validated as being a IPv4 or IPv6
CIDR range and lowercased, then announced the same way L</ban> announces a
single IP, except the range is announced verbatim rather than having the
C<mask4>/C<mask6> host prefix length appended. Banning an already banned
range is a noop.

    $fw_helper->ban_cidr( ban => '1.2.3.0/24' );

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

	my $command = $self->_route_command_cidr( 'announce', $opts{ban} );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $command;
	} else {
		my $output = `$command 2>&1`;
		if ( $? != 0 ) {
			$self->{error} = 26;
			$self->{errorString}
				= 'ban failed. non-zero exit code for the command... "' . $command . '"... output... ' . $output;
			$self->warn;
		}
	}

	$self->{banned_cidr}{ $opts{ban} } = 1;
} ## end sub ban_cidr

=head2 unban_cidr

Unbans a CIDR range. The value of ban is validated as being a IPv4 or IPv6
CIDR range and lowercased, then the route announced for it by L</ban_cidr>
is withdrawn via the configured driver. Unbanning a range that is not banned
is a noop.

    $fw_helper->unban_cidr( ban => '1.2.3.0/24' );

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

	my $command = $self->_route_command_cidr( 'withdraw', $opts{ban} );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $command;
	} else {
		my $output = `$command 2>&1`;
		if ( $? != 0 ) {
			$self->{error} = 27;
			$self->{errorString}
				= 'unban failed. non-zero exit code for the command... "' . $command . '"... output... ' . $output;
			$self->warn;
		}
	}

	delete( $self->{banned_cidr}{ $opts{ban} } );
} ## end sub unban_cidr

=head2 list_cidr

List banned CIDR ranges. Returns an array of the currently banned ranges
from internal state; the BGP daemon is not queried.

    my @banned_cidrs = $fw_helper->list_cidr;

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
internal state; the BGP daemon is not queried. CIDR ranges are not included;
for those see L</list_cidr>.

    my @banned = $fw_helper->list;

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

Re-announces every retained blackhole route. A best effort teardown
(failures ignored) is done first, then the announce command is re-run for
every banned IP and CIDR range. The BGP daemons do not persist announced
state across restarts, so this is how the announcements are restored after
the daemon is bounced.

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

	# teardown is best effort; a session that already dropped the routes is
	# exactly what re_init is meant to recover from
	{
		local $@;
		eval { $self->teardown; };
	}
	$self->init;

	my @re_init_test_data;
	foreach my $item ( keys( %{ $self->{banned} } ) ) {
		my $command = $self->_route_command( 'announce', $item );
		if ( $self->{testing} ) {
			push( @re_init_test_data, $command );
		} else {
			my $output = `$command 2>&1`;
			if ( $? != 0 ) {
				$self->{error} = 13;
				$self->{errorString}
					= 'ban failed. non-zero exit code for the command... "' . $command . '"... output... ' . $output;
				$self->warn;
			}
		}
	} ## end foreach my $item ( keys( %{ ...}))

	foreach my $item ( keys( %{ $self->{banned_cidr} } ) ) {
		my $command = $self->_route_command_cidr( 'announce', $item );
		if ( $self->{testing} ) {
			push( @re_init_test_data, $command );
		} else {
			my $output = `$command 2>&1`;
			if ( $? != 0 ) {
				$self->{error} = 26;
				$self->{errorString}
					= 'ban failed. non-zero exit code for the command... "' . $command . '"... output... ' . $output;
				$self->warn;
			}
		}
	} ## end foreach my $item ( keys( %{ ...}))

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@re_init_test_data;
	}

	$self->{inited} = 1;
} ## end sub re_init

=head2 teardown

Withdraws every announced blackhole route, running the driver's withdraw
command for each banned IP and CIDR range, and marks the backend as not
inited. The ban list is retained, so L</re_init> can restore the
announcements.

=cut

sub teardown {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{inited} = 0;

	my @commands;
	foreach my $item ( keys( %{ $self->{banned} } ) ) {
		push( @commands, $self->_route_command( 'withdraw', $item ) );
	}
	foreach my $item ( keys( %{ $self->{banned_cidr} } ) ) {
		push( @commands, $self->_route_command_cidr( 'withdraw', $item ) );
	}

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@commands;
	} else {
		foreach my $item (@commands) {
			my $output = `$item 2>&1`;
			if ( $? != 0 ) {
				$self->{error} = 17;
				$self->{errorString}
					= 'teardown failed. non-zero exit code for the command... "' . $item . '"... output... ' . $output;
				$self->warn;
			}
		}
	} ## end else [ if ( $self->{testing} ) ]
} ## end sub teardown

=head2 stop

Alias for L</teardown>.

=cut

sub stop {
	my ( $self, %opts ) = @_;

	return $self->teardown(%opts);
}

=head2 check

Runs the driver's neighbor summary command (C<exabgpcli show neighbor
summary>, C<gobgp neighbor>, or C<vtysh -c 'show ip bgp summary'> for frr)
and treats a zero exit as healthy, returning 1, and 0 otherwise. This only
confirms the BGP daemon holding the announcements is reachable; whether the
sessions to the routers are up and the announcements accepted is not
checked.

=cut

sub check {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	my $command = $self->_check_command;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $command;
		return 1;
	}

	my $output = `$command 2>&1`;
	return $? == 0 ? 1 : 0;
} ## end sub check

=head2 flush

Removes all bans at once by running the driver's withdraw command for every
banned IP and CIDR range, then clearing the ban lists.

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

	my @commands;
	foreach my $item ( keys( %{ $self->{banned} } ) ) {
		push( @commands, $self->_route_command( 'withdraw', $item ) );
	}
	foreach my $item ( keys( %{ $self->{banned_cidr} } ) ) {
		push( @commands, $self->_route_command_cidr( 'withdraw', $item ) );
	}

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@commands;
	} else {
		foreach my $item (@commands) {
			my $output = `$item 2>&1`;
			if ( $? != 0 ) {
				$self->{error} = 25;
				$self->{errorString}
					= 'flush failed. non-zero exit code for the command... "' . $item . '"... output... ' . $output;
				$self->warn;
			}
		}
	} ## end else [ if ( $self->{testing} ) ]

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

=head2 20, driverInvalid

The driver option is not one of 'exabgp', 'gobgp', or 'frr'.

=head2 21, announceTypeInvalid

The announce_type is not 'rtbh' or 'flowspec', or flowspec was requested with
the frr driver, which does not support it.

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

The backend does not support CIDR bans.

=head2 30, listCidrFailed

Failed to get a list of CIDR bans.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.ent> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut

1;    # End of Net::Firewall::BlockerHelper::backends::bgp_rtbh
