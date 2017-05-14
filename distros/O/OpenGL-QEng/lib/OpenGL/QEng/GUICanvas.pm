###  $Id: GUICanvas.pm 322 2008-07-19 22:32:21Z duncan $
####------------------------------------------
## @file
# Define GUICanvas Class
# GUI Widgets and related capabilities
#

## @class GUICanvas
# Provide a GUI Canvas in OpenGL

package OpenGL::QEng::GUICanvas;

use strict;
use warnings;
use OpenGL qw/:all/;

use base qw/OpenGL::QEng::GUIThing/;

#--------------------------------------------------
## @cmethod % new()
# Create a GUICanvas
#
sub new {
  my ($class,@props) = @_;

  @props = %{$props[0]} if (scalar(@props) == 1);
  my $self = OpenGL::QEng::GUIThing->new();
  $self->{relief}        = 'sunken';
  $self->{color}         = 'white';
  $self->{clickCallback} = undef;
  bless($self,$class);

  $self->passedArgs({@props});
  $self->create_accessors;
  # put it after creating accessors to keep it private
  # create each drawlist as an array hashed by the tag value - '???' is the
  # key for the untagged items
  $self->{drawlists} = {};
  $self;
}

######
###### Public Instance Methods
######

#--------------------------------------------------
## @method draw()
#  Draw the background for the GUI area
sub draw {
  my ($self) = @_;

  $self->setColor($self->{color});

  # draw background for the text.
  glBegin(GL_QUADS);
  glVertex2i($self->{x},                $self->{y}                );
  glVertex2i($self->{x},                $self->{y}+$self->{height});
  glVertex2i($self->{x}+$self->{width}, $self->{y}+$self->{height});
  glVertex2i($self->{x}+$self->{width}, $self->{y}                );
  glEnd();

  if ($self->{relief} eq 'sunken') {
    # Draw an outline around the canvas with width 3
    glLineWidth(3);

    # The colours for the outline are reversed when the canvas area is raised.
    if ($self->{relief} eq 'sunken') {
      glColor3f(0.4,0.4,0.4);
    } else {
      glColor3f(0.8,0.8,0.8);
    }
    glBegin(GL_LINE_STRIP);
    glVertex2i($self->{x}+$self->{width}, $self->{y}                );
    glVertex2i($self->{x},                $self->{y}                );
    glVertex2i($self->{x},                $self->{y}+$self->{height});
    glEnd();

    if ($self->{relief} eq 'sunken') {
      glColor3f(0.8,0.8,0.8);
    } else {
      glColor3f(0.4,0.4,0.4);
    }
    glBegin(GL_LINE_STRIP);
    glVertex2i($self->{x},                $self->{y}+$self->{height});
    glVertex2i($self->{x}+$self->{width}, $self->{y}+$self->{height});
    glVertex2i($self->{x}+$self->{width}, $self->{y}                );
    glEnd();

    glLineWidth(1);
  }
  return unless $self->{drawlists};

  for my $tag (keys %{$self->{drawlists}}) {
    for my $item (@{ $self->{drawlists}{$tag} }) {
      $item->draw($self->{x},$self->{y}, $self->{width},$self->{height});
    }
  }
}

#--------------------------------------------------
sub erase {
  my $self = shift;
  undef $self->{drawlists};
}

#--------------------------------------------------
sub delete {
  my ($self, $tag) = @_;
  undef $self->{drawlists}{$tag};
}

#--------------------------------------------------
sub create {
  my ($self,$subclass,@props) = @_;

  my $class = "GUICanvas$subclass";
  require "OpenGL/QEng/$class.pm";

  my $item = "OpenGL::QEng::$class"->new(@props);
  push @{$self->{drawlists}{$item->tag || '???'}}, $item;
}

#==================================================================
###
### Test Driver for GUICanvas Object
###
if (not defined caller()) {
  package main;

  require OpenGL;
  require GUIMaster;

  my $ovSize = 400;
  my $winw = $ovSize;
  my $winh = $ovSize;

  OpenGL::glutInit;
  OpenGL::glutInitDisplayMode(OpenGL::GLUT_RGB   |
			      OpenGL::GLUT_DEPTH |
			      OpenGL::GLUT_DOUBLE);
  OpenGL::glutInitWindowSize($ovSize,$ovSize);
  OpenGL::glutInitWindowPosition(200,100);
  my $win1 = OpenGL::glutCreateWindow("OpenGL GUICanvas Test");
  glViewport(0,0,$winw,$winh);

  my $GUIRoot = OpenGL::QEng::GUIMaster->new(wid=>$win1,x=>$ovSize,y=>0,
			       width=>$ovSize,height=>$ovSize);
  my $t1 = OpenGL::QEng::GUICanvas->new(x=>10,y=>10,
			  width=>$ovSize-30,height=>$ovSize-30,
			  color=>'lightgray');
  $GUIRoot->adopt($t1);
  $t1->create('Image',x=>100,y=>100,height=>32, width=>32,
	              texture=>'splash', tag=>'brown');
  $t1->create('Line', x=>20,y=>10,x2=>200,y2=>100,color=>'blue');
  $t1->create('Poly', 201,201,301,301,250,205,color=>'pink');
  $t1->create('Circle',x=>300,y=>300,radius=>30,color=>'orange');

  glutDisplayFunc(sub{ $GUIRoot->GUIDraw(@_) });
  glutMouseFunc(  sub{ $GUIRoot->mouseButton(@_) });

  glutMainLoop;
}

#------------------------------------------------------------------------------
1;

__END__

=head1 NAME

GUICanvas -- Provide a GUI Canvas in OpenGL

Creates a window where the program can draw.  Supports a callback for
a mouse click in the canvas returning the relative coordinates.
Program controls background color.  Program can erase the area.  Can
associate a tag value with each drawn item and erase by tag value.
Can draw lines, textures, Has (will have) associated classes for
image, line, polygon and oval
 image (texture, x,y,tag)
 line (x1,y1,x2,y2,[color],[width],[tag]
 oval (x1,y1,x2,y2,[color],[tag]
 polygon (x1,y1,...,xn,yn,[color],[tag]

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

