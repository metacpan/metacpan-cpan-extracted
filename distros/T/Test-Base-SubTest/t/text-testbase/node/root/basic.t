use Project::Libs;
use t::Utils;

use Test::More;
use Text::TestBase::SubTest::Node::Root;
use Text::TestBase::SubTest::Node::SubTest;

my $root = Text::TestBase::SubTest::Node::Root->new;
is $root->name, 'root';
isa_ok $root, 'Text::TestBase::SubTest::Node::SubTest';

is $root->last_subtest( depth => 0 )->name, 'root';
is $root->last_subtest( depth => 1 ),       undef;

$root->append_child(
    Text::TestBase::SubTest::Node::SubTest->new(
        name => 'subtest1',
    )
);

is $root->last_subtest( depth => 1 )->name, 'subtest1';
is $root->last_subtest( depth => 2 ),       undef;

$root->child_subtests(0)->append_child(
    Text::TestBase::SubTest::Node::SubTest->new(
        name => 'subtest2-1',
    )
);
$root->child_subtests(0)->append_child(
    Text::TestBase::SubTest::Node::SubTest->new(
        name => 'subtest2-2',
    )
);

is $root->last_subtest( depth => 2 )->name, 'subtest2-2';
is $root->last_subtest( depth => 3 ),       undef;

is $root->next_sibling, undef;

done_testing;
