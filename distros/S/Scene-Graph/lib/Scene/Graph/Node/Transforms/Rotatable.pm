package Scene::Graph::Transforms::Rotatable;
use Moose::Role;

requires 'rotate';

has '+is_rotatable' => (
    default => 1
);

1;

__END__

=head1 NAME

Scene::Graph::Transforms::Rotatable - A Rotatable Node Role

=head1 DESCRIPTION

Requires that the composing class have a C<rotate> method and sets the
C<is_rotatable> attribute to true.

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2010 Cold Hard Code, LLC.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
