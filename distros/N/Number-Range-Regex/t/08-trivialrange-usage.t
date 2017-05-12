#!perl -w
$|++;

use strict;
use Test::More tests => 906;

use lib "./t";
use _nrr_test_util;

use lib "./blib/lib";
use Number::Range::Regex;

my $tr_1XX = Number::Range::Regex::TrivialRange->new(100, 199);
ok(test_rangeobj_exhaustive($tr_1XX));
ok($tr_1XX->to_string eq '100..199');
my $tr_12X = Number::Range::Regex::TrivialRange->new(120, 129);
ok(test_rangeobj_exhaustive($tr_12X));
ok($tr_12X->to_string eq '120..129');
my $tr_14X = Number::Range::Regex::TrivialRange->new(140, 149);
ok(test_rangeobj_exhaustive($tr_14X));
ok($tr_14X->to_string eq '140..149');
my $tr_100_to_149 = Number::Range::Regex::TrivialRange->new(100, 149);
ok($tr_100_to_149->to_string eq '100..149');
ok(test_rangeobj_exhaustive($tr_100_to_149));
my $tr_130_to_179 = Number::Range::Regex::TrivialRange->new(130, 179);
ok($tr_130_to_179->to_string eq '130..179');
ok(test_rangeobj_exhaustive($tr_130_to_179));

my ($range, $c, $re);

# self is superset
$range = $tr_1XX->union($tr_12X);
ok($range);
ok($range->to_string eq '100..199');
$re = $range->regex;
ok($re);
ok($range->isa('Number::Range::Regex::TrivialRange'));
ok($range->{min} == $tr_1XX->{min});
ok($range->{max} == $tr_1XX->{max});
ok( /^$re$/ ) for( 100..199 );
ok( !/^$re$/ ) for( 99,200 );
ok( $range->contains($_) ) for( 100..199 );
ok( !$range->contains($_) ) for( 99,200 );

# other is superset
$range = $tr_12X->union($tr_1XX);
ok($range);
ok($range->to_string eq '100..199');
$re = $range->regex;
ok($re);
ok($range->isa('Number::Range::Regex::TrivialRange'));
ok($range->{min} == $tr_1XX->{min});
ok($range->{max} == $tr_1XX->{max});
ok( /^$re$/ ) for( 100..199 );
ok( !/^$re$/ ) for( 99,200 );
ok( $range->contains($_) ) for( 100..199 );
ok( !$range->contains($_) ) for( 99,200 );

# overlap with an other that is higher
$range = $tr_100_to_149->union($tr_130_to_179);
ok($range);
ok($range->to_string eq '100..179');
$re = $range->regex;
ok($re);
ok(!$range->isa('Number::Range::Regex::TrivialRange'));
ok($range->{min} == 100);
ok($range->{max} == 179);
ok( /^$re$/ ) for( 100..179 );
ok( !/^$re$/ ) for( 99,180 );
ok( $range->contains($_) ) for( 100..179 );
ok( !$range->contains($_) ) for( 99,180 );

# overlap with an other that is lower
$range = $tr_130_to_179->union($tr_100_to_149);
ok($range);
ok($range->to_string eq '100..179');
$re = $range->regex;
ok($re);
ok(!$range->isa('Number::Range::Regex::TrivialRange'));
ok($range->{min} == 100);
ok($range->{max} == 179);
ok( /^$re$/ ) for( 100..179 );
ok( !/^$re$/ ) for( 99,180 );
ok( $range->contains($_) ) for( 100..179 );
ok( !$range->contains($_) ) for( 99,180 );

# discontinuous with an other that is higher
$range = $tr_12X->union($tr_14X);
ok($range);
ok($range->to_string eq '120..129,140..149');
$re = $range->regex;
ok($re);
ok(!$range->isa('Number::Range::Regex::TrivialRange'));
ok( /^$re$/ ) for( 120..129,140..149 );
ok( !/^$re$/ ) for( 119,130..139,150 );
ok( $range->contains($_) ) for( 120..129,140..149 );
ok( !$range->contains($_) ) for( 119,130..139,150 );

# discontinuous with an other that is lower
$range = $tr_14X->union($tr_12X);
ok($range);
ok($range->to_string eq '120..129,140..149');
$re = $range->regex;
ok($re);
ok(!$range->isa('Number::Range::Regex::TrivialRange'));
ok( /^$re$/ ) for( 120..129,140..149 );
ok( !/^$re$/ ) for( 119,130..139,150 );
ok( $range->contains($_) ) for( 120..129,140..149 );
ok( !$range->contains($_) ) for( 119,130..139,150 );
