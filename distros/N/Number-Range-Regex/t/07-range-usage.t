#!perl -w
$|++;

use strict;
use Test::More tests => 960;

use lib "./t";
use _nrr_test_util;

use lib "./blib/lib";
use Number::Range::Regex qw ( range rangespec );

my $r_1XX = range(100, 199);
ok(test_rangeobj_exhaustive($r_1XX));
ok($r_1XX->to_string eq '100..199');
my $r_12X = range(120, 129);
ok(test_rangeobj_exhaustive($r_12X));
ok($r_12X->to_string eq '120..129');
my $r_14X = range(140, 149);
ok(test_rangeobj_exhaustive($r_14X));
ok($r_14X->to_string eq '140..149');
my $r_100_to_149 = range(100, 149);
ok(test_rangeobj_exhaustive($r_100_to_149));
ok($r_100_to_149->to_string eq '100..149');
my $r_130_to_179 = range(130, 179);
ok(test_rangeobj_exhaustive($r_130_to_179));
ok($r_130_to_179->to_string eq '130..179');

my ($range, $c, $re);

# self is superset
$range = $r_1XX->union($r_12X);
ok($range->to_string eq '100..199');
$re = $range->regex;
ok($range);
ok($re);
ok($range->{min} == $r_1XX->{min});
ok($range->{max} == $r_1XX->{max});
ok( /^$re$/ ) for( 100..199 );
ok( !/^$re$/ ) for( 99,200 );
ok( $range->contains($_) ) for( 100..199 );
ok( !$range->contains($_) ) for( 99,200 );

# other is superset
$range = $r_12X->union($r_1XX);
ok($range->to_string eq '100..199');
$re = $range->regex;
ok($range);
ok($re);
ok($range->{min} == $r_1XX->{min});
ok($range->{max} == $r_1XX->{max});
ok( /^$re$/ ) for( 100..199 );
ok( !/^$re$/ ) for( 99,200 );
ok( $range->contains($_) ) for( 100..199 );
ok( !$range->contains($_) ) for( 99,200 );

# test uncollapsible ranges
my $r_1XXb = range(101, 198);
ok(test_rangeobj_exhaustive($r_1XXb));
ok($r_1XXb->to_string eq '101..198');
my $r_12Xb = range(121, 128);
ok(test_rangeobj_exhaustive($r_12Xb));
ok($r_12Xb->to_string eq '121..128');
$range = $r_1XXb->union($r_12Xb);
ok($range);
$re = $range->regex;
ok($re);
ok($range->{min} == $r_1XXb->{min});
ok($range->{max} == $r_1XXb->{max});

# overlap with an other that is higher
$range = $r_100_to_149->union($r_130_to_179);
ok($range);
ok($range->to_string eq '100..179');
$re = $range->regex;
ok($re);
ok($range->{min} == 100);
ok($range->{max} == 179);
ok( /^$re$/ ) for( 100..179 );
ok( !/^$re$/ ) for( 99,180 );
ok( $range->contains($_) ) for( 100..179 );
ok( !$range->contains($_) ) for( 99,180 );

# overlap with an other that is lower
$range = $r_130_to_179->union($r_100_to_149);
ok($range);
ok($range->to_string eq '100..179');
$re = $range->regex;
ok($re);
ok($range->{min} == 100);
ok($range->{max} == 179);
ok( /^$re$/ ) for( 100..179 );
ok( !/^$re$/ ) for( 99,180 );
ok( $range->contains($_) ) for( 100..179 );
ok( !$range->contains($_) ) for( 99,180 );

# discontinuous with an other that is higher
$range = $r_12X->union($r_14X);
ok($range);
ok($range->to_string eq '120..129,140..149');
$re = $range->regex;
ok($re);
ok(!defined $range->{min});
ok(!defined $range->{max});
ok( /^$re$/ ) for( 120..129,140..149 );
ok( !/^$re$/ ) for( 119,130..139,150 );
ok( $range->contains($_) ) for( 120..129,140..149 );
ok( !$range->contains($_) ) for( 119,130..139,150 );

# discontinuous with an other that is lower
$range = $r_14X->union($r_12X);
ok($range);
ok($range->to_string eq '120..129,140..149');
$re = $range->regex;
ok($re);
ok(!defined $range->{min});
ok(!defined $range->{max});
ok( /^$re$/ ) for( 120..129,140..149 );
ok( !/^$re$/ ) for( 119,130..139,150 );
ok( $range->contains($_) ) for( 120..129,140..149 );
ok( !$range->contains($_) ) for( 119,130..139,150 );

$range = range(100, 104);
ok($range);
ok($range->to_string eq '100..104');
ok($range->regex);
ok(test_range_regex(100, 104, $range->regex));
ok(check_type($range, 'Simple'));

$range = $range->union( range(106, 109) );
ok($range);
ok($range->to_string eq '100..104,106..109');
ok($range->regex);
ok(test_range_regex(100, 104, $range->regex));
ok(test_range_regex(106, 109, $range->regex));
ok(check_type($range, 'Compound'));

$range = $range->union( range(104, 106) );
ok($range);
ok($range->to_string eq '100..109');
ok($range->regex);
ok(test_range_regex(100, 109, $range->regex));
ok(check_type($range, 'Simple'));

$range = range(99, 104);
ok($range);
ok($range->to_string eq '99..104');
ok($range->regex);
ok(test_range_regex(99, 104, $range->regex));
ok(check_type($range, 'Simple'));

$range = $range->union( range(106, 109) );
ok($range);
ok($range->to_string eq '99..104,106..109');
ok($range->regex);
ok(test_range_regex(99, 104, $range->regex));
ok(test_range_regex(106, 109, $range->regex));
ok(check_type($range, 'Compound'));

$range = $range->union( range(105, 105) );
ok($range);
ok($range->to_string eq '99..109');
ok($range->regex);
ok(test_range_regex(99, 109, $range->regex));
ok(check_type($range, 'Simple'));

$range = range(3, 37);
ok($range);
ok($range->to_string eq '3..37');
ok(check_type($range, 'Simple'));
$range = $range->union( range(40,50) );
ok($range);
ok($range->to_string eq '3..37,40..50');
ok(check_type($range, 'Compound'));
$range = $range->union( range(82, 92) );
ok($range->to_string eq '3..37,40..50,82..92');
ok($range);
my $rlength = length($range->regex);
ok(check_type($range, 'Compound'));
$range = $range->union( range(61, 71) );
ok($range->to_string eq '3..37,40..50,61..71,82..92');
ok($range);
ok(check_type($range, 'Compound'));
$range = $range->union( range(7, 85) );
ok($range);
ok($range->to_string eq '3..92');
ok($rlength > length($range->regex));
ok(check_type($range, 'Simple'));

