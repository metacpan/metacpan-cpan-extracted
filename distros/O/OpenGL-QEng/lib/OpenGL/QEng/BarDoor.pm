###  $Id: BarDoor.pm 424 2008-08-19 16:27:43Z duncan $
####------------------------------------------
###
## @file
# Define BarDoor Class

## @class BarDoor
# Doors in game - grate (bars) styles
#

package OpenGL::QEng::BarDoor;

use strict;
use warnings;
use OpenGL qw/:all/;

use base qw/OpenGL::QEng::Part/;

#####
##### Class Methods - called as Class->function($a,$b,$c)
#####

## @cmethod BarDoor new(@args)
# Create a new BarDoor
#
sub new {
  my ($class,@props) = @_;

  my $props = (scalar(@props) == 1) ? $props[0] : {@props};

  $props->{color} ||= 'black';
  $props->{face}  ||= [];
  $props->{xsize} ||= 4;
  $props->{ysize} ||= 7;
  $props->{zsize} ||= .1;
  $props->{model} ||= {minx => 0,                 maxx => $props->{xsize},
		       miny => 0,                 maxy => $props->{ysize},
		       minz => -$props->{zsize}/2,maxz => $props->{zsize}/2,
		       ##### Grate Door parameters
		       barCnt    => 7,
		       barWidth  => 0.1,
		       hbarWidth => 0.5,
		      };
  $props->{model}{gapWidth} ||=
    ($props->{model}{maxx}
     -$props->{model}{minx}
     -$props->{model}{barCnt}*$props->{model}{barWidth})
      /($props->{model}{barCnt}-1);
  # Y values for horizontal bars
  $props->{model}{h1} ||=
    $props->{model}{miny}+0.5*($props->{model}{maxy}-$props->{model}{miny})/6;
  $props->{model}{h2} ||=
    $props->{model}{miny}+3.0*($props->{model}{maxy}-$props->{model}{miny})/6;
  $props->{model}{h3} ||=
    $props->{model}{miny}+5.5*($props->{model}{maxy}-$props->{model}{miny})/6;

  my $self = OpenGL::QEng::Part->new($props);
  bless($self,$class);

  #$self->passedArgs({@props});
  $self->create_accessors;
  $self->register_events;

  $self;
}

##
## instance methods
##

{; #begin drawlist closure
 #
 my $dl = 0;
 my $chkErr = 0; #debug flag

#------------------------------------------
## @method draw($mode)
# Draw this object in its current state at its current location
# or set up for testing for a touch
 sub draw {
   my ($self,$mode) = @_;

   my $mdl = $self->model();

   if ($mode == OpenGL::GL_SELECT) {
     glLoadName($self->{GLid});
   }

   glTranslatef($self->{x},$self->y,$self->{z});
   glRotatef($self->{yaw},0,1,0) if $self->{yaw};

   if ($dl) {
     OpenGL::glCallList($dl);
     $chkErr && $self->tErr('draw Door3');
   } else {
     $dl = $self->getDLname();
     OpenGL::glNewList($dl,OpenGL::GL_COMPILE);

     #$chkErr && $self->tErr('Door_19');
     $self->setColor('black');
     glBegin(OpenGL::GL_QUADS);
     glVertex3f($mdl->{minx},                 $mdl->{miny},$mdl->{minz});
     glVertex3f($mdl->{minx}+$mdl->{barWidth},$mdl->{miny},$mdl->{minz});
     glVertex3f($mdl->{minx}+$mdl->{barWidth},$mdl->{maxy},$mdl->{minz});
     glVertex3f($mdl->{minx},                 $mdl->{maxy},$mdl->{minz});
     &OpenGL::glEnd();
     $chkErr && $self->tErr('Door_9');
     my $vx = $mdl->{minx}+$mdl->{gapWidth};
     for (my $i = 1; $i<$mdl->{barCnt}; $i++) {
       glBegin(OpenGL::GL_QUADS);
       glVertex3f($vx,                 $mdl->{miny},$mdl->{minz});
       glVertex3f($vx+$mdl->{barWidth},$mdl->{miny},$mdl->{minz});
       glVertex3f($vx+$mdl->{barWidth},$mdl->{maxy},$mdl->{minz});
       glVertex3f($vx,                 $mdl->{maxy},$mdl->{minz});
       &OpenGL::glEnd();
       $vx += $mdl->{barWidth}+$mdl->{gapWidth};
     }
     glBegin(OpenGL::GL_QUADS);
     glVertex3f($mdl->{minx},                 $mdl->{miny},$mdl->{maxz});
     glVertex3f($mdl->{minx}-$mdl->{barWidth},$mdl->{miny},$mdl->{maxz});
     glVertex3f($mdl->{minx}-$mdl->{barWidth},$mdl->{maxy},$mdl->{maxz});
     glVertex3f($mdl->{minx},                 $mdl->{maxy},$mdl->{maxz});
     &OpenGL::glEnd();

     $chkErr && $self->tErr('Door_91');
     glBegin(OpenGL::GL_QUADS);
     glVertex3f($mdl->{maxx},$mdl->{h1}-$mdl->{hbarWidth}/2,$mdl->{minz});
     glVertex3f($mdl->{maxx},$mdl->{h1}+$mdl->{hbarWidth}/2,$mdl->{minz});
     glVertex3f($mdl->{minx},$mdl->{h1}+$mdl->{hbarWidth}/2,$mdl->{minz});
     glVertex3f($mdl->{minx},$mdl->{h1}-$mdl->{hbarWidth}/2,$mdl->{minz});
     &OpenGL::glEnd();
     glBegin(OpenGL::GL_QUADS);
     glVertex3f($mdl->{maxx},$mdl->{h2}-$mdl->{hbarWidth}/2,$mdl->{minz});
     glVertex3f($mdl->{maxx},$mdl->{h2}+$mdl->{hbarWidth}/2,$mdl->{minz});
     glVertex3f($mdl->{minx},$mdl->{h2}+$mdl->{hbarWidth}/2,$mdl->{minz});
     glVertex3f($mdl->{minx},$mdl->{h2}-$mdl->{hbarWidth}/2,$mdl->{minz});
     &OpenGL::glEnd();
     glBegin(OpenGL::GL_QUADS);
     glVertex3f($mdl->{maxx},$mdl->{h3}-$mdl->{hbarWidth}/2,$mdl->{minz});
     glVertex3f($mdl->{maxx},$mdl->{h3}+$mdl->{hbarWidth}/2,$mdl->{minz});
     glVertex3f($mdl->{minx},$mdl->{h3}+$mdl->{hbarWidth}/2,$mdl->{minz});
     glVertex3f($mdl->{minx},$mdl->{h3}-$mdl->{hbarWidth}/2,$mdl->{minz});
     &OpenGL::glEnd();
     OpenGL::glEndList();
     OpenGL::glCallList($dl);   #### Draw it the first time
     $chkErr && $self->tErr('draw Door1');
   }
   if ($self->contains) {
     foreach my $o (@{$self->contains}) {
       $o->draw($mode);
     }
   }

   glRotatef(-$self->{yaw},0,1,0) if $self->{yaw};
   glTranslatef(-$self->{x},-$self->y,-$self->{z});

   $chkErr && $self->tErr('Door_texture');
 }
} #end closure

#--------------------------------------------------------------
sub tractable { # tractability - 'solid', 'seethru', 'passable'
  return 'seethru';
}

#------------------------------------------------------------------------------
1;


=head1 NAME

BarDoor -- Iron grate style door

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

