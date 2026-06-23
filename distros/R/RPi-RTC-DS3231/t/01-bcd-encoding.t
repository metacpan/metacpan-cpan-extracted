use strict;
use warnings;

use RPi::RTC::DS3231;
use Test::More;

# Simple sanity check of the BCD codec for the standalone distribution. The
# comprehensive, exhaustive proof lives in the rpi-wiringpi test platform
# (t/321-rtc-bcd.t); this is the lightweight regression guard.
#
# Months 10, 11 and 12 are the real-world values the old raw-binary write
# corrupted: raw 10/11/12 (0x0A/0x0B/0x0C) are illegal BCD. dec2bcd() fixes it.

my $dec2bcd = \&RPi::RTC::DS3231::dec2bcd;
my $bcd2dec = \&RPi::RTC::DS3231::bcd2dec;

for my $v (10, 11, 12){
    ok ! is_valid_bcd($v),           "raw $v is illegal BCD (the old bug)";
    ok is_valid_bcd($dec2bcd->($v)), "dec2bcd($v) is valid BCD";
    is $bcd2dec->($dec2bcd->($v)), $v, "...and round-trips back to $v";
}

done_testing();

# A byte is valid BCD only when each nibble is 0-9.
sub is_valid_bcd {
    my ($byte) = @_;
    return (($byte & 0x0F) <= 9) && ((($byte >> 4) & 0x0F) <= 9);
}
