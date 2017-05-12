package Schedule::Week;

use 5.008008;
use strict;
use warnings;

use Readonly;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'days' => [ qw(
   $MONDAY $TUESDAY $WEDNESDAY $THURSDAY $FRIDAY $SATURDAY $SUNDAY
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'days'} } );

our $VERSION = '1.0';

our Readonly::Scalar $SUNDAY    = 0;
our Readonly::Scalar $MONDAY    = 1;
our Readonly::Scalar $TUESDAY   = 2;
our Readonly::Scalar $WEDNESDAY = 3;
our Readonly::Scalar $THURSDAY  = 4;
our Readonly::Scalar $FRIDAY    = 5;
our Readonly::Scalar $SATURDAY  = 6;

sub new {

    my $class = shift;

    my $self = {
        'ts' => _initialize_schedule()
    };

    return bless $self, $class;
}

#  Day convenience accessors
sub sunday { 
    my ($self, $hours_array_ref, $state) = @_; 
    $self->hours_for_day($SUNDAY, $hours_array_ref, $state); 
}

sub monday { 
    my ($self, $hours_array_ref, $state) = @_;
    $self->hours_for_day($MONDAY, $hours_array_ref, $state); 
}

sub tuesday { 
    my ($self, $hours_array_ref, $state) = @_;
    $self->hours_for_day($TUESDAY, $hours_array_ref, $state); 
}

sub wednesday { 
    my ($self, $hours_array_ref, $state) = @_;
    $self->hours_for_day($WEDNESDAY, $hours_array_ref, $state); 
}

sub thursday { 
    my ($self, $hours_array_ref, $state) = @_;
    $self->hours_for_day($THURSDAY, $hours_array_ref, $state); 
}

sub friday { 
    my ($self, $hours_array_ref, $state) = @_;
    $self->hours_for_day($FRIDAY, $hours_array_ref, $state); 
}

sub saturday { 
    my ($self, $hours_array_ref, $state) = @_;
    $self->hours_for_day($SATURDAY, $hours_array_ref, $state); 
}

#  set or get hours across all days
sub hours {

    my ($self, $hours_array_ref, $state) = @_;

    my @hour_states;

    if (! defined $hours_array_ref) {
        croak 'Missing reference to array of hours to get/set!';
    }

    if (ref($hours_array_ref) ne 'ARRAY') {
        croak "$hours_array_ref is not a reference to an array!";
    }

    if (defined $state) {
        $state = ($state == 0) ? 0 : 1;
        for my $day ($SUNDAY ... $SATURDAY) {
            $hour_states[$day] = [];
            for my $hour (@{$hours_array_ref}) {
                $self->{'ts'}->[$day]->[$hour] = $state;
                push(@{$hour_states[$day]}, $state);
            }
        }
    }


    if (scalar(@hour_states) == 0) {
        for my $day ($SUNDAY ... $SATURDAY) {
            $hour_states[$day] = [];
            for my $hour (@{$hours_array_ref}) {
                push(@{$hour_states[$day]},
                     $self->{'ts'}->[$day]->[$hour]);
            }
        }
    }

    return @hour_states;
}

#  Reset all bits in arrays to 0
sub reset {
    my $self = shift;
    $self->{'ts'} = _initialize_schedule();
}

#  Does this day have any hours scheduled?
sub has_hours {

    my ($self, $day) = @_;

    if (($day < $SUNDAY) || ($day > $SATURDAY)) {
        croak "Day number $day is invalid";
    }

    return grep(/1/, @{$self->{'ts'}->[$day]});
}

