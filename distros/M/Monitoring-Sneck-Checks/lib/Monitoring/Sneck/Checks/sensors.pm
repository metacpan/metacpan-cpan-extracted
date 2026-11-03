package Monitoring::Sneck::Checks::sensors;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';
use File::Slurp qw(read_file);

=head1 NAME

Monitoring::Sneck::Checks::sensors - checks temperatures, fans, and voltages

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# Where Linux's hwmon devices are. Set by tests.
our $HWMON = '/sys/class/hwmon';

# The hwmon sensor types, what their inputs are divided by, and their units.
our %TYPES = ( temp => [ 1000, 'C' ], fan => [ 1, 'RPM' ], in => [ 1000, 'V' ] );

=head1 SYNOPSIS

    sensors|perl:sensors
    cpu_temp|perl:sensors -s '^coretemp' -w 80 -c 90
    no_gpu|perl:sensors -x '^nouveau' -i

=head1 DESCRIPTION

On Linux, reads every temperature, fan, and voltage from
/sys/class/hwmon, so lm-sensors is not needed, and checks each against
the limits its chip gives, as well as its alarm and fault flags. With
--warning or --critical, temperatures are checked against those alone,
their alarm flags left out.

- temperatures :: At or over crit, or a crit alarm, is CRITICAL. At or
over max, or a max or plain alarm, is WARNING.

- fans :: Under min, or a alarm, is CRITICAL, as a fan that stopped is
one.

- voltages :: Outside of min and max, or a alarm, is WARNING.

A fault, a sensor that is broken or not hooked up, is UNKNOWN unless
--ignore-fault is given. A sensor that can not be read, such as on a
GPU that is powered down, is left out. Limits of 0 or less are taken
as not set, as some chips report them that way.

On FreeBSD, only temperatures are known, from dev.cpu.N.temperature,
with coretemp's tjmax as crit, and the ACPI thermal zones, with _CRT as
crit and _HOT as max, through L<BSD::Sysctl>. Other OSes are UNKNOWN,
as is finding no sensors.

On Linux each sensor is named by its chip and its label, such as
"coretemp Core 0", or its file, such as "nct6775 fan2". On FreeBSD they
are cpuN and tzN. Every one with a reading goes into the perfdata,
with what it is checked against as its ranges.

=head1 OPTIONS

- -s, --sensor :: A regex sensors names must match to be checked. May
be given more than once, matching any is enough.

- -x, --exclude :: A regex for sensors to leave out. May be given more
than once.

- -w, --warning :: Range of degrees C for temperatures, in place of
what the chips say.

- -c, --critical :: Range of degrees C for temperatures, in place of
what the chips say.

- -i, --ignore-fault :: Faults are OK.

=cut

sub option_spec { return ( 'sensor|s=s@', 'exclude|x=s@', 'warning|w=s', 'critical|c=s', 'ignore-fault|i' ) }

sub ranges { return ( 'warning', 'critical' ) }

sub validate {
	my ( $self, $options ) = @_;

	my @problems;
	foreach my $name ( 'sensor', 'exclude' ) {
		foreach my $regex ( @{ $options->{$name} // [] } ) {
			push( @problems, '--' . $name . ' "' . $regex . '" is not a valid regex' ) if !eval { qr/$regex/; 1 };
		}
	}

	return @problems;
} ## end sub validate

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	my @sensors = grep { $self->wanted( $_->{name} ) }
		( $self->os eq 'freebsd' ? $self->freebsd_sensors : $self->linux_sensors );
	if ( !defined( $sensors[0] ) ) {
		return $self->finish( $self->UNKNOWN, 'no sensors found' );
	}

	my @codes;
	my @problems;
	foreach my $sensor (@sensors) {
		my ( $code, $why ) = $self->sensor_status($sensor);
		push( @codes, $code );
		push( @problems, $sensor->{name} . ' ' . $why ) if $code != $self->OK;
		next if !defined( $sensor->{value} );
		my ( $warning, $critical ) = $self->perf_ranges($sensor);
		$self->perfdata(
			label    => $sensor->{name},
			value    => $sensor->{value},
			warning  => $warning,
			critical => $critical
		);
	} ## end foreach my $sensor (@sensors)

	my $message = scalar(@sensors) . ' sensors';
	$message = $message . ', ' . join( ', ', @problems ) if defined( $problems[0] );

	return $self->finish( $self->worst(@codes), $message );
} ## end sub check

=head2 perf_ranges

Returns the warning and critical ranges for a sensor's perfdata, as
it is checked under L</DESCRIPTION>. For a temperature, max and crit,
or --warning and --critical if given. For a fan, critical is under
min. For a voltage, warning is outside min to max. Any not known is
undef.

- sensor :: As for L</sensor_status>.

    my ( $warning, $critical ) = $check->perf_ranges( { type => 'fan', min => 300 } );
    # ( undef, '300:' )

