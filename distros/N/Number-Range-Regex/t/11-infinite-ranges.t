#!perl -w
$|++;

use strict;
use Test::More tests => 333;

use lib "./t";
use _nrr_test_util;

use lib "./blib/lib";
use Number::Range::Regex;
use Number::Range::Regex::Util::inf qw ( neg_inf pos_inf );

# test both ways, return true if both are true, false if both false, else die
sub test_symmetrical {
  my ($r1, $r2, $op) = @_;
  my $v1 = $r1->$op( $r2 );
  my $v2 = $r2->$op( $r1 );
  return $v1 && $v2   ? 1
       : !$v1 && !$v2 ? undef
       : die "assymetrical test $r1->$op($r2) != $r2->$op($r1)";
}

my $r;
my $both = Number::Range::Regex::SimpleRange->new( neg_inf, pos_inf );
my $le_3 = Number::Range::Regex::SimpleRange->new( neg_inf, 3 );
my $le_4 = Number::Range::Regex::SimpleRange->new( neg_inf, 4 );
my $le_5 = Number::Range::Regex::SimpleRange->new( neg_inf, 5 );
my $ge_3 = Number::Range::Regex::SimpleRange->new( 3, pos_inf );
my $ge_4 = Number::Range::Regex::SimpleRange->new( 4, pos_inf );
my $ge_5 = Number::Range::Regex::SimpleRange->new( 5, pos_inf );

ok($both->contains($_)) for(-1,0,1);
ok($le_3->contains($_)) for(-1..3);
ok(!$le_3->contains($_)) for(4,99);
ok($le_4->contains($_)) for(-1..4);
ok(!$le_4->contains($_)) for(5,99);
ok($le_5->contains($_)) for(-1..5);
ok(!$le_5->contains($_)) for(6,99);

ok(!$ge_3->contains($_)) for(-1..2);
ok($ge_3->contains($_)) for(3..5,99);
ok(!$ge_4->contains($_)) for(-1..3);
ok($ge_4->contains($_)) for(4..5,99);
ok(!$ge_5->contains($_)) for(-1..4);
ok($ge_5->contains($_)) for(5,99);

# everything touches and overlaps the complete set
foreach ($le_3, $le_4, $le_5, $ge_3, $ge_4, $ge_5) {
  ok( test_symmetrical($both, $_, 'touches') );
  ok( test_symmetrical($both, $_, 'overlaps') );
}

# everything touches and overlaps anything going the same direction
foreach my $le_a ( $le_3, $le_4, $le_5 ) {
  foreach my $le_b ( $le_3, $le_4, $le_5 ) {
    ok( test_symmetrical($le_a, $le_b, 'touches') );
    ok( test_symmetrical($le_a, $le_b, 'overlaps') );
  }
}
foreach my $ge_a ( $ge_3, $ge_4, $ge_5 ) {
  foreach my $ge_b ( $ge_3, $ge_4, $ge_5 ) {
    ok( test_symmetrical($ge_a, $ge_b, 'touches') );
    ok( test_symmetrical($ge_a, $ge_b, 'overlaps') );
  }
}

ok( test_symmetrical($ge_3, $le_3, 'touches') );
ok( test_symmetrical($ge_3, $le_3, 'overlaps') );
ok( test_symmetrical($ge_3, $le_4, 'touches') );
ok( test_symmetrical($ge_3, $le_4, 'overlaps') );
ok( test_symmetrical($ge_3, $le_5, 'touches') );
ok( test_symmetrical($ge_3, $le_5, 'overlaps') );

ok( test_symmetrical($ge_4, $le_3, 'touches') );
ok( !test_symmetrical($ge_4, $le_3, 'overlaps') );
ok( test_symmetrical($ge_4, $le_4, 'touches') );
ok( test_symmetrical($ge_4, $le_4, 'overlaps') );
ok( test_symmetrical($ge_4, $le_5, 'touches') );
ok( test_symmetrical($ge_4, $le_5, 'overlaps') );

ok( !test_symmetrical($ge_5, $le_3, 'touches') );
ok( !test_symmetrical($ge_5, $le_3, 'overlaps') );
ok( test_symmetrical($ge_5, $le_4, 'touches') );
ok( !test_symmetrical($ge_5, $le_4, 'overlaps') );
ok( test_symmetrical($ge_5, $le_5, 'touches') );
ok( test_symmetrical($ge_5, $le_5, 'overlaps') );

#IR->union( SR ) tests
$r = $both->union( Number::Range::Regex::CompoundRange->new() );
ok($r->to_string eq $both->to_string);
$r = $le_5->union( Number::Range::Regex::CompoundRange->new() );
ok($r->to_string eq $le_5->to_string);
$r = $ge_5->union( Number::Range::Regex::CompoundRange->new() );

