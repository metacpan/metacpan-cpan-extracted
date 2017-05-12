use strict;
use warnings;

use Test::More;
BEGIN { use_ok('RPi::ADC::ADS') };

my $mod = 'RPi::ADC::ADS';

{ # default params
    my $obj = $mod->new;

    is ref $obj, 'RPi::ADC::ADS', "object is in proper class";
    is $obj->{model}, 'ADS1015', "default model is ok";
    is $obj->{addr}, 0x48, "default addr is ok";
    is $obj->{device}, '/dev/i2c-1', "default dev is ok";
    is $obj->{channel}, 0x4000, "default channel is ok";

    my @reg = $obj->register;
    is @reg, 2, "default register has proper elem count";
    is $reg[0], 195, "default register MSB ok";
    is $reg[1], 3, "default register LSB ok";
}

{ # set params
    my $obj = $mod->new(
        model   => 'ADS1115',
        addr    => 0x49,
        device  => '/dev/i2c-0',
        channel => 2
    );

    is $obj->{model}, 'ADS1115', "param model is ok";
    is $obj->{addr}, 0x49, "param addr is ok";
    is $obj->{device}, '/dev/i2c-0', "param dev is ok";
    is $obj->{channel}, 0x6000, "param channel is ok";
}

done_testing();