=cut

sub perf_ranges {
	my ( $self, $sensor ) = @_;

	if ( $sensor->{type} eq 'temp' ) {
		return ( $self->opt('warning'), $self->opt('critical') ) if $self->user_limits;
		return ( $sensor->{max},        $sensor->{crit} );
	}
	if ( $sensor->{type} eq 'fan' ) {
		return ( undef, defined( $sensor->{min} ) ? $sensor->{min} . ':' : undef );
	}
	return ( undef, undef ) if !defined( $sensor->{min} ) && !defined( $sensor->{max} );

	return ( ( $sensor->{min} // '~' ) . ':' . ( $sensor->{max} // '' ), undef );
} ## end sub perf_ranges

=head2 user_limits

Returns 1 if --warning or --critical was given, so they are used for
temperatures in place of what the chips say.

=cut

sub user_limits {
	my ($self) = @_;

	return ( defined( $self->opt('warning') ) || defined( $self->opt('critical') ) ) ? 1 : 0;
}

=head2 wanted

Returns 1 if a sensor name is to be checked, as --sensor and --exclude
say, else 0.

=cut

sub wanted {
	my ( $self, $name ) = @_;

	my @want = @{ $self->opt('sensor') // [] };
	return 0 if defined( $want[0] ) && !grep { $name =~ /$_/ } @want;
	return 0 if grep                         { $name =~ /$_/ } @{ $self->opt('exclude') // [] };

	return 1;
}

=head2 sensor_status

Works out the status of a sensor, as said under L</DESCRIPTION>.

- sensor :: Hash ref of name, type, one of temp, fan, or in, value,
min, max, crit, any undef if not known, and alarm, max_alarm,
min_alarm, crit_alarm, and fault, each 1 if set.

Returns the code and why, or undef for why if OK.

=cut

sub sensor_status {
	my ( $self, $sensor ) = @_;

	my $value = $sensor->{value};
	my $unit  = $TYPES{ $sensor->{type} }[1];
	if ( $sensor->{fault} ) {
		return ( $self->OK,      undef ) if $self->opt('ignore-fault');
		return ( $self->UNKNOWN, 'has a fault' );
	}
	return ( $self->UNKNOWN, 'can not be read' ) if !defined($value);

	my $is = 'is ' . $value . ' ' . $unit;
	if ( $sensor->{type} eq 'temp' ) {
		if ( $self->user_limits ) {
			my $code = $self->threshold_status( $value, $self->opt('warning'), $self->opt('critical') );
			return ( $code, $code == $self->OK ? undef : $is );
		}
		return ( $self->CRITICAL, $is . ', crit is ' . $sensor->{crit} )
			if defined( $sensor->{crit} ) && $value >= $sensor->{crit};
		return ( $self->CRITICAL, $is . ', its crit alarm is set' ) if $sensor->{crit_alarm};
		return ( $self->WARNING,  $is . ', max is ' . $sensor->{max} )
			if defined( $sensor->{max} ) && $value >= $sensor->{max};
		return ( $self->WARNING, $is . ', its alarm is set' ) if $sensor->{max_alarm} || $sensor->{alarm};
	} elsif ( $sensor->{type} eq 'fan' ) {
		return ( $self->CRITICAL, $is . ', min is ' . $sensor->{min} )
			if defined( $sensor->{min} ) && $value < $sensor->{min};
		return ( $self->CRITICAL, $is . ', its alarm is set' ) if $sensor->{alarm} || $sensor->{min_alarm};
	} else {
		return ( $self->WARNING, $is . ', min is ' . $sensor->{min} )
			if defined( $sensor->{min} ) && $value < $sensor->{min};
		return ( $self->WARNING, $is . ', max is ' . $sensor->{max} )
			if defined( $sensor->{max} ) && $value > $sensor->{max};
		return ( $self->WARNING, $is . ', its alarm is set' )
			if $sensor->{alarm} || $sensor->{min_alarm} || $sensor->{max_alarm};
	}

	return ( $self->OK, undef );
} ## end sub sensor_status

=head2 linux_sensors

Returns the sensors under /sys/class/hwmon, as hash refs as taken by
L</sensor_status>.

=cut

sub linux_sensors {
	my ($self) = @_;

	my @sensors;
	opendir( my $hwmon, $HWMON ) or return ();
	foreach my $device ( sort( grep { /\Ahwmon[0-9]+\z/ } readdir($hwmon) ) ) {
		my $dir  = $HWMON . '/' . $device;
		my $chip = _read( $dir . '/name' ) // $device;
		opendir( my $files, $dir ) or next;
		my %inputs = map { /\A((temp|fan|in)([0-9]+))_input\z/ ? ( $1 => $2 ) : () } readdir($files);
		foreach my $sensor ( sort { _natural( $a, $b ) } keys(%inputs) ) {
			my $type    = $inputs{$sensor};
			my $divisor = $TYPES{$type}[0];
			my $read    = sub {
				my $value = _read( $dir . '/' . $sensor . '_' . $_[0] );
				return undef if !defined($value) || $value !~ /\A-?[0-9]+\z/;
				return $value / $divisor;
			};
			my %info = (
				name  => $chip . ' ' . ( _read( $dir . '/' . $sensor . '_label' ) // $sensor ),
				type  => $type,
				value => $read->('input'),
			);
			foreach my $limit ( 'min', 'max', 'crit' ) {
				my $value = $read->($limit);
				$info{$limit} = ( defined($value) && $value > 0 ) ? $value : undef;
			}
			foreach my $flag ( 'alarm', 'min_alarm', 'max_alarm', 'crit_alarm', 'fault' ) {
				$info{$flag} = ( _read( $dir . '/' . $sensor . '_' . $flag ) // 0 ) eq '1' ? 1 : 0;
			}
			# such as a GPU that is powered down, which lm-sensors shows as N/A
			next if !defined( $info{value} ) && !$info{fault};
			push( @sensors, \%info );
		} ## end foreach my $sensor ( sort { _natural( $a, $b ) ...})
	} ## end foreach my $device ( sort( grep { /\Ahwmon[0-9]+\z/...}))

	return @sensors;
} ## end sub linux_sensors

=head2 freebsd_sensors

Returns the temperatures FreeBSD knows through sysctl, as hash refs as
taken by L</sensor_status>.

=cut

sub freebsd_sensors {
	my ($self) = @_;

	my @sensors;
	my $cpus = eval { $self->sysctl('hw.ncpu') } // 0;
	foreach my $cpu ( 0 .. $cpus - 1 ) {
		my $value = _celsius( eval { $self->sysctl( 'dev.cpu.' . $cpu . '.temperature' ) } );
		next if !defined($value);
		push(
			@sensors,
			{
				name  => 'cpu' . $cpu,
				type  => 'temp',
				value => $value,
				crit  => _celsius( eval { $self->sysctl( 'dev.cpu.' . $cpu . '.coretemp.tjmax' ) } ),
			}
		);
	} ## end foreach my $cpu ( 0 .. $cpus - 1 )
	foreach my $zone ( 0 .. 31 ) {
		my $base  = 'hw.acpi.thermal.tz' . $zone;
		my $value = _celsius( eval { $self->sysctl( $base . '.temperature' ) } );
		last if !defined($value);
		push(
			@sensors,
			{
				name  => 'tz' . $zone,
				type  => 'temp',
				value => $value,
				crit  => _celsius( eval { $self->sysctl( $base . '._CRT' ) } ),
				max   => _celsius( eval { $self->sysctl( $base . '._HOT' ) } ),
			}
		);
	} ## end foreach my $zone ( 0 .. 31 )

	return @sensors;
} ## end sub freebsd_sensors

# Reads a sysfs file.
#
# Args...
#
#     - path :: The file.
#
# Returns its content without the trailing newline, or undef if it can
# not be read, as some sensors that are not there fail to read.
#
# Example...
#
#     _read('/sys/class/hwmon/hwmon0/name');    # 'coretemp'
sub _read {
	my ($path) = @_;

	my $content = read_file( $path, err_mode => 'quiet' );
	return undef if !defined($content);
	$content =~ s/\s+\z//;

	return $content;
}

# Turns a FreeBSD temperature sysctl into degrees C. They may come as
# text, such as '45.0C', as deci-Kelvin, as for IK sysctls read raw, or
# as degrees C already. -1, which ACPI uses for not set, is undef.
#
# Args...
#
#     - value :: The value, or undef.
#
# Returns the degrees C, rounded to a tenth, or undef.
#
# Example...
#
#     _celsius('45.0C');    # 45.0
#     _celsius(3181);       # 45.0
sub _celsius {
	my ($value) = @_;

	return undef if !defined($value) || $value !~ /\A(-?[0-9]+(?:\.[0-9]+)?)C?\z/;
	$value = $1;
	return undef                  if $value <= 0;
	$value = $value / 10 - 273.15 if $value > 1000;

	return sprintf( '%.1f', $value ) + 0;
} ## end sub _celsius

# Compares sensor file names so temp2 comes before temp10.
#
# Args...
#
#     - a, b :: The names, such as 'temp2' and 'temp10'.
#
# Returns -1, 0, or 1, as cmp.
#
# Example...
#
#     sort { _natural( $a, $b ) } ( 'temp10', 'temp2' );    # ( 'temp2', 'temp10' )
sub _natural {
	my ( $first, $second ) = @_;

	my ( $first_type,  $first_number )  = $first  =~ /\A([a-z]+)([0-9]+)\z/;
	my ( $second_type, $second_number ) = $second =~ /\A([a-z]+)([0-9]+)\z/;

	return $first_type cmp $second_type || $first_number <=> $second_number;
}

1;
