package P2::Scheduler;

use v5.18;
our $VERSION = '0.07';

use Moose;
use POSIX       qw(ceil);
use UUID        qw(uuid);
use Date::Calc  qw(
    Days_in_Month
    Day_of_Week
);

# resources per priority
has 'resources' => (is => 'ro', isa => 'ArrayRef', required => 1);

# the type of resource
has 'resource_type' => (is => 'ro', isa => 'Str', default => 'namespace');

# how many tests per priority per day
has 'weight'     => (is => 'rw', isa => 'ArrayRef', default => sub {[3,2,1]});

# use this to set the hours in the testing slot
has 'hour_slots' => (is => 'rw', isa => 'ArrayRef', default => sub {[1,2,3,4,5]} );
has 'fixed_intervals' => ( is => 'rw', isa => 'Bool', default => 0 );

has 'year'       => (is => 'rw', isa => 'Int', default => 2020);

# this to set to run P3 and P2 tests only on selected months
# defaults to run all tests for all priorities all year round
has 'pri_per_month' => (is => 'rw', isa => 'ArrayRef', default => sub{ return [3,3,3,3,3,3,3,3,3,3,3,3]});

# this to leave some spare days at the end of the month to reschedule tests
# defaults to 0 spare days
has 'spare_days_per_month' => (is => 'rw', isa => 'Int', default => 0);

# this to start right not at the first business day of the month
# usefull when you reschedule things in between...
has 'starting_from' => (is => 'rw', isa => 'Int', default => 0);

# use this if you want to limit the number of testing days in a week, always starting
# from Monday, defaults to 5 (Monday to Friday)
has 'num_week_days' => (is => 'rw', isa => 'Int', default => 5); 

# use this if you want to select the business days to run the tests
# 1 => Monday,..., 5 => Friday
has 'selected_week_days' => (is => 'rw', isa => 'ArrayRef', default => sub{ return [1,2,3,4,5] });

# the Kubernetes (or any other means to address the proper cloud) context...
has 'context' => (is => 'rw', isa => 'Str');

# Label to be added to resource and context to derive experiment unique name...
has 'label' => (is => 'rw', isa => 'Str', default => "");

# a description of what is happening to the resource, it will appear as title
has 'action' => (is => 'rw', isa => 'Str', default => "No action specified");


sub BUILD {
    my $self = shift;

    $self->{tot_mins} = ($self->{hour_slots}->[-1] - $self->{hour_slots}->[0]) * 60;
    my $tot_experiments = eval join '+', @{$self->{weight}};
    $self->{mins_interval} = $self->{tot_mins} / $tot_experiments;
}

sub year_schedule {
    my $self = shift;

    my @year_schedule = ();
    for (1..12) {
        push @year_schedule, $self->month_schedule($_);
    }
    return @year_schedule;
}


