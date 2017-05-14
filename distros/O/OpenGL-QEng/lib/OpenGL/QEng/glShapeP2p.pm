###  $Id: glShapeP2p.pm 424 2008-08-19 16:27:43Z duncan $
####------------------------------------------

## @file glShapeP2p.pm
# Define glShapeP2p tools
#   Tools for drawing shapes given end points in OpenGL
#

## @class glShapeP2p
#  Methods for drawing cylinders or Blocks from point 1 to point 2 in OpenGL

package OpenGL::QEng::glShapeP2p;

use strict;
use warnings;
use OpenGL qw/:all/;
use Math::Trig;

use constant PI => 4*atan2(1,1);
use constant RADIANS => PI/180.0;
use constant DEGREES => 180.0/PI;

#program version
my $VERSION="0.2";

my $texFg =0;

my @col = ([0.0,0.0,1.0],
	   [160.0/255.0, 23.0/255.0, 240.0/255.0],
	   [1.0,0.0,0.0],
	   [1.0,0.0,1.0],
	   [1.0,1.0,0.0],
	   [1.0,1.0,1.0],
	   [0.0,1.0,1.0],
	   [0.0,1.0,0.0]
	  );

#------------------------------------------
## @method $ drawBlock($x1,$y1,$z1,$x2,$y2,$z2)
sub drawBlock {
  my ($x1,$y1,$z1,$x2,$y2,$z2)= @_;

  my (@x,@y,@z);

  $x[0] = $x1;
  $y[0] = $y1;
  $z[0] = $z1;
  $x[1] = $x2;
  $y[1] = $y1;
  $z[1] = $z1;
  $x[2] = $x2;
  $y[2] = $y2;
  $z[2] = $z1;
  $x[3] = $x1;
  $y[3] = $y2;
  $z[3] = $z1;

  $x[4] = $x1;
  $y[4] = $y1;
  $z[4] = $z2;
  $x[5] = $x2;
  $y[5] = $y1;
  $z[5] = $z2;
  $x[6] = $x2;
  $y[6] = $y2;
  $z[6] = $z2;
  $x[7] = $x1;
  $y[7] = $y2;
  $z[7] = $z2;

  # list of the face numbers for the Block
  #verticies in each face
  my @f =
    ( 0, 1, 2, 3,		#front
      3, 2, 6, 7,		# top
      7, 6, 5, 4,		#
      4, 5, 1, 0,		#bottom
      5, 6, 2, 1,		#
      7, 4, 0, 3,		#
    );

  # Texture x coordingate
  my @texture_coords_x = (0.0, 0.0, 1.0, 1.0);

  # Texture y coordingate
  my @texture_coords_y = (0.0, 1.0, 0.0, 1.0);

  # texture orientation map
  my @texture_pat = ([0,2,3,1],
		     [1,0,2,3],
		     [3,1,0,2],
		     [2,3,1,0],
		     [2,3,1,0],
		     [1,0,2,3]);

  # List of texture names corresponding to Block faces
  my @texture = ('side','wood','side','wood','side','side');

  # create all sides but the top
  for my $i ( 1, 2, 3, 4, 5, 0 ) {
    $texFg && glEnable(OpenGL::GL_TEXTURE_2D);
    #OpenGL::glBindTexture(OpenGL::GL_TEXTURE_2D,$texture[$i]);
    #$texFg && $self->pickTexture($texture[$i]);
    #glTranslatef(0,0.4,0);
    #glColor4f($col[$i][0],$col[$i][1],$col[$i][2],1.0);
    OpenGL::glBegin(OpenGL::GL_POLYGON);
    for my $j (0..3) {
      #$texFg &&
	OpenGL::glTexCoord2f($texture_coords_x[$texture_pat[$i][$j]],
			     $texture_coords_y[$texture_pat[$i][$j]]);
      my $k = $f[$i*4+$j];
      OpenGL::glVertex3f($x[$k],$y[$k],$z[$k]);
      #print "side: $i $x[$k],$y[$k],$z[$k]\n";
    }
    OpenGL::glEnd();
  }
  $texFg && OpenGL::glDisable(OpenGL::GL_TEXTURE_2D);
}

#------------------------------------------------------------
sub drawCyl {
  my ($x1,$y1,$z1,$x2,$y2,$z2,$dia1,$dia2)= @_;
  $dia1=0.03 unless defined $dia1;
  $dia2=0.03 unless defined $dia2;
  OpenGL::glTranslatef($x1,$y1,$z1);
  ### find the length
  my $len = sqrt(($x2-$x1)*($x2-$x1)+($y2-$y1)*($y2-$y1)+($z2-$z1)*($z2-$z1));

  ### Then rotate the scene so that point 2 lies on the z-axis
  my $rotX = getXrotate($x1,$y1,$z1,$x2,$y2,$z2);
  my $rotY = getYrotate($x1,$y1,$z1,$x2,$y2,$z2);

  my $workQuad = gluNewQuadric();
  ### Rotate around Y to get the XZ coords along Z
  OpenGL::glRotatef(-$rotY,0,1,0);
  ### Rotate around X to get the Y component along Z
  OpenGL::glRotatef(+$rotX,1,0,0);
  OpenGL::gluCylinder($workQuad,$dia1,$dia2,$len,10,10);
  ### Restore the scene
  OpenGL::glRotatef(-$rotX,1,0,0);
  OpenGL::glRotatef(+$rotY,0,1,0);
  OpenGL::glTranslatef(-$x1,-$y1,-$z1);
}

