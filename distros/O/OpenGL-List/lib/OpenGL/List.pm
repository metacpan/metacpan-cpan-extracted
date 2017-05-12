package OpenGL::List;

=pod

=head1 NAME

OpenGL::List - Massively optimise your Perl OpenGL program with display lists

=head1 DESCRIPTION

=head FUNCTIONS

=cut

use 5.006;
use strict;
use warnings;
use OpenGL ();

our $VERSION = '0.01';

=pod

=head2 glpList

  my $list_name = glpList {
      glBegin( GL_LINES );
      glVertex3f( 0, 0, 0 );
      glVertex3f( 1, 0, 0 );
      glVertex3f( 0, 0, 0 );
      glVertex3f( 0, 1, 0 );
      glVertex3f( 0, 0, 0 );
      glVertex3f( 0, 0, 1 );
      glEnd();
  };

The glpLine function is used to define a block of Perl OpenGL instructions that
should be immediately compiled into a display list.

Returns a new display list name that can be passed to glCallList() later.

=cut

sub glpList(&) {
	my $code = shift;
	my $id   = OpenGL::glGenLists(1);
	OpenGL::glNewList( $id, OpenGL::GL_COMPILE() );
	$code->();
	OpenGL::glEndList();
	return $id;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=OpenGL-List>

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<OpenGL>

=head1 COPYRIGHT

Copyright 2010 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
