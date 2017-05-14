###  $Id: GUIThing.pm 322 2008-07-19 22:32:21Z duncan $
####------------------------------------------
## @file
# Define GUIThing Class
# GUI Widgets and related capabilities
#

## @class GUIThing
# Base class for the widgets implemented in the GUI interface for OpenGL.

package OpenGL::QEng::GUIThing;

use strict;
use warnings;
use OpenGL ':all';
use File::ShareDir;
use OpenGL::QEng::Event;
use OpenGL::QEng::TextureList;

use base qw/OpenGL::QEng::OUtil/;

#--------------------------------------------------
## @cmethod % new()
# Create a GUIThing
#
sub new {
  my ($class,@props) = @_;

  @props = %{$props[0]} if (scalar(@props) == 1);

  my $self = {event     => OpenGL::QEng::Event->new,
	      x         => 0,
	      y         => 0,
	      width     => 0,
	      height    => 0,
              color     => 'pink',
              texture   => undef,
	      textColor => 'purple',
	      font      => GLUT_BITMAP_HELVETICA_10,
	      children  => undef,
	     };
  bless($self,$class);
  $self->passedArgs({@props});
  $self->create_accessors;

  $self;
}

######
###### Public Instance Methods
######

#------------------------------------------
sub adopt {
  my ($self,$child) = @_;
  push (@{$self->{children}},$child);
}

#-------------------------------------
## @method   send_event(%event)
#signal an event
sub send_event {
  $_[0]->{event}->yell(@_)
}

#---------------------------------------------------------------------------
sub inside {
  my ($self, $x, $y) = @_;

  if ($x > $self->{x}                &&
      $x < $self->{x}+$self->{width} &&
      $y > $self->{y}                &&
      $y < $self->{y}+$self->{height} ) {
    return 1;
  }
  0;
}

#-----------------------------------------------------------------------------
sub buttonPress {
  my ($self, $x, $y) = @_;

  for my $child (@{$self->{children}}) {
    if ($child->inside($x,$y)) {
      $child->buttonPress($x,$y);
      return;
    }
  }
  # still here, try us...
  $self->{state} = 1; # mouse cursor was in this button
  if ($self->{pressCallback}) {
    if (ref($self->{pressCallback}) eq 'ARRAY') {
      my @pcb = @{$self->{pressCallback}};
      my $cref = shift @pcb;
      $cref->(@pcb);
    } else {
      $self->{pressCallback}($self);
    }
  }
}

#---------------------------------------------------------------------------
sub buttonRelease {
  my ($self, $x, $y) = @_;

  for my $child (@{$self->{children}}) {
    if ($child->inside($self->{mouse}{xpress}, $self->{mouse}{ypress}) &&
	$child->inside($x,$y)) {
      $child->{mouse} = $self->{mouse};
      $child->buttonRelease($x,$y);
      return;
    }
  }
  # still here, try us...
  if ($self->{clickCallback}) {
    if (ref($self->{clickCallback}) eq 'ARRAY') {
      my @pcb = @{$self->{clickCallback}};
      my $cref = shift @pcb;
      $cref->(@pcb);
    } else {
      $self->{clickCallback}($self);
    }
    $self->{state} = 0;
  }
}

#---------------------------------------------------------------------------
sub buttonPassive {
  my ($self, $x, $y) = @_;

  for my $child (@{$self->{children}}) {
    if ($child->inside($x,$y)) {
      $child->buttonPassive($x,$y);
      return;
    }
  }
  # still here, try us...
  if (($self->{highlighted}||0) == 0) {
    $self->{highlighted} = 1;
    #$needRedraw = 1;
    glutPostRedisplay();
  }
}

#---------------------------------------------------------------------------
sub setFont {
  my ($self, $font) = @_;
  if ( $font == GLUT_BITMAP_9_BY_15 ||
       $font == GLUT_BITMAP_8_BY_13 ||
       $font == GLUT_BITMAP_TIMES_ROMAN_10 ||
       $font == GLUT_BITMAP_TIMES_ROMAN_24 ||
       $font == GLUT_BITMAP_HELVETICA_10 ||
       $font == GLUT_BITMAP_HELVETICA_12 ||
       $font == GLUT_BITMAP_HELVETICA_18) {
    $self->{font} = $font;
  } else {
    print STDERR "$font is not a recognized glut bitmap font name\n";
  }
}

#---------------------------------------------------------------------------
# \brief This function draws a text string to the screen using glut
#        bitmap fonts.
# \param font	-	the font to use. it can be one of the following :
# 		GLUT_BITMAP_9_BY_15		
# 		GLUT_BITMAP_8_BY_13			
# 		GLUT_BITMAP_TIMES_ROMAN_10	
# 		GLUT_BITMAP_TIMES_ROMAN_24	
# 		GLUT_BITMAP_HELVETICA_10	
# 		GLUT_BITMAP_HELVETICA_12	
# 		GLUT_BITMAP_HELVETICA_18	
#
# \param text	-	the text string to output
# \param x	-	the x co-ordinate
# \param y	-	the y co-ordinate
#
#-----------------------------------------------------------
sub write {
  my ($self, $font, $text, $x, $y) = @_;

  glRasterPos2i($x, $y);
  for my $c (split //, $text) {
    glutBitmapCharacter($font, ord($c));
  }
}

