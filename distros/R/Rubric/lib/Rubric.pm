use strict;
use warnings;
package Rubric 0.157;
# ABSTRACT: a notes and bookmarks manager with tagging

#pod =head1 DESCRIPTION
#pod
#pod This module is currently just a placeholder and a container for documentation.
#pod You don't want to actually C<use Rubric>, even if you want to use Rubric.
#pod
#pod Rubric is a note-keeping system that also serves as a bookmark manager.  Users
#pod store entries, which are small (or large) notes with a set of categorizing
#pod "tags."  Entries may also refer to URIs.
#pod
#pod Rubric was inspired by the excellent L<http://del.icio.us/> service and the
#pod Notational Velocity note-taking software for Mac OS.
#pod
#pod =head1 WARNING
#pod
#pod This is young software, likely to have bugs and likely to change in strange
#pod ways.  I will try to keep the documented API stable, but not if it makes
#pod writing Rubric too inconvenient.
#pod
#pod Basically, just take note that this software works, but it's still very much
#pod under construction.
#pod
#pod =head1 INSTALLING AND UPGRADING
#pod
#pod Consult the README file in this distribution for instructions on installation
#pod and upgrades.
#pod
#pod =head1 TODO
#pod
#pod For now, consult the C<todo.html> template for future milestones, or check
#pod L<http://rjbs.manxome.org/rubric/docs/todo>.
#pod
#pod =head1 THANKS
#pod
#pod ...to a lot of people whom I will try to name, in time.  Among these helpful
#pod people are Ian Langworth, Shawn Sorichetti, John Cappiello, and Dave O'Neill.
#pod
#pod =head1 SEE ALSO
#pod
#pod =for :list
#pod * L<http://del.icio.us/>
#pod one of my original inspirations
#pod * L<http://notational.net/>
#pod Notational Velocity, another of my inspirations
#pod * L<http://unalog.com/>
#pod a social bookmarks system, written in Python
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rubric - a notes and bookmarks manager with tagging

=head1 VERSION

version 0.157

=head1 DESCRIPTION

This module is currently just a placeholder and a container for documentation.
You don't want to actually C<use Rubric>, even if you want to use Rubric.

Rubric is a note-keeping system that also serves as a bookmark manager.  Users
store entries, which are small (or large) notes with a set of categorizing
"tags."  Entries may also refer to URIs.

Rubric was inspired by the excellent L<http://del.icio.us/> service and the
Notational Velocity note-taking software for Mac OS.

=head1 PERL VERSION

This code is effectively abandonware.  Although releases will sometimes be made
to update contact info or to fix packaging flaws, bug reports will mostly be
ignored.  Feature requests are even more likely to be ignored.  (If someone
takes up maintenance of this code, they will presumably remove this notice.)
This means that whatever version of perl is currently required is unlikely to
change -- but also that it might change at any new maintainer's whim.

=head1 WARNING

This is young software, likely to have bugs and likely to change in strange
ways.  I will try to keep the documented API stable, but not if it makes
writing Rubric too inconvenient.

Basically, just take note that this software works, but it's still very much
under construction.

=head1 INSTALLING AND UPGRADING

Consult the README file in this distribution for instructions on installation
and upgrades.

=head1 TODO

For now, consult the C<todo.html> template for future milestones, or check
L<http://rjbs.manxome.org/rubric/docs/todo>.

=head1 THANKS

...to a lot of people whom I will try to name, in time.  Among these helpful
people are Ian Langworth, Shawn Sorichetti, John Cappiello, and Dave O'Neill.

=head1 SEE ALSO

=over 4

=item *

L<http://del.icio.us/>

one of my original inspirations

=item *

L<http://notational.net/>

Notational Velocity, another of my inspirations

=item *

L<http://unalog.com/>

a social bookmarks system, written in Python

=back

=head1 AUTHOR

Ricardo SIGNES <rjbs@semiotic.systems>

=head1 CONTRIBUTORS

=for stopwords Brian Cassidy jcap@codesimply.com John Cappiello SJ Anderson Ricardo SIGNES Shawn Sorichetti

=over 4

=item *

Brian Cassidy <bricas@cpan.org>

=item *

jcap@codesimply.com <jcap@virgo.codesimply.com>

=item *

John Cappiello <jcap@codesimply.com>

=item *

John SJ Anderson <genehack@genehack.org>

=item *

Ricardo SIGNES <rjbs@codesimply.com>

=item *

Shawn Sorichetti <ssoriche@coloredblocks.net>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
