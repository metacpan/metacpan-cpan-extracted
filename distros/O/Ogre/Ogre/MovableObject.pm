package Ogre::MovableObject;

use strict;
use warnings;

use Ogre::ShadowCaster;
use Ogre::AnimableObject;
our @ISA = qw(Ogre::ShadowCaster Ogre::AnimableObject);



1;

__END__
=head1 NAME

Ogre::MovableObject

=head1 SYNOPSIS

  use Ogre;
  use Ogre::MovableObject;
  # (for now see examples/README.txt)

=head1 DESCRIPTION

See the online API documentation at
 L<http://www.ogre3d.org/docs/api/html/classOgre_1_1MovableObject.html>

B<Note:> this Perl binding is currently I<experimental> and subject to API changes.

=head1 INSTANCE METHODS

=head2 $obj->getName()

I<Returns>

=over

=item String

=back

=head2 $obj->getMovableType()

I<Returns>

=over

=item String

=back

=head2 $obj->getParentNode()

I<Returns>

=over

=item Node *

=back

=head2 $obj->getParentSceneNode()

I<Returns>

=over

=item SceneNode *

=back

=head2 $obj->isAttached()

I<Returns>

=over

=item bool

=back

=head2 $obj->isInScene()

I<Returns>

=over

=item bool

=back

=head2 $obj->getBoundingRadius()

I<Returns>

=over

=item Real

=back

=head2 $obj->setVisible($bool visible)

I<Parameter types>

=over

=item $bool visible : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getVisible()

I<Returns>

=over

=item bool

=back

=head2 $obj->isVisible()

I<Returns>

=over

=item bool

=back

=head2 $obj->setRenderingDistance($Real dist)

I<Parameter types>

=over

=item $Real dist : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getRenderingDistance()

I<Returns>

=over

=item Real

=back

=head2 $obj->setRenderQueueGroup($uint8 queueID)

I<Parameter types>

=over

=item $uint8 queueID : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getRenderQueueGroup()

I<Returns>

=over

=item uint8

=back

=head2 $obj->setQueryFlags($uint32 flags)

I<Parameter types>

=over

=item $uint32 flags : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->addQueryFlags($uint32 flags)

I<Parameter types>

=over

=item $uint32 flags : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->removeQueryFlags($unsigned long flags)

I<Parameter types>

=over

=item $unsigned long flags : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getQueryFlags()

I<Returns>

=over

=item uint32

=back

=head2 $obj->setVisibilityFlags($uint32 flags)

I<Parameter types>

=over

=item $uint32 flags : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->addVisibilityFlags($uint32 flags)

I<Parameter types>

=over

=item $uint32 flags : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->removeVisibilityFlags($uint32 flags)

I<Parameter types>

=over

=item $uint32 flags : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getVisibilityFlags()

I<Returns>

=over

=item uint32

=back

=head2 $obj->getEdgeList()

I<Returns>

=over

=item EdgeData *

=back

=head2 $obj->hasEdgeList()

I<Returns>

=over

=item bool

=back

=head2 $obj->setCastShadows($bool enabled)

I<Parameter types>

=over

=item $bool enabled : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getCastShadows()

I<Returns>

=over

=item bool

=back

=head2 $obj->getPointExtrusionDistance($const Light *l)

I<Parameter types>

=over

=item $const Light *l : (no info available)

=back

I<Returns>

=over

=item Real

=back

=head2 $obj->getTypeFlags()

I<Returns>

=over

=item uint32

=back

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

For licensing information, see README.txt .

=cut