ok($r->to_string eq $ge_5->to_string);
$r = $le_5->union( range(2, 4) );
ok($r->to_string eq "-inf..5") ;
ok(!$r->isa('Number::Range::Regex::CompoundRange'));
ok($r->is_infinite);
ok($r->contains($_)) for(-1..5);
ok(!$r->contains($_)) for(6);
$r = $le_5->union( range(2, 5) );
ok($r->to_string eq "-inf..5") ;
ok(!$r->isa('Number::Range::Regex::CompoundRange'));
ok($r->is_infinite);
ok($r->contains($_)) for(-1..5);
ok(!$r->contains($_)) for(6);
$r = $le_5->union( range(2, 6) );
ok($r->to_string eq "-inf..6") ;
ok(!$r->isa('Number::Range::Regex::CompoundRange'));
ok($r->is_infinite);
ok($r->contains($_)) for(-1..6);
ok(!$r->contains($_)) for(7);
$r = $le_5->union( range(6, 7) ); # test touches() operation
ok($r->to_string eq "-inf..7") ;
ok(!$r->isa('Number::Range::Regex::CompoundRange'));
ok($r->is_infinite);
ok($r->contains($_)) for(-1..7);
ok(!$r->contains($_)) for(8);
$r = $le_5->union( range(7, 8) );
ok($r->to_string eq "-inf..5,7..8") ;
ok($r->isa('Number::Range::Regex::CompoundRange'));
ok($r->is_infinite);
ok($r->contains($_)) for(-1..5,7..8);
ok(!$r->contains($_)) for(6,9);

$r = $ge_5->union( range(6, 8) );
ok($r->to_string eq "5..+inf");
ok(!$r->isa('Number::Range::Regex::CompoundRange'));
ok($r->is_infinite);
ok(!$r->contains($_)) for(-1..4);
ok($r->contains($_)) for(5..9);
$r = $ge_5->union( range(5, 8) );
ok($r->to_string eq "5..+inf");
ok(!$r->isa('Number::Range::Regex::CompoundRange'));
ok($r->is_infinite);
ok(!$r->contains($_)) for(-1..4);
ok($r->contains($_)) for(5..9);
$r = $ge_5->union( range(4, 8) );
ok($r->to_string eq "4..+inf");
ok(!$r->isa('Number::Range::Regex::CompoundRange'));
ok($r->is_infinite);
ok(!$r->contains($_)) for(-1..3);
ok($r->contains($_)) for(4..9);
$r = $ge_5->union( range(3, 4) ); # test touches() operation
ok($r->to_string eq "3..+inf");
ok(!$r->isa('Number::Range::Regex::CompoundRange'));
ok($r->is_infinite);
ok(!$r->contains($_)) for(-1..2);
ok($r->contains($_)) for(3..9);
$r = $ge_5->union( range(2, 3) );
ok($r->to_string eq "2..3,5..+inf");
ok($r->isa('Number::Range::Regex::CompoundRange'));
ok($r->is_infinite);
ok(!$r->contains($_)) for(-1..1,4);
ok($r->contains($_)) for(2..3,5..9);

# IR->union( CR ) tests
$r = $both->union( rangespec( '1,9' ) );
ok($r->to_string eq $both->to_string);
$r = $le_5->union( rangespec( '1,9' ) );
ok($r->to_string ne $le_5->to_string);
ok($r->to_string eq '-inf..5,9');
$r = $ge_5->union( rangespec( '1,9' ) );
ok($r->to_string ne $ge_5->to_string);
ok($r->to_string eq '1,5..+inf');
$r = $le_5->union( rangespec( '2,4..6,8' ) );
ok($r->to_string ne $le_5->to_string);
ok($r->to_string eq '-inf..6,8');
$r = $ge_5->union( rangespec( '2,4..6,8' ) );
ok($r->to_string ne $ge_5->to_string);
ok($r->to_string eq '2,4..+inf');

# IR->union( IR ) tests (easy ones)
for $r ($le_3, $le_4, $le_5, $ge_3, $ge_4, $ge_5) {
  # $both U anything and anything U $both == $both
  ok( $both->to_string eq $both->union( $r )->to_string );
  ok( $both->to_string eq $r->union( $both )->to_string );
  # anything U anything == anything
  ok( $r->to_string eq $r->union( $r )->to_string );
}

