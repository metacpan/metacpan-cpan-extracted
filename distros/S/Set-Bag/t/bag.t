use Test::More tests => 47;

BEGIN { use_ok( 'Set::Bag'); }

use strict;

my $bag_n = Set::Bag->new;
my $bag_a = Set::Bag->new(apples => 3, oranges => 4);

is($bag_n, '()', 'null bag');
is($bag_a, '(apples => 3, oranges => 4)', 'bag with apples and oranges');

{
  my %g3 = $bag_a->grab;
  ok((keys(%g3) == 2) && ($g3{apples} == 3) && ($g3{oranges} == 4),
     'grab with no parameters yields a hash');
}

{
  my @g4 = $bag_a->grab('bananas','oranges','plums');
  ok(eq_array(\@g4, [undef, 4, undef]), 
     'grab with parameters yields the selected bag count');
}

my $bag_b = Set::Bag->new(mangos => 3);

$bag_b->insert(apples => 1);
ok(($bag_b->grab('apples') == 1) &&
   ($bag_b->grab('mangos') == 3), 'insert test with existing element');

$bag_b->insert(coconuts => 0);
ok(($bag_b->grab('apples') == 1) &&
   ($bag_b->grab('mangos') == 3), 'insert test with empty item');

$bag_b->delete(mangos => 1);
ok(($bag_b->grab('apples') == 1) &&
   ($bag_b->grab('mangos') == 2), 'delete test with existing element');

eval { $bag_b->delete(mangos => 10) };
ok($@, 'exception expected');
is($@, qq{Set::Bag::delete: 'mangos' 2 < 10\n}, 
   'delete more than existing test.');
ok(($bag_b->grab('apples') == 1) &&
   ($bag_b->grab('mangos') == 2), 'bag should not have changed' );

eval { $bag_b->delete(cherries => 1) };
ok($@, 'exception expected');
is($@, qq{Set::Bag::delete: 'cherries' 0 < 1\n}, 
   'delete non-existant item');
ok(($bag_b->grab('apples') == 1) &&
   ($bag_b->grab('mangos') == 2), 'bag should not have changed.');

eval { $bag_b->delete(cherries => 0) };
ok((not $@), 'delete non-existing item from bag is fine');
ok(($bag_b->grab('apples') == 1) &&
   ($bag_b->grab('mangos') == 2), 'bag should not have changed.');

{
  my $r = $bag_a->sum($bag_b);
  ok(($r->grab('apples') == 4) &&
     ($r->grab('mangos') == 2) &&
     ($r->grab('oranges') == 4), 'sum test');
}

my $bag_d = $bag_a->union($bag_b);
ok(($bag_d->grab('apples') == 3) &&
   ($bag_d->grab('mangos') == 2) &&
   ($bag_d->grab('oranges') == 4), 'union test');

{
  my $r = $bag_a->intersection($bag_b);
  ok($r->grab('apples') == 1, 'intersection test');
}

{
  my $r = $bag_a->complement;
  ok(($r->grab('apples') == 1) &&
     ($r->grab('mangos') == 3), 'complement test');
}

{
  my $r = $bag_b->copy;
  $r->insert(oranges => 1);
  ok(($r->grab('apples') == 1) &&
     ($r->grab('mangos') == 2), 'copy test');
}

{
  my $r = $bag_a + $bag_b;
  ok(($r->grab('apples') == 4) &&
     ($r->grab('mangos') == 2) &&
     ($r->grab('oranges') == 4), 'sum binary operator');
}

{
  my $r = $bag_a->copy;
  $r += $bag_b;
  ok(($r->grab('apples') == 4) &&
     ($r->grab('mangos') == 2) &&
     ($r->grab('oranges') == 4), 'sum with assignment')
}

my $bag_g = Set::Bag->new(apples => 1, oranges => 1);
{
  my $r = $bag_a - $bag_g;
  ok(($r->grab('apples') == 2) &&
     ($r->grab('oranges') == 3), 'difference unary operator');
}

{
  my $r = $bag_a->copy;
  $r -= $bag_g;
  ok(($r->grab('apples') == 2) &&
     ($r->grab('oranges') == 3), 'difference with assignment');
}

{
  my $r = $bag_a | $bag_b;
  ok(($r->grab('apples') == 3) &&
     ($r->grab('mangos') == 2) &&
     ($r->grab('oranges') == 4), 'union unary operator');
}

{
  my $r = $bag_a->copy;
  $r |= $bag_b;
  ok(($r->grab('apples') == 3) &&
     ($r->grab('mangos') == 2) &&
     ($r->grab('oranges') == 4), 'union with assignment');
}

{
  my $r = $bag_a & $bag_b;
  ok($r->grab('apples') == 1, 'intersection unary operator');
}

{ 
  my $r = $bag_a->copy;
  $r &= $bag_b;
  ok($r->grab('apples') == 1, 'intersection with assignment');
}

{
  my $r = -$bag_a;
  ok(($r->grab('apples') == 1) &&
     ($r->grab('mangos') == 3), 'comlement binary operator');
}

{
  my $over_delete;
  eval { $over_delete = $bag_d->over_delete };
  ok(not $@);
  ok($over_delete == 0, q{checking the 'over_delete' attribute});
}

eval { $bag_d->over_delete(4,5,6) };
ok($@,'exception expected');
is($@, "Set::Bag::over_delete: too many arguments (3), want 0 or 1\n", 'exception text ok');

ok($bag_d->over_delete(1) == 1, q{setting the 'over_delete' attribute});

eval { $bag_d->delete(mangos => 5) };
ok((not $@), 'ignore delete of non-existant bag element');
ok(($bag_d->grab('apples') == 3) &&
   ($bag_d->grab('oranges') == 4), 'no change to bag');

eval { $bag_d->delete(cherries => 1) };
ok((not $@), 'ignore delete of existant bag element (because of over_delete attribute)');
ok(($bag_d->grab('apples') == 3) &&
   ($bag_d->grab('oranges') == 4), 'no change to bag');

$bag_d->over_delete(0);

eval { $bag_d->insert(apples => -1) };
ok((not $@), 'insert negative is not an error');
ok(($bag_d->grab('apples') == 2) &&
   ($bag_d->grab('oranges') == 4), 'insert negative on bag is ok');

eval { $bag_d->delete(apples => -1) };
ok((not $@), 'delete negative is not an error');
ok(($bag_d->grab('apples') == 3) &&
   ($bag_d->grab('oranges') == 4), 'delete negative on bag is ok');

$bag_a->over_delete(1);

my $bag_c = $bag_a->difference($bag_b);
ok(($bag_c->grab('apples') == 2) &&
   ($bag_c->grab('oranges') == 4), 'difference test');

{
  my $r = $bag_a - $bag_b;
  ok(($r->grab('apples') == 2) &&
     ($r->grab('oranges') == 4), 'difference unary operator');
}

{
  my $r = Set::Bag->new(banana=>7, coconut=>4, grapes=>9);
  my @e = $r->elements;
  ok(eq_array(\@e, ['banana', 'coconut', 'grapes']), 'elements test');
}

{
  my $r = Set::Bag->new(kiwis => 4);
  my @e = $r->elements;
  ok(eq_array(\@e, ['kiwis']), 'elements test');
}

# eof
