###  $Id: Detector.pm 424 2008-08-19 16:27:43Z duncan $
####------------------------------------------
###
## @file
# Define Detector Class

## @class Detector
# object activates map controlled actions when the team nears it
#

package OpenGL::QEng::Detector;

use strict;
use warnings;
use OpenGL qw/:all/;
use OpenGL::QEng::glShapeP2p;

use base qw/OpenGL::QEng::Box/;

#####
##### Class methods
#####

## @cmethod Detector new($class, @arg)
# Create a Detector
#
sub new {
  my ($class,@props) = @_;

  @props = %{$props[0]} if (scalar(@props) == 1);

  my $self = OpenGL::QEng::Box->new;
  $self->{state}   = 'new';
  $self->{visible} = 0;
  $self->{y}       = 0.5;
  $self->{color}   = 'chartreuse';
  $self->{model} = {minx => -1.0,  maxx => 1.0,
		    miny =>  0.01, maxy => 0.10,
		    minz => -1.0,  maxz => 1.0 };
  bless($self,$class);

  $self->passedArgs({@props});
  $self->create_accessors;
  $self->register_events;

  $self;
}
#------------------------------------------
## @method draw($mode)
# Draw this object in its current state at its current location
# or set up for testing for a touch
sub draw {
  my ($self,$mode) = @_;

  my $chkErr = 1;		# flag

  if ($mode == OpenGL::GL_SELECT) {
    glLoadName($self->{GLid});
  }
  glTranslatef($self->x,$self->y,$self->z);
  glRotatef($self->{roll}, 0,0,1) if $self->{roll};
  glRotatef($self->{yaw},  0,1,0) if $self->{yaw};
  glRotatef($self->{pitch},1,0,0) if $self->{pitch};
  OpenGL::QEng::glShapeP2p::drawDisk($self,0, 0, 0.9, 'purple');
  OpenGL::QEng::glShapeP2p::drawDisk($self,0,0,0.8, 'blue');
  OpenGL::QEng::glShapeP2p::drawDisk($self,0,0,0.7,'green');
  OpenGL::QEng::glShapeP2p::drawDisk($self,0,0,0.6,'red');
  #$self->drawCircle(0, 0, 0.8,0.9, 'purple');
  #$self->drawCircle(0,0,0.7,0.8, 'blue');
  #$self->drawCircle(0,0,0.6,0.7,'green');
  #$self->drawCircle(0,0,0.0,0.6,'red');

  glRotatef(-$self->{pitch},1,0,0) if $self->{pitch};
  glRotatef(-$self->{yaw},  0,1,0) if $self->{yaw};
  glRotatef(-$self->{roll}, 0,0,1) if $self->{roll};
  glTranslatef(-$self->x,-$self->y,-$self->z);

  $chkErr && $self->tErr('draw Detector');
}

#------------------------------------------
sub tractable {			# tractability - 'solid', 'seethru', 'passable'
  'passable';
}


#------------------------------------------------------------------------------
1;

__END__

=head1 NAME

Detector -- a Thing to attach a near event (team_at) handler to; sort of a
transporter

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

