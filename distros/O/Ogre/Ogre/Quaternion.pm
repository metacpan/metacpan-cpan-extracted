package Ogre::Quaternion;

use strict;
use warnings;

# xxx: this should be in XS, but I can't get it to work
use overload
  '==' => \&quat_eq_xs,
  '!=' => \&quat_ne_xs,
  '+' => \&quat_plus_xs,
  '-' => \&quat_minus_xs,
  '*' => \&quat_mult_xs,
  '0+' => sub { $_[0] },
  'neg' => \&quat_neg_xs,
  ;


1;

__END__
=head1 NAME

Ogre::Quaternion

=head1 SYNOPSIS

  use Ogre;
  use Ogre::Quaternion;
  # (for now see examples/README.txt)

=head1 DESCRIPTION

See the online API documentation at
 L<http://www.ogre3d.org/docs/api/html/classOgre_1_1Quaternion.html>

B<Note:> this Perl binding is currently I<experimental> and subject to API changes.

=head1 CLASS METHODS

=head2 Ogre::Quaternion->new(...)

I<Parameter types>

=over

=item ... : this varies... (sorry, look in the .xs file)

=back

I<Returns>

=over

=item Quaternion *

=back

=head2 Ogre::Quaternion->DESTROY()

This method is called automatically; don't call it yourself.

=head2 \&eq_xs

This is an operator overload method; don't call it yourself.

=head2 \&plus_xs

This is an operator overload method; don't call it yourself.

=head2 \&mult_xs

This is an operator overload method; don't call it yourself.

=head2 \&neg_xs

This is an operator overload method; don't call it yourself.

=head1 INSTANCE METHODS

=head2 $obj->FromRotationMatrix($kRot)

I<Parameter types>

=over

=item $kRot : Matrix3 *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->ToRotationMatrix($kRot)

I<Parameter types>

=over

=item $kRot : Matrix3 *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->FromAngleAxis($rfAngle, $rkAxis)

I<Parameter types>

=over

=item $rfAngle : Degree (or Radian) *

=item $rkAxis : Vector3 *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->ToAngleAxis($rfAngle, $rkAxis)

I<Parameter types>

=over

=item $rfAngle : Degree (or Radian) *

=item $rkAxis : Vector3 *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->FromAxes($xAxis, $yAxis, $zAxis)

I<Parameter types>

=over

=item $xAxis : Vector3 *

=item $yAxis : Vector3 *

=item $zAxis : Vector3 *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->ToAxes($xAxis, $yAxis, $zAxis)

I<Parameter types>

=over

=item $xAxis : Vector3 *

=item $yAxis : Vector3 *

=item $zAxis : Vector3 *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->xAxis()

I<Returns>

=over

=item Vector3 *

=back

=head2 $obj->yAxis()

I<Returns>

=over

=item Vector3 *

=back

=head2 $obj->zAxis()

I<Returns>

=over

=item Vector3 *

=back

=head2 $obj->Dot($rkQ)

I<Parameter types>

=over

=item $rkQ : Quaternion *

=back

I<Returns>

=over

=item Real

=back

=head2 $obj->Norm()

I<Returns>

=over

=item Real

=back

=head2 $obj->normalise()

I<Returns>

=over

=item Real

=back

=head2 $obj->getRoll($bool reprojectAxis=true)

I<Parameter types>

=over

=item $bool reprojectAxis=true : (no info available)

=back

I<Returns>

=over

=item Radian *

=back

=head2 $obj->getPitch($bool reprojectAxis=true)

I<Parameter types>

=over

=item $bool reprojectAxis=true : (no info available)

=back

I<Returns>

=over

=item Radian *

=back

=head2 $obj->getYaw($bool reprojectAxis=true)

I<Parameter types>

=over

=item $bool reprojectAxis=true : (no info available)

=back

I<Returns>

=over

=item Radian *

=back

=head2 $obj->equals($rhs, $tolerance)

I<Parameter types>

=over

=item $rhs : Quaternion *

=item $tolerance : Degree (or Radian) *

=back

I<Returns>

=over

=item bool

=back

=head2 $obj->w()

I<Returns>

=over

=item Real

=back

=head2 $obj->x()

I<Returns>

=over

=item Real

=back

=head2 $obj->y()

I<Returns>

=over

=item Real

=back

=head2 $obj->z()

I<Returns>

=over

=item Real

=back

=head2 $obj->setW($w)

I<Parameter types>

=over

=item $w : Real

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setX($x)

I<Parameter types>

=over

=item $x : Real

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setY($y)

I<Parameter types>

=over

=item $y : Real

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setZ($z)

I<Parameter types>

=over

=item $z : Real

=back

I<Returns>

=over

=item void

=back

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

For licensing information, see README.txt .

=cut