#-----------------------------------------------------------
## Provide function glut seems to lack
sub glutBitmapLength {
  my ($self, $font, $text) = @_;

  my $size = 0;
  for my $c (split //, $text) {
    $size += glutBitmapWidth($font, ord($c));
  }
  $size;
}

#-----------------------------------------------------------
## Determine how much of a line will fit
sub glutWhatFits {
  my ($self, $font, $text, $max) = @_;

  my $size = 0;
  my $char = 0;
  for my $c (split //, $text) {
    $size += glutBitmapWidth($font, ord($c));
    if ($size>$max) {
      return $char;
    } else {
      $char++;
    }
  }
  return -1;
}

#-----------------------------------------------------------
## @method $ tErr
# print any pending OpenGL error
sub tErr {
  my ($self, $w) = @_;

  while (my $e = glGetError()) {
    print "$e, ",gluErrorString($e)," \@:$w\n";
  }
}

#----------------------------------------------------
{;
 my $textList;

## @method $ pickTexture($key)
# Set the texture from a texture name string
 sub pickTexture {
   my ($self,$key) = @_;

   unless (defined $textList) {
     my $idir = File::ShareDir::dist_dir('Games-Quest3D');
     $idir .= '/images';
     $textList = OpenGL::QEng::TextureList->new($idir);
   }
   $textList->pickTexture($key);
 }
}

#---???---???---???---???---???---???---???---???---???---???---???---???
##### Duplicate of capabilities in Thing.  Need to Find the "right" location
# for them

## select a color by name

{;# @map_item Current colors are:
 my %colors;

 sub make_color_map {
   %colors = ('blue'     =>[0.0,0.0,1.0],
	      'purple'   =>[160.0/255.0, 23.0/255.0, 240.0/255.0],
	      'pink'     =>[1.0,0.733,0.870],
	      'pink'     =>[1.0,192.0/255.0,203.0/255.0],
	      'red'      =>[1.0,0.0,0.0],
	      'magenta'  =>[1.0,0.0,1.0],
	      'yellow'   =>[1.0,1.0,0.0],
	      'white'    =>[1.0,1.0,1.0],
	      'cyan'     =>[0.0,1.0,1.0],
	      'green'    =>[0.0,1.0,0.0],
	      'beige'    =>[245.0/255.0,245.0/255.0,135.0/255.0],
	      'brown'    =>[141.0/255.0, 76.0/255.0, 47.0/255.0],
	      'orange'   =>[255.0/255.0,165.0/255.0,0.0/255.0],
	      'gold'     =>[255.0/255.0,215.0/255.0,0.0/255.0],
	      'gray'     =>[64.0/255.0,64.0/255.0,64.0/255.0],
	      'gray75'   =>[191.0/255.0,191.0/255.0,191.0/255.0],
	      'slate gray'=>[112.0/255.0,128.0/255.0,144.0/255.0],
	      'darkgray' =>[47.0/255.0,79.0/255.0,79.0/255.0],
	      'medgray'  =>[192.0/255.0,192.0/255.0,192.0/255.0],
	      'lightgray'=>[211.0/255.0,211.0/255.0,211.0/255.0],
	      'black'    =>[0.0,0.0,0.0],
	      'cream'    =>[250.0/255.0,240.0/255.0,230.0/255.0],
	      'light green' =>[144.0/255.0,238.0/255.0,144.0/255.0],
	      'light blue' =>[173.0/255.0,216.0/255.0,230.0/255.0],
	     );
   my $path = 'rgb.txt';
   for my $p ('/etc/X11/rgb.txt',
	      '/usr/share/X11/rgb.txt',
	      '/usr/X11R6/lib/X11/rgb.txt',
	      '/usr/openwin/lib/X11/rgb.txt',
	     ) {
     ($path=$p, last) if -f $p;
   }
   if (open my $rgb,'<',$path) {
     while (my $line = <$rgb>) {
       my ($r,$g,$b,$name);
       next unless ($r,$g,$b,$name) =
	 $line =~ /^\s*(\d+)\s+(\d+)\s+(\d+)\s+(\w.*\w)\s*$/;
       $colors{lc $name} = [$r/255.0,$g/255.0,$b/255.0,];
     }
     close $rgb;
   }
 }

#-------------------------------------
## @method setColor($color)
# set the color from a text name
 sub setColor {
   my ($self,$color) = @_;

   make_color_map() unless $colors{red};
   $color = lc $color;
   if ($color eq 'clear'){
     glColor4f(0.0,0.0,0.0,1.0);
   } elsif (defined($colors{$color})) {
     glColor4f($colors{$color}[0],$colors{$color}[1],$colors{$color}[2],1.0);
   } else {
     print "unknown color $color\n";
   }
 }

#-------------------------------------
## @method @ getColor($color)
# get the color value triplet from a text name
sub getColor {
   my ($self,$color) = @_;

   make_color_map() unless $colors{red};
   $color = lc $color;
   if (defined $colors{$color}) {
     return @{$colors{$color}};
   }
   print "unknown color $color\n";
 }
} # end closure

#==================================================================
###
### Test Driver for GUIThing Object
###
if (not defined caller()) {
  package main;

  use OpenGL qw\:all\;


}

#------------------------------------------------------------------------------
1;

__END__

=head1 NAME

GUIThing -- Base class for the OpenGL GUI widgets.

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

