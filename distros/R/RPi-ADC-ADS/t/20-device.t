use strict;
use warnings;

use RPi::ADC::ADS;
use Test::More;

my $mod = 'RPi::ADC::ADS';

{ # default

    my $obj = $mod->new;

    is $obj->device, '/dev/i2c-1', "device() default is ok";
}

{ # legit devices

    my $obj = $mod->new;

    for my $num (0..9){
        my $dev = "/dev/i2c-$num";
        $obj->device($dev);
        is $obj->device, $dev, "device $dev ok";
    }
}

{ # faulty devices

    my $obj = $mod->new;

    for (qw(71 76 A)){
        my $ok = eval { $obj->device($_); 1; };
        is $ok, undef, "dies with device $_, which is incorrect";
    }

    for (qw(-1 10)){
        my $dev = "/i2c-$_";
        my $ok = eval { $obj->device($dev); 1; };
        is $ok, undef, "dies with device $dev, which is incorrect";
        like $@, qr/invalid device name/, "... error msg ok";
    }
}
done_testing();