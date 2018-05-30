use strict;
use warnings;
use feature 'say';

use RPi::RTC::DS3231;
use Test::More;

if (! $ENV{RPI_RTC}){
    plan(skip_all => "Skipping: RPI_RTC environment variable not set");
}

my $mod = 'RPi::RTC::DS3231';

{ # 24-hr clock fail

    my $o = $mod->new;

    is $o->clock_hours(24), 24, "24 hr clock enabled ok";
    is eval { $o->am_pm; 1 }, undef, "reading AM/PM fails in 24-hr clk mode";
    like $@, qr/not available when in 24/, "...and error is sane";
    is eval { $o->am_pm('AM'); 1 }, undef, "writing AM/PM fails in 24-hr clk mode";
    like $@, qr/can not be set when in 24/, "...and error is sane";
}

{ # set/get

    my $o = $mod->new;

    $o->clock_hours(12);
    is eval {$o->am_pm('X'); 1; }, undef, "am_pm() croaks with invalid param";
    like $@, qr/requires either 'AM' or 'PM'/, "...and error is sane";

    $o->clock_hours(24);
    is $o->min(13), 13, "set 24-hr clock to 13th min ok";
    is $o->sec(13), 13, "set 24-hr clock to 13th sec ok";

    # AM hours

    for (0..12){
        is $o->clock_hours(24), 24, "24 hr clock enabled ok";
        is $o->hour($_), $_, "set 24-hr clock to hour '$_' ok";
        is $o->clock_hours(12), 12, "12 hr clock enabled ok";
        is $o->am_pm, 'AM', "hr $_ in 24 clock mode is AM ok";
    }

    # PM hours

    for (13..23){
        is $o->clock_hours(24), 24, "24 hr clock enabled ok";
        is $o->hour($_), $_, "set 24-hr clock to hour '$_' ok";
        is $o->clock_hours(12), 12, "12 hr clock enabled ok";
        is $o->am_pm, 'PM', "hr $_ in 24 clock mode is PM ok";
    }

    is $o->clock_hours(24), 24, "set back to 24 hr clock ok";
}

done_testing();
