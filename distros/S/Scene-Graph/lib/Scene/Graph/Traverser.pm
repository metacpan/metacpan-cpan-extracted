package Scene::Graph::Traverser;
use Moose;

use Geometry::AffineTransform;

has 'node_list' => (
    traits => [ 'Array' ],
    is => 'ro',
    isa => 'ArrayRef',
    handles => {
        'add_node_to_list' => 'push',
        'next' => 'pop',
        'node_count' => 'count'
    },
    lazy_build => 1
);

has 'identities' => (
    traits => [ 'Array' ],
    is => 'ro',
    isa => 'ArrayRef',
    default => sub { [] },
    handles => {
        'identity_pop' => 'pop',
        'identity_push' => 'push'
    }
);

has 'identity' => (
    is => 'rw',
    isa => 'Geometry::AffineTransform',
);

has 'scene' => (
    is => 'ro',
    isa => 'Scene::Graph::Node',
    required => 1
);

sub _build_node_list {
    my ($self) = @_;

    $self->identity(Geometry::AffineTransform->new);

    my $nodes = $self->_walk_scene($self->scene);
    return $nodes;
}

sub _walk_scene {
    my ($self, $snode) = @_;

    # Clone the node, as we'll be manipulating it.
    my $n = $snode->clone;

    if($n->is_translatable) {
        my $curr_ident = $self->identity;
        # Ask the node to translate itself based on our current identity
        # matrix.
        $n->translate($curr_ident);

        # Save away the current state...
        $self->save;
        # Grab the unsullied node's origin
        my $o = $snode->origin;
        # Translate according to the same...
        $self->identity($curr_ident->clone->translate($o->x, $o->y));
    }

    my @nodes;
    unless($snode->is_leaf) {
        # Recurse if this node has children, we use reverse to retain the
        # push/pop convenience
        foreach my $child (reverse @{ $snode->children }) {
            push(@nodes, @{ $self->_walk_scene($child) });
        }
    }
    # We push the node on after it's children so that we can use push/pop
    # rather than push/unshift and still get the root node first
    push(@nodes, $n);

    if($n->is_translatable) {
        # Since we modified the identity, restore it
        $self->restore;
    }

    return \@nodes;
}

sub restore {
    my ($self) = @_;

    $self->identity($self->identity_pop);
}

sub save {
    my ($self) = @_;

    $self->identity_push($self->identity);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Scene::Graph::Traverser - Traverse a Scene::Graph

=head1 DESCRIPTION

Traverses a Scene::Graph scene and return a flat array of nodes with all
transformations completed.

=head1 SYNOPSIS

    use Scene::Graph;

    my $foo = Scene::Graph->new();
    ...

=head1 ATTRIBUTES

=head2 node_list

Array of nodes, created from traversing the scene and applying
transformations.

=head2 identities

Stack of identity objects representing the state of transformations through
the traversal process.

=head2 identity

The current identity.  Only relevant during traversal.

=head2 scene

The scene being traversed.

=head1 METHODS

=head2 restore

Pop the last identity off the stack and set it as the current one.

=head2 save

Push the current identity on to the stack.

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2010 Cold Hard Code, LLC.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


1;