sub hours_for_day {
    my ($self, $day, $hours_ref, $state) = @_;

    if (($day < $SUNDAY) || ($day > $SATURDAY)) {
        croak "Day number $day is invalid";
    }

    if ((defined $hours_ref) && (ref($hours_ref) ne 'ARRAY')) {
        croak "$hours_ref is not a reference to an array!";
    }

    my @hour_states = ();

    #  Want all hour states for the day
    if (! defined $hours_ref) {
        return @{$self->{'ts'}->[$day]};
    }

    if (defined($state)) {
        $state = ($state == 0) ? 0 : 1;
        for my $h (@{$hours_ref}) {
            $self->{'ts'}->[$day]->[$h] = $state;
            push(@hour_states, $self->{'ts'}->[$day]->[$h]);
        }
    }

    if (scalar(@hour_states) == 0) {
        for my $h (@{$hours_ref}) {
            push(@hour_states, $self->{'ts'}->[$day]->[$h]);
        }
    }

    return @hour_states;
}

#  Return 1 or 0 to indicate if the passed in time falls in the
#  active periods of this schedule.  If no time stamp is passed
#  in, defaults to now.

sub is_active {

    my ($self, $ts) = @_;

    #  Default to now
    $ts = time() if not defined $ts;
    my ($hr, $day) = (localtime())[2, 6];

    return ($self->{'ts'}->[$day]->[$hr] == 1) ? 1 : 0;
}

#  Serialize a schedule into a string of 168 1s and 0s

sub serialize {
    my $self = shift;

    my $serialized = "";

    for my $day ($SUNDAY ... $SATURDAY) {
        $serialized .= join('', @{$self->{'ts'}->[$day]});
    }

    return $serialized;
}

#  Return an instantiated schedule made from the passed in
#  serialized string

sub deserialize {
    my $serialized = shift;

    if (! defined $serialized) {
        croak "Must pass in a serialized schedule!";
    }

    if (length($serialized) != 168) {
        croak "Passed in serialized schedule is not 168 hours (chars) long!";
    }

    if ($serialized =~ m/[^01]+/) {
        croak "Passed in serialized schedule must be all 1s and 0s";
    }

    my $offset = 0;

    my $hours_in_day = 24;

    my $schedule = Schedule::Week->new();

    #  Localize for map() in loop below
    local $_;

    for my $day ($SUNDAY ... $SATURDAY) {
        my $day_template = substr($serialized, $offset, $hours_in_day);

        #  Explicitly convert to integers to keep perl from guessing that
        #  values are 1 character strings
        my @hours = map { int($_); } (split('', $day_template));

        $schedule->{'ts'}->[$day] = \@hours;
        $offset += $hours_in_day;
    }

    return $schedule;
}

#  Set hours on or off for all weekdays in one shot or retrieve values
#  for same.
sub weekday_hours {
    my ($self, $hours_ref, $state) = @_;

    my @results;

    for my $day ($MONDAY ... $FRIDAY) {
        push(@results, [$self->hours_for_day($day, $hours_ref, $state)]);
    }

    return @results;
}

#  Set hours on or off for all weekends in one shot or retrieve values for
#  same.
sub weekend_hours {
    my ($self, $hours_ref, $state) = @_;

    my @results;

    for my $day ($SATURDAY, $SUNDAY) {
        push(@results, [$self->hours_for_day($day, $hours_ref, $state)]);
    }

    return @results;
}

### Private methods
sub _initialize_schedule {

    my @schedule = ();
    $schedule[$SUNDAY]    = _initialize_hours(0);
    $schedule[$MONDAY]    = _initialize_hours(0);
    $schedule[$TUESDAY]   = _initialize_hours(0);
    $schedule[$WEDNESDAY] = _initialize_hours(0);
    $schedule[$THURSDAY]  = _initialize_hours(0);
    $schedule[$FRIDAY]    = _initialize_hours(0);
    $schedule[$SATURDAY]  = _initialize_hours(0);

    return \@schedule;
}

sub _initialize_hours {

    my $v = shift;

    return [
        # Hours of day, starting with 12 AM (hour 00 aka midnight)
        $v, $v, $v, $v, $v, $v, $v, $v,
        $v, $v, $v, $v, $v, $v, $v, $v,
        $v, $v, $v, $v, $v, $v, $v, $v,
    ];

}

1;
