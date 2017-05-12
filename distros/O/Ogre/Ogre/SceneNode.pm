package Ogre::SceneNode;

use strict;
use warnings;

use Ogre::Node;
our @ISA = qw(Ogre::Node);


1;

__END__
=head1 NAME

Ogre::SceneNode

=head1 SYNOPSIS

  use Ogre;
  use Ogre::SceneNode;
  # (for now see examples/README.txt)

=head1 DESCRIPTION

See the online API documentation at
 L<http://www.ogre3d.org/docs/api/html/classOgre_1_1SceneNode.html>

B<Note:> this Perl binding is currently I<experimental> and subject to API changes.

=head1 INSTANCE METHODS

=head2 $obj->createChildSceneNode(...)

I<Parameter types>

=over

=item ... : this varies... (sorry, look in the .xs file)

=back

I<Returns>

=over

=item SceneNode *

=back

=head2 $obj->attachObject($obj)

I<Parameter types>

=over

=item $obj : MovableObject *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->detachObject($obj)

I<Parameter types>

=over

=item $obj : MovableObject *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getParentSceneNode()

I<Returns>

=over

=item SceneNode *

=back

=head2 $obj->numAttachedObjects()

I<Returns>

=over

=item unsigned short

=back

=head2 $obj->detachAllObjects()

I<Returns>

=over

=item void

=back

=head2 $obj->removeAndDestroyAllChildren()

I<Returns>

=over

=item void

=back

=head2 $obj->isInSceneGraph()

I<Returns>

=over

=item bool

=back

=head2 $obj->getCreator()

I<Returns>

=over

=item SceneManager *

=back

=head2 $obj->showBoundingBox($bShow)

I<Parameter types>

=over

=item $bShow : bool

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getShowBoundingBox()

I<Returns>

=over

=item bool

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

=head2 $obj->setDirection($x, $y, $z, $relativeTo, $localDirectionVector)

I<Parameter types>

=over

=item $x : Real

=item $y : Real

=item $z : Real

=item $relativeTo : int

=item $localDirectionVector : Vector3 *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->lookAt($targetPoint, $relativeTo, $localDirectionVector)

I<Parameter types>

=over

=item $targetPoint : Vector3 *

=item $relativeTo : int

=item $localDirectionVector : Vector3 *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setAutoTracking($enabled, $target, $localDirectionVector, $offset)

I<Parameter types>

=over

=item $enabled : bool

=item $target : SceneNode *

=item $localDirectionVector : Vector3 *

=item $offset : Vector3 *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getAutoTrackTarget()

I<Returns>

=over

=item SceneNode *

=back

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

For licensing information, see README.txt .

=cut
