package Text::TestBase::SubTest::Node;
use strict;
use warnings;
use Class::Accessor::Lite (
    rw => [qw/parent_node index depth/],
);

sub new        { die 'override it!' }
sub is_subtest { die 'override it!' }
sub get_lineno { die 'override it!' }

sub next_sibling {
    my ($self) = @_;
    return unless $self->parent_node;
    $self->parent_node->child_nodes($self->index + 1);
}

1;

