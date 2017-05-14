###  $Id: Torch.pm 424 2008-08-19 16:27:43Z duncan $
####------------------------------------------

## @file 
# Define Torch Class

## @class Torch
# Torch for decoration

package OpenGL::QEng::Torch;

use strict;
use warnings;
use OpenGL qw/:all/;

use base qw/OpenGL::QEng::Thing/;

#------------------------------------------
sub new {
  my ($class,@props) = @_;

  @props = %{$props[0]} if (scalar(@props) == 1);

  my $self = OpenGL::QEng::Thing->new;
  $self->{y}     = 5;
  $self->{color} = 'orange';
  $self->{model} = {miny =>  0,   maxy => 1,
		    minz => -0.5, maxz => +0.5,
		    minx => -0.5, maxx => +0.5,};
  $self->{dl}    = undef;
  bless($self,$class);

  $self->passedArgs({@props});
  $self->register_events;
  $self->create_accessors;
  $self;
}

#------------------------------------------
sub draw {
  my ($self, $mode) = @_;

  if ($mode == OpenGL::GL_SELECT) {
    glLoadName($self->{GLid});
  }

  glTranslatef($self->{x},$self->y,$self->{z});
  glRotatef($self->{yaw},0,1,0) if $self->{yaw};
  glRotatef(90,1,0,0);
  if ($self->dl) {
    OpenGL::glCallList($self->dl);
  } else {
    $self->dl($self->getDLname);
    OpenGL::glNewList($self->dl,OpenGL::GL_COMPILE);

    $self->setColor('darkslategray');
    glutSolidCone(0.2,2.0,10,10);
    $self->setColor('red');
    glutSolidCone(0.1,-0.20,10,10);
    glColor3f(255.0/255.0, 0/255.0,0/255.0); #red
    $self->setColor('yellow');
    glEnable (GL_BLEND); glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glColor4f(255/255.0, 255/255.0,0/255.0,0.4); # see-thru yellow
    glutSolidCone(0.2,-0.50,10,10);
    glTranslatef(0,0,-0.5);

    glColor4f(255/255.0, 255/255.0,0/255.0,0.1); # see-thru yellow
    glutSolidSphere(0.9,20,16);
    glDisable(GL_BLEND);

    glTranslatef(0,0,0.5);
    OpenGL::glEndList();
    OpenGL::glCallList($self->dl);  #### Draw it the first time
  }

  glRotatef(-$self->{yaw},0,1,0) if $self->{yaw};
  glRotatef(-90,1,0,0);
  glTranslatef(-$self->{x},-$self->y,-$self->{z});

  $self->tErr('draw Torch');
}

#===========================================================================
#
# the map 'tunnel1.txt' has a Torches for testing
#

#------------------------------------------------------------------------------
1;

__END__

=head1 NAME

Torch -- a decorative wall lamp

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

