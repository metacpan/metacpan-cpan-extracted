package Scene::Graph::Node::Transforms::Translatable;
use Moose::Role;

use Geometry::Primitive::Point;

has '+is_translatable' => (
    default => 1
);

has 'origin' => (
    is => 'ro',
    isa => 'Geometry::Primitive::Point',
    default => sub { Geometry::Primitive::Point->new(x => 0, y => 0) }
);

sub translate {
    my ($self, $transformer) = @_;

    my $o = $self->origin;
    my ($x, $y) = $transformer->transform($o->x, $o->y);
    $self->origin->x($x);
    $self->origin->y($y);
}

1;


__END__

=head1 NAME

Scene::Graph::Transforms::Translatable - A Translatable Node Role

=head1 DESCRIPTION

Requires that the composing class have a C<translate> method and sets the
C<is_translatable> attribute to true.

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2010 Cold Hard Code, LLC.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
