use Project::Libs;
use t::Utils;

use Test::More;
use Test::Memory::Cycle;
use Text::TestBase::SubTest::Node::Block;
use Text::TestBase::SubTest::Node::SubTest;
use Test::Memory::Cycle;

my $parent1 = Text::TestBase::SubTest::Node::SubTest->new(
    name => 'parent1',
    depth => 1,
    _lineno => 2,
);

isa_ok $parent1, 'Text::TestBase::SubTest::Node';

ok ! $parent1->is_block;
ok   $parent1->is_subtest;

is $parent1->get_lineno, 2;

is_deeply $parent1->child_nodes,    [];
is_deeply $parent1->child_blocks,   [];
is_deeply $parent1->child_subtests, [];
ok ! $parent1->has_child_nodes;
ok ! $parent1->has_child_blocks;
ok ! $parent1->has_child_subtests;

$parent1->append_child(
    Text::TestBase::SubTest::Node::Block->new(name => 'block1'),
);

ok   $parent1->has_child_nodes;
ok   $parent1->has_child_blocks;
ok ! $parent1->has_child_subtests;

$parent1->append_child(
    Text::TestBase::SubTest::Node::SubTest->new(name => 'subtest1', ),
);

ok $parent1->has_child_nodes;
ok $parent1->has_child_blocks;
ok $parent1->has_child_subtests;

is $parent1->child_nodes(0)->name,   'block1';
is $parent1->child_nodes(1)->name,   'subtest1';
is $parent1->child_nodes->[0]->name, 'block1';
is $parent1->child_nodes->[1]->name, 'subtest1';

my $block1   = $parent1->child_blocks(0);
my $subtest1 = $parent1->child_subtests(0);

is $block1->name,   'block1';
is $subtest1->name, 'subtest1';
is $block1->name,   $parent1->child_blocks->[0]->name;
is $subtest1->name, $parent1->child_subtests->[0]->name;

is $parent1->next_sibling,      undef;
is $block1->next_sibling->name, $subtest1->name;
is $subtest1->next_sibling,     undef;

is $parent1->depth,  1;
is $block1->depth,   2; 
is $subtest1->depth, 2;

memory_cycle_ok($parent1);
memory_cycle_ok($block1);
memory_cycle_ok($subtest1);

done_testing;
