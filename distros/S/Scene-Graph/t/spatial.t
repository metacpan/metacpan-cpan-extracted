use Test::More;

use Scene::Graph;
use Scene::Graph::Node;
use Scene::Graph::Node::Spatial;
use Scene::Graph::Node::Transform;
use Scene::Graph::Traverser;
use Geometry::Primitive::Point;

my $root = Scene::Graph::Node->new(id => 'grandma');
my $trans = Scene::Graph::Node::Spatial->new(id => 'mom');
$trans->origin->x(5);
$trans->origin->y(5);
$root->add_child($trans);

my $child = Scene::Graph::Node::Spatial->new(id => 'daughter');
$child->origin->x(5);
$child->origin->y(5);

$trans->add_child($child);

my $child2 = Scene::Graph::Node::Spatial->new(id => 'son');
$child2->origin->x(2);
$child2->origin->y(2);

$trans->add_child($child2);

cmp_ok($trans->child_count, '==', 2, 'mom has 2 children');

my $traverser = Scene::Graph::Traverser->new(scene => $root);
cmp_ok($traverser->next->id, 'eq', 'grandma', 'grandma is first');

my $mom = $traverser->next;
cmp_ok($mom->id, 'eq', 'mom', 'mom is second');
cmp_ok($mom->origin->x, '==', 5, 'mom x:5');
cmp_ok($mom->origin->y, '==', 5, 'mom y:5');

my $daughter = $traverser->next;
cmp_ok($daughter->id, 'eq', 'daughter', 'daughter is last');
cmp_ok($daughter->origin->x, '==', 10, 'daughter x:10');
cmp_ok($daughter->origin->y, '==', 10, 'daughter y:10');

my $son = $traverser->next;
cmp_ok($son->id, 'eq', 'son', 'son is last');
cmp_ok($son->origin->x, '==', 7, 'son x:7');
cmp_ok($son->origin->y, '==', 7, 'son y:7');

done_testing;