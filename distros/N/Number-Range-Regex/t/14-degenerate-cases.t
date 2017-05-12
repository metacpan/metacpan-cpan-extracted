#!perl -w
$|++;

use strict;
use Test::More tests => 57;

use lib "./t";
use _nrr_test_util;

use lib "./blib/lib";
use Number::Range::Regex;

my $r;

# test leading zero stripping
$r = rangespec( '03..03', {no_leading_zeroes=>1} );
ok($r->to_string eq 3);
ok('3' =~ /^$r$/);
ok('03' !~ /^$r$/);
ok('003' !~ /^$r$/);
$r = rangespec( '03..03', {no_leading_zeroes=>0} );
ok($r->to_string eq 3);
ok('3' =~ /^$r$/);
ok('03' =~ /^$r$/);
ok('003' =~ /^$r$/);
$r = rangespec( '-03..-03', {no_leading_zeroes=>1} );
ok($r->to_string eq -3);
ok('-3' =~ /^$r$/);
ok('-03' !~ /^$r$/);
ok('-003' !~ /^$r$/);
$r = rangespec( '-03..-03', {no_leading_zeroes=>0} );
ok($r->to_string eq -3);
ok('-3' =~ /^$r$/);
ok('-03' =~ /^$r$/);
ok('-003' =~ /^$r$/);
$r = rangespec( '00..00', {no_leading_zeroes=>1} );
ok($r->to_string eq 0);
ok(0 =~ /^$r$/);
ok('00' !~ /^$r$/);
ok('000' !~ /^$r$/);
$r = rangespec( '00..00', {no_leading_zeroes=>0} );
ok($r->to_string eq 0);
ok(0 =~ /^$r$/);
ok('00' =~ /^$r$/);
ok('000' =~ /^$r$/);

# tests for -0 (aka 0)
$r = rangespec( '-0..-0' );
ok($r);
ok($r->to_string eq 0);
ok(0 =~ /^$r$/);
$r = rangespec( '-0..0' );
ok($r);
ok($r->to_string eq 0);
ok(0 =~ /^$r$/);
$r = rangespec( '0..-0' );
ok($r);
ok($r->to_string eq 0);
ok(0 =~ /^$r$/);

# -inf..-inf, +inf..+inf are errors
$r = rangespec('-inf..+inf');
ok($r);
eval { $r = rangespec('+inf..+inf'); };
ok($@);
eval { $r = rangespec('-inf..-inf'); };
ok($@);

# out of order
$r = eval { rangespec( '3..6,-6..-3' ); };
ok(!$@);
ok($r);
ok($r->to_string eq '-6..-3,3..6' );

# overlapping simplerange yields debug warn
ok_local_stderr( sub { $r = rangespec( '3..6,5..9' ) },
                 qr  /^rangespec call got overlap: 5..6/ );
ok($r);
ok($r->to_string eq '3..9' );

# non-overlapping simpleranges yield nothing on stderr
ok_local_stderr( sub { $r = rangespec( '3..5,6..9' ) },
                 qr  /^$/ );
ok($r);
ok($r->to_string eq '3..9' );

ok_local_stderr( sub { $r = rangespec( '3..4,6..9' ) },
                 qr  /^$/ );
ok($r);
ok($r->to_string eq '3..4,6..9' );

my $r1 = rangespec( '3..4,6..9' );
my $r2 = rangespec( '4..5,11..22' );
ok_local_stderr( sub { $r = $r1->union($r2, { warn_overlap => 1 } ) },
                 qr  /^union call got overlap/ );
ok($r);
ok($r->to_string eq '3..9,11..22');

$r2 = rangespec( '6,11..22' );
ok_local_stderr( sub { $r = $r1->union($r2, { warn_overlap => 1 } ) },
                 qr  /^union call got overlap/ );
ok($r);
ok($r->to_string eq '3..4,6..9,11..22');

$r2 = rangespec( '5,11..22' );
ok_local_stderr( sub { $r = $r1->union($r2, { warn_overlap => 1 } ) },
                 qr  /^$/ );
ok($r);
ok($r->to_string eq '3..9,11..22');
