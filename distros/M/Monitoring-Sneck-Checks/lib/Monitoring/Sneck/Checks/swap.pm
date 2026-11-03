package Monitoring::Sneck::Checks::swap;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';
use Time::HiRes ();

=head1 NAME

Monitoring::Sneck::Checks::swap - checks how much swap is used

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# Where swapinfo is on FreeBSD. Set by tests.
our $SWAPINFO = '/usr/sbin/swapinfo';

# The codes --no-swap takes.
our %NO_SWAP_CODES = ( ok => 0, warning => 1, critical => 2, unknown => 3 );

=head1 SYNOPSIS

    swap|perl:swap
    swap_tight|perl:swap -w 20 -c 50 -n critical
    swapping|perl:swap -W 100 -C 1000

=head1 DESCRIPTION

Checks the percent of swap used, across every swap device. On Linux it
is read from /proc/meminfo. On FreeBSD it is from running swapinfo, as
the sysctl it keeps it in is not one L<BSD::Sysctl> reads. Other OSes
are UNKNOWN.

Having no swap is OK, unless --no-swap says otherwise, as plenty of
hosts run without it on purpose.

Swap being used but sitting there is harmless, while swapping all the
time is not. --rate-warning and --rate-critical check the pages
swapped in and out per second since the last run, from pswpin and
pswpout in /proc/vmstat on Linux, and v_swappgsin and v_swappgsout
through L<BSD::Sysctl> on FreeBSD. The counts are kept in a state file,
see L<Monitoring::Sneck::Checks::base/read_state>, so the first run, or
one after a reboot, has no rate. They are only kept and checked if one
of those is given.

=head1 OPTIONS

- -w, --warning :: Range of percent used.
Default :: 80

- -c, --critical :: Range of percent used.
Default :: 90

- -n, --no-swap :: What having no swap is, ok, warning, critical, or
unknown.
Default :: ok

- -W, --rate-warning :: Range of pages swapped in and out per second.

- -C, --rate-critical :: Range of pages swapped in and out per second.

=cut

sub option_spec { return ( 'warning|w=s', 'critical|c=s', 'no-swap|n=s', 'rate-warning|W=s', 'rate-critical|C=s' ) }

sub defaults { return { warning => '80', critical => '90', 'no-swap' => 'ok' } }

sub ranges { return ( 'warning', 'critical', 'rate-warning', 'rate-critical' ) }

sub validate {
	my ( $self, $options ) = @_;

	return ( '--no-swap must be ' . join( ', ', sort( keys(%NO_SWAP_CODES) ) ) )
		if !defined( $NO_SWAP_CODES{ lc( $options->{'no-swap'} ) } );

	return ();
}

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	my ( $total,     $used )      = $self->swap;
	my ( $rate_code, $rate_text ) = $self->rate_status;
	if ( !$total ) {
		return $self->finish( $self->worst( $NO_SWAP_CODES{ lc( $self->opt('no-swap') ) }, $rate_code ),
			'no swap' . $rate_text );
	}

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
	my $code = $self->worst( $self->threshold_status( $percent, $self->opt('warning'), $self->opt('critical') ),
		$rate_code );

	return $self->finish( $code,
			  $percent
			. '% used, '
			. sprintf( '%.0f', $used / 1048576 ) . ' of '
			. sprintf( '%.0f', $total / 1048576 ) . ' MiB'
			. $rate_text );
} ## end sub check

=head2 rate_status

Works out the pages swapped per second since the last run, if
--rate-warning or --rate-critical is given, saving the counts for the
next, and adds its perfdata.

Returns the code and text to add to the message, OK and '' if not
checked or there is no rate yet. Dies if the state can not be kept.

=cut

