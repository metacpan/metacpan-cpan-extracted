###  $Id: Sword.pm 424 2008-08-19 16:27:43Z duncan $
####------------------------------------------

## @file Sword.pm
# Define Sword Class

## @class Sword
# Implement and draw a sword

package OpenGL::QEng::Sword;

use strict;
use warnings;
use OpenGL qw/:all/;
use OpenGL::QEng::glShapeP2p;

use base qw/OpenGL::QEng::SimpleThing/;


#------------------------------------------
sub new {
  my ($class,@props) = @_;

  @props = %{$props[0]} if (scalar(@props) == 1);

  my $self = OpenGL::QEng::SimpleThing->new;
  $self->{y}     = 0;
  $self->{color} = 'yellow';
  ### Sword Shape parameters
  $self->{model} = {miny => -0.0,
		    maxy => +0.1,
		    minx => -1.25,
		    maxx => +1.25,
		    minz => -0.25,
		    maxz => +0.25,
		    hiltx=> +1.25-0.4,
		    guardx=>+1.25-0.4-0.05,
		    pointx=>-1.25+0.75,
		    bladez=>+0.08,
		   };
  bless ($self,$class);

  $self->passedArgs({@props});
  $self->register_events;
  $self;
}

#------------------------------------------
## @method $ desc()
# Return a text description of this object
sub desc { 'Might help pry open a door' }

#------------------------------------------
## @method $ textName
# Displayable name of this thing
sub textName {"Well worn\n  sword"}

#------------------------------------------
{my $dl;			#closure over $dl

 sub draw {
   my ($self, $mode) = @_;

   if ($mode == OpenGL::GL_SELECT) {
     glLoadName($self->{GLid});
   }

   glTranslatef($self->{x},$self->y,$self->{z});
   glRotatef($self->{roll}, 0,0,1) if $self->{roll};
   glRotatef($self->{yaw},  0,1,0) if $self->{yaw};
   glRotatef($self->{pitch},1,0,0) if $self->{pitch};
   if ($dl) {
     OpenGL::glCallList($dl);
     #      $chkErr && $self->tErr('draw Sword1');
   } else {
     $dl = $self->getDLname();
     OpenGL::glNewList($dl,OpenGL::GL_COMPILE);

     #$chkErr &&
     $self->tErr('draw sword 2');
     # Hilt
     $self->setColor('black');
     OpenGL::QEng::glShapeP2p::drawCyl($self->{model}{hiltx},
			       $self->{model}{maxy}/2,
			       0.0,   #$self->{model}{minz}+0.2,
			       $self->{model}{maxx},
			       $self->{model}{maxy}/2,
			       0.0,   #$self->{model}{maxz}-0.2,
			       0.1,0.1);
     if (01) {
       OpenGL::QEng::glShapeP2p::drawBlock($self->{model}{guardx},
				   $self->{model}{miny},
				   $self->{model}{minz},
				   $self->{model}{hiltx},
				   $self->{model}{maxy},
				   $self->{model}{maxz});
     }
     $self->setColor('lightgray');
     glBegin(GL_QUADS);
     glVertex3f($self->{model}{pointx}, $self->{model}{maxy}/2,
		-$self->{model}{bladez});
     glVertex3f($self->{model}{guardx}, $self->{model}{maxy}/2,
 		-$self->{model}{bladez});
     glVertex3f($self->{model}{guardx}, $self->{model}{maxy}, 0);
     glVertex3f($self->{model}{pointx}, $self->{model}{maxy}, 0);

     glVertex3f($self->{model}{pointx}, $self->{model}{maxy}/2,
		+$self->{model}{bladez});
     glVertex3f($self->{model}{guardx}, $self->{model}{maxy}/2,
 		+$self->{model}{bladez});
     glVertex3f($self->{model}{guardx}, $self->{model}{maxy},0);
     glVertex3f($self->{model}{pointx}, $self->{model}{maxy},0);


     glVertex3f($self->{model}{pointx}, $self->{model}{maxy}/2,
		-$self->{model}{bladez});
     glVertex3f($self->{model}{guardx}, $self->{model}{maxy}/2,
 		-$self->{model}{bladez});
     glVertex3f($self->{model}{guardx}, $self->{model}{miny},0);
     glVertex3f($self->{model}{pointx}, $self->{model}{miny},0);

     glVertex3f($self->{model}{pointx}, $self->{model}{maxy}/2,
		+$self->{model}{bladez});
     glVertex3f($self->{model}{guardx}, $self->{model}{maxy}/2,
 		+$self->{model}{bladez});
     glVertex3f($self->{model}{guardx}, $self->{model}{miny},0);
     glVertex3f($self->{model}{pointx}, $self->{model}{miny},0);

     glEnd;

     glBegin(GL_TRIANGLES);
     glVertex3f($self->{model}{minx},$self->{model}{maxy}/2,0);
     glVertex3f($self->{model}{pointx},
		$self->{model}{maxy}/2,
		-$self->{model}{bladez});
     glVertex3f($self->{model}{pointx},
		$self->{model}{maxy},
		0);

     glVertex3f($self->{model}{minx},$self->{model}{maxy}/2,0);
     glVertex3f($self->{model}{pointx},
		$self->{model}{maxy}/2,
		+$self->{model}{bladez});
     glVertex3f($self->{model}{pointx},
		$self->{model}{maxy},
		0);

     glVertex3f($self->{model}{minx},$self->{model}{maxy}/2,0);
     glVertex3f($self->{model}{pointx},
		$self->{model}{maxy}/2,
		-$self->{model}{bladez});
     glVertex3f($self->{model}{pointx},
		$self->{model}{miny},
		0);

     glVertex3f($self->{model}{minx},$self->{model}{maxy}/2,0);
     glVertex3f($self->{model}{pointx},
		$self->{model}{maxy}/2,
		+$self->{model}{bladez});
     glVertex3f($self->{model}{pointx},
		$self->{model}{miny},
		0);
     glEnd;
     $self->setColor('medgray');
     glBegin(GL_LINES);
     glVertex3f($self->{model}{minx},$self->{model}{maxy}/2,0);
     glVertex3f($self->{model}{guardx},
		$self->{model}{maxy},0);
#		+$self->{model}{bladez});
     glVertex3f($self->{model}{minx},$self->{model}{maxy}/2,0);
     glVertex3f($self->{model}{guardx},
		$self->{model}{miny},0);
#		$self->{model}{minz}+0.15);
     glEnd;
     OpenGL::glEndList();
     OpenGL::glCallList($dl);	#### Draw it the first time
   }
  glRotatef(-$self->{pitch},1,0,0) if $self->{pitch};
  glRotatef(-$self->{yaw},  0,1,0) if $self->{yaw};
  glRotatef(-$self->{roll}, 0,0,1) if $self->{roll};

   glTranslatef(-$self->{x},-$self->y,-$self->{z});

   $self->tErr('draw Sword');
 }
}				#end closure

#===========================================================================
#
# the map 'new_quests.txt' has a sword for testing, so does 'girlmap.txt'
#

#------------------------------------------------------------------------------
1;

__END__

=head1 NAME

Sword -- sharp, pointy subclass of SimpleThing

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

