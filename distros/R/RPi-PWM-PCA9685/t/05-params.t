#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use RPi::PWM::PCA9685;

# These exercise the parameter validation and failure paths only, so
# they run fine on machines with no PCA9685 (or no I2C bus) attached

plan tests => 14;

my $ok = eval {
    RPi::PWM::PCA9685->new(addr => 999999);
    1;
};
is $ok, undef, "new() dies with an out of range addr param";
like $@, qr/addr param/, "...with a relevant error message";

$ok = eval {
    RPi::PWM::PCA9685->new(drive => 'bogus');
    1;
};
is $ok, undef, "new() dies with an invalid drive param";
like $@, qr/drive param/, "...with a relevant error message";

$ok = eval {
    RPi::PWM::PCA9685->new(device => '/dev/nonexistent-i2c');
    1;
};
is $ok, undef, "new() dies if the i2c device can't be opened";
like $@, qr/failed to open/, "...with the underlying error message";

# A device-less object gets us through the Perl-level validation
# without ever touching the XS layer

my $fake = bless {}, 'RPi::PWM::PCA9685';

eval { $fake->duty(99, 0); };
like $@, qr/\$channel param/, "duty() validates the channel";

eval { $fake->duty(0, 9999); };
like $@, qr/\$duty param/, "duty() validates the duty value";

eval { $fake->duty_pct(0, 101); };
like $@, qr/\$pct param/, "duty_pct() validates the percent";

eval { $fake->freq('abc'); };
like $@, qr/\$freq param/, "freq() validates the frequency";

eval { $fake->pwm(0, 99999, 0); };
like $@, qr/\$on param/, "pwm() validates the on ticks";

eval { $fake->register(999); };
like $@, qr/\$reg param/, "register() validates the register";

eval { $fake->servo_us(0); };
like $@, qr/\$us param/, "servo_us() requires a pulse width";

eval { $fake->duty(0, 2048); };
like $@, qr/device has been closed/, "methods croak once the device is closed";
