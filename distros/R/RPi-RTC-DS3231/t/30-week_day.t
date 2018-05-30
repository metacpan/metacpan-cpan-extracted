use strict;
use warnings;
use feature 'say';

use RPi::RTC::DS3231;
use Test::More;

if (! $ENV{RPI_RTC}){
    plan(skip_all => "Skipping: RPI_RTC environment variable not set");
}

my $mod = 'RPi::RTC::DS3231';

my %days = (
    1 => "Monday",
    2 => "Tuesday",
    3 => "Wednesday",
    4 => "Thursday",
    5 => "Friday",
    6 => "Saturday",
    7 => "Sunday",
);

{ # set/get

    my $o = $mod->new;

    for (1..7){
        is $o->day($_), $days{$_}, "$_ == $days{$_} ok";
    }
}

{   # out of bounds/illegal chars

    my $o = $mod->new;

    for (qw(8 0)){
        is eval { $o->day($_); 1; }, undef, "setting dow to '$_' fails ok";
    }
}
done_testing();
