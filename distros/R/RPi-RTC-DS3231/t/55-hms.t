use strict;
use warnings;
use feature 'say';

use RPi::RTC::DS3231;
use Test::More;

if (! $ENV{RPI_RTC}){
    plan(skip_all => "Skipping: RPI_RTC environment variable not set");
}

my $mod = 'RPi::RTC::DS3231';

{ # set/get

    my $o = $mod->new;

    $o->clock_hours(24);

    $o->year(2018);
    $o->month(5);
    $o->mday(17);
    $o->hour(23);
    $o->min(55);
    $o->sec(01);

    like $o->hms, qr/^23:55:\d{2}$/, "hms() in 24-hr mode ok";

    $o->clock_hours(12);

    like $o->hms, qr/^11:55:\d{2} PM$/, "hms() in 12-hr PM mode ok";

    $o->hour(1);
    $o->am_pm('AM');

    like $o->hms, qr/^01:55:\d{2} AM$/, "hms() in 12-hr AM mode ok";
}

done_testing();
