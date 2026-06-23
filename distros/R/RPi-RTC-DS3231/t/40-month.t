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

    for (1..12){
        is $o->month($_), $_, "setting month to $_ ok";
    }
}

{   # out of bounds/illegal chars

    my $o = $mod->new;

    for (qw(0 13)){
        is eval { $o->month($_); 1; }, undef, "setting month to '$_' fails ok";
    }
}

{ # raw-register BCD guard (simple; the exhaustive loop lives in rpi-wiringpi)
  #
  # The round-trip above self-masks the bug: getMonth() does bcd2dec(reg), and
  # bcd2dec(0x0C) == 12, so month(12)/month round-trips green even when the
  # register holds illegal BCD. Read the actual stored byte for the worst-case
  # value and assert it is valid BCD. This FAILS on the old raw-binary setMonth
  # (month 12 -> 0x0C) and PASSES on the BCD setMonth (month 12 -> 0x12). Reg
  # 0x05 = month bits 0-4 (mask 0x1F) + Century bit 7 (DS3231 Figure 1).
    my $o = $mod->new;

    $o->month(12);
    is $o->_get_register(0x05) & 0x1F, RPi::RTC::DS3231::dec2bcd(12),
        'month 12 stored as valid BCD 0x12 in reg 0x05 (not raw 0x0C)';

    # The Century bit (0x80) must survive a month() write
    RPi::RTC::DS3231::setRegister(
        $o->_fd,
        0x05,
        0x80 | RPi::RTC::DS3231::dec2bcd(6),
        'seed century',
    );
    $o->month(12);
    ok $o->_get_register(0x05) & 0x80, 'Century bit (0x80) preserved across month() write';
}

done_testing();
