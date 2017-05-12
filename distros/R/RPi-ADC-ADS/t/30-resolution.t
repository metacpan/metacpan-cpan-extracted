use strict;
use warnings;

use RPi::ADC::ADS;
use Test::More;

my $mod = 'RPi::ADC::ADS';

{ # default

    my $obj = $mod->new;
    is $obj->_resolution, 12, "default resolution ok";
}

{
    my $obj = $mod->new;

    for my $d (qw(13 14 15 18)){
        my $model = "ADS10$d";
        $obj->model($model);
        is $obj->_resolution, 12, "model $model has ok resolution";
    }

    for my $d (qw(13 14 15 18)){
        my $model = "ADS11$d";
        $obj->model($model);
        is $obj->_resolution, 16, "model $model has ok resolution";
    }
}

done_testing();