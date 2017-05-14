###  $Id: Stair.pm 424 2008-08-19 16:27:43Z duncan $
####------------------------------------------

## @file
# Define Stair Class

## @class Stair
# Stair for map transition
#

package OpenGL::QEng::Stair;

use strict;
use warnings;
use OpenGL qw/:all/;

use base qw/OpenGL::QEng::Thing/;

#------------------------------------------
sub new {
  my ($class,@props) = @_;

  @props = %{$props[0]} if (scalar(@props) == 1);

  my $self = OpenGL::QEng::Thing->new;
  $self->{type}  = 'up';
  $self->{color} = 'cornsilk';
  $self->{model} = {miny => 0, maxy => 8,
		    minz => 0, maxz => 8,
		    minx => 0, maxx => 4,};
  bless ($self,$class);

  $self->passedArgs({@props});
  $self->register_events;
  $self;
}

#------------------------------------------
{my $dl;			#closure over $dl
 my $chkErr = 01;

 sub draw {
   my ($self, $mode) = @_;

   if ($mode == OpenGL::GL_SELECT) {
     glLoadName($self->{GLid});
   }
   glTranslatef($self->{x},$self->{y},$self->{z});
   glRotatef($self->{yaw},0,1,0) if $self->{yaw};

   $self->setColor('gray');
   $self->setColor('purple');

   if ($dl) {
#     OpenGL::glCallList($dl);
     $chkErr && $self->tErr('draw Stair1');
   } else {
#     $dl = $self->getDLname();
#     OpenGL::glNewList($dl,OpenGL::GL_COMPILE);
     glEnable(OpenGL::GL_TEXTURE_2D);
     $self->pickTexture('stair');
     &glShapeP2p::drawBlock(0.0,0.0,0.0,8.0,1.0,1.0);
     $chkErr && $self->tErr('draw Stair3');
     &glShapeP2p::drawBlock(0.0,1.0,1.0,8.0,2.0,2.0);
     $chkErr && $self->tErr('draw Stair4');

     glShapeP2p::drawBlock(0.0,2.0,2.0,8.0,3.0,3.0);
     $chkErr && $self->tErr('draw Stair5');
     glShapeP2p::drawBlock(0.0,3.0,3.0,8.0,4.0,4.0);
     glShapeP2p::drawBlock(0.0,4.0,4.0,8.0,5.0,5.0);
     glShapeP2p::drawBlock(0.0,5.0,5.0,8.0,6.0,6.0);
     glShapeP2p::drawBlock(0.0,6.0,6.0,8.0,7.0,7.0);
     glShapeP2p::drawBlock(0.0,7.0,7.0,8.0,8.0,8.0);
     OpenGL::glDisable(OpenGL::GL_TEXTURE_2D);
     if ($self->{type} eq 'up') {
     #Hole in ceiling  #
     $self->setColor('black');
     glBegin(OpenGL::GL_QUADS);
     glVertex3f(0.0, 7.9, 8.0);
     glVertex3f(8.0, 7.9, 8.0);
     glVertex3f(8.0, 7.9, 0.0);
     glVertex3f(0.0, 7.9, 0.0);
     glEnd();
   }
#     OpenGL::glEndList();
#     OpenGL::glCallList($dl); #### Draw it the first time
     $chkErr && $self->tErr('draw Stair5');
   }
   glRotatef(-$self->{yaw},0,1,0) if $self->{yaw};
   glTranslatef(-$self->{x}+0.6,-$self->{y}-0.25,-$self->{z});

   $self->tErr('draw Stair');
 }
}				#end closure

#==================================================================
#
# Test with the map stairTest.txt
#

#------------------------------------------------------------------------------
1;

__END__

=head1 NAME

Stair -- for map level transitions

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

