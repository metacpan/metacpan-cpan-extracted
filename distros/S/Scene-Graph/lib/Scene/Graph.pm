package Scene::Graph;
use warnings;
use strict;

our $VERSION = '0.01';

1;

__END__

=head1 NAME

Scene::Graph - A Two-Dimensional Scene Graph

=head1 DESCRIPTION

This is a pure-perl implementation of a L<http://en.wikipedia.org/wiki/Scene_graph|scene graph>.
It allows the creation of scenes of nodes with translations.  The scene may
then be traversed using L<Scene::Graph::Traverser>.  It allows iteration over
a flat array of cloned nodes with all applicable transformations applied.

=head1 WARNING

This module is in the early stages of development is is likely to change
significantly.  Release early, release often.

=head1 SYNOPSIS

    use Scene::Graph::Node;
    use Scene::Graph::Traverser;

    my $box = Scene::Graph::Node->new;

    my $thing1 = Scene::Graph::Node->new;
    my $thing2 = Scene::Graph::Node->new;
    $box->add_child($thing1);
    $box->add_child($thing2);

    my $traverser = Scene::Graph::Traverser->new(scene => $thing);
    while(my $node = $traverser->next) {
        # 1st is box, then thing1 and finally thing2
    }

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2010 Cold Hard Code, LLC.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
