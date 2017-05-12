use Project::Libs;
use t::Utils;

use Test::More;
use Text::TestBase::SubTest::Node::Block;

my $node = Text::TestBase::SubTest::Node::Block->new;

isa_ok $node, 'Text::TestBase::Block';
isa_ok $node, 'Text::TestBase::SubTest::Node';

ok   $node->is_block;
ok ! $node->is_subtest;

done_testing;
