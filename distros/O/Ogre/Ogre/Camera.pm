package Ogre::Camera;

use strict;
use warnings;

use Ogre::Frustum;
our @ISA = qw(Ogre::Frustum);


1;

__END__
=head1 NAME

Ogre::Camera

=head1 SYNOPSIS

  use Ogre;
  use Ogre::Camera;
  # (for now see examples/README.txt)

=head1 DESCRIPTION

See the online API documentation at
 L<http://www.ogre3d.org/docs/api/html/classOgre_1_1Camera.html>

B<Note:> this Perl binding is currently I<experimental> and subject to API changes.

=head1 INSTANCE METHODS

=head2 $obj->getSceneManager()

I<Returns>

=over

=item SceneManager *

=back

=head2 $obj->getName()

I<Returns>

=over

=item String

=back

=head2 $obj->setPolygonMode($sd)

I<Parameter types>

=over

=item $sd : int

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getPolygonMode()

I<Returns>

=over

=item int

=back

=head2 $obj->setPosition(...)

I<Parameter types>

=over

=item ... : this varies... (sorry, look in the .xs file)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getPosition()

I<Returns>

=over

=item Vector3 *

=back

=head2 $obj->move($vec)

I<Parameter types>

=over

=item $vec : Vector3 *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->moveRelative($vec)

I<Parameter types>

=over

=item $vec : Vector3 *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setDirection(...)

I<Parameter types>

=over

=item ... : this varies... (sorry, look in the .xs file)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->lookAt(...)

I<Parameter types>

=over

=item ... : this varies... (sorry, look in the .xs file)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->roll($angle)

I<Parameter types>

=over

=item $angle : Degree (or Radian) *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->yaw($angle)

I<Parameter types>

=over

=item $angle : Degree (or Radian) *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->pitch($angle)

I<Parameter types>

=over

=item $angle : Degree (or Radian) *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->rotate($q)

I<Parameter types>

=over

=item $q : Quaternion *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setFixedYawAxis($useFixed, $fixedAxis)

I<Parameter types>

=over

=item $useFixed : bool

=item $fixedAxis : Vector3 *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setOrientation($q)

I<Parameter types>

=over

=item $q : Quaternion *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getMovableType()

I<Returns>

=over

=item String

=back

=head2 $obj->setAutoTracking($enabled, $target=0, $offset=&Vector3::ZERO)

I<Parameter types>

=over

=item $enabled : bool

=item $target=0 : SceneNode *

=item $offset=&Vector3::ZERO : const Vector3 *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setLodBias($Real factor=1.0)

I<Parameter types>

=over

=item $Real factor=1.0 : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getLodBias()

I<Returns>

=over

=item Real

=back

=head2 $obj->setWindow($Real Left, $Real Top, $Real Right, $Real Bottom)

I<Parameter types>

=over

=item $Real Left : (no info available)

=item $Real Top : (no info available)

=item $Real Right : (no info available)

=item $Real Bottom : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->resetWindow()

I<Returns>

=over

=item void

=back

=head2 $obj->isWindowSet()

I<Returns>

=over

=item bool

=back

=head2 $obj->getBoundingRadius()

I<Returns>

=over

=item Real

=back

=head2 $obj->getAutoTrackTarget()

I<Returns>

=over

=item SceneNode *

=back

=head2 $obj->getViewport()

I<Returns>

=over

=item Viewport *

=back

=head2 $obj->setAutoAspectRatio($bool autoratio)

I<Parameter types>

=over

=item $bool autoratio : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getAutoAspectRatio()

I<Returns>

=over

=item bool

=back

=head2 $obj->setCullingFrustum($frustum)

I<Parameter types>

=over

=item $frustum : Frustum *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getCullingFrustum()

I<Returns>

=over

=item Frustum *

=back

=head2 $obj->getNearClipDistance()

I<Returns>

=over

=item Real

=back

=head2 $obj->getFarClipDistance()

I<Returns>

=over

=item Real

=back

=head2 $obj->setUseRenderingDistance($bool use)

I<Parameter types>

=over

=item $bool use : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getUseRenderingDistance()

I<Returns>

=over

=item bool

=back

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

For licensing information, see README.txt .

=cut
