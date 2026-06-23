use strict;
use warnings;
use feature 'say';

use RPi::RTC::DS3231;
use Test::More;

if (! $ENV{RPI_RTC}){
    plan(skip_all => "Skipping: RPI_RTC environment variable not set");
}

my $mod = 'RPi::RTC::DS3231';

{ # celsius, within the DS3231 operating range
  #
  # Note: the negative-temperature sign fix cannot be exercised at room
  # temperature (there is no way to inject a sub-zero reading through getTemp()),
  # so this asserts a sane range rather than a known value. The sign decode
  # itself is logic-verified separately. The old qr/\d+/ would have passed a
  # bogus +231 (the sign bug's output for -25C); the range bound rejects that.
    my $o = $mod->new;
    my $temp = $o->temp;
    like $temp, qr/^-?\d+(?:\.\d{2})?$/, "temp() returns a number";
    cmp_ok $temp, '>=', -40, "temp() >= -40C (DS3231 spec floor)";
    cmp_ok $temp, '<=', 85,  "temp() <= 85C (DS3231 spec ceiling)";
}

{ # fahrenheit, within the DS3231 operating range (-40F .. 185F)
    my $o = $mod->new;
    my $f = $o->temp('f');
    like $f, qr/^-?\d+(?:\.\d{2})?$/, "temp('f') returns a number";
    cmp_ok $f, '>=', -40,  "temp('f') >= -40F";
    cmp_ok $f, '<=', 185,  "temp('f') <= 185F";
}
done_testing();
