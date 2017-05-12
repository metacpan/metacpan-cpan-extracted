use strict;
use warnings;

use RPi::ADC::ADS;
use Test::More;

my $mod = 'RPi::ADC::ADS';

{ # default

    my $obj = $mod->new;

    is $obj->addr, 0x48, "addr() default is ok";
}

{ # legit addrs

    my $obj = $mod->new;

    # 72, 73, 74, 75

    for (0x48, 0x49, 0x4A, 0x4B){
        $obj->addr($_);
        is $obj->addr, $_, "address $_ set ok";
    }
}

{ # faulty addrs

    my $obj = $mod->new;

    my $ok = eval { $obj->addr('A'); 1; };

    is $ok, undef, "alpha chars in addr() die";
    like $@, qr/invalid address/, "...with proper error msg";

    for (qw(71 76)){
        my $ok = eval { $obj->addr($_); 1; };
        is $ok, undef, "dies with addr $_, which is out of bounds";
    }
}
done_testing();