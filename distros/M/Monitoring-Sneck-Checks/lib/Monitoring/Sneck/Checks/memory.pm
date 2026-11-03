package Monitoring::Sneck::Checks::memory;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';

=head1 NAME

Monitoring::Sneck::Checks::memory - checks how much memory is used

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    memory|perl:memory
    memory_zfs|perl:memory -a -w 85 -c 95

=head1 DESCRIPTION

Checks the percent of memory used, which is what is not available to
start new programs with. On Linux that is MemAvailable from
/proc/meminfo, or MemFree, Buffers, and Cached added up on kernels
without it. On FreeBSD it is the free and inactive pages, through
L<BSD::Sysctl>. Other OSes are UNKNOWN.

The ZFS ARC counts as used on both, as the kernel does not count it as
available, though most of it can be given back. --arc counts what it
holds over its minimum as available.

=head1 OPTIONS

- -w, --warning :: Range of percent used.
Default :: 90

- -c, --critical :: Range of percent used.
Default :: 95

- -a, --arc :: Count the ZFS ARC over its minimum as available.

=cut

sub option_spec { return ( 'warning|w=s', 'critical|c=s', 'arc|a' ) }

sub defaults { return { warning => '90', critical => '95' } }

sub ranges { return ( 'warning', 'critical' ) }

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	my ( $total, $available ) = $self->memory;
	$available = $available + $self->arc_spare if $self->opt('arc');
	$available = $total                        if $available > $total;
	my $used    = $total - $available;
	my $percent = sprintf( '%.1f', $used / $total * 100 );

	$self->perfdata(
		label    => 'used',
		value    => $percent,
		uom      => '%',
		warning  => $self->opt('warning'),
		critical => $self->opt('critical'),
		min      => 0,
		max      => 100
	);
	$self->perfdata( label => 'used_bytes', value => $used, uom => 'B', min => 0, max => $total );
	my $code = $self->threshold_status( $percent, $self->opt('warning'), $self->opt('critical') );

	return $self->finish( $code,
			  $percent
			. '% used, '
			. _mib($used) . ' of '
			. _mib($total) . ' MiB'
			. ( $self->opt('arc') ? ', ARC over its minimum as available' : '' ) );
} ## end sub check

=head2 memory

Returns the bytes of memory in total and available. Dies if they can
not be found.

=cut

sub memory {
	my ($self) = @_;

	if ( $self->os eq 'linux' ) {
		my %meminfo = $self->proc_file('meminfo') =~ /^(\w+):\s+([0-9]+)/mg;
		die("no MemTotal in meminfo\n") if !$meminfo{MemTotal};
		my $available = $meminfo{MemAvailable}
			// ( ( $meminfo{MemFree} // 0 ) + ( $meminfo{Buffers} // 0 ) + ( $meminfo{Cached} // 0 ) );
		return ( $meminfo{MemTotal} * 1024, $available * 1024 );
	}
	if ( $self->os eq 'freebsd' ) {
		my $page_size = $self->sysctl('hw.pagesize');
		my $pages     = $self->sysctl('vm.stats.vm.v_free_count') + $self->sysctl('vm.stats.vm.v_inactive_count');
		return ( $self->sysctl('hw.physmem'), $pages * $page_size );
	}

	die( 'not supported on ' . $self->os . "\n" );
} ## end sub memory

=head2 arc_spare

Returns the bytes the ZFS ARC holds over its minimum, 0 if there is no
ARC.

=cut

sub arc_spare {
	my ($self) = @_;

	my ( $size, $minimum );
	if ( $self->os eq 'linux' ) {
		my $arcstats = eval { $self->proc_file('spl/kstat/zfs/arcstats') } // '';
		($size)    = $arcstats =~ /^size\s+\d+\s+([0-9]+)/m;
		($minimum) = $arcstats =~ /^c_min\s+\d+\s+([0-9]+)/m;
	} elsif ( $self->os eq 'freebsd' ) {
		$size    = eval { $self->sysctl('kstat.zfs.misc.arcstats.size') };
		$minimum = eval { $self->sysctl('kstat.zfs.misc.arcstats.c_min') };
	}
	return 0 if !defined($size) || !defined($minimum) || $size <= $minimum;

	return $size - $minimum;
} ## end sub arc_spare

# Turns bytes into whole MiB.
#
# Args...
#
#     - bytes :: The number of bytes.
#
# Returns the MiB, rounded.
#
# Example...
#
#     _mib(1073741824);    # 1024
sub _mib {
	return sprintf( '%.0f', $_[0] / 1048576 );
}

1;
