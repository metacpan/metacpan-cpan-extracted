package Monitoring::Sneck::Checks::thermal_throttle;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';
use File::Slurp qw(read_file);

=head1 NAME

Monitoring::Sneck::Checks::thermal_throttle - checks for CPUs being thermally throttled

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# Where the CPUs are in sysfs. Set by tests.
our $CPU_DIR = '/sys/devices/system/cpu';

=head1 SYNOPSIS

    thermal_throttle|perl:thermal_throttle
    thermal_throttle_laptop|perl:thermal_throttle -w 100 -c 1000

=head1 DESCRIPTION

Counts the thermal throttle events since the last run, from the
counters Linux keeps under /sys/devices/system/cpu/cpu*/thermal_throttle
for Intel CPUs. By default any is WARNING.

There are core and package counters. Hyperthreads of a core share its
counters, and every CPU in a package shows the package's, so they are
counted once each, going by the topology under each CPU. --warning and
--critical go by the worse of the two.

The counters are kept in a state file, see
L<Monitoring::Sneck::Checks::base/read_state>, so the first run, and
the first after a reboot, have nothing to compare to and are OK. The
counts since boot are said as well.

The milliseconds throttled are said when the kernel has the
*_throttle_total_time_ms counters.

- CRITICAL :: New core or package events over --critical.

- WARNING :: New core or package events over --warning.

- UNKNOWN :: Not being Linux, or the state not being readable or
writable.

- OK :: Everything else, including having no counters, as with AMD CPUs
and most VMs, so the same check can go everywhere.

=head1 OPTIONS

- -w, --warning :: Range for the new core or package events.
Default :: 0

- -c, --critical :: Range for the new core or package events.

=cut

sub option_spec { return ( 'warning|w=s', 'critical|c=s' ) }

sub defaults { return { warning => '0' } }

sub ranges { return ( 'warning', 'critical' ) }

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	die( 'not supported on ' . $self->os . "\n" ) if $self->os ne 'linux';

	# a counter or topology file, as a number, or undef if it is not there
	my $read = sub {
		my $content = read_file( $_[0], err_mode => 'quiet' );
		return undef if !defined($content);
		return $content =~ /\A\s*([0-9]+)\s*\z/ ? $1 : undef;
	};

	# each core and package only once, the first CPU of it seen
	my %cores;
	my %packages;
	opendir( my $dh, $CPU_DIR ) or return $self->finish( $self->OK, 'no thermal throttle counters' );
	foreach my $cpu ( grep { /\Acpu[0-9]+\z/ } readdir($dh) ) {
		my $throttle = $CPU_DIR . '/' . $cpu . '/thermal_throttle';
		next if !-d $throttle;
		my $package = $read->( $CPU_DIR . '/' . $cpu . '/topology/physical_package_id' ) // $cpu;
		my $core    = $read->( $CPU_DIR . '/' . $cpu . '/topology/core_id' )             // $cpu;
		$cores{ $package . ':' . $core } //= {
			count => $read->( $throttle . '/core_throttle_count' ),
			ms    => $read->( $throttle . '/core_throttle_total_time_ms' ),
		};
		$packages{$package} //= {
			count => $read->( $throttle . '/package_throttle_count' ),
			ms    => $read->( $throttle . '/package_throttle_total_time_ms' ),
		};
	} ## end foreach my $cpu ( grep { /\Acpu[0-9]+\z/ } readdir...)
	return $self->finish( $self->OK, 'no thermal throttle counters' ) if !%cores;

	# the count and ms of all cores or packages, ms being undef if any lacks it, as on older kernels
	my $add_up = sub {
		my ($counters) = @_;
		my $count      = 0;
		my $ms         = 0;
		foreach my $counter ( values( %{$counters} ) ) {
			$count = $count + ( $counter->{count} // 0 );
			$ms    = ( defined($ms) && defined( $counter->{ms} ) ) ? $ms + $counter->{ms} : undef;
		}
		return ( $count, $ms );
	}; ## end $add_up = sub
	my %now;
	( $now{core_count},    $now{core_ms} )    = $add_up->( \%cores );
	( $now{package_count}, $now{package_ms} ) = $add_up->( \%packages );

	my $file  = $Monitoring::Sneck::Checks::base::STATE_DIR . '/thermal_throttle.json';
	my $state = $self->read_state($file);
	return $self->finish( $self->UNKNOWN, 'can not read the state in ' . $file ) if !defined($state);
	my $problem = $self->write_state( $file, \%now );
	return $self->finish( $self->UNKNOWN, $problem ) if defined($problem);

	my $since_boot = $now{core_count} . ' core and ' . $now{package_count} . ' package';

	# lower counts than last time is a reboot, so starts over
	if (   !defined( $state->{core_count} )
		|| $now{core_count} < $state->{core_count}
		|| $now{package_count} < ( $state->{package_count} // 0 ) )
	{
		return $self->finish( $self->OK, 'first check, ' . $since_boot . ' throttle events since boot' );
	}

	my %new;
	foreach my $name ( 'core_count', 'package_count', 'core_ms', 'package_ms' ) {
		next if !defined( $now{$name} ) || !defined( $state->{$name} );
		$new{$name} = $now{$name} - $state->{$name};
		$new{$name} = $now{$name} if $new{$name} < 0;
	}

	my $code = $self->worst(
		$self->threshold_status( $new{core_count},    $self->opt('warning'), $self->opt('critical') ),
		$self->threshold_status( $new{package_count}, $self->opt('warning'), $self->opt('critical') )
	);
	foreach my $name ( 'core', 'package' ) {
		$self->perfdata(
			label    => $name . '_events',
			value    => $new{ $name . '_count' },
			warning  => $self->opt('warning'),
			critical => $self->opt('critical'),
			min      => 0,
		);
		$self->perfdata( label => $name . '_time', value => $new{ $name . '_ms' }, uom => 'ms', min => 0 )
			if defined( $new{ $name . '_ms' } );
	} ## end foreach my $name ( 'core', 'package' )

	my @parts
		= ( $new{core_count} . ' core and ' . $new{package_count} . ' package throttle events since the last check' );
	if ( defined( $new{core_ms} ) && defined( $new{package_ms} ) ) {
		push( @parts, $new{core_ms} . ' ms and ' . $new{package_ms} . ' ms throttled' );
	}
	push( @parts, $since_boot . ' since boot' );

	return $self->finish( $code, join( ', ', @parts ) );
} ## end sub check

1;
