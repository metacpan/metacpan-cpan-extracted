package Scene::Graph::Node::Spatial;
use Moose;

extends 'Scene::Graph::Node';

with 'Scene::Graph::Node::Transforms::Translatable';

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Scene::Graph::Node::Spatial - A Node with an origin point

=head1 DESCRIPTION

Combines the L<Scene::Graph::Note::Transforms::Translatable|Translatable> role
with a Node for spatial awareness.

=head1 SYNOPSIS

    use Scene::Graph::Node::Spatial;
    use Geometry::Primitive::Point;

    my $foo = Scene::Graph::Node::Spatial->new(
        origin => Geometry::Primitive::Point->new(x => 5, y => 5)
    );

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2010 Cold Hard Code, LLC.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
