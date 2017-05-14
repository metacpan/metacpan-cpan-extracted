###  $Id: ArchWall.pm 424 2008-08-19 16:27:43Z duncan $
####------------------------------------------

## @file
# Define ArchWall "Class"

## @class ArchWall
# no base class: just a convienience function for creating a
# wall with an opening
#

package OpenGL::QEng::ArchWall;

use strict;
use warnings;
use OpenGL::QEng::Wall;
use OpenGL::QEng::Opening;

#-------------------------------------------------------------
# Create a length of Wall with a doorway (Opening)
#
sub new {
  my ($fakeclass,@props) = @_;

  my $props = (scalar(@props) == 1) ? $props[0] : {@props};
  my $self = OpenGL::QEng::Wall->new($props);
  $self->assimilate(OpenGL::QEng::Opening->new(x=>2));

  $self;
}

1;

__END__

=head1 NAME

ArchWall -- a convienience function for creating a wall with an opening

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

