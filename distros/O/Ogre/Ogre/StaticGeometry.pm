package Ogre::StaticGeometry;

use strict;
use warnings;


1;

__END__
=head1 NAME

Ogre::StaticGeometry

=head1 SYNOPSIS

  use Ogre;
  use Ogre::StaticGeometry;
  # (for now see examples/README.txt)

=head1 DESCRIPTION

See the online API documentation at
 L<http://www.ogre3d.org/docs/api/html/classOgre_1_1StaticGeometry.html>

B<Note:> this Perl binding is currently I<experimental> and subject to API changes.

=head1 INSTANCE METHODS

=head2 $obj->getName()

I<Returns>

=over

=item String

=back

=head2 $obj->addEntity($ent, $position, $orientation, $scale)

I<Parameter types>

=over

=item $ent : Entity *

=item $position : Vector3 *

=item $orientation : Quaternion *

=item $scale : Vector3 *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->addSceneNode($node)

I<Parameter types>

=over

=item $node : SceneNode *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->build()

I<Returns>

=over

=item void

=back

=head2 $obj->destroy()

I<Returns>

=over

=item void

=back

=head2 $obj->reset()

I<Returns>

=over

=item void

=back

=head2 $obj->setRenderingDistance($dist)

I<Parameter types>

=over

=item $dist : Real

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

=head2 $obj->getSquaredRenderingDistance()

I<Returns>

=over

=item Real

=back

=head2 $obj->setVisible($visible)

I<Parameter types>

=over

=item $visible : bool

=back

I<Returns>

=over

=item void

=back

=head2 $obj->isVisible()

I<Returns>

=over

=item bool

=back

=head2 $obj->setCastShadows($castShadows)

I<Parameter types>

=over

=item $castShadows : bool

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

=head2 $obj->setRegionDimensions($size)

I<Parameter types>

=over

=item $size : Vector3 *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setOrigin($origin)

I<Parameter types>

=over

=item $origin : Vector3 *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setRenderQueueGroup($queueID)

I<Parameter types>

=over

=item $queueID : uint8

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

=head2 $obj->dump($filename)

I<Parameter types>

=over

=item $filename : String

=back

I<Returns>

=over

=item void

=back

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

For licensing information, see README.txt .

=cut
