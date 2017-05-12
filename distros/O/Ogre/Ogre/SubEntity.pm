package Ogre::SubEntity;

use strict;
use warnings;

use Ogre::Renderable;
our @ISA = qw(Ogre::Renderable);


1;

__END__
=head1 NAME

Ogre::SubEntity

=head1 SYNOPSIS

  use Ogre;
  use Ogre::SubEntity;
  # (for now see examples/README.txt)

=head1 DESCRIPTION

See the online API documentation at
 L<http://www.ogre3d.org/docs/api/html/classOgre_1_1SubEntity.html>

B<Note:> this Perl binding is currently I<experimental> and subject to API changes.

=head1 INSTANCE METHODS

=head2 $obj->getMaterialName()

I<Returns>

=over

=item String

=back

=head2 $obj->setMaterialName($String name)

I<Parameter types>

=over

=item $String name : (no info available)

=back

I<Returns>

=over

=item void

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

=head2 $obj->isVisible()

I<Returns>

=over

=item bool

=back

=head2 $obj->getSubMesh()

I<Returns>

=over

=item SubMesh *

=back

=head2 $obj->getParent()

I<Returns>

=over

=item Entity *

=back

=head2 $obj->getMaterial()

I<Returns>

=over

=item const Material *

=back

=head2 $obj->getTechnique()

I<Returns>

=over

=item Technique *

=back

=head2 $obj->getRenderOperation($OUTLIST RenderOperation *op)

I<Parameter types>

=over

=item $OUTLIST RenderOperation *op : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getWorldOrientation()

I<Returns>

=over

=item Quaternion *

=back

=head2 $obj->getWorldPosition()

I<Returns>

=over

=item Vector3 *

=back

=head2 $obj->getNormaliseNormals()

I<Returns>

=over

=item bool

=back

=head2 $obj->getNumWorldTransforms()

I<Returns>

=over

=item unsigned short

=back

=head2 $obj->getSquaredViewDepth($const Camera *cam)

I<Parameter types>

=over

=item $const Camera *cam : (no info available)

=back

I<Returns>

=over

=item Real

=back

=head2 $obj->getCastsShadows()

I<Returns>

=over

=item bool

=back

=head2 $obj->getVertexDataForBinding()

I<Returns>

=over

=item VertexData *

=back

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

For licensing information, see README.txt .

=cut
