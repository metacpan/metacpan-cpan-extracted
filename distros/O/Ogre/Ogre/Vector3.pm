package Ogre::Vector3;

use strict;
use warnings;

# xxx: this should be in XS, but I can't get it to work
use overload
  '==' => \&vec3_eq_xs,
  '!=' => \&vec3_ne_xs,
  '<' => \&vec3_lt_xs,
  '>' => \&vec3_gt_xs,
  '+' => \&vec3_plus_xs,
  '-' => \&vec3_minus_xs,
  '*' => \&vec3_mult_xs,
  '/' => \&vec3_div_xs,
  '0+' => sub { $_[0] },
  'neg' => \&vec3_neg_xs,
  ;


1;

__END__
=head1 NAME

Ogre::Vector3

=head1 SYNOPSIS

  use Ogre;
  use Ogre::Vector3;
  # (for now see examples/README.txt)

=head1 DESCRIPTION

See the online API documentation at
 L<http://www.ogre3d.org/docs/api/html/classOgre_1_1Vector3.html>

B<Note:> this Perl binding is currently I<experimental> and subject to API changes.

=head1 CLASS METHODS

=head2 Ogre::Vector3->new(...)

I<Parameter types>

=over

=item ... : this varies... (sorry, look in the .xs file)

=back

I<Returns>

=over

=item Vector3 *

=back

=head2 Ogre::Vector3->DESTROY()

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

=head2 $obj->length()

I<Returns>

=over

=item Real

=back

=head2 $obj->squaredLength()

I<Returns>

=over

=item Real

=back

=head2 $obj->distance($rhs)

I<Parameter types>

=over

=item $rhs : Vector3 *

=back

I<Returns>

=over

=item Real

=back

=head2 $obj->squaredDistance($rhs)

I<Parameter types>

=over

=item $rhs : Vector3 *

=back

I<Returns>

=over

=item Real

=back

=head2 $obj->dotProduct($vec)

I<Parameter types>

=over

=item $vec : Vector3 *

=back

I<Returns>

=over

=item Real

=back

=head2 $obj->absDotProduct($vec)

I<Parameter types>

=over

=item $vec : Vector3 *

=back

I<Returns>

=over

=item Real

=back

=head2 $obj->normalise()

I<Returns>

=over

=item Real

=back

=head2 $obj->crossProduct($rkVector)

I<Parameter types>

=over

=item $rkVector : const Vector3 *

=back

I<Returns>

=over

=item Vector3 *

=back

=head2 $obj->midPoint($rkVector)

I<Parameter types>

=over

=item $rkVector : const Vector3 *

=back

I<Returns>

=over

=item Vector3 *

=back

=head2 $obj->makeFloor($cmp)

I<Parameter types>

=over

=item $cmp : Vector3 *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->makeCeil($cmp)

I<Parameter types>

=over

=item $cmp : Vector3 *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->perpendicular()

I<Returns>

=over

=item Vector3 *

=back

=head2 $obj->randomDeviant($angle, $up=&Vector3::ZERO)

I<Parameter types>

=over

=item $angle : Degree (or Radian) *

=item $up=&Vector3::ZERO : const Vector3 *

=back

I<Returns>

=over

=item Vector3 *

=back

=head2 $obj->getRotationTo($dest, $fallbackAxis=&Vector3::ZERO)

I<Parameter types>

=over

=item $dest : const Vector3 *

=item $fallbackAxis=&Vector3::ZERO : const Vector3 *

=back

I<Returns>

=over

=item Quaternion *

=back

=head2 $obj->isZeroLength()

I<Returns>

=over

=item bool

=back

=head2 $obj->normalisedCopy()

I<Returns>

=over

=item Vector3 *

=back

=head2 $obj->reflect($normal)

I<Parameter types>

=over

=item $normal : const Vector3 *

=back

I<Returns>

=over

=item Vector3 *

=back

=head2 $obj->positionEquals($rhs, $tolerance=0.001)

I<Parameter types>

=over

=item $rhs : Vector3 *

=item $tolerance=0.001 : Real

=back

I<Returns>

=over

=item bool

=back

=head2 $obj->positionCloses($rhs, $tolerance=0.001)

I<Parameter types>

=over

=item $rhs : Vector3 *

=item $tolerance=0.001 : Real

=back

I<Returns>

=over

=item bool

=back

=head2 $obj->directionEquals($rhs, $tolerance)

I<Parameter types>

=over

=item $rhs : Vector3 *

=item $tolerance : Degree (or Radian) *

=back

I<Returns>

=over

=item bool

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
