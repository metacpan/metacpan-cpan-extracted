# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Numeric-Array.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use strict;
use Test::More tests => 18 ;

BEGIN { use_ok('Numeric::LL_Array',
 qw( packId_d packId_s packId_c packId_L access_d access_s access_L
     dd2d2_modf ds2d2_frexp dd2d2_frexp sc2L2_lshift
     ss2s2_min ss2s2_max s2s1_min_assign s2s1_max_assign)) };

my $d   = pack packId_d, my $f  = 8904625e-3;	# 5**3 * 71237 - exactly representable
my $dd  = pack packId_d, 0;
my $ss  = pack packId_s, 0;
my $res = pack packId_d, 0;

dd2d2_modf($d, $dd, $res, 0, 0, 0, 0, "", "", "");
ok(1, "finished modf($f)");
is_deeply(access_d($res), .625, "... fractional part correct");
is_deeply(access_d($dd), 8904, "... integer part correct");

ds2d2_frexp($d, $ss, $res, 0, 0, 0, 0, "", "", "");
ok(1, "finished frexp($f), short exponent");
is_deeply(access_d($res), 0.54349517822265625, "... mantissa correct");
is_deeply(access_s($ss), 14, "... exponent correct");

dd2d2_frexp($d, $dd, $res, 0, 0, 0, 0, "", "", "");
ok(1, "finished frexp($f), double exponent");
is_deeply(access_d($res), 0.54349517822265625, "... mantissa correct");
is_deeply(access_d($dd), 14, "... exponent correct");

my $s3  = pack packId_s, 3;
my $c30 = pack packId_c, 30;
my $Lr  = pack packId_L, 18;

sc2L2_lshift($s3, $c30, $Lr, 0, 0, 0, 0, "", "", "");
ok(1, "finished lshift with size change");
is_deeply(access_L($Lr), (3<<30), "... lshift correct");

my $s5  = pack packId_s, 5;
my $sR = pack packId_s, 50;

s2s1_max_assign($s5, $sR, 0, 0, 0, "", "");
is_deeply(access_s($sR), 50, "... max_assign doesn't assign");

s2s1_min_assign($s3, $sR, 0, 0, 0, "", "");
is_deeply(access_s($sR), 3, "... min_assign assigns");

s2s1_min_assign($s5, $sR, 0, 0, 0, "", "");
is_deeply(access_s($sR), 3, "... min_assign does not assign");

s2s1_max_assign($s5, $sR, 0, 0, 0, "", "");
is_deeply(access_s($sR), 5, "... max_assign assigns");

ss2s2_min($s3, $s5, $sR, 0, 0, 0, 0, "", "", "");
is_deeply(access_s($sR), 3, "... min correct");

ss2s2_max($s3, $s5, $sR, 0, 0, 0, 0, "", "", "");
is_deeply(access_s($sR), 5, "... max correct");
