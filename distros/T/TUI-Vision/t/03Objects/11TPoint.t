use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Objects::Point';
}

# Test TPoint->new
my $point1 = TPoint->new(x => 5, y => 10);
is($point1->x, 5, "TPoint->new sets x correctly");
is($point1->y, 10, "TPoint->new sets y correctly");

# Test default values
my $point2 = TPoint->new();
is($point2->x, 0, "TPoint->new sets default x to 0");
is($point2->y, 0, "TPoint->new sets default y to 0");

# Test the clone method
subtest 'clone method' => sub {
  my $point = TPoint->new(x => 5, y => 10);
  my $clone = $point->clone();
  isa_ok($clone, TPoint);
  is($clone->{x}, 5, 'x is cloned correctly');
  is($clone->{y}, 10, 'y is cloned correctly');
  isnt($point, $clone, 'clone is a different object');
  is_deeply($point, $clone, 'clone has the same data as the original');
};

# Test x accessor
$point1->x(15);
is($point1->x, 15, "TPoint->x sets and gets x correctly");

# Test y accessor
$point1->y(20);
is($point1->y, 20, "TPoint->y sets and gets y correctly");

done_testing();
