use strict;
use warnings;

### after: use lib qw(@RT_LIB_PATH@);
use lib qw(/opt/rt4/local/lib /opt/rt4/lib);

package RT::Extension::AutomaticAssignment::Test;

use base qw(RT::Test);

sub import {
    my $class = shift;
    my %args  = @_;

    $args{'requires'} ||= [];
    if ( $args{'testing'} ) {
        unshift @{ $args{'requires'} }, 'RT::Extension::AutomaticAssignment';
    } else {
        $args{'testing'} = 'RT::Extension::AutomaticAssignment';
    }

    $class->SUPER::import( %args );
    $class->export_to_level(1);

    require RT::Extension::AutomaticAssignment;
}

sub bootstrap_more_config {
    my $self = shift;
    my ($config) = @_;

    print $config q{
Set( $Timezone, 'UTC');

my @Holidays = (
    '2016-09-05', # Labor Day
    '2016-12-25', # Christmas
    '2017-01-01', # New Year's Day
);

Set(%ServiceBusinessHours, (
    'Morning' => {
        1 => { Name => 'Monday',    Start => '08:00', End => '13:30' },
        2 => { Name => 'Tuesday',   Start => '08:00', End => '13:30' },
        3 => { Name => 'Wednesday', Start => '08:00', End => '13:30' },
        4 => { Name => 'Thursday',  Start => '08:00', End => '13:30' },
        5 => { Name => 'Friday',    Start => '08:00', End => '13:30' },
        holidays => \@Holidays,
    },
    'Afternoon' => {
        1 => { Name => 'Monday',    Start => '13:00', End => '18:00' },
        2 => { Name => 'Tuesday',   Start => '13:00', End => '18:00' },
        3 => { Name => 'Wednesday', Start => '13:00', End => '18:00' },
        4 => { Name => 'Thursday',  Start => '13:00', End => '18:00' },
        5 => { Name => 'Friday',    Start => '13:00', End => '18:00' },
        holidays => \@Holidays,
    },
    'Weekend' => {
        6 => { Name => 'Saturday',  Start => '08:00', End => '18:00' },
        7 => { Name => 'Sunday',    Start => '08:00', End => '18:00' },
        holidays => \@Holidays,
    },
));
};

}

1;

