use strict;
use warnings;

use RPi::RTC::DS3231;
use Test::More;

if (! $ENV{RPI_RTC}){
    plan(skip_all => "Skipping: RPI_RTC environment variable not set");
}

my $mod = 'RPi::RTC::DS3231';

{ # set/get 24 hour clock

    my $o = $mod->new;

    # set 24 hr clock mode

    $o->clock_hours(24);

    for (0..23){
        is $o->hour($_), $_, "setting 24-clock hour to '$_' result is ok";
        is $o->hour, $_, "...and reading is also '$_'"
    }

    for (-1, 25){
        is eval {$o->hour($_); 1}, undef, "sending '$_' results in failure ok";
        like $@, qr/out of bounds.*0-23/, "...and for '$_', error msg is sane";
    }
}

{ # set/get 12 hour clock

    my $o = $mod->new;

    # set 12 hr clock mode

    is $o->clock_hours(12), 12, "set to 12 hr clock ok";

    for (1..12){
        $o->hour($_);
        is $o->hour, $_, "setting hour to '$_' result is ok";
        is $o->hour, $_, "...and reading is also '$_'"
    }

    for (0, 13){
        is eval {$o->hour($_); 1}, undef, "sending '$_' results in failure ok";
        like $@, qr/out of bounds.*1-12/, "...and for '$_', error msg is sane";
    }
}

{ # raw-register BCD guard, 12-hour mode (simple; exhaustive loop in rpi-wiringpi)
  #
  # As with month, the 12-hour round-trip self-masks the raw-vs-BCD bug. Read
  # the actual stored byte for the worst-case value and assert valid BCD. FAILS
  # on the old raw setHour (hour 12 -> 0x0C) and PASSES on the BCD setHour (hour
  # 12 -> 0x12). Reg 0x02 = hour BCD bits 0-4 (mask 0x1F) + AM/PM bit 5 (0x20)
  # + 12/24 bit 6 (0x40).
    my $o = $mod->new;
    $o->clock_hours(12);

    $o->hour(12);
    is $o->_get_register(0x02) & 0x1F, RPi::RTC::DS3231::dec2bcd(12),
        '12-hour hour 12 stored as valid BCD 0x12 in reg 0x02 (not raw 0x0C)';

    # The 12/24-select (0x40) and AM/PM (0x20) bits must survive an hour() write
    $o->clock_hours(12);
    $o->am_pm('PM');
    $o->hour(11);
    my $reg = $o->_get_register(0x02);
    ok $reg & 0x40, '12/24-hour select bit preserved across hour() write';
    ok $reg & 0x20, 'AM/PM bit preserved across hour() write';
}

done_testing();
