###  $Id: Sconce.pm 424 2008-08-19 16:27:43Z duncan $
####------------------------------------------

## @file
# Define Sconce Class

## @class Sconce
# Sconce for decoration -- a wall lamp

package OpenGL::QEng::Sconce;

use strict;
use warnings;
use OpenGL qw/:all/;
use OpenGL::QEng::glShapeP2p;

use base qw/OpenGL::QEng::Thing/;

my $light_count = 0;  # OpenGL limits scenes to 8 light sources 0-7

#------------------------------------------
sub new {
  my ($class,@props) = @_;

  @props = %{$props[0]} if (scalar(@props) == 1);

  my $self = OpenGL::QEng::Thing->new;
  $self->{y}     = 5;
  $self->{color} = 'yellow';
  ### Plaque Shape parameters
  $self->{model} = {miny => -0.5,
		    maxy => +0.5,
		    minx => -0.3,
		    maxx => +0.3,
		    minz => -0.05,
		    maxz => +0.05,
		   };
  $self->{light_num} = $light_count++;
  bless ($self,$class);

  $self->passedArgs({@props});
  $self->register_events;
  $self;
}

#------------------------------------------
{my %dl; #closure over $dl

my %colors = ('yellow'=>[[255.0/255.0,  0.0/255.0,  0.0/255.0],  # red core
			 [255.0/255.0,255.0/255.0,  0.0/255.0],  # yellow cone
			 [255.0/255.0,255.0/255.0,  0.0/255.0]], # yellow globe
	      'red'   =>[[255.0/255.0,  0.0/255.0,255.0/255.0],  # purple core
			 [255.0/255.0,  0.0/255.0,  0.0/255.0],  # red cone
			 [255.0/255.0,  0.0/255.0,  0.0/255.0]], # red globe
	      'blue'  =>[[255.0/255.0,  0.0/255.0,255.0/255.0],  # purple core
			 [  0.0/255.0,  0.0/255.0,255.0/255.0],  # blue cone
			 [  0.0/255.0,  0.0/255.0,255.0/255.0]], # blue globe
	      'green' =>[[  0.0/255.0,255.0/255.0,  0.0/255.0],  # green core
			 [  0.0/255.0,255.0/255.0,  0.0/255.0],  # green cone
			 [  0.0/255.0,255.0/255.0,  0.0/255.0]], # green globe
	     );

 sub draw {
   my ($self, $mode) = @_;

   my @light_parm = (GL_LIGHT0, GL_LIGHT1, GL_LIGHT2, GL_LIGHT3,
		      GL_LIGHT4, GL_LIGHT5, GL_LIGHT6, GL_LIGHT7);

   my @lightPos = (0.0, 0.0, 0.0, 0.0);
   my @lightAmb = (1.0, 1.0, 1.0, 1.0);
   my @lightDiff = (1.0, 1.0, 1.0, 1.0);
   my @lightSpec = (1.0, 1.0, 1.0, 1.0);

   if ($mode == OpenGL::GL_SELECT) {
     glLoadName($self->{GLid});
   }

   glTranslatef($self->{x},$self->y,$self->{z});
   glRotatef($self->{yaw},0,1,0) if $self->{yaw};
   #glRotatef(90,1,0,0);
   if ($dl{$self->{color}}) {
     OpenGL::glCallList($dl{$self->{color}});
     #      $chkErr && &main::tErr('draw Floor1');
   } else {
     $dl{$self->{color}} = $self->getDLname();
     OpenGL::glNewList($dl{$self->{color}},OpenGL::GL_COMPILE);
     # Set up light source info
     my $light_num = $light_parm[$self->{light_num}];
       glMaterialfv_p(GL_FRONT_AND_BACK,GL_EMISSION,@lightSpec);
     if (0 && defined $light_num) {
       glEnable(GL_LIGHTING);
       glLightfv_p($light_num, GL_POSITION, @lightPos);
       glLightfv_p($light_num, GL_AMBIENT, @lightAmb);
       glLightfv_p($light_num, GL_DIFFUSE, @lightDiff);
       glLightfv_p($light_num, GL_SPECULAR, @lightSpec);
       #glLightf($light_num, GL_QUADRATIC_ATTENUATION, 0.07);
       glPushAttrib(GL_LIGHTING_BIT);
       glMaterialfv_p(GL_FRONT, GL_AMBIENT, @lightAmb);
       glMaterialfv_p(GL_FRONT, GL_DIFFUSE, @lightDiff);
       glMaterialfv_p(GL_FRONT, GL_SPECULAR, @lightSpec);
       glMaterialfv_p(GL_FRONT_AND_BACK,GL_EMISSION,@lightSpec);
       glPopAttrib;
     }
     #$chkErr &&
       $self->tErr('draw sconce light 1');
     # Wall Plaque
     $self->setColor('brown');
     OpenGL::QEng::glShapeP2p::drawBlock($self->{model}{minx},
				 $self->{model}{miny},
				 $self->{model}{minz},
				 $self->{model}{maxx},
				 $self->{model}{maxy},
				 $self->{model}{maxz});
     #Candle
     $self->setColor('white');
     OpenGL::QEng::glShapeP2p::drawCyl(0.0,
			       $self->{model}{miny}+0.2,
			       $self->{model}{minz}+0.5,
			       0.0,
			       $self->{model}{maxy}+0.1,
			       $self->{model}{minz}+0.5,0.2,0.2);
     #base
     $self->setColor('black');
     OpenGL::QEng::glShapeP2p::drawCyl(0.0,
			       $self->{model}{miny}+0.2,
			       $self->{model}{minz}+0.5,
			       0.0,
			       $self->{model}{miny}+0.0,
			       $self->{model}{minz}+0.5,0.3,0.0);

     #$self->setColor('gray');
     #glutSolidCone(0.2,2.0,10,10);
     #$self->setColor('purple');
     glColor3f(255.0/255.0, 0/255.0,255.0/255.0); #purple
     #glutSolidCone(0.1,-0.20,10,10);
     OpenGL::QEng::glShapeP2p::drawCyl(0.0,
			       $self->{model}{maxy}+0.1,
			       $self->{model}{minz}+0.5,
			       0.0,
			       $self->{model}{maxy}+0.3,
			       $self->{model}{minz}+0.5,0.1,0.0);

     my @rgb = @{$colors{$self->{color}}[0]};

     glColor3f($rgb[0],$rgb[1],$rgb[2]);
     #$self->setColor('blue');
     glEnable (GL_BLEND); glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
     glColor4f(0/255.0, 0/255.0,255.0/255.0,0.4); # see-thru yellow
     glColor4f($colors{$self->{color}}[1][0],
	       $colors{$self->{color}}[1][1],
	       $colors{$self->{color}}[1][2],0.4); #transparent
     #glutSolidCone(0.2,-0.50,10,10);
     OpenGL::QEng::glShapeP2p::drawCyl(0.0,
			       $self->{model}{maxy}+0.1,
			       $self->{model}{minz}+0.5,
			       0.0,
			       $self->{model}{maxy}+0.4,
			       $self->{model}{minz}+0.5,0.2,0.0);

     glTranslatef(0.0,
		  $self->{model}{maxy}+0.4,
		  $self->{model}{minz}+0.5);

     glColor4f(0/255.0, 0/255.0,255.0/255.0,0.1); # see-thru yellow
     glColor4f($colors{$self->{color}}[2][0],
	       $colors{$self->{color}}[2][1],
	       $colors{$self->{color}}[2][2],0.1); #very transparent

     glutSolidSphere(0.9,20,16);
     glDisable(GL_BLEND);

     glTranslatef(0.0,
		  -($self->{model}{maxy}+0.4),
		  -($self->{model}{minz}+0.5));
     OpenGL::glEndList();
     OpenGL::glCallList($dl{$self->{color}});  #### Draw it the first time
   }

   glRotatef(-$self->{yaw},0,1,0) if $self->{yaw};
#   glRotatef(-90,1,0,0);
   glTranslatef(-$self->{x},-$self->y,-$self->{z});

   $self->tErr('draw Sconce');
 }
} #end closure

#==================================================================
#
# use the map "tunnel2.txt" as a test for Sconce
#

#------------------------------------------------------------------------------
1;

__END__

=head1 NAME

Sconce -- a decorative wall lamp

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

