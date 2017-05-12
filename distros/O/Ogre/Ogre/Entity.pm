package Ogre::Entity;

use strict;
use warnings;

use Ogre::MovableObject;
our @ISA = qw(Ogre::MovableObject);   # Ogre::Resource::Listener


########## GENERATED CONSTANTS BEGIN
require Exporter;
unshift @Ogre::Entity::ISA, 'Exporter';

our %EXPORT_TAGS = (
	'VertexDataBindChoice' => [qw(
		BIND_ORIGINAL
		BIND_SOFTWARE_SKELETAL
		BIND_SOFTWARE_MORPH
		BIND_HARDWARE_MORPH
	)],
);

$EXPORT_TAGS{'all'} = [ map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS ];
our @EXPORT_OK = @{ $EXPORT_TAGS{'all'} };
our @EXPORT = ();
########## GENERATED CONSTANTS END

1;

__END__
=head1 NAME

Ogre::Entity

=head1 SYNOPSIS

  use Ogre;
  use Ogre::Entity;
  # (for now see examples/README.txt)

=head1 DESCRIPTION

See the online API documentation at
 L<http://www.ogre3d.org/docs/api/html/classOgre_1_1Entity.html>

B<Note:> this Perl binding is currently I<experimental> and subject to API changes.

=head1 INSTANCE METHODS

=head2 $obj->getMesh()

I<Returns>

=over

=item const Mesh *

=back

=head2 $obj->getSubEntity(...)

I<Parameter types>

=over

=item ... : this varies... (sorry, look in the .xs file)

=back

I<Returns>

=over

=item SubEntity *

=back

=head2 $obj->getNumSubEntities()

I<Returns>

=over

=item unsigned int

=back

=head2 $obj->clone($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item Entity *

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

=head2 $obj->setRenderQueueGroup($uint8 queueID)

I<Parameter types>

=over

=item $uint8 queueID : (no info available)

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

=head2 $obj->getAnimationState($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item AnimationState *

=back

=head2 $obj->getAllAnimationStates()

I<Returns>

=over

=item AnimationStateSet *

=back

=head2 $obj->setDisplaySkeleton($display)

I<Parameter types>

=over

=item $display : bool

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getDisplaySkeleton()

I<Returns>

=over

=item bool

=back

=head2 $obj->getManualLodLevel($index)

I<Parameter types>

=over

=item $index : size_t

=back

I<Returns>

=over

=item Entity *

=back

=head2 $obj->getNumManualLodLevels()

I<Returns>

=over

=item size_t

=back

=head2 $obj->setMeshLodBias($factor, $maxDetailIndex=0, $minDetailIndex=99)

I<Parameter types>

=over

=item $factor : Real

=item $maxDetailIndex=0 : unsigned short

=item $minDetailIndex=99 : unsigned short

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setMaterialLodBias($factor, $maxDetailIndex=0, $minDetailIndex=99)

I<Parameter types>

=over

=item $factor : Real

=item $maxDetailIndex=0 : unsigned short

=item $minDetailIndex=99 : unsigned short

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setPolygonModeOverrideable($PolygonModeOverrideable)

I<Parameter types>

=over

=item $PolygonModeOverrideable : bool

=back

I<Returns>

=over

=item void

=back

=head2 $obj->attachObjectToBone($boneName, $pMovable, $offsetOrientation=&Quaternion::IDENTITY, $offsetPosition=&Vector3::ZERO)

I<Parameter types>

=over

=item $boneName : String

=item $pMovable : MovableObject *

=item $offsetOrientation=&Quaternion::IDENTITY : const Quaternion *

=item $offsetPosition=&Vector3::ZERO : const Vector3 *

=back

I<Returns>

=over

=item TagPoint *

=back

=head2 $obj->detachObjectFromBone(...)

I<Parameter types>

=over

=item ... : this varies... (sorry, look in the .xs file)

=back

I<Returns>

=over

=item MovableObject *

=back

=head2 $obj->detachAllObjectsFromBone()

I<Returns>

=over

=item void

=back

=head2 $obj->getBoundingRadius()

I<Returns>

=over

=item Real

=back

=head2 $obj->setNormaliseNormals($bool normalise)

I<Parameter types>

=over

=item $bool normalise : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getNormaliseNormals()

I<Returns>

=over

=item bool

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

=head2 $obj->hasSkeleton()

I<Returns>

=over

=item bool

=back

=head2 $obj->getSkeleton()

I<Returns>

=over

=item SkeletonInstance *

=back

=head2 $obj->isHardwareAnimationEnabled()

I<Returns>

=over

=item bool

=back

=head2 $obj->getSoftwareAnimationRequests()

I<Returns>

=over

=item int

=back

=head2 $obj->getSoftwareAnimationNormalsRequests()

I<Returns>

=over

=item int

=back

=head2 $obj->addSoftwareAnimationRequest($bool normalsAlso)

I<Parameter types>

=over

=item $bool normalsAlso : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->removeSoftwareAnimationRequest($bool normalsAlso)

I<Parameter types>

=over

=item $bool normalsAlso : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->shareSkeletonInstanceWith($entity)

I<Parameter types>

=over

=item $entity : Entity *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->hasVertexAnimation()

I<Returns>

=over

=item bool

=back

=head2 $obj->stopSharingSkeletonInstance()

I<Returns>

=over

=item void

=back

=head2 $obj->sharesSkeletonInstance()

I<Returns>

=over

=item bool

=back

=head2 $obj->refreshAvailableAnimationState()

I<Returns>

=over

=item void

=back

=head2 $obj->getTypeFlags()

I<Returns>

=over

=item uint32

=back

=head2 $obj->getVertexDataForBinding()

I<Returns>

=over

=item VertexData *

=back

=head2 $obj->chooseVertexDataForBinding($bool hasVertexAnim)

I<Parameter types>

=over

=item $bool hasVertexAnim : (no info available)

=back

I<Returns>

=over

=item int

=back

=head2 $obj->isInitialised()

I<Returns>

=over

=item bool

=back

=head2 $obj->backgroundLoadingComplete($res)

I<Parameter types>

=over

=item $res : Resource *

=back

I<Returns>

=over

=item void

=back

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

For licensing information, see README.txt .

=cut
