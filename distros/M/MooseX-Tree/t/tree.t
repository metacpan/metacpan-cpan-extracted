# tree.t

use Test::Most;

{

    package MooseX::Tree::Test::Node;

    use Moose;
    with 'MooseX::Tree';

    has name => ( is => 'ro', isa => 'Str', required => 1 );

    1;
}

my $node = 'MooseX::Tree::Test::Node';

ok my $t = $node->new( name => 'root' ), "new";

ok !$t->parent, "no parent";
ok !@{ $t->children }, "no children";

is scalar( $t->ancestors ),   0, "no ancestors";
is scalar( $t->descendants ), 0, "no descendents";

my $child1 = $node->new( name => 'child 1' );
my $child2 = $node->new( name => 'child 2' );
ok $t->add_children( $child1, $child2 ), "add_children";

is $t->children->[0]->name, 'child 1', "got child";

is scalar( $t->ancestors ),   0, "no ancestors";
is scalar( $t->descendants ), 2, "got two descendents";
is_deeply
    [ map { $_->name } $t->descendants ],
    [ 'child 1', 'child 2' ],
    "correct descendants";

my $child3 = $node->new( name => 'child 3' );
ok $t->add_children($child3), "add_children to existing";

$child1->add_children(
    $node->new( name => 'grandchild 1 A' ),
    $node->new( name => 'grandchild 1 B' ),
);

$child3->add_children(
    $node->new( name => 'grandchild 3 A' ),
    $node->new( name => 'grandchild 3 B' ),
);

note "descendants - ordering";

ok my @descendants_pre   = $t->descendants( order => 'pre' ),   "pre order";
ok my @descendants_post  = $t->descendants( order => 'post' ),  "post order";
ok my @descendants_level = $t->descendants( order => 'level' ), "level order";
ok my @descendants_group = $t->descendants( order => 'group' ), "group order";

is scalar(@descendants_pre),   7, "got 7 children and grandchildren";
is scalar(@descendants_post),  7, "got 7 children and grandchildren";
is scalar(@descendants_level), 7, "got 7 children and grandchildren";
is scalar(@descendants_group), 2, "got 2 levels";

is_deeply [ map { $_->name } @descendants_pre ],
    [
    "child 1",
    "grandchild 1 A",
    "grandchild 1 B",
    "child 2",
    "child 3",
    "grandchild 3 A",
    "grandchild 3 B",
    ],
    "pre order ok";

is_deeply [ map { $_->name } @descendants_post ],
    [
    "grandchild 1 A",
    "grandchild 1 B",
    "child 1",
    "child 2",
    "grandchild 3 A",
    "grandchild 3 B",
    "child 3",
    ],
    "pre order ok";

is_deeply [ map { $_->name } @descendants_level ],
    [
    "child 1",
    "child 2",
    "child 3",
    "grandchild 1 A",
    "grandchild 1 B",
    "grandchild 3 A",
    "grandchild 3 B",
    ],
    "pre order ok";

is_deeply [ map { $_->name } @{ $descendants_group[0] } ],
    [ "child 1", "child 2", "child 3", ],
    "level 0 ok";


is_deeply [ map { $_->name } @{ $descendants_group[1] } ],
    [
    "grandchild 1 A",
    "grandchild 1 B",
    "grandchild 3 A",
    "grandchild 3 B",
    ],
    "level 1 ok";

done_testing();
