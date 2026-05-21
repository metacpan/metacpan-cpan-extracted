use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Objects::Point';
  use_ok 'TUI::Objects::Rect';
}

my $p1 = TPoint->new( x => 5,  y => 5 );
my $p2 = TPoint->new( x => 15, y => 15 );
isa_ok( $p1, TPoint );
isa_ok( $p2, TPoint );

my $rect1 = TRect->new( ax => 0, ay => 0, bx => 10, by => 10 );
my $rect2 = TRect->new( a => $p1, b => $p2 );
isa_ok( $rect1, TRect );
isa_ok( $rect2, TRect );

ok( $rect1->contains( TPoint->new( x => 5, y => 5 ) ),
  "Rect1 contains point (5,5)" );
ok( !$rect1->isEmpty(), "Rect1 is not empty" );

$rect1->move( 2, 3 );
is( $rect1->a->x(), 2,  "Rect1 moved to (2,3): a.x" );
is( $rect1->a->y(), 3,  "Rect1 moved to (2,3): a.y" );
is( $rect1->b->x(), 12, "Rect1 moved to (2,3): b.x" );
is( $rect1->b->y(), 13, "Rect1 moved to (2,3): b.y" );

$rect1->grow( 1, 1 );
is( $rect1->a->x(), 1,  "Rect1 grown by (1,1): a.x" );
is( $rect1->a->y(), 2,  "Rect1 grown by (1,1): a.y" );
is( $rect1->b->x(), 13, "Rect1 grown by (1,1): b.x" );
is( $rect1->b->y(), 14, "Rect1 grown by (1,1): b.y" );

$rect1->intersect( $rect2 );
is( $rect1->a->x(), 5,  "Rect1 intersected with Rect2: a.x" );
is( $rect1->a->y(), 5,  "Rect1 intersected with Rect2: a.y" );
is( $rect1->b->x(), 13, "Rect1 intersected with Rect2: b.x" );
is( $rect1->b->y(), 14, "Rect1 intersected with Rect2: b.y" );

$rect1->Union( $rect2 );
is( $rect1->a->x(), 5,  "Rect1 union with Rect2: a.x" );
is( $rect1->a->y(), 5,  "Rect1 union with Rect2: a.y" );
is( $rect1->b->x(), 15, "Rect1 union with Rect2: b.x" );
is( $rect1->b->y(), 15, "Rect1 union with Rect2: b.y" );

# Test overloaded operators
ok( $rect1 == $rect2, "Rect1 is equal to Rect2" );
ok( $rect1 != TRect->new( ax => 0, ay => 0, bx => 10, by => 10 ),
  "Rect1 is not equal to a new Rect" );

# Test a accessor
$rect1->a( $p1 );
cmp_ok( $rect1->a(), '==', $p1, "Rect1 a sets and gets correctly" );

# Test b accessor
$rect1->b( $p2 );
cmp_ok( $rect1->b(), '==', $p2, "Rect1 b sets and gets correctly" );

# Test the clone method
subtest 'clone method' => sub {
  my $rect = TRect->new(ax => 1, ay => 2, bx => 3, by => 4);
  my $clone = $rect->clone();
  isa_ok($clone, TRect);
  isa_ok($clone->{a}, TPoint);
  isa_ok($clone->{b}, TPoint);
  is($clone->{a}{x}, 1, 'a.x is cloned correctly');
  is($clone->{a}{y}, 2, 'a.y is cloned correctly');
  is($clone->{b}{x}, 3, 'b.x is cloned correctly');
  is($clone->{b}{y}, 4, 'b.y is cloned correctly');
  isnt($rect, $clone, 'clone is a different object');
  is_deeply($rect, $clone, 'clone has the same data as the original');
};

done_testing();
