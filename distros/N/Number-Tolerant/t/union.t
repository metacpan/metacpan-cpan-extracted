use Test::More tests => 102;

use strict;
use warnings;

BEGIN { use_ok("Number::Tolerant"); }

my $alpha = Number::Tolerant->new(4.5  => to => 5.25);
my $beta  = Number::Tolerant->new(5.75 => to => 6.25);

isa_ok($alpha, 'Number::Tolerant');
isa_ok($beta,  'Number::Tolerant');

my $choice = $alpha | $beta;

isa_ok($choice,   'Number::Tolerant::Union', 'union');

is_deeply(
  [ $choice->options ],
  [ $alpha, $beta ],
  ' ... options are as requested'
);

is("$choice", '(4.5 <= x <= 5.25) or (5.75 <= x <= 6.25)', ' ... stringifies');

{
  no warnings 'uninitialized';
  is(0+$choice, 0,           " ... plus zero, it's zero");
}

ok(0.0 != $alpha,          " ... 0.0 isn't equal to alpha option");
ok(0.0 != $beta,           " ... 0.0 isn't equal to beta option");

ok(0.0 != $choice,         " ... 0.0 isn't equal to it");
ok(4.4 != $choice,         " ... 4.4 isn't equal to it");
ok(4.5 == $choice,         " ... 4.5 is equal to it");
ok(5.0 == $choice,         " ... 5.0 is equal to it");
ok(5.5 != $choice,         " ... 5.5 isn't equal to it");
ok(5.6 != $choice,         " ... 5.6 isn't equal to it");
ok(6.0 == $choice,         " ... 6.0 is equal to it");

ok(not(0.0 == $choice),    " ... 0.0 isn't equal to it");
ok(not(5.0 != $choice),    " ... 5.0 isn't not equal to it");

ok(     4.4 < $alpha,     " ... 4.4 is less than alpha");
ok(not( 4.5 < $alpha),    " ... 4.5 isn't less than alpha");
ok(not( 5.0 < $alpha),    " ... 5.0 isn't less than alpha");
ok(not( 5.5 < $alpha),    " ... 5.5 isn't less than alpha");
ok(not( 5.6 < $alpha),    " ... 5.6 isn't less than alpha");

ok(     4.4 < $beta,      " ... 4.4 is less than beta");
ok(     4.5 < $beta,      " ... 4.5 isn't less than beta");
ok(     5.0 < $beta,      " ... 5.0 isn't less than beta");
ok(     5.5 < $beta,      " ... 5.5 isn't less than beta");
ok(     5.6 < $beta,      " ... 5.6 isn't less than beta");

ok(     4.4 < $choice,     " ... 4.4 is less than union");
ok(not( 4.5 < $choice),    " ... 4.5 isn't less than union");
ok(not( 5.0 < $choice),    " ... 5.0 isn't less than union");
ok(not( 5.5 < $choice),    " ... 5.5 isn't less than union");
ok(not( 5.6 < $choice),    " ... 5.6 isn't less than union");

ok(not( 4.4 > $alpha),     " ... 4.4 isn't more than alpha");
ok(not( 4.5 > $alpha),     " ... 4.5 isn't more than alpha");
ok(not( 5.0 > $alpha),     " ... 5.0 isn't more than alpha");
ok(     5.5 > $alpha,      " ... 5.5 is more than alpha");
ok(     5.6 > $alpha,      " ... 5.6 is more than alpha");
ok(     6.5 > $alpha,      " ... 6.5 is more than alpha");

ok(not( 4.4 > $beta),      " ... 4.4 isn't more than beta");
ok(not( 4.5 > $beta),      " ... 4.5 isn't more than beta");
ok(not( 5.0 > $beta),      " ... 5.0 isn't more than beta");
ok(not( 5.5 > $beta),      " ... 5.5 isn't more than beta");
ok(not( 5.6 > $beta),      " ... 5.6 isn't more than beta");
ok(     6.5 > $beta,       " ... 6.5 is more than beta");

