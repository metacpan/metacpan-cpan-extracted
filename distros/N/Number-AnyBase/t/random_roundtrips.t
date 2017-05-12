#!perl

use strict;
use warnings;

use constant {
    TESTS   => 10,
    MAX_NUM => 0x0FFFFFFF
};

use Test::More tests => TESTS * 5;

use Number::AnyBase;

{
    note TESTS . q( random roundtrips over 0..9, 'A'..'Z', 'a'..'z');
    my $conv = Number::AnyBase->new( [0..9, 'A'..'Z', 'a'..'z'] );
    for my $test (1 .. TESTS) {
        my $dec_num = int rand MAX_NUM;
        my $base_num = $conv->to_base($dec_num);
        is $conv->to_dec($base_num), $dec_num, "Roundtrip $dec_num > $base_num > $dec_num"
    }
}

{
    note TESTS . q( random roundtrips over uri-safe alphabet);
    my $conv = Number::AnyBase->new_urisafe;
    for my $test (1 .. TESTS) {
        my $dec_num = int rand MAX_NUM;
        my $base_num = $conv->to_base($dec_num);
        is $conv->to_dec($base_num), $dec_num, "Roundtrip $dec_num > $base_num > $dec_num"
    }
}

{
    note TESTS . q( random roundtrips over binary alphabet);
    my $conv = Number::AnyBase->new( '01' );
    for my $test (1 .. TESTS) {
        my $dec_num = int rand MAX_NUM;
        my $base_num = $conv->to_base($dec_num);
        is $conv->to_dec($base_num), $dec_num, "Roundtrip $dec_num > $base_num > $dec_num"
    }
}

{
    note TESTS . q( random roundtrips over hex alphabet);
    my $conv = Number::AnyBase->new( '0123456789ABCDEF' );
    for my $test (1 .. TESTS) {
        my $dec_num = int rand MAX_NUM;
        my $base_num = $conv->to_base($dec_num);
        is $conv->to_dec($base_num), $dec_num, "Roundtrip $dec_num > $base_num > $dec_num"
    }
}

{
    note TESTS . q( random roundtrips over ascii printable alphabet);
    no warnings;
    my $seq = Number::AnyBase->new_ascii;
    for my $test (1 .. TESTS) {
        my $dec_num = int rand MAX_NUM;
        my $base_num = $seq->to_base($dec_num);
        is $seq->to_dec($base_num), $dec_num, "Roundtrip $dec_num > $base_num > $dec_num"
    }
}
