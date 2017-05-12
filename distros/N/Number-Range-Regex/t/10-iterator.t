#!perl -w
$|++;

use strict;
use Test::More tests => 190;

use lib "./t";
use _nrr_test_util;

use lib "./blib/lib";
use Number::Range::Regex qw ( range rangespec );
use Number::Range::Regex::Util;
use Number::Range::Regex::Iterator;

my ($it, $range);

$range = range(4, 55);
ok($range);

$it = $range->iterator();
ok($it);
ok($it->isa('Number::Range::Regex::Iterator'));

# tests for fetch/next/prev before explicit first/last/seek should be ok here
# since we have a defined min and therefore call first() at new time
eval { $it->fetch() }; ok(!$@);
eval { $it->next() }; ok(!$@);
eval { $it->prev() }; ok(!$@);

# Iterator->new(...)->fetch == Iterator->new(...)->first->fetch
eval { $it->fetch }; ok(!$@);
ok($it->fetch == 4);

# check first(), last(), seek()
ok($it->first);
ok($it->fetch == 4);
ok($it->first->fetch == 4);
ok($it->last);
ok($it->fetch == 55);
ok($it->last->fetch == 55);
ok($it->seek(42));
ok($it->fetch == 42);
ok($it->prev->fetch == 41);
ok($it->seek(42)->next->fetch == 43);

# prev()/next() not valid after going out of range
ok($it->first);
do {} while ($it->next);
eval { $it->next }; ok($@);
ok($it->first);
do {} while ($it->next);
eval { $it->prev }; ok($@);
ok($it->last);
do {} while ($it->prev);
eval { $it->next }; ok($@);
ok($it->last);
do {} while ($it->prev);
eval { $it->prev }; ok($@);
ok($it->seek(4)->fetch() == 4);
ok($it->seek(55)->fetch() == 55);
eval { $it->seek(500) }; ok($@);

# one-liners involving new()
ok(Number::Range::Regex::Iterator->new( $range )->first->fetch == 4);
ok(Number::Range::Regex::Iterator->new( $range )->last->fetch == 55);

# some more one-liners
ok($it->first->next->next->fetch == 6);
ok($it->first->next->prev->next->fetch == 5);
ok($it->last->prev->prev->fetch == 53);
ok($it->last->prev->next->prev->fetch == 54);

$range = range( 3, 3 )->intersection( range( 4, 4 ) ); #empty range
ok($range);
eval { $it = $range->iterator(); };
ok($@);

$range = rangespec('0,2,4,6,8');
ok($range);
$it = $range->iterator();
ok($it);
ok($it->isa('Number::Range::Regex::Iterator'));

# check first(), last(), seek()
ok($it->first->fetch == 0);
ok($it->last->fetch == 8);
ok($it->seek(4));
ok($it->fetch == 4);
ok($it->prev->fetch == 2);
ok($it->seek(4)->next->fetch == 6);

ok( $it->first->fetch == 0);
ok( $it->next->fetch == 2);
ok( $it->next->fetch == 4);
ok( $it->next->fetch == 6);
ok( $it->next->fetch == 8);
eval { $it->next->fetch; }; ok($@);

ok( $it->last->fetch == 8);
ok( $it->prev->fetch == 6);
ok( $it->prev->fetch == 4);
ok( $it->prev->fetch == 2);
ok( $it->prev->fetch == 0);
eval { $it->prev->fetch; }; ok($@);
eval { $it->seek( -1 ) }; ok($@);
eval { $it->seek( 1 ) }; ok($@);
eval { $it->seek( 3 ) }; ok($@);
eval { $it->seek( 5 ) }; ok($@);
eval { $it->seek( 7 ) }; ok($@);
eval { $it->seek( 9 ) }; ok($@);

# test number of elements in a large iterator
$range = rangespec('1,10..19,100..199,1000..1999,10000..19999');
ok($range);
$it = $range->iterator();
ok($it);
ok($it->isa('Number::Range::Regex::Iterator'));
$it->first;
my $c = 0;
do { ++$c } while ($it->next);
ok($c == 11111);
# some first/last/seek tests on a large iterator
ok($it->first->fetch == 1);
ok($it->last->fetch == 19999);
ok($it->seek(12)->fetch == 12);
ok($it->seek(123)->fetch == 123);
ok($it->seek(1234)->fetch == 1234);
ok($it->seek(12345)->fetch == 12345);
eval { $it->seek( 0 ) }; ok($@);
eval { $it->seek( 5 ) }; ok($@);
eval { $it->seek( 50 ) }; ok($@);
eval { $it->seek( 500 ) }; ok($@);
eval { $it->seek( 5000 ) }; ok($@);
eval { $it->seek( 50000 ) }; ok($@);

# test a trivialrange
$range = Number::Range::Regex::TrivialRange->new( 1230, 1239 );
ok($range);
$it = $range->iterator();
ok($it);
ok($it->isa('Number::Range::Regex::Iterator'));
ok($it->seek(1234)->fetch == 1234);
ok($it->first->fetch == 1230);
ok($it->next->fetch == 1231);
ok($it->next->next->fetch == 1233);
ok($it->next->next->next->next->next->next->fetch == 1239);
eval { $it->next };
ok(!$@);
eval { $it->fetch };
ok($@); # can't fetch() an out of range (overflow) iterator

# test an emptyrange
$range = rangespec('');
ok($range);
eval { $it = $range->iterator(); };
ok($@); #can get an iterator object, just can't do anything useful