sub rate_status {
	my ($self) = @_;

	my ( $warning, $critical ) = ( $self->opt('rate-warning'), $self->opt('rate-critical') );
	return ( $self->OK, '' ) if !defined($warning) && !defined($critical);

	my ( $in, $out ) = $self->swap_counts;
	my $file    = $Monitoring::Sneck::Checks::base::STATE_DIR . '/swap.json';
	my $state   = $self->read_state($file) // {};
	my $now     = Time::HiRes::time;
	my $problem = $self->write_state( $file, { time => $now, in => $in, out => $out } );
	die( $problem . "\n" ) if defined($problem);

	# a lower count than last time is a reboot, so starts over
	return ( $self->OK, ', no swap rate yet' )
		if !defined( $state->{time} )
		|| $now <= $state->{time}
		|| $in <  ( $state->{in}  // 0 )
		|| $out < ( $state->{out} // 0 );
	my $seconds  = $now - $state->{time};
	my $in_rate  = sprintf( '%.1f', ( $in - $state->{in} ) / $seconds );
	my $out_rate = sprintf( '%.1f', ( $out - $state->{out} ) / $seconds );
	my $total    = sprintf( '%.1f', $in_rate + $out_rate );
	$self->perfdata( label => 'swap_in',  value => $in_rate,  min     => 0 );
	$self->perfdata( label => 'swap_out', value => $out_rate, min     => 0 );
	$self->perfdata( label => 'swapping', value => $total,    warning => $warning, critical => $critical, min => 0 );

	return (
		$self->threshold_status( $total, $warning, $critical ),
		', swapping ' . $in_rate . ' pages/s in and ' . $out_rate . ' out'
	);
} ## end sub rate_status

=head2 swap_counts

Returns the pages swapped in and out since boot. Dies if they can not
be found.

=cut

sub swap_counts {
	my ($self) = @_;

	if ( $self->os eq 'linux' ) {
		my %vmstat = $self->proc_file('vmstat') =~ /^(\w+) ([0-9]+)$/mg;
		die("no pswpin and pswpout in /proc/vmstat\n") if !defined( $vmstat{pswpin} ) || !defined( $vmstat{pswpout} );
		return ( $vmstat{pswpin}, $vmstat{pswpout} );
	}
	if ( $self->os eq 'freebsd' ) {
		return ( $self->sysctl('vm.stats.vm.v_swappgsin'), $self->sysctl('vm.stats.vm.v_swappgsout') );
	}

	die( 'not supported on ' . $self->os . "\n" );
} ## end sub swap_counts

=head2 swap

Returns the bytes of swap in total and used. Dies if they can not be
found.

=cut

sub swap {
	my ($self) = @_;

	if ( $self->os eq 'linux' ) {
		my %meminfo = $self->proc_file('meminfo') =~ /^(\w+):\s+([0-9]+)/mg;
		die("no SwapTotal in meminfo\n") if !defined( $meminfo{SwapTotal} );
		return ( $meminfo{SwapTotal} * 1024, ( $meminfo{SwapTotal} - ( $meminfo{SwapFree} // 0 ) ) * 1024 );
	}
	if ( $self->os eq 'freebsd' ) {
		return $self->swapinfo;
	}

	die( 'not supported on ' . $self->os . "\n" );
} ## end sub swap

=head2 swapinfo

Runs swapinfo -k and adds up its devices. Dies if it fails.

Returns the bytes of swap in total and used.

=cut

sub swapinfo {
	my ($self) = @_;

	my ( $exit, $output ) = $self->run_command( $SWAPINFO, '-k' );
	die( $SWAPINFO . ' exited ' . $exit . "\n" ) if $exit;
	my @lines = split( /\n/, $output );

	# Device 1K-blocks Used Avail Capacity, with a Total line after more than one device
	my ( $total, $used ) = ( 0, 0 );
	foreach my $line (@lines) {
		my ( $device, $blocks, $device_used ) = split( /\s+/, $line );
		next if !defined($device_used) || $device eq 'Device' || $device eq 'Total' || $blocks !~ /\A[0-9]+\z/;
		$total += $blocks;
		$used  += $device_used;
	}

	return ( $total * 1024, $used * 1024 );
} ## end sub swapinfo

1;
