package Scene::Graph::Node;
use Moose;

with 'MooseX::Clone';

use Geometry::Primitive::Point;

has 'id' => (
    traits => [ 'Clone' ],
    is => 'ro',
    isa => 'Str'
);

has 'children' => (
    traits => [ 'Array', 'NoClone' ],
    is => 'ro',
    isa => 'ArrayRef[Scene::Graph::Node]',
    default => sub { [] },
    handles => {
        add_child => 'push',
        child_count => 'count',
        is_leaf => 'is_empty'
    }
);

has 'is_rotatable' => (
    traits => [ 'Clone' ],
    is => 'ro',
    isa => 'Bool',
    default => 0
);

has 'is_scalable' => (
    traits => [ 'Clone' ],
    is => 'ro',
    isa => 'Bool',
    default => 0
);

has 'is_translatable' => (
    traits => [ 'Clone' ],
    is => 'ro',
    isa => 'Bool',
    default => 0
);

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Scene::Graph::Node - A Node in a scene

=head1 SYNOPSIS

Perhaps a little code snippet.

    use Scene::Graph;

    my $foo = Scene::Graph->new();
    ...

=head1 ATTRIBUTES

=head2 children

An arrayref of children of this node.

=head1 METHODS

=head2 add_child

Add a child node to this one.

=head2 child_count

The number of child nodes this node has.

=head2 is_leaf

Returns true if this node has no children.

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2010 Cold Hard Code, LLC.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
