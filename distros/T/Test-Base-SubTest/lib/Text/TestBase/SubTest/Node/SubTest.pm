package Text::TestBase::SubTest::Node::SubTest;
use parent qw(Text::TestBase::SubTest::Node);
use Carp qw(croak);
use Scalar::Util qw(weaken);
use Class::Accessor::Lite (
    rw => [qw/name/],
);
sub new {
    my ($class, %args) = @_;
    bless +{
        %args,
        child_nodes => [],
    }, $class;
}

sub get_lineno { return $_[0]->{_lineno} }

sub is_subtest { 1 }
sub is_block   { 0 }
sub is_root    { 0 }

sub child_nodes { # ro
    my ($self, $i) = @_;
    return $self->{child_nodes} unless defined $i;
    return $self->{child_nodes}->[$i];
}

sub child_blocks   { # ro
    my ($self, $i) = @_;
    my @nodes = grep { ! $_->is_subtest } @{ $self->child_nodes };
    return \@nodes unless defined $i;
    return $nodes[$i];
}

sub child_subtests { # ro
    my ($self, $i) = @_;
    my @nodes = grep { $_->is_subtest } @{ $self->child_nodes };
    return \@nodes unless defined $i;
    return $nodes[$i];
}

sub has_child_nodes    { scalar(@{ $_[0]->child_nodes    }) > 0 }
sub has_child_blocks   { scalar(@{ $_[0]->child_blocks   }) > 0 }
sub has_child_subtests { scalar(@{ $_[0]->child_subtests }) > 0 }

sub append_child {
    my ($self, $child) = @_;
    croak '$self->depth is required' unless defined $self->depth;
    my $child_nodes = $self->child_nodes;

    $child->parent_node($self);
    $child->index(scalar @$child_nodes);
    $child->depth($self->depth + 1);

    push @$child_nodes, $child;
    weaken $child->{parent_node};
}

1;