ok(not( 4.4 > $choice),    " ... 4.4 isn't more than it");
ok(not( 4.5 > $choice),    " ... 4.5 isn't more than it");
ok(not( 5.0 > $choice),    " ... 5.0 isn't more than it");
ok(not( 5.5 > $choice),    " ... 5.5 isn't more than it");
ok(not( 5.6 > $choice),    " ... 5.6 isn't more than it");
ok(     6.5 > $choice,     " ... 6.5 is more than it");

is( (4 <=> $choice), -1,   " ... 4 <=> union is -1");
is( (5 <=> $choice),  0,   " ... 5 <=> union is 0");
is( (6 <=> $choice),  0,   " ... 6 <=> union is 0");
is( (7 <=> $choice),  1,   " ... 7 <=> union is 1");

# ... and now more of the same, BACKWARDS

ok($choice != 0.0,         " ... it isn't equal to 0.0");
ok($choice != 4.4,         " ... it isn't equal to 4.4");
ok($choice == 4.5,         " ... it is equal to 4.5");
ok($choice == 5.0,         " ... it is equal to 5.0");
ok($choice != 5.5,         " ... it is equal to 5.5");
ok($choice != 5.6,         " ... it isn't equal to 5.6");
ok($choice == 6.0,         " ... it isn't equal to 6.0");

ok(not( $alpha < 4.4),     " ... alpha isn't less than 4.4");
ok(not( $alpha < 4.5),     " ... alpha isn't less than 4.5");
ok(not( $alpha < 5.0),     " ... alpha isn't less than 5.0");
ok(     $alpha < 5.5,      " ... alpha is less than 5.5");
ok(     $alpha < 5.6,      " ... alpha is less than 5.6");
ok(     $alpha < 6.5,      " ... alpha is less than 5.6");

ok(not( $beta < 4.4),      " ... beta isn't less than 4.4");
ok(not( $beta < 4.5),      " ... beta isn't less than 4.5");
ok(not( $beta < 5.0),      " ... beta isn't less than 5.0");
ok(not( $beta < 5.5),      " ... beta isn't less than 5.5");
ok(not( $beta < 5.6),      " ... beta isn't less than 5.6");
ok(     $beta < 6.5,       " ... beta is less than 5.6");

ok(not( $choice < 4.4),    " ... it isn't less than 4.4");
ok(not( $choice < 4.5),    " ... it isn't less than 4.5");
ok(not( $choice < 5.0),    " ... it isn't less than 5.0");
ok(not( $choice < 5.5),    " ... it isn't less than 5.5");
ok(not( $choice < 5.6),    " ... it isn't less than 5.6");
ok(     $choice < 6.5,     " ... it is less than 5.6");

ok(     $alpha > 4.4,      " ... alpha is more than 4.4");
ok(not( $alpha > 4.5),     " ... alpha isn't more than 4.5");
ok(not( $alpha > 5.0),     " ... alpha isn't more than 5.0");
ok(not( $alpha > 5.5),     " ... alpha isn't more than 5.5");
ok(not( $alpha > 5.6),     " ... alpha isn't more than 5.6");
ok(not( $alpha > 6.5),     " ... alpha isn't more than 6.5");

ok(     $beta > 4.4,       " ... beta is more than 4.4");
ok(     $beta > 4.5,       " ... beta is more than 4.5");
ok(     $beta > 5.0,       " ... beta is more than 5.0");
ok(     $beta > 5.5,       " ... beta is more than 5.5");
ok(     $beta > 5.6,       " ... beta is more than 5.6");
ok(not( $beta > 6.5),      " ... beta isn't more than 6.5");

ok(     $choice > 4.4,     " ... it is more than 4.4");
ok(not( $choice > 4.5),    " ... it isn't more than 4.5");
ok(not( $choice > 5.0),    " ... it isn't more than 5.0");
ok(not( $choice > 5.5),    " ... it isn't more than 5.5");
ok(not( $choice > 5.6),    " ... it isn't more than 5.6");
ok(not( $choice > 6.5),    " ... it isn't more than 6.5");

is( ($choice <=> 4),  1,    " ... 4 <=> it is 1");
is( ($choice <=> 5),  0,    " ... 5 <=> it is 0");
is( ($choice <=> 6),  0,    " ... 6 <=> it is 0");
is( ($choice <=> 7), -1,    " ... 7 <=> it is -1");
