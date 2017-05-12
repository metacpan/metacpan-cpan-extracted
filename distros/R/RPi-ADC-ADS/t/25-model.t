use strict;
use warnings;

use RPi::ADC::ADS;
use Test::More;

my $mod = 'RPi::ADC::ADS';

{ # default

    my $obj = $mod->new;

    is $obj->model, 'ADS1015', "model() default is ok";
}

{ # legit models

    my $obj = $mod->new;


    for my $d (qw(13 14 15 18)){
        for (qw(10 11)) {
            my $dev = 'ADS'."${_}$d";
            is $obj->model( $dev ), $dev, "$dev model ok";
        }
    }
}

{ # faulty models

    my $obj = $mod->new;

    for (qw(BDS1015 ADC1015 ADS2015 ADS1215 ADS1119 ADS1016 ADS1017)){
        my $ok = eval { $obj->model($_); 1; };
        is $ok, undef, "dies with model $_, which is out of bounds";
        like $@, qr/invalid model name/, "...with proper error msg";
    }
}
done_testing();