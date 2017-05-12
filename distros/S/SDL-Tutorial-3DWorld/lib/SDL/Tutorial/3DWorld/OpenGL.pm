package SDL::Tutorial::3DWorld::OpenGL;

=pod

=head1 NAME

SDL::Tutorial::3DWorld::OpenGL - Utility package for initialising OpenGL

=head1 DESCRIPTION

The current implementation of L<OpenGL> does not implement modern proper
constants. Instead, the constants it provides only come into existance one
they have been exported.

Because of the number of exports involved, this can require a hundred K or so
per package you export to. Over a large application with dozens or hundreds of
classes, this can add up to megabytes or multiple megabytes of complexity and
wasted memory.

This package has no interface, but instead tickles the internals of the
L<OpenGL> module to allow the constants inside it to work without having to
import them (repeatedly) into your packages.

Admittedly, it actually does this by exporting the constants. But this only
needs to occur once instead of having to be done dozens of times.

There is a plan to alter the way that the OpenGL packages work to remove this
flaw and allow use without function exporting. Once these fixes have been made
this module will be removed.

=cut

use 5.008;
use strict;
use warnings;
use OpenGL ':all';

our $VERSION = '0.33';

1;

=cut

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SDL-Tutorial-3DWorld>

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<SDL>, L<OpenGL>

=head1 COPYRIGHT

Copyright 2010 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
