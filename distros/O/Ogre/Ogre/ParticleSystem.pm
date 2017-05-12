package Ogre::ParticleSystem;

use strict;
use warnings;

use Ogre::StringInterface;
use Ogre::MovableObject;
our @ISA = qw(Ogre::StringInterface Ogre::MovableObject);


1;

__END__
=head1 NAME

Ogre::ParticleSystem

=head1 SYNOPSIS

  use Ogre;
  use Ogre::ParticleSystem;
  # (for now see examples/README.txt)

=head1 DESCRIPTION

See the online API documentation at
 L<http://www.ogre3d.org/docs/api/html/classOgre_1_1ParticleSystem.html>

B<Note:> this Perl binding is currently I<experimental> and subject to API changes.

=head1 CLASS METHODS

=head2 Ogre::ParticleSystem->setDefaultIterationInterval($Real iterationInterval)

I<Parameter types>

=over

=item $Real iterationInterval : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 Ogre::ParticleSystem->getDefaultIterationInterval()

I<Returns>

=over

=item Real

=back

=head2 Ogre::ParticleSystem->setDefaultNonVisibleUpdateTimeout($Real timeout)

I<Parameter types>

=over

=item $Real timeout : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 Ogre::ParticleSystem->getDefaultNonVisibleUpdateTimeout()

I<Returns>

=over

=item Real

=back

=head2 Ogre::ParticleSystem->cleanupDictionary()

I<Returns>

=over

=item void

=back

=head2 Ogre::ParticleSystem->setDefaultQueryFlags($uint32 flags)

I<Parameter types>

=over

=item $uint32 flags : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 Ogre::ParticleSystem->getDefaultQueryFlags()

I<Returns>

=over

=item uint32

=back

=head2 Ogre::ParticleSystem->setDefaultVisibilityFlags($uint32 flags)

I<Parameter types>

=over

=item $uint32 flags : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 Ogre::ParticleSystem->getDefaultVisibilityFlags()

I<Returns>

=over

=item uint32

=back

=head2 Ogre::ParticleSystem->extrudeVertices($vertexBuffer, $originalVertexCount, $lightPos, $extrudeDist)

I<Parameter types>

=over

=item $vertexBuffer : HardwareVertexBuffer *

=item $originalVertexCount : size_t

=item $lightPos : const Vector4 *

=item $extrudeDist : Real

=back

I<Returns>

=over

=item void

=back

=head1 INSTANCE METHODS

=head2 $obj->setRenderer($typeName)

I<Parameter types>

=over

=item $typeName : String

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getRenderer()

I<Returns>

=over

=item ParticleSystemRenderer *

=back

=head2 $obj->getRendererName()

I<Returns>

=over

=item String

=back

=head2 $obj->addEmitter($emitterType)

I<Parameter types>

=over

=item $emitterType : String

=back

I<Returns>

=over

=item ParticleEmitter *

=back

=head2 $obj->getEmitter($unsigned short index)

I<Parameter types>

=over

=item $unsigned short index : (no info available)

=back

I<Returns>

=over

=item ParticleEmitter *

=back

=head2 $obj->getNumEmitters()

I<Returns>

=over

=item unsigned short

=back

=head2 $obj->removeEmitter($unsigned short index)

I<Parameter types>

=over

=item $unsigned short index : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->removeAllEmitters()

I<Returns>

=over

=item void

=back

=head2 $obj->addAffector($affectorType)

I<Parameter types>

=over

=item $affectorType : String

=back

I<Returns>

=over

=item ParticleAffector *

=back

=head2 $obj->getAffector($unsigned short index)

I<Parameter types>

=over

=item $unsigned short index : (no info available)

=back

I<Returns>

=over

=item ParticleAffector *

=back

=head2 $obj->getNumAffectors()

I<Returns>

=over

=item unsigned short

=back

=head2 $obj->removeAffector($unsigned short index)

I<Parameter types>

=over

=item $unsigned short index : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->removeAllAffectors()

I<Returns>

=over

=item void

=back

=head2 $obj->clear()

I<Returns>

=over

=item void

=back

=head2 $obj->getNumParticles()

I<Returns>

=over

=item size_t

=back

=head2 $obj->createParticle()

I<Returns>

=over

=item Particle *

=back

=head2 $obj->createEmitterParticle($emitterName)

I<Parameter types>

=over

=item $emitterName : String

=back

I<Returns>

=over

=item Particle *

=back

=head2 $obj->getParticle($size_t index)

I<Parameter types>

=over

=item $size_t index : (no info available)

=back

I<Returns>

=over

=item Particle *

=back

=head2 $obj->getParticleQuota()

I<Returns>

=over

=item size_t

=back

=head2 $obj->setParticleQuota($size_t quota)

I<Parameter types>

=over

=item $size_t quota : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getEmittedEmitterQuota()

I<Returns>

=over

=item size_t

=back

=head2 $obj->setEmittedEmitterQuota($size_t quota)

I<Parameter types>

=over

=item $size_t quota : (no info available)

=back

I<Returns>

=over

=item void

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

=head2 $obj->getBoundingRadius()

I<Returns>

=over

=item Real

=back

=head2 $obj->fastForward($Real time, $Real interval=0.1)

I<Parameter types>

=over

=item $Real time : (no info available)

=item $Real interval=0.1 : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setSpeedFactor($Real speedFactor)

I<Parameter types>

=over

=item $Real speedFactor : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getSpeedFactor()

I<Returns>

=over

=item Real

=back

=head2 $obj->setIterationInterval($Real iterationInterval)

I<Parameter types>

=over

=item $Real iterationInterval : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getIterationInterval()

I<Returns>

=over

=item Real

=back

=head2 $obj->setNonVisibleUpdateTimeout($Real timeout)

I<Parameter types>

=over

=item $Real timeout : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getNonVisibleUpdateTimeout()

I<Returns>

=over

=item Real

=back

=head2 $obj->getMovableType()

I<Returns>

=over

=item String

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

=head2 $obj->getResourceGroupName()

I<Returns>

=over

=item String

=back

=head2 $obj->getOrigin()

I<Returns>

=over

=item String

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

=head2 $obj->setSortingEnabled($bool enabled)

I<Parameter types>

=over

=item $bool enabled : (no info available)

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

=head2 $obj->setBounds($aabb)

I<Parameter types>

=over

=item $aabb : const AxisAlignedBox *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setBoundsAutoUpdated($bool autoUpdate, $Real stopIn=0.0f)

I<Parameter types>

=over

=item $bool autoUpdate : (no info available)

=item $Real stopIn=0.0f : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setKeepParticlesInLocalSpace($bool keepLocal)

I<Parameter types>

=over

=item $bool keepLocal : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getKeepParticlesInLocalSpace()

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
