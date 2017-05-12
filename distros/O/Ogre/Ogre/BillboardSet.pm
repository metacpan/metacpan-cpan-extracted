package Ogre::BillboardSet;

use strict;
use warnings;

use Ogre::MovableObject;
use Ogre::Renderable;
our @ISA = qw(Ogre::MovableObject Ogre::Renderable);


1;

__END__
=head1 NAME

Ogre::BillboardSet

=head1 SYNOPSIS

  use Ogre;
  use Ogre::BillboardSet;
  # (for now see examples/README.txt)

=head1 DESCRIPTION

See the online API documentation at
 L<http://www.ogre3d.org/docs/api/html/classOgre_1_1BillboardSet.html>

B<Note:> this Perl binding is currently I<experimental> and subject to API changes.

=head1 CLASS METHODS

=head2 Ogre::BillboardSet->new($name, $poolSize=20, $externalDataSource=false)

I<Parameter types>

=over

=item $name : String

=item $poolSize=20 : unsigned int

=item $externalDataSource=false : bool

=back

I<Returns>

=over

=item BillboardSet *

=back

=head2 Ogre::BillboardSet->DESTROY()

This method is called automatically; don't call it yourself.

=head1 INSTANCE METHODS

=head2 $obj->createBillboard($x, $y, $z, $colour=&ColourValue::White)

I<Parameter types>

=over

=item $x : Real

=item $y : Real

=item $z : Real

=item $colour=&ColourValue::White : const ColourValue *

=back

I<Returns>

=over

=item Billboard *

=back

=head2 $obj->getNumBillboards()

I<Returns>

=over

=item int

=back

=head2 $obj->setAutoextend($bool autoextend)

I<Parameter types>

=over

=item $bool autoextend : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getAutoextend()

I<Returns>

=over

=item bool

=back

=head2 $obj->setSortingEnabled($bool sortenable)

I<Parameter types>

=over

=item $bool sortenable : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getSortingEnabled()

I<Returns>

=over

=item bool

=back

=head2 $obj->setPoolSize($size_t size)

I<Parameter types>

=over

=item $size_t size : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getPoolSize()

I<Returns>

=over

=item unsigned int

=back

=head2 $obj->clear()

I<Returns>

=over

=item void

=back

=head2 $obj->getBillboard($unsigned int index)

I<Parameter types>

=over

=item $unsigned int index : (no info available)

=back

I<Returns>

=over

=item Billboard *

=back

=head2 $obj->removeBillboard($unsigned int index)

I<Parameter types>

=over

=item $unsigned int index : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setBillboardOrigin($int origin)

I<Parameter types>

=over

=item $int origin : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getBillboardOrigin()

I<Returns>

=over

=item int

=back

=head2 $obj->setBillboardRotationType($int rotationType)

I<Parameter types>

=over

=item $int rotationType : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getBillboardRotationType()

I<Returns>

=over

=item int

=back

=head2 $obj->setDefaultDimensions($Real width, $Real height)

I<Parameter types>

=over

=item $Real width : (no info available)

=item $Real height : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setDefaultWidth($Real width)

I<Parameter types>

=over

=item $Real width : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getDefaultWidth()

I<Returns>

=over

=item Real

=back

=head2 $obj->setDefaultHeight($Real height)

I<Parameter types>

=over

=item $Real height : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getDefaultHeight()

I<Returns>

=over

=item Real

=back

=head2 $obj->setMaterialName($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getMaterialName()

I<Returns>

=over

=item String

=back

=head2 $obj->beginBillboards($size_t numBillboards=0)

I<Parameter types>

=over

=item $size_t numBillboards=0 : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->injectBillboard($bb)

I<Parameter types>

=over

=item $bb : const Billboard *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->endBillboards()

I<Returns>

=over

=item void

=back

=head2 $obj->setBounds($box, $radius)

I<Parameter types>

=over

=item $box : const AxisAlignedBox *

=item $radius : Real

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getBoundingRadius()

I<Returns>

=over

=item Real

=back

=head2 $obj->getCullIndividually()

I<Returns>

=over

=item bool

=back

=head2 $obj->setCullIndividually($bool cullIndividual)

I<Parameter types>

=over

=item $bool cullIndividual : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setBillboardType($int bbt)

I<Parameter types>

=over

=item $int bbt : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getBillboardType()

I<Returns>

=over

=item int

=back

=head2 $obj->setCommonDirection($vec)

I<Parameter types>

=over

=item $vec : const Vector3 *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setCommonUpVector($vec)

I<Parameter types>

=over

=item $vec : const Vector3 *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setUseAccurateFacing($bool acc)

I<Parameter types>

=over

=item $bool acc : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getUseAccurateFacing()

I<Returns>

=over

=item bool

=back

=head2 $obj->getMovableType()

I<Returns>

=over

=item String

=back

=head2 $obj->getSquaredViewDepth($cam)

I<Parameter types>

=over

=item $cam : const Camera *

=back

I<Returns>

=over

=item Real

=back

=head2 $obj->setBillboardsInWorldSpace($bool ws)

I<Parameter types>

=over

=item $bool ws : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setTextureStacksAndSlices($uchar stacks, $uchar slices)

I<Parameter types>

=over

=item $uchar stacks : (no info available)

=item $uchar slices : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setPointRenderingEnabled($bool enabled)

I<Parameter types>

=over

=item $bool enabled : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->isPointRenderingEnabled()

I<Returns>

=over

=item bool

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
