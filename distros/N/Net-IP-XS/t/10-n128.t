#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 95;

use Math::BigInt;
use Net::IP::XS;
my $nt = "Net::IP::XS::N128";

my $max_128_minus_1 = '340282366920938463463374607431768211454';
my $max_128         = '340282366920938463463374607431768211455';

# Unsigned integer operations.
{
    my $n1 = $nt->new();
    ok($n1, 'Got new N128 object');

    $n1->set_ui(0);
    is($n1->cmp_ui(0), 0, '0 cmp 0 equals 0');
    
    $n1->set_ui(1);
    is($n1->cmp_ui(0), 1, '1 cmp 0 equals 1');

    $n1->set_ui(0);
    is($n1->cmp_ui(1), -1, '0 cmp 1 equals -1');

    $n1->set_ui(1);
    $n1->blsft(1);
    is($n1->cmp_ui(2), 0, '1 << 1 equals 2');
    
    $n1->set_ui(1);
    $n1->blsft(8);
    is($n1->cmp_ui(256), 0, '1 << 8 equals 256');

    for my $i (9, 10, 11, 32, 64, 127) {
        $n1->set_ui(1);
        $n1->blsft($i);
        is($n1->cmp_ui(256), 1, "(1 << $i) cmp 256 equals 1");
    }

    for my $i (1, 2, 3, 31, 32, 33, 64, 127) {
        $n1->set_ui(1);
        $n1->blsft($i);
        $n1->brsft($i);
        is($n1->cmp_ui(1), 0, "1 << $i >> $i equals 1");
    }

    my $n2 = $nt->new();
    $n2->set_ui(0);

    my @ui_tests = (
        [ 'band', 1, 0, 0 ],
        [ 'band', 1, 1, 1 ],
        [ 'bior', 1, 0, 1 ],
        [ 'bior', 1, 1, 1 ],
        [ 'bior', 0, 0, 0 ],
        [ 'bxor', 1, 0, 1 ],
        [ 'bxor', 1, 1, 0 ],
        [ 'bxor', 0, 0, 0 ],
        [ 'badd', 0, 0, 0 ],
        [ 'badd', 1, 1, 2 ],
        [ 'badd', 100, 100, 200 ],
        [ 'badd', 256, 256, 512 ],
        [ 'bsub', 0, 0, 0 ],
        [ 'bsub', 0, 1, 0 ],
        [ 'bsub', 1, 0, 1 ],
        [ 'bsub', 1, 1, 0 ],
        [ 'bsub', 4294967295, 4294967294, 1 ],
        [ 'bsub', 4294967295, 1234567890, 3060399405 ],
    );

    for my $data (@ui_tests) {
        my ($fn, $n1v, $n2v, $res) = @{$data};
        $n1->set_ui($n1v);
        $n2->set_ui($n2v);
        $n1->$fn($n2);
        is($n1->cmp_ui($res), 0, "$n1v $fn $n2v equals $res");
    }

    my @add_ui_tests = (
        [ 0, 0, 0 ],
        [ 0, 1, 1 ],
        [ 1, 0, 1 ],
        [ 1, 1, 2 ],
        [ 100, 100, 200 ],
        [ 256, 256, 512 ],
    );

    for my $data (@add_ui_tests) {
        my ($a, $b, $c) = @{$data};
        $n1->set_ui($a);
        $n1->badd_ui($b);
        is($n1->cmp_ui($c), 0, "$a + $b equals $c (add unsigned integer)");
    }
}

