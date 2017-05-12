#!perl

use strict;
use warnings;
use utf8;

use Test::More;

BEGIN {
    if ( $^V lt v5.10.0 ) {
        plan skip_all => "This perl is too old to run these tests"
    }
}

use constant {
    TESTS   => 10,
    MAX_NUM => 0x0FFFFFFF
};

plan tests => TESTS * 1;

if ( Test::Builder->VERSION < 2 ) {
    foreach my $method ( qw(output failure_output) ) {
        binmode Test::More->builder->$method, ':utf8'
    }
}

use Number::AnyBase;

{
    note TESTS . q( random roundtrips with japanese alphabet);
    my $base = Number::AnyBase->new(
        'ぁあおかがきぎほぼぽまみむめもやゅはばぱゆょらるれゐゑを'
    );
    for my $test (1 .. TESTS) {
        my $dec_num = int rand MAX_NUM;
        my $base_num = $base->to_base($dec_num);
        is $base->to_dec($base_num), $dec_num,
            "Roundtrip $dec_num > '$base_num' > $dec_num"
    }
}
