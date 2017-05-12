use Test::More;

use Scene::Graph;
use Scene::Graph::Node;
use Scene::Graph::Traverser;
use Geometry::Primitive::Point;

my $root = Scene::Graph::Node->new(id => 'grandma');
my $trans = Scene::Graph::Node->new(id => 'mom');
$root->add_child($trans);

my $child = Scene::Graph::Node->new(id => 'daughter');
$trans->add_child($child);

my $child2 = Scene::Graph::Node->new(id => 'son');
$trans->add_child($child2);


my $traverser = Scene::Graph::Traverser->new(scene => $root);
cmp_ok($traverser->node_count, '==', 4, '4 nodes');
cmp_ok($traverser->next->id, 'eq', 'grandma', 'grandma is first');
cmp_ok($traverser->next->id, 'eq', 'mom', 'mom is second');
cmp_ok($traverser->next->id, 'eq', 'daughter', 'daughter is nearly last');
cmp_ok($traverser->next->id, 'eq', 'son', 'son is last');

done_testing;