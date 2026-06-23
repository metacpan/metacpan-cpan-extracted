use strict;
use warnings;

use RPi::ADC::ADS;
use Test::More;

# new() must apply the gain => arg (and must NOT derive gain from mode). The old
# constructor did $self->gain($args{mode}), so a gain => arg was silently
# ignored and a mode => arg corrupted the gain. These checks falsify that bug.

my $mod = 'RPi::ADC::ADS';

# gain index -> config-register bits (DS SBAS444, config reg bits 11-9). gain
# index 1 (0x200, +/-4.096V) is the default.
my %gain = (
    0 => 0x000,
    1 => 0x200,
    2 => 0x400,
    3 => 0x600,
    4 => 0x800,
    5 => 0xA00,
    6 => 0xC00,
    7 => 0xE00,
);

{ # default
    my $o = $mod->new;
    is $o->gain, 0x200, "default gain is DEFAULT_GAIN (0x200, +/-4.096V) ok";
}

{ # gain => N is applied by the constructor (the fix). FAILS on the old code,
  # which ignored gain => and left every object at DEFAULT_GAIN.
    for my $g (0 .. 7){
        my $o = $mod->new(gain => $g);
        is $o->gain, $gain{$g},
            "new(gain => $g) sets the gain register to its value ($gain{$g})";
    }
}

{ # mode must not leak into gain. The old code did gain($args{mode}), so
  # mode => 0 wrongly set gain to 0x000 (the +/-6.144V range).
    my $o = $mod->new(mode => 0);
    is $o->gain, 0x200,
        "new(mode => 0) leaves gain at the default (mode does not set gain)";
}

{ # gain and mode are independent in new()
    my $o = $mod->new(gain => 4, mode => 0);
    is $o->gain, $gain{4}, "new(gain => 4, mode => 0): gain is 4's value";
}

done_testing();
