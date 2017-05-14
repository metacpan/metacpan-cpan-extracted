###  $Id: GUIText.pm 322 2008-07-19 22:32:21Z duncan $
####------------------------------------------
## @file
# Define GUIText Class
# GUI Widgets and related capabilities
#

## @class GUIText
# Provide a Text widget in OpenGL
#
# Creates a window where the program can write text<br>
# New lines add at the bottom.<br>
# When the window is full, the lines scroll up<br>
# Program controls background color and font.<br>
# Program can erase the area.

package OpenGL::QEng::GUIText;

use strict;
use warnings;
use OpenGL qw/:all/;

use base qw/OpenGL::QEng::GUIThing/;

#--------------------------------------------------
## @cmethod % new()
# Create a GUIText
#
sub new {
  my ($class,@props) = @_;

  @props = %{$props[0]} if (scalar(@props) == 1);
  my $self = OpenGL::QEng::GUIThing->new();
  $self->{text}             = undef;
  $self->{relief}           = 'sunken';
  $self->{color}            = 'white';
  $self->{textColor}        = 'black';
  bless($self,$class);

  $self->passedArgs({@props});
  $self->create_accessors;
  # put it after creating accessors to keep it private
  $self->{array} = [$self->{text}] if defined $self->{text};
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

  $self->setColor($self->{color}||'beige');

  # draw background for the text.
  glBegin(GL_QUADS);
  glVertex2i($self->{x},                $self->{y}                );
  glVertex2i($self->{x},                $self->{y}+$self->{height});
  glVertex2i($self->{x}+$self->{width}, $self->{y}+$self->{height});
  glVertex2i($self->{x}+$self->{width}, $self->{y}                );
  glEnd();

  if ($self->{relief} eq 'sunken') {
    # Draw an outline around the text with width 3
    glLineWidth(3);

    # The colours for the outline are reversed when the text area is raised.
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
  return unless $self->{array};

  # calculate the number of lines to display
  my $lines = @{$self->{array}};
  my $lineHeight = 16; # glutBitmapHeight($self->{font}, ord 'M');
  my $linesAvail = int(($self->{height}-10)/$lineHeight);
  my $topLineIdx = $lines-$linesAvail;
  if ($topLineIdx<0) {
    $topLineIdx = 0;
  }

  # set to an em over from the left edge
  my $fontx = $self->{x} + glutBitmapWidth($self->{font}, ord 'M');
  my $fonty = $self->{y} + 5;
  $self->setColor($self->{textColor});
  for my $line (@{$self->{array}}[$topLineIdx..($lines-1)]) {
    unless (defined $line) {
      print STDERR "empty line in $self y=$fonty tli=$topLineIdx lines=$lines\n";
      next;
    }
    $fonty += $lineHeight;
    $self->write($self->{font},$line,$fontx,$fonty);
  }
}

#--------------------------------------------------
sub erase {
  my $self = shift;
  undef $self->{array};
}

#--------------------------------------------------
sub insert {
  my ($self, @text) = @_;

  for my $line (@text) {
    my $index = $self->glutWhatFits($self->font,'MM'.$line, $self->{width});
    if ($index<0) {
      # all fits
      push @{$self->{array}}, $line;
    } else {
      my $splitLoc = rindex($line,' ',$index);
      push @{$self->{array}}, substr($line,0,$splitLoc);
      $self->insert('  -'.substr($line,$splitLoc));
    }
  }

}

#==================================================================
###
### Test Driver for GUIText Object
###
if (not defined caller()) {
  package main;

  require OpenGL; # qw/:all/;
  require GUIMaster;

  my $t1;
  my $testText2;
  my $testText = sub {
    my $arg = shift;
    if (1) {
      $t1->insert("$arg aaaaaaaaaaaaaaaaaa");
    }
    $t1->color('light green');
    $t1->textColor('pink');
    glutPostRedisplay();
    glutTimerFunc(300.0,$testText2,++$arg);
  };

  $testText2 = sub {
    my $arg = shift;
    if (1) {
      $t1->setFont(GLUT_BITMAP_HELVETICA_12);
      $t1->insert("$arg zzzzzzzzzzzzzzzzzzzzzz");
      if ($arg >= 8) {
	$t1->erase();
	$arg = -1;
      }
    }
    $t1->color('beige');
    $t1->textColor('green');
    glutPostRedisplay();
    glutTimerFunc(300.0,$testText,++$arg);
  };

  my $winsize = 400;
  my $winw = $winsize;
  my $winh = $winsize;

  OpenGL::glutInit;
  OpenGL::glutInitDisplayMode(OpenGL::GLUT_RGB   |
			      OpenGL::GLUT_DEPTH |
			      OpenGL::GLUT_DOUBLE);
  OpenGL::glutInitWindowSize($winsize*2,$winsize);
  OpenGL::glutInitWindowPosition(200,100);
  my $win1 = OpenGL::glutCreateWindow("OpenGL GUIText Test");
  glViewport(0,0,$winw,$winh);

  my $GUIRoot = OpenGL::QEng::GUIMaster->new(x=>$winsize,y=>0,
			       width=>$winsize,height=>$winsize);
  $t1 = OpenGL::QEng::GUIText->new(x=>10,y=>10,
		     width=>300,height=>80,text=>'How now brown cow ');
  $t1->insert('How now brown cow How now brown cow How now brown cow ');
  $GUIRoot->adopt($t1);

  glutTimerFunc(100.0,$testText,0);
  glutDisplayFunc(sub{ $GUIRoot->GUIDraw(@_) });
  glutMouseFunc(  sub{ $GUIRoot->mouseButton(@_) });

  glutMainLoop;
}

#------------------------------------------------------------------------------
1;

__END__

=head1 NAME

GUIText -- Creates a window where the program can write scrolled text

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

