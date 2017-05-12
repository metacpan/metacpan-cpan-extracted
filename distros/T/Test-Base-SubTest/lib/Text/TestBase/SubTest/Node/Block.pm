package Text::TestBase::SubTest::Node::Block;
use strict;
use warnings;
use parent qw(
    Text::TestBase::Block
    Text::TestBase::SubTest::Node
);

sub is_subtest { 0 }
sub is_block   { 1 }

1;
