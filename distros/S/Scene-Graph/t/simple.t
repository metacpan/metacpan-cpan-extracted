use Test::More;

use Scene::Graph::Node;
use Geometry::Primitive::Point;

my $root = Scene::Graph::Node->new;
my $child = Scene::Graph::Node->new;

$root->add_child($child);

cmp_ok($root->child_count, '==', 1, '1 child');

done_testing;