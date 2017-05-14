#  $Id: Switch.pm 424 2008-08-19 16:27:43Z duncan $
####------------------------------------------
###
## @file
# Define Switch class

## @class Switch
# Switches in game -- Object looks and acts like a switch

package OpenGL::QEng::Switch;

use strict;
use warnings;
use OpenGL qw/:all/;

use base qw/OpenGL::QEng::Thing/;

#------------------------------------------
## @cmethod Switch new(@args)
# Create a switch at given location
#
sub new {
  my ($class,@prop) = @_;

  my $props = (scalar(@prop) == 1) ? $prop[0] : {@prop};

  my $self = OpenGL::QEng::Thing->new;
  $self->{state}      = 'off';  # State of the switch 'on' or 'off'
  $self->{on_event}   = undef;  # Event to send when switch is turned on
  $self->{off_event}  = undef;  # Event to send when switch is turned off
  $self->{levang}     = 0;      # Current angle of switch
  $self->{target}{levang} = undef; # Final angle of switch
  $self->{color}      = 'midnight blue';
  $self->{xsize}      = $props->{xsize} ||1;    # extent in x dir
  $self->{ysize}      = $props->{ysize} ||0.1;  # extent in y dir
  $self->{zsize}      = $props->{zsize} ||1;    # extent in z dir
  $self->{model}      = {minx => -$self->{xsize}/2,
			 maxx => +$self->{xsize}/2,
			 miny =>  0,
			 maxy => +$self->{ysize},
			 minz => -$self->{zsize}/2,
			 maxz => +$self->{zsize}/2,};
  bless($self,$class);

  $self->passedArgs($props);
  $self->create_accessors;
  $self->register_events;

  $self;
}

#-----------------------------------------------------------------
sub make_me_nod {
  1;
}

#-----------------------------------------------------------
## @method $ handle_touch($self, $game)
# @event_ref may send on_event setting "Switch Turned On"
#
sub handle_touch {
  my ($self) = @_;

  if ($self->{state} eq 'off') {
    $self->{target}{levang} = 40;
    $self->state('on');
    $self->send_event($self->{on_event},"Switch Turned On\n")
      if defined $self->{on_event};
  }
  else { #if ($self->state eq 'on') {
    $self->{target}{levang} = 0;
    $self->state('off');
    $self->send_event($self->{off_event},"Switch Turned Off\n")
      if defined $self->{off_event};
  }
}

#------------------------------------------
## @method draw($self, $mode)
# Draw this object in its current state at its current location
# or set up for testing for a touch
sub draw {
  my ($self,$mode) = @_;

  my ($minx,$maxx) = ($self->model->{minx},$self->model->{maxx});
  my ($miny,$maxy) = ($self->model->{miny},$self->model->{maxy});
  my ($minz,$maxz) = ($self->model->{minz},$self->model->{maxz});

  if ($mode == OpenGL::GL_SELECT) {
    glLoadName($self->{GLid});
  }
  glTranslatef($self->{x},$self->y,$self->{z});
  glColor3f(139.0/255.0, 69.0/255.0,19.0/255.0); #chocolate4

  glBegin(OpenGL::GL_QUADS);

  #left face
  glVertex3f($minx,$miny,$minz);
  glVertex3f($minx,$miny,$maxz);
  glVertex3f($minx,$maxy,$maxz);
  glVertex3f($minx,$maxy,$minz);

  #right face
  glVertex3f($maxx,$miny,$maxz);
  glVertex3f($maxx,$maxy,$maxz);
  glVertex3f($maxx,$maxy,$minz);
  glVertex3f($maxx,$miny,$minz);

  #front face
  glVertex3f($minx,$miny,$minz);
  glVertex3f($minx,$maxy,$minz);
  glVertex3f($maxx,$maxy,$minz);
  glVertex3f($maxx,$miny,$minz);

  #rear face
  glVertex3f($maxx,$maxy,$maxz);
  glVertex3f($maxx,$miny,$maxz);
  glVertex3f($minx,$miny,$maxz);
  glVertex3f($minx,$maxy,$maxz);

  #bottom
  glVertex3f($minx,$miny,$minz);
  glVertex3f($minx,$miny,$maxz);
  glVertex3f($maxx,$miny,$maxz);
  glVertex3f($maxx,$miny,$minz);

  #top
  glVertex3f($minx,$maxy,$minz);
  glVertex3f($minx,$maxy,$maxz);
  glVertex3f($maxx,$maxy,$maxz);
  glVertex3f($maxx,$maxy,$minz);
  glEnd();

  glPushMatrix();

  #rotate is at "pivot"
  my $ang = $self->{levang} % 360;
  glRotatef($ang,0,0,1);
  glRotatef($ang,1,0,0);
  $self->setColor('black');

  ## Lever ArmShort top
  if (01) {
    #verticies in each face
    my @f=(0, 1, 2, 3,		#front
	   3, 2, 6, 7,		# top
	   7, 6, 5, 4,		#
	   4, 5, 1, 0,		#bottom
	   5, 6, 2, 1,		#
	   7, 4, 0, 3,		#
	  );
    # coordinates of the verticies of the exterior rectangular solid
    my @x=(-0.05,-0.05,-0.05,-0.05, 0.05, 0.05,0.05, 0.05);
    my @y=(   0.01,0.01,    2.0, 2.0,0.01,0.01,2.0, 2.0);
    my @z=(   -0.05, 0.05,    0.05,-0.05,-0.05, 0.05,0.05,-0.05);

    # create all sides but the bottom
    for my $i ( 0, 1, 2, 4, 5 ) {
      glBegin(GL_POLYGON);
      for my $j (0..3) {
	my $k = $f[$i*4+$j];
	glVertex3f($x[$k],$y[$k],$z[$k]);
      }
      glEnd();
      $self->tErr("display18");
    }
  }
  glPopMatrix;
  glTranslatef(-$self->{x},$self->y,-$self->{z});

  $self->tErr('draw Switch');
}

#===========================================================================
#
# the map 'girlmap.txt' has a switch for testing
#

#------------------------------------------------------------------------------
1;

__END__

=head1 NAME

Switch -- Switches in game -- Object looks and acts like a switch

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