# tests on infiniteranges
$range = range( 2, undef );
ok($range);
$it = $range->iterator();
ok($it);
ok($it->isa('Number::Range::Regex::Iterator'));
# can fetch/next/prev before first/last/seek, as min is defined
eval { $it->fetch() }; ok(!$@);
eval { $it->next() }; ok(!$@);
eval { $it->prev() }; ok(!$@);
ok($it->first->fetch == 2);
ok($it->next->fetch == 3);
ok($it->next->prev->next->prev->fetch == 3);
ok($it->prev->next->prev->next->fetch == 3);
ok($it->next->next->next->prev->prev->prev->fetch == 3);
eval { $it->last };
ok($@);
eval { $it->seek( 1 ) };
ok($@);
ok($it->seek( 2**30 )->next->fetch == 2**30+1);
ok($it->seek( 2**30 )->prev->fetch == 2**30-1);

$range = range( -2, undef );
ok($range);
$it = $range->iterator();
ok($it);
ok($it->isa('Number::Range::Regex::Iterator'));
# can fetch/next/prev before first/last/seek, as min is defined
eval { $it->fetch() }; ok(!$@);
eval { $it->next() }; ok(!$@);
eval { $it->prev() }; ok(!$@);
ok($it->first->fetch == -2);
ok($it->next->fetch == -1);
ok($it->next->fetch == 0);
ok($it->next->fetch == 1);
ok($it->next->prev->next->prev->fetch == 1);
ok($it->prev->next->prev->next->fetch == 1);
ok($it->prev->prev->prev->next->next->next->fetch == 1);
eval { $it->last };
ok($@);
eval { $it->seek( -3 ) };
ok($@);
ok($it->seek( 2**30 )->next->fetch == 2**30+1);
ok($it->seek( 2**30 )->prev->fetch == 2**30-1);

$range = range( undef, 2 );
ok($range);
$it = $range->iterator();
ok($it);
ok($it->isa('Number::Range::Regex::Iterator'));
# can't fetch/next/prev before first/last/seek - min not defined
eval { $it->fetch() }; ok($@);
eval { $it->next() }; ok($@);
eval { $it->prev() }; ok($@);

eval { $it->first };
ok($@);
ok($it->last->fetch == 2);
ok($it->prev->fetch == 1);
ok($it->prev->fetch == 0);
ok($it->prev->fetch == -1);
ok($it->next->prev->next->prev->fetch == -1);
ok($it->prev->next->prev->next->fetch == -1);
ok($it->next->next->next->prev->prev->prev->fetch == -1);
ok($it->prev->prev->prev->next->next->next->fetch == -1);
ok($@);
eval { $it->seek( 3 ) };
ok($@);
ok($it->seek( -2**30 )->next->fetch == -2**30+1);
ok($it->seek( -2**30 )->prev->fetch == -2**30-1);

$range = range( undef, -2 );
ok($range);
$it = $range->iterator();
ok($it);
ok($it->isa('Number::Range::Regex::Iterator'));
# can't fetch/next/prev before first/last/seek - min not defined
eval { $it->fetch() }; ok($@);
eval { $it->next() }; ok($@);
eval { $it->prev() }; ok($@);
eval { $it->first };
ok($@);
ok($it->last->fetch == -2);
ok($it->prev->fetch == -3);
ok($it->prev->fetch == -4);
ok($it->prev->fetch == -5);
ok($it->next->prev->next->prev->fetch == -5);
ok($it->prev->next->prev->next->fetch == -5);
ok($it->next->next->next->prev->prev->prev->fetch == -5);
ok($it->prev->prev->prev->next->next->next->fetch == -5);
ok($@);
eval { $it->seek( -1 ) };
ok($@);
ok($it->seek( -2**30 )->next->fetch == -2**30+1);
ok($it->seek( -2**30 )->prev->fetch == -2**30-1);

$range = range(undef, -1000)->union( range(1000, undef) );
ok($range);
ok($range->to_string eq '-inf..-1000,1000..+inf');
$it = $range->iterator();
ok($it);
ok($it->isa('Number::Range::Regex::Iterator'));
# can't fetch/next/prev before first/last/seek - min not defined
eval { $it->fetch() }; ok($@);
eval { $it->next() }; ok($@);
eval { $it->prev() }; ok($@);
eval { $it->first };
ok($@);
eval { $it->last };
ok($@);
ok($it->seek( -1001 )->fetch == -1001);
ok($it->seek( -1000 )->fetch == -1000);
ok($it->seek( 1000 )->fetch == 1000);
ok($it->seek( 1001 )->fetch == 1001);
eval { $it->seek( -999 ) }; ok($@);
eval { $it->seek( -99 ) }; ok($@);
eval { $it->seek( -9 ) }; ok($@);
eval { $it->seek( 0 ) }; ok($@);
eval { $it->seek( 9 ) }; ok($@);
eval { $it->seek( 99 ) }; ok($@);
eval { $it->seek( 999 ) }; ok($@);
ok($it->seek( 2**30 )->next->fetch == 2**30+1);
ok($it->seek( 2**30 )->prev->fetch == 2**30-1);
ok($it->seek( -2**30 )->next->fetch == -2**30+1);
ok($it->seek( -2**30 )->prev->fetch == -2**30-1);

$range = empty_set();
ok($range);
ok($range->to_string eq '');
eval { $it = $range->iterator(); };
ok($@);
ok($@ =~ /iterate over an empty range/);
