package Monitoring::Sneck::Checks::bond;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';

=head1 NAME

Monitoring::Sneck::Checks::bond - checks link aggregation, bonding on Linux and lagg on FreeBSD

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# Where ifconfig is on FreeBSD. Set by tests.
our $IFCONFIG = '/sbin/ifconfig';

=head1 SYNOPSIS

    bond|perl:bond
    bond_uplink|perl:bond -b bond0 -m 2
    bond_lagg|perl:bond -b lagg0 -b lagg1

=head1 DESCRIPTION

Checks every bond and its members. A bond that lost a member keeps
passing traffic, and stays up as far as
L<Monitoring::Sneck::Checks::interface> can tell, so it tends to go
unseen till the last member goes too.

- CRITICAL :: A bond that is down, has no members up, or has fewer up
than --members. A bond given with --bond that is not there.

- WARNING :: A member that is not up, or with LACP, one that is up but
not aggregating, as happens when the switch port is not set up for it.
With LACP on Linux, there being no LACP partner at all.

- OK :: Everything else, including there being no bonds, unless --bond
says one should be there.

On Linux, bonds are read from /proc/net/bonding. A member is up if its
MII status is, and with 802.3ad, if it is in the active aggregator,
which the kernel only shows to root. On FreeBSD, laggs are read from
ifconfig -a. A member is up if its link is active, and with LACP, if it
is active, collecting, and distributing. Other OSes are UNKNOWN.

=head1 OPTIONS

- -b, --bond :: A bond that must be there, such as bond0 or lagg0. May
be given more than once.

- -m, --members :: How many members each bond must have up.

=cut

sub option_spec { return ( 'bond|b=s@', 'members|m=i' ) }

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	my @bonds
		= $self->os eq 'linux'   ? $self->linux_bonds
		: $self->os eq 'freebsd' ? $self->freebsd_bonds
		:                          die( 'not supported on ' . $self->os . "\n" );
	my %have = map { $_->{name} => 1 } @bonds;
	my @codes;
	my @parts;
	foreach my $name ( @{ $self->opt('bond') // [] } ) {
		next if $have{$name};
		push( @codes, $self->CRITICAL );
		push( @parts, $name . ' is not there' );
	}

	my $members_wanted = $self->opt('members') // 0;
	foreach my $bond (@bonds) {
		my @members  = @{ $bond->{members} };
		my @not_up   = grep { defined( $_->{problem} ) } @members;
		my $up_count = scalar(@members) - scalar(@not_up);
		$self->perfdata(
			label => $bond->{name} . ' members',
			value => $up_count,
			min   => 0,
			max   => scalar(@members)
		);

		my @says = ( $up_count . ' of ' . scalar(@members) . ' members up' );
		unshift( @says, 'down' ) if !$bond->{up};
		push( @says, 'wanted ' . $members_wanted ) if $up_count < $members_wanted;
		push( @says, map { $_->{name} . ' ' . $_->{problem} } @not_up );
		push( @says, $bond->{problem} ) if defined( $bond->{problem} );

		my $code = $self->OK;
		$code = $self->WARNING  if defined( $not_up[0] ) || defined( $bond->{problem} );
		$code = $self->CRITICAL if !$bond->{up} || !$up_count || $up_count < $members_wanted;
		push( @codes, $code );
		push( @parts, $bond->{name} . ' ' . $bond->{mode} . ' ' . join( ', ', @says ) );
	} ## end foreach my $bond (@bonds)
	return $self->finish( $self->OK, 'no bonds' ) if !defined( $parts[0] );

	return $self->finish( $self->worst(@codes), join( '; ', @parts ) );
} ## end sub check

=head2 linux_bonds

Returns the bonds under /proc/net/bonding, sorted by name, as hash refs
of...

- name :: The bond, such as bond0.

- mode :: What it is doing, such as 802.3ad or active-backup.

- up :: 1 if the bond itself is up, else 0.

- problem :: What is wrong with the bond as a whole though it is up,
such as having no LACP partner, or undef.

- members :: Array ref of hash refs of name and problem, why the member
is not counted as up, such as down, or undef if it is.

Bonding not being loaded is having no bonds.

=cut