#------------------------------------------------------------
sub getXrotate {
  my ($x1,$y1,$z1,$x2,$y2,$z2) = @_;
  my $ret = getAngle($y2-$y1,sqrt(($z2-$z1)*($z2-$z1)+
				  ($x2-$x1)*($x2-$x1)));
  return $ret;
}

#------------------------------------------------------------
sub getYrotate {
  my ($x1,$y1,$z1,$x2,$y2,$z2) = @_;
  my $ret = getAngle($x2-$x1,$z2-$z1);
  return $ret;
}

#------------------------------------------------------------
sub getZrotate {
  my ($x1,$y1,$z1,$x2,$y2,$z2) = @_;
  my $ret = getAngle($x2-$x1,$y2-$y1);
  return $ret;
}

#------------------------------------------------------------
sub getAngle {
  my ($dx,$dz) = @_;
  my $ang=0;
  my $len =sqrt($dx*$dx+$dz*$dz);
  if ($len<.0001) {
    return $ang;
  }

  my $xang = DEGREES*(asin(abs($dx)/$len));
  if ($dx<0 and $dz<0) {
    $ang = 180-$xang;
  } elsif ($dx<0) {
    $ang = $xang;
  } elsif ($dz<0) {
    $ang = $xang+180;
  } else {
    $ang = -$xang;
  }
  return $ang;
}

  sub drawDisk {
    my ($self, $originX,$originZ,$radius,$color) = @_;
    #my $radius =0.5;
    ## draw a solid disc from a bunch of triangles
    #my $originX = 0.0;
    #my $originZ = 0.0;
	
    my $vectorZ1=$originZ;
    my $vectorX1=$originX;
    $self->setColor($color);
    glBegin(GL_TRIANGLES);	
    for (my $i=0;$i<=360;$i+=10) {
      my $angle=$i/57.29577957795135;	
      my $vectorX=$originX+($radius*sin($angle));
      my $vectorZ=$originZ+($radius*cos($angle));		
      glVertex3f($originX,0,$originZ);
      glVertex3f($vectorX1,0,$vectorZ1);
      glVertex3f($vectorX,0,$vectorZ);
      $vectorZ1=$vectorZ;
      $vectorX1=$vectorX;	
    }
    glEnd();
  }


  sub drawCircle {
    my ($self, $originX,$originZ,$radius1, $radius2,$color) = @_;
	
    my $vectorZ1=$originZ;
    my $vectorX1=$originX;
    $self->setColor($color);
    glBegin(GL_TRIANGLE_STRIP);	
    for (my $i=0;$i<=360;$i+=10) {
      my $angle1=$i/57.29577957795135;	
      my $angle2=($i+5)/57.29577957795135;	


      my $vectorX1=$originX+($radius1*sin($angle1));
      my $vectorZ1=$originZ+($radius1*cos($angle1));		
      my $vectorX2=$originX+($radius2*sin($angle2));
      my $vectorZ2=$originZ+($radius2*cos($angle2));		
      glVertex3f($vectorX1,4,$vectorZ1);
      glVertex3f($vectorX2,4,$vectorZ2);
    }
    glEnd();
  }


1;

__END__

=head1 NAME

glShapeP2p - draw cylinders or Blocks from point 1 to point 2

=head1 SYNOPSIS

use OpenGL::QEng::glShapeP2p;

To draw cylinders

  drawCyl(1.1,0.2,0.0,
	  2.5,-1.2,0.5);

  drawCyl($x1,$y1,$z1,$x2,$y2,$z2,$dia1,$dia2);

To draw blocks

  drawBlock(1.1,0.2,0.0,
	  2.5,-1.2,0.5);

  drawBlock($x1,$y1,$z1,$x2,$y2,$z2,$dia1,$dia2);



=head1 DESCRIPTION

drawCyl

Draw a cylinder in the current color from point 1 (x1,y1,z1)
to point 2 (x2,y2,z2).  The diameter at point 1 is dia1 (default 0.03).
The diameter at point 2 is dia2 (default 0.03).

drawBlock

Draw a block in the current color from point 1 (x1,y1,z1)
to point 2 (x2,y2,z2).  The points define a diagonal of the block.

=head1 SEE ALSO

Uses OpenGL and Math::Trig.

=cut
