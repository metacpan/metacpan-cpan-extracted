###################################################
#
#	ArcBall.pm
#
# 	From Graphics Gems IV.
#
# This is an example of the controller class:
# the routines set_wh and mouse_moved are the standard routines.
#
# This needs a faster implementation (?)

package PDL::Graphics::TriD::QuaterController;
use strict;
use warnings;
use PDL::Graphics::TriD::Quaternion;
use base qw(PDL::Graphics::TriD::ButtonControl);
use fields qw /Inv Quat/;

use constant PI => 3.14159265358979323846264338327950288;

$PDL::Graphics::TriD::verbose //= 0;

sub new {
  my($type,$win,$inv,$quat) = @_;
  my $this = $type->SUPER::new($win);
  $this->{Inv} = $inv;
  $this->{Quat} = (defined($quat) ? $quat :
			PDL::Graphics::TriD::Quaternion->new(1,0,0,0));
  $win->add_resizecommand(sub {$this->set_wh(@_)});
  $this;
}

# setup for subclasses
sub mouse_moved {
  my($this,$x0,$y0,$x1,$y1) = @_;
  # Copy the size of the owning viewport to our size, in case it changed
  @$this{qw(H W)} = @{$this->{Win}}{qw(H W)};
  if ($PDL::Graphics::TriD::verbose) {
    print "QuaterController: mouse-moved: $this: $x0,$y0,$x1,$y1,$this->{W},$this->{H},$this->{SC}\n";
    if ($PDL::Graphics::TriD::verbose > 1) {
      print "\tthis is:\n";
      foreach my $k(sort keys %$this) {
        print "\t$k\t=>\t$this->{$k}\n";
      }
    }
  }
}

# Original ArcBall
#
package PDL::Graphics::TriD::ArcBall;
use base qw/PDL::Graphics::TriD::QuaterController/;

sub xy2qua {
  my($this,$x,$y) = @_;
  $x -= $this->{W}/2; $y -= $this->{H}/2;
  $y = -$y;
  return $this->normxy2qua($x,$y);
}

sub mouse_moved {
  my($this,$x0,$y0,$x1,$y1) = @_;
  $this->SUPER::mouse_moved($x0,$y0,$x1,$y1);
# Convert both to quaternions.
  my $arc = $this->xy2qua($x1,$y1) / $this->xy2qua($x0,$y0);
  if ($this->{Inv}) {
          $arc->invert_rotation_this();
  }
  $this->{Quat} .= $arc * $this->{Quat};
  1;  # signals a refresh
}

sub get_z {
  my ($this, $dist) = @_;
  sqrt(1-$dist**2);
}

# x,y to unit quaternion on the sphere.
sub normxy2qua {
  my($this,$x,$y) = @_;
  $x /= $this->{SC}; $y /= $this->{SC};
  my $dist = sqrt ($x ** 2 + $y ** 2);
  if ($dist > 1.0) {$x /= $dist; $y /= $dist; $dist = 1.0;}
  my $z = $this->get_z($dist);
  PDL::Graphics::TriD::Quaternion->new(0,$x,$y,$z)->normalise;
}

# Tjl's version: a cone - more even change of
package PDL::Graphics::TriD::ArcCone;

use base qw/PDL::Graphics::TriD::ArcBall/;

sub get_z {
  my ($this, $dist) = @_;
  1-$dist;
}

# Tjl's version2: a bowl -- angle is proportional to displacement.
package PDL::Graphics::TriD::ArcBowl;

use base qw/PDL::Graphics::TriD::ArcBall/;
BEGIN { *PI = \&PDL::Graphics::TriD::QuaterController::PI; }

sub get_z {
  my ($this, $dist) = @_;
  cos($dist*PI/2);
}

package PDL::Graphics::TriD::Orbiter;

use base qw/PDL::Graphics::TriD::QuaterController/;
BEGIN { *PI = \&PDL::Graphics::TriD::QuaterController::PI; }

# we rotate about our space's "Z" because that's what we made vertical
# this is different from the OpenGL Z axis which is towards the viewer
sub mouse_moved {
  my($this,$x0,$y0,$x1,$y1) = @_;
  $this->SUPER::mouse_moved($x0,$y0,$x1,$y1);
  my ($dx, $dy) = ($x1-$x0, $y1-$y0);
  $dx /= $this->{W}/2; $dy /= $this->{H}/2; # scale to whole window not SC
  my ($x_rad, $y_rad) = map PI*$_, $dx, $dy;
  my $q_horiz = PDL::Graphics::TriD::Quaternion->new(cos $x_rad/2, 0, 0, sin $x_rad/2);
  my $q_vert = PDL::Graphics::TriD::Quaternion->new(cos $y_rad/2, sin $y_rad/2, 0, 0);
  if ($this->{Inv}) {
    $_->invert_rotation_this for $q_horiz, $q_vert;
  }
  $this->{Quat} .= $q_vert * $this->{Quat} * $q_horiz;
  1;  # signals a refresh
}

1;