# Remaining operations.
{
    my $n1 = $nt->new();
    $n1->set_ui(0);

    my @set;
    for (my $i = 0; $i < 128; $i++) {
        if ($n1->tstbit($i)) {
            push @set, $i;
        }
    }
    ok((not @set), 'No bits set in number set to zero');

    $n1->bnot();

    my @not_set;
    for (my $i = 0; $i < 128; $i++) {
        if (not $n1->tstbit($i)) {
            push @not_set, $i;
        }
    }
    ok((not @not_set), 'All bits set in complement of zero');

    for (my $i = 0; $i < 128; $i++) {
        $n1->clrbit($i);
    }
    @set = ();
    for (my $i = 0; $i < 128; $i++) {
        if ($n1->tstbit($i)) {
            push @set, $i;
        }
    }
    ok((not @set), 'Cleared all bits, no bits set');

    for (my $i = 0; $i < 128; $i++) {
        $n1->setbit($i);
    }
    @not_set = ();
    for (my $i = 0; $i < 128; $i++) {
        if (not $n1->tstbit($i)) {
            push @not_set, $i;
        }
    }
    ok((not @not_set), 'Set all bits, all bits set');

    $n1->set_ui(0);
    $n1->setbit(0);
    is($n1->cmp_ui(1), 0, 'Bit index begins from LSB (set)');

    $n1->set_ui(0);
    $n1->clrbit(0);
    is($n1->cmp_ui(0), 0, 'Bit index begins from LSB (clear)');

    $n1->setbit(100);
    ok($n1->tstbit(100), 'Bit index begins from LSB (test)');

    $n1->set_ui(0);
    for (my $i = 0; $i < 8; $i++) {
        $n1->setbit($i);
    }
    is($n1->cmp_ui(255), 0,
        'Setting lowest eight bits worked correctly');

    my $n2 = $nt->new();
    $n1->set_ui(0);
    $n2->set_ui(0);

    $n1->setbit(120);
    $n2->setbit(121);
    is($n1->cmp($n2), -1, 'Object comparison - less than');
    is($n1->cmp($n1),  0, 'Object comparison - equality');
    is($n2->cmp($n1),  1, 'Object comparison - more than');

    $n1->set_ui(0);
    $n2->set_ui(0);
    $n1->setbit(90);
    $n2->setbit(91);
    is($n1->cmp($n2), -1, 'Object comparison - less than (2)');
    is($n1->cmp($n1),  0, 'Object comparison - equality (2)');
    is($n2->cmp($n1),  1, 'Object comparison - more than (2)');

    $n1->set_ui(0);
    $n2->set_ui(0);
    $n1->setbit(55);
    $n2->setbit(56);
    is($n1->cmp($n2), -1, 'Object comparison - less than (3)');
    is($n1->cmp($n1),  0, 'Object comparison - equality (3)');
    is($n2->cmp($n1),  1, 'Object comparison - more than (3)');

    $n1->set_ui(0);
    $n2->set_ui(0);
    $n1->setbit(27);
    $n2->setbit(28);
    is($n1->cmp($n2), -1, 'Object comparison - less than (4)');
    is($n1->cmp($n1),  0, 'Object comparison - equality (4)');
    is($n2->cmp($n1),  1, 'Object comparison - more than (4)');

    $n1->set_binstr('1');
    $n2->set_ui(1);
    is($n1->cmp($n2), 0, 'Set number based on bitstring (1)');

    $n1->set_binstr('1' x 2);
    $n2->set_ui(3);
    is($n1->cmp($n2), 0, 'Set number based on bitstring (3)');

    $n1->set_binstr('101');
    $n2->set_ui(5);
    is($n1->cmp($n2), 0, 'Set number based on bitstring (5)');

    $n1->set_binstr(('0' x 127) . '1');
    $n2->set_ui(1);
    is($n1->cmp($n2), 0, 'Set number based on bitstring (1)');

    $n1->set_binstr(('0' x 126) . '11');
    $n2->set_ui(3);
    is($n1->cmp($n2), 0, 'Set number based on bitstring (3)');

    $n1->set_binstr(('0' x 125) . ('1' x 128));
    $n2->set_ui(7);
    is($n1->cmp($n2), 0, 'Set number based on bitstring (7, and too long)');

    $n1->set_binstr(('0' x 96) . ('1' x 32));
    $n2->set_ui(4294967295);
    is($n1->cmp($n2), 0, 'Set number based on bitstring ((1 << 32) - 1)');

    $n1->set_ui(0);
    $n1->bnot();
    $n2->set_ui(1);
    $n1->badd($n2);
    is($n1->cmp_ui(0), 0, 'Addition allows for overflow');

    $n1->set_ui(0);
    $n1->bnot();
    $n2->set_ui(100);
    $n1->badd($n2);
    is($n1->cmp_ui(99), 0, 'Addition allows for overflow (2)');

    $n1->set_ui(0);
    $n1->bnot();
    $n2->set_ui(1);
    $n2->badd($n1);
    is($n2->cmp_ui(0), 0, 'Addition allows for overflow (3)');
}

# From/to decimal string.
{
    my @nums = (
        '0', '1', '2', '3', '1024', '10000', '65535', '65536',
        '12341234123412341234', $max_128_minus_1, $max_128
    );

    for my $num (@nums) {
        my $mb = Math::BigInt->new($num);
        my $n128 = $nt->new();
        $n128->set_decstr($num);
        my $mbstr = $mb->bstr();
        my $n128str = $n128->bstr();
        is($n128str, $mbstr, "From/to string ($num)");
    }

    my $n128 = $nt->new();
    $n128->set_ui(0);
    $n128->set_decstr('340282366920938463463374607431768211456');
    is($n128->bstr(), $max_128,
        'If number is too large, N128 is set to (1 << 128) - 1');
}

# From/to decimal string with operations.
{
    my @tests = (
        [ 'badd', '4294967295', '1', '4294967296' ],
        [ 'badd', '9223372036854775807', '4294967297',
                  '9223372041149743104' ],
        [ 'badd', $max_128, '1', '0' ],
        [ 'badd', $max_128, '5', '4' ],
        [ 'badd', $max_128_minus_1, 1, $max_128 ],
        [ 'badd', $max_128_minus_1, 2, 0 ],
        [ 'bsub', '4294967296', '1', '4294967295' ],
        [ 'bsub', '9223372041149743104', '9223372036854775807', 
                  '4294967297' ],
        [ 'bsub', $max_128, 1, $max_128_minus_1 ],
    );

    for my $data (@tests) {
        my ($fn, $n1v, $n2v, $res) = @{$data};
        my $n1 = $nt->new();
        my $n2 = $nt->new();
        my $n3 = $nt->new();
        $n1->set_decstr($n1v);
        $n2->set_decstr($n2v);
        $n3->set_decstr($res);
        $n1->$fn($n2);
        is($n1->cmp($n3), 0, "$n1v $fn $n2v equals $res");
    }
}

1;