sub month_schedule {
    my ( $self, $month ) = @_;

    my @schedule = ();
    my @bd = $self->_get_business_days_of_month( $month );

    my @experiment_index=(0,0,0);
    for (my $day_index=0;$day_index<scalar(@bd) - $self->spare_days_per_month;$day_index++) {
        next unless ( $bd[$day_index]->{day} >= $self->starting_from );
        my $exp_index=1;
        for (my $priority=0;$priority<$self->pri_per_month->[$month-1];$priority++) {
            next unless $self->resources->[$priority]; # skip this priority if no resources there...
            for ( my $index=0;$index<$self->weight->[$priority];$index++) {
                my $exp_mins = $self->{mins_interval} * $exp_index;
                push @schedule, { 
                    year        => $self->year, 
                    month       => sprintf("%02d", $month),
                    day         => sprintf("%02d", $bd[$day_index]->{day}),
                    dow         => $bd[$day_index]->{dow},
                    resource    => $self->resources->[$priority][$experiment_index[$priority]],
                    priority    => $priority+1,
                    hour        => $self->{fixed_intervals} ? sprintf("%02d", $self->{hour_slots}->[0] + int($exp_mins/60)) : 
                                    sprintf("%02d", $self->hour_slots->[ int(rand(1000)) % scalar( @{$self->hour_slots} ) ]),
                    min         => $self->{fixed_intervals} ? sprintf("%02d", $exp_mins % 60) :
                                    sprintf("%02d", int(rand(100)) % 60), 
                };
                $experiment_index[$priority] = ($experiment_index[$priority] + 1) % 
                    scalar( @{$self->resources->[$priority]} );
                $exp_index++;
            }
        }
    }

    return map{{ 
        exp_id   => lc( substr($_->{resource}, 0, 40).'-'.substr(uuid(), -8) ), # there is a k8s constraint on length of cronjob ids...
        context  => $self->context,
        resource => $_->{resource},
        resource_type => $self->{resource_type},
        filepath => $_->{resource}.'-'.$self->label.'-'.$self->context, 
        schedule => "$_->{min} $_->{hour} $_->{day} $_->{month} *",
        priority => $_->{priority},
        title    => "Resource: $_->{resource}, action: $self->{action}",
        year     => $self->year,
        mins     => $_->{min},
        hour     => $_->{hour},
        dom      => $_->{day},
        month    => $_->{month},
        dow      => "*"
    }} @schedule;
}

sub _get_business_days_of_month {
    my ( $self, $month ) = @_;

    my @business_days=();
    my $days = Days_in_Month($self->year, $month);
    foreach my $day (1..$days) {
        my $dow = Day_of_Week($self->year, $month, $day);
        if (( $dow <= $self->num_week_days) && ( grep /$dow/, @{$self->selected_week_days} )) {
            push @business_days, { day => $day, dow => $dow };
        }
    }
    return @business_days;
}

no Moose;
__PACKAGE__->meta->make_immutable;

=pod

=head1 NAME

P2::Scheduler - This module helps organizing monthly tests at component level.



=head1 SYNOPSIS

    use P2::Scheduler;

    my $scheduler = P2::Scheduler->new(
        resources       => [][],        # resources ordered by priority (mandatory)
        context         => ...,         # the K8s context
        label           => ...,         # a fixed label to be added to each resource name to compose the experiment name
        action          => ...,         # a description of what is happening to the resource, it will appear as title
        weight          => [3,2,1],     # the weight of each priority, basically how many tests to run for a 
                                        # given priority (defaults to [3,2,1])
        hour_slots      => [1,2,3,4,5], # hours of the day at which tests can run (mandatory)
        spare_days_per_month => 2,      # number of business days to leave as spare at the end of the month
        starting_from   => 6,           # index of the day of the month to start from (defaults to 1)
        year            => ...          # mandatory
        num_week_days   => 3            # number of business days to count starting from Monday, defaults to 5
        pri_per_month' => [3,3,3,3,3,3,3,3,3,3,3,3] # an array for the minimum priority to take into consideration when scheduling 
                                        # experiments for each month. Default to all
                                        # priorities for all months. This is meant to be
                                        # used in case we want to limit priority 2/3
                                        # experiments only to specific months.
        selected_week_days => [3,4],    # list of business days ids to consider:
                                        # 1 => Monday,..., 5 => Friday
                                        # for example the string '2,3,4' would set tests to run only
                                        # between Tuesdays and Thursdays
        fixed_intervals => 1            # if experiments times should be strictly scheduled in 
                                        # fixed intervals or randomly allocated

    );

    # getting the schedule for January...
    my @schedule = $scheduler->month_schedule(1);

    # or for the whole year...
    my @schedule = $scheduler->year_schedule();



=head1 AUTHOR

Marco Masetti, C<< <marco.masetti at sky.uk> >>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc P2::Scheduler


=head1 LICENSE AND COPYRIGHT

Copyright 2020 Marco Masetti.

This program is free software; you can redistribute it and/or modify it
under the terms of the the BSD 3-Clause License.

=cut
#---------------------------------------------------------------------
