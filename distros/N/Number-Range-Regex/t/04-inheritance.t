#!perl -w
$|++;

use strict;
use Test::More tests => 41;

use lib "./t";
use _nrr_test_util;

use lib "./blib/lib";
use Number::Range::Regex;
use Number::Range::Regex::Util;

my $r;

$r = empty_set();
ok($r->isa('Number::Range::Regex::Range'));
ok($r->is_empty());
ok(!$r->is_infinite());
ok(!$r->isa('Number::Range::Regex::SimpleRange'));
ok(!$r->isa('Number::Range::Regex::TrivialRange'));

$r = Number::Range::Regex::SimpleRange->new( 3, 4 );
ok($r->isa('Number::Range::Regex::Range'));
ok(!$r->is_empty());
ok(!$r->is_infinite());
ok(!$r->isa('Number::Range::Regex::CompoundRange'));
ok($r->isa('Number::Range::Regex::SimpleRange'));
ok(!$r->isa('Number::Range::Regex::TrivialRange'));

$r = $r->union( Number::Range::Regex::SimpleRange->new( 7, 11 ) );
ok($r->isa('Number::Range::Regex::Range'));
ok(!$r->is_empty());
ok(!$r->is_infinite());
ok($r->isa('Number::Range::Regex::CompoundRange'));
ok(!$r->isa('Number::Range::Regex::SimpleRange'));
ok(!$r->isa('Number::Range::Regex::TrivialRange'));

$r = Number::Range::Regex::TrivialRange->new( 5, 8 );
ok($r->isa('Number::Range::Regex::Range'));
ok(!$r->is_empty());
ok(!$r->is_infinite());
ok(!$r->isa('Number::Range::Regex::CompoundRange'));
ok($r->isa('Number::Range::Regex::SimpleRange'));
ok($r->isa('Number::Range::Regex::TrivialRange'));

$r = Number::Range::Regex::SimpleRange->new( 7, '+inf' );
ok($r->isa('Number::Range::Regex::Range'));
ok(!$r->is_empty());
ok($r->is_infinite());
ok(!$r->isa('Number::Range::Regex::CompoundRange'));
ok($r->isa('Number::Range::Regex::SimpleRange'));
ok(!$r->isa('Number::Range::Regex::TrivialRange'));

$r = $r->union( Number::Range::Regex::SimpleRange->new( -2, 2 ) );
ok($r->isa('Number::Range::Regex::Range'));
ok(!$r->is_empty());
ok($r->is_infinite());
ok($r->isa('Number::Range::Regex::CompoundRange'));
ok(!$r->isa('Number::Range::Regex::SimpleRange'));
ok(!$r->isa('Number::Range::Regex::TrivialRange'));

$r = $r->union( Number::Range::Regex::SimpleRange->new( '-inf', 99 ) );
ok($r->isa('Number::Range::Regex::Range'));
ok(!$r->is_empty());
ok($r->is_infinite());
ok(!$r->isa('Number::Range::Regex::CompoundRange'));
ok($r->isa('Number::Range::Regex::SimpleRange'));
ok(!$r->isa('Number::Range::Regex::TrivialRange'));


