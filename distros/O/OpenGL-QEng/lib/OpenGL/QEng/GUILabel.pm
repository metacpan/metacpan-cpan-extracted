###  $Id: GUILabel.pm 322 2008-07-19 22:32:21Z duncan $
####------------------------------------------
## @file
# Define GUILabel Class
# GUI Widgets and related capabilities
#

## @class GUILabel
# Label widget in OpenGL

package OpenGL::QEng::GUILabel;

use strict;
use warnings;
use OpenGL qw/:all/;

use base qw/OpenGL::QEng::GUIThing/;

#--------------------------------------------------
## @cmethod % new()
# Create a GUILabel
#
sub new {
  my ($class,@props) = @_;

  @props = %{$props[0]} if (scalar(@props) == 1);

  my $self = OpenGL::QEng::GUIThing->new();
  $self->{text}      = ' ';
  $self->{textColor} = undef;
  bless($self,$class);

  $self->passedArgs({@props});
  $self->create_accessors;
  $self;
}

######
###### Public Instance Methods
######

## @method draw()
#  Draw the ...
sub draw {
  my ($self) = @_;

  if (0) {
    glColor3f(0.6,0.6,0.6);
    # draw background for the label.

    glBegin(GL_QUADS);
    glVertex2i($self->{x},                $self->{y}                );
    glVertex2i($self->{x},                $self->{y}+$self->{height});
    glVertex2i($self->{x}+$self->{width}, $self->{y}+$self->{height});
    glVertex2i($self->{x}+$self->{width}, $self->{y}                );
    glEnd();

    glColor3f(0.4,0.4,0.4);
  }
  # Calculate the x and y coords for the text string in order to center it.
  my $fontx = $self->{x} + ($self->{width} -
			    $self->glutBitmapLength($self->{font},
						    $self->{text})) / 2 ;
  my $fonty = $self->{y} + ($self->{height}+10)/2;
  glColor3f(0,0,0);
  $self->setColor($self->{textColor}) if defined $self->{textColor};
  $self->write($self->{font},$self->{text},$fontx,$fonty);
}

#==================================================================
###
### Test Driver for GUILabel Object
###
if (not defined caller()) {
  package main;

  require OpenGL; # qw/:all/;
  require GUIMaster;

  my $winsize = 400;
  my $winw = $winsize;
  my $winh = $winsize;

  OpenGL::glutInit;
  OpenGL::glutInitDisplayMode(OpenGL::GLUT_RGB   |
			      OpenGL::GLUT_DEPTH |
			      OpenGL::GLUT_DOUBLE);
  OpenGL::glutInitWindowSize($winsize,$winsize);
  OpenGL::glutInitWindowPosition(200,100);
  my $win1 = OpenGL::glutCreateWindow("OpenGL GUILabel Test");
  glViewport(0,0,$winw,$winh);

  my $GUIRoot = OpenGL::QEng::GUIMaster->new(wid=>$win1,x=>0,y=>0,
			       width=>$winsize,height=>$winsize,
			       color=>'white');

  $GUIRoot->adopt(OpenGL::QEng::GUILabel->new(x=>10,y=>10,
				width=>100,height=>32,text=>'test label'));

  glutDisplayFunc(      sub{ $GUIRoot->GUIDraw(@_) });
  glutMouseFunc(        sub{ $GUIRoot->mouseButton(@_) });
  glutMotionFunc(       sub{ $GUIRoot->mouseMotion(@_) });
  glutPassiveMotionFunc(sub{ $GUIRoot->mousePassiveMotion(@_) });

  glutMainLoop;
}

#------------------------------------------------------------------------------
1;

__END__

=head1 NAME

GUILabel -- label widget

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

