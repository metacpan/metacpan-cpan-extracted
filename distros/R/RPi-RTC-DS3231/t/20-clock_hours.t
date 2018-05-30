use strict;
use warnings;

use RPi::RTC::DS3231;
use Test::More;

if (! $ENV{RPI_RTC}){
    plan(skip_all => "Skipping: RPI_RTC environment variable not set");
}

my $mod = 'RPi::RTC::DS3231';

{ # bounds checking

    my $o = $mod->new;

    is $o->clock_hours(12), 12, "set to 12 ok";
    is $o->clock_hours(24), 24, "set to 24 ok";

    is eval { $o->clock_hours(13); 1 }, undef, "'13' is invalid ok";
    is eval { $o->clock_hours('a'); 1 }, undef, "'a' is invalid ok";
}

{ # set/get

    my $o = $mod->new;

    $o->min(1);
    $o->sec(1);

    is $o->clock_hours(24), 24, "setting clock to 24 hr result ok";
    is $o->clock_hours, 24, "...and so is the return with no param";

    # 0

    is $o->hour(0), 0, "hr 0 in 24-hr mode ok";
    $o->clock_hours(12);
    is $o->clock_hours, 12, "set clock to 12-hr ok";
    is $o->hour, 12, "hr 0 in 12-hr mode ok";

    for (1..12){
        is $o->clock_hours(24), 24, "set clock to 24-hr ok";
        is $o->hour($_), $_, "hr $_ in 24-hr mode ok";
        is $o->clock_hours(12), 12, "set clock to 12-hr ok";
        is $o->hour, $_, "hr $_ in 12-hr mode ok";
    }

    for (13..23){
        is $o->clock_hours(24), 24, "set clock to 24-hr ok";
        is $o->hour($_), $_, "hr $_ in 24-hr mode ok";
        is $o->clock_hours(12), 12, "set clock to 12-hr ok";
        my $hr = $_ - 12;
        is $o->hour, $hr, "hr $_ == $hr in 12-hr mode ok";
    }
}

done_testing();