# IR->union( IR ) tests part 2 - same direction tests
$r = $le_3->union( $le_4 );
ok($r->to_string eq '-inf..4');
$r = $le_3->union( $le_5 );
ok($r->to_string eq '-inf..5');
$r = $le_4->union( $le_5 );
ok($r->to_string eq '-inf..5');
$r = $ge_3->union( $ge_4 );
ok($r->to_string eq '3..+inf');
$r = $ge_3->union( $ge_5 );
ok($r->to_string eq '3..+inf');
$r = $ge_4->union( $ge_5 );
ok($r->to_string eq '4..+inf');

# IR->union( IR ) tests part 3 - opposite direction tests, le*->union( ge* ) / ge*->union( le* )
$r = $le_3->union( $ge_3 );
ok($r->to_string eq '-inf..+inf');
$r = $ge_3->union( $le_3 );
ok($r->to_string eq '-inf..+inf');
$r = $le_3->union( $ge_4 );
ok($r->to_string eq '-inf..+inf');
$r = $ge_4->union( $le_3 );
ok($r->to_string eq '-inf..+inf');
$r = $le_3->union( $ge_5 );
ok($r->to_string eq '-inf..3,5..+inf');
$r = $ge_5->union( $le_3 );
ok($r->to_string eq '-inf..3,5..+inf');
$r = $le_4->union( $ge_3 );
ok($r->to_string eq '-inf..+inf');
$r = $ge_3->union( $le_4 );
ok($r->to_string eq '-inf..+inf');
$r = $le_4->union( $ge_4 );
ok($r->to_string eq '-inf..+inf');
$r = $ge_4->union( $le_4 );
ok($r->to_string eq '-inf..+inf');
$r = $le_4->union( $ge_5 );
ok($r->to_string eq '-inf..+inf');
$r = $ge_5->union( $le_4 );
ok($r->to_string eq '-inf..+inf');
$r = $le_5->union( $ge_3 );
ok($r->to_string eq '-inf..+inf');
$r = $ge_3->union( $le_5 );
ok($r->to_string eq '-inf..+inf');
$r = $le_5->union( $ge_4 );
ok($r->to_string eq '-inf..+inf');
$r = $ge_4->union( $le_5 );
ok($r->to_string eq '-inf..+inf');
$r = $le_5->union( $ge_5 );
ok($r->to_string eq '-inf..+inf');
$r = $ge_5->union( $le_5 );
ok($r->to_string eq '-inf..+inf');

# check for infiniterange creation with range() via undef/'-inf'/'+inf'
ok(range( 3, undef )->to_string eq '3..+inf');
ok(range( 3, pos_inf )->to_string eq '3..+inf');
ok(range( 3, 'inf' )->to_string eq '3..+inf');
ok(range( -3, undef )->to_string eq '-3..+inf');
ok(range( -3, pos_inf )->to_string eq '-3..+inf');
ok(range( -3, 'inf' )->to_string eq '-3..+inf');
ok(range( undef, -3 )->to_string eq '-inf..-3');
ok(range( neg_inf, -3 )->to_string eq '-inf..-3');
ok(range( undef, 3 )->to_string eq '-inf..3');
ok(range( neg_inf, 3 )->to_string eq '-inf..3');

# check for infiniterange creation with rangespec()
$r = rangespec('-inf..-2');
ok($r->to_string eq '-inf..-2');
$r = rangespec('-inf..2');
ok($r->to_string eq '-inf..2');
$r = rangespec('-2..+inf');
ok($r->to_string eq '-2..+inf');
$r = rangespec('-2..inf');
ok($r->to_string eq '-2..+inf');
$r = rangespec('2..+inf');
ok($r->to_string eq '2..+inf');
$r = rangespec('2..inf');
ok($r->to_string eq '2..+inf');
$r = rangespec('-inf..-77,-42..42,77..+inf');
ok($r->to_string eq '-inf..-77,-42..42,77..+inf');

# tests of is_infinite()
ok(!Number::Range::Regex::CompoundRange->new()->is_infinite());
ok( range(undef, 3)->is_infinite() );
ok( range(-3, undef)->is_infinite() );
ok(!range(-3, 3)->is_infinite() );
ok( rangespec('-inf..-2,2..4,6..8,10..12')->is_infinite());
ok( rangespec('2..4,6..8,10..12,14..+inf')->is_infinite());
ok(!rangespec('2..4,6..8,10..12')->is_infinite());

$r = Number::Range::Regex::CompoundRange->new();
ok( $r );
$r = $r->invert;
ok( $r );
ok( $r->is_infinite() );
ok( $r->to_string eq '-inf..+inf' );
$r = $r->invert;
ok( $r );
ok(!$r->is_infinite() );
ok( $r->to_string eq '' );
