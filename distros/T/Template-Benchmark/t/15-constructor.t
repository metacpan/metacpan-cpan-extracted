#!perl -T

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Template::Benchmark;

plan tests => 1;

my ( $bench );

#
#  1: unknown constructor option
throws_ok
    {
        $bench = Template::Benchmark->new(
            this_constructor_option_doesnt_exist => 1,
            );
    }
    qr{Unknown constructor option 'this_constructor_option_doesnt_exist' at .*Template.*Benchmark\.pm line},
    'error on construct with unknown option';