sub linux_bonds {
	my ($self) = @_;

	my $bonding_dir = $Monitoring::Sneck::Checks::base::PROC . '/net/bonding';
	opendir( my $bonding, $bonding_dir ) or return ();
	my @names = sort( grep { !/\A\./ } readdir($bonding) );
	closedir($bonding);

	my @bonds;
	foreach my $name (@names) {
		# what is before the first "Slave Interface: " is about the bond, each after it about a member
		my ( $about_bond, @about_members ) = split( /^Slave Interface: /m, $self->proc_file( 'net/bonding/' . $name ) );

		# "fault-tolerance (active-backup)" and the like have the short name in parens, while
		# "IEEE 802.3ad Dynamic link aggregation" and the two load balancing ones have none
		my ($mode) = $about_bond =~ /^Bonding Mode: (.+?)\s*$/m;
		$mode //= 'unknown';
		if ( $mode =~ /\(([^)]+)\)/ ) {
			$mode = $1;
		} elsif ( $mode =~ /802\.3ad/ ) {
			$mode = '802.3ad';
		}
		my ($bond_status)       = $about_bond =~ /^MII Status: (.+?)\s*$/m;
		my ($active_aggregator) = $about_bond =~ /^Active Aggregator Info:\s*\n\s*Aggregator ID: ([0-9]+)/m;

		my @members;
		foreach my $about_member (@about_members) {
			my ($member_name)   = $about_member =~ /\A(\S+)/;
			my ($member_status) = $about_member =~ /^MII Status: (.+?)\s*$/m;
			my ($aggregator)    = $about_member =~ /^Aggregator ID: ([0-9]+)/m;
			$member_status //= 'unknown';

			my $problem;
			if ( $member_status ne 'up' ) {
				$problem = $member_status;
			} elsif ( defined($active_aggregator) && defined($aggregator) && $aggregator != $active_aggregator ) {
				$problem = 'not in the active aggregator';
			}
			push( @members, { name => $member_name, problem => $problem } );
		} ## end foreach my $about_member (@about_members)

		push(
			@bonds,
			{
				name    => $name,
				mode    => $mode,
				up      => ( $bond_status // '' ) eq 'up' ? 1 : 0,
				problem => $about_bond =~ /^\s*Partner Mac Address: 00:00:00:00:00:00\s*$/m
				? 'no LACP partner'
				: undef,
				members => \@members,
			}
		);
	} ## end foreach my $name (@names)

	return @bonds;
} ## end sub linux_bonds

=head2 freebsd_bonds

Returns the laggs ifconfig -a shows, sorted by name, as for
L</linux_bonds>. Dies if ifconfig fails.

=cut

sub freebsd_bonds {
	my ($self) = @_;

	my ( $exit, $output ) = $self->run_command( $IFCONFIG, '-a' );
	die( 'ifconfig -a exited ' . $exit . "\n" ) if $exit;

	# a interface is its name and a colon starting a line, then indented lines
	my %about;
	foreach my $about_interface ( split( /\n(?=\S)/, $output ) ) {
		$about{$1} = $about_interface if $about_interface =~ /\A(\S+?):/;
	}

	my @bonds;
	foreach my $name ( sort( keys(%about) ) ) {
		my ($protocol) = $about{$name} =~ /^\s+laggproto (\S+)/m;
		next if !defined($protocol);

		# such as "laggport: igb0 flags=1c<ACTIVE,COLLECTING,DISTRIBUTING>". Only LACP flags every
		# working port, failover flagging just the one in use, so the port's own link is gone by.
		my @members;
		while ( $about{$name} =~ /^\s+laggport: (\S+) flags=[0-9a-f]+<([^>]*)>/mg ) {
			my ( $port, $port_flags ) = ( $1, $2 );
			my ($link) = ( $about{$port} // '' ) =~ /^\s+status: (.+?)\s*$/m;

			my $problem;
			if ( defined($link) && $link ne 'active' ) {
				$problem = $link;
			} elsif ( $protocol eq 'lacp' && grep { $port_flags !~ /\b$_\b/ }
				( 'ACTIVE', 'COLLECTING', 'DISTRIBUTING' ) )
			{
				$problem = 'not aggregating';
			}
			push( @members, { name => $port, problem => $problem } );
		} ## end while ( $about{$name} =~ /^\s+laggport: (\S+) flags=[0-9a-f]+<([^>]*)>/mg)

		my ($flags)  = $about{$name} =~ /\A\S+ flags=[0-9a-f]+<([^>]*)>/;
		my ($status) = $about{$name} =~ /^\s+status: (.+?)\s*$/m;
		push(
			@bonds,
			{
				name    => $name,
				mode    => $protocol,
				up      => ( ( $flags // '' ) =~ /\bUP\b/ && ( $status // 'active' ) eq 'active' ) ? 1 : 0,
				problem => undef,
				members => \@members,
			}
		);
	} ## end foreach my $name ( sort( keys(%about) ) )

	return @bonds;
} ## end sub freebsd_bonds

1;
