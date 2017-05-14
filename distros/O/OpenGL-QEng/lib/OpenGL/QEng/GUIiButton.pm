###  $Id:  $
####------------------------------------------
## @file
# Define GUIiButton Class
# GUI Widgets and related capabilities
#

## @class GUIiButton
# Provide a GUI iButton in OpenGL

package OpenGL::QEng::GUIiButton;

use strict;
use warnings;
use OpenGL qw/:all/;

use base qw/OpenGL::QEng::GUIButton/;

#--------------------------------------------------
## @cmethod % new()
# Create a GUIiButton
#
sub new {
  my ($class,@props) = @_;

  @props = %{$props[0]} if (scalar(@props) == 1);
  my $self = OpenGL::QEng::GUIButton->new();
  $self->{texture} = [undef,undef];
  bless($self,$class);

  $self->passedArgs({@props});
  $self->create_accessors;
  $self;
}

######
###### Public Instance Methods
######

## @method draw()
#  Draw the background for the GUI area
sub draw {
  my ($self) = @_;

  my $state_i = ($self->{state}) ? 1 : 0;
  $self->pickTexture($self->{texture}[$state_i]);
  glTexParameterf(GL_TEXTURE_2D, OpenGL::GL_TEXTURE_WRAP_S, GL_REPEAT);
  glTexParameterf(GL_TEXTURE_2D, OpenGL::GL_TEXTURE_WRAP_T, GL_REPEAT);
  glEnable(GL_TEXTURE_2D);

  # draw texture for the button.
  glBegin(GL_QUADS);
  glTexCoord2f(0,1); glVertex2i($self->x,             $self->y              );
  glTexCoord2f(0,0); glVertex2i($self->x,             $self->y+$self->height);
  glTexCoord2f(1,0); glVertex2i($self->x+$self->width,$self->y+$self->height);
  glTexCoord2f(1,1); glVertex2i($self->x+$self->width,$self->y              );
  glEnd();
  glDisable(GL_TEXTURE_2D);

  if ($self->{text}) {
    # Calculate the x and y coords for the text string in order to center it.
    my $fontx =
      $self->{x} + ($self->{width}
		    - $self->glutBitmapLength($self->{font},
					      $self->{text})) / 2 ;
    # adjustment of 23 is chosen by eye because it seems to work
    my $fonty = $self->{y} + ($self->{height}+23)/2;

    # if the button is pressed, make it look as though the string has
    # been pushed down. It's just a visual thing to help with the
    # overall look....
    if ($self->{state}) {
      $fontx+=2;
      $fonty+=2;
    }

    #XXX handle highlighted someday

    glColor3f(1,1,1);
    $self->setColor($self->{textColor}) if defined $self->{textColor};
    my @lines = split ' ',$self->{text};
    $fonty = $fonty -12*scalar(@lines)/2;
    for my $line ( @lines) {
      my $fontx =
	$self->{x} + ($self->{width}
		    - $self->glutBitmapLength($self->{font},
					      $line)) / 2 ;
      $self->write($self->{font},$line,$fontx,$fonty);
      $fonty += 12;
    }
  }
}

#------------------------------------------------------------------------------
1;

__END__

=head1 NAME

GUIButton -- 2D/3D button with texture images for each state

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

