package Ogre::SceneManager;

use strict;
use warnings;


########## GENERATED CONSTANTS BEGIN
require Exporter;
unshift @Ogre::SceneManager::ISA, 'Exporter';

our %EXPORT_TAGS = (
	'IlluminationRenderStage' => [qw(
		IRS_NONE
		IRS_RENDER_TO_TEXTURE
		IRS_RENDER_RECEIVER_PASS
	)],
	'SpecialCaseRenderQueueMode' => [qw(
		SCRQM_INCLUDE
		SCRQM_EXCLUDE
	)],
	'PrefabType' => [qw(
		PT_PLANE
		PT_CUBE
		PT_SPHERE
	)],
);

$EXPORT_TAGS{'all'} = [ map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS ];
our @EXPORT_OK = @{ $EXPORT_TAGS{'all'} };
our @EXPORT = ();
########## GENERATED CONSTANTS END

1;

__END__
=head1 NAME

Ogre::SceneManager

=head1 SYNOPSIS

  use Ogre;
  use Ogre::SceneManager;
  # (for now see examples/README.txt)

=head1 DESCRIPTION

See the online API documentation at
 L<http://www.ogre3d.org/docs/api/html/classOgre_1_1SceneManager.html>

B<Note:> this Perl binding is currently I<experimental> and subject to API changes.

=head1 INSTANCE METHODS

=head2 $obj->getName()

I<Returns>

=over

=item String

=back

=head2 $obj->getTypeName()

I<Returns>

=over

=item String

=back

=head2 $obj->createCamera($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item Camera *

=back

=head2 $obj->getCamera($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item Camera *

=back

=head2 $obj->hasCamera($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item bool

=back

=head2 $obj->destroyCamera($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item void

=back

=head2 $obj->destroyAllCameras()

I<Returns>

=over

=item void

=back

=head2 $obj->createLight($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item Light *

=back

=head2 $obj->getLight($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item Light *

=back

=head2 $obj->hasLight($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item bool

=back

=head2 $obj->destroyLight($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item void

=back

=head2 $obj->destroyAllLights()

I<Returns>

=over

=item void

=back

=head2 $obj->createSceneNode($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item SceneNode *

=back

=head2 $obj->destroySceneNode($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getRootSceneNode()

I<Returns>

=over

=item SceneNode *

=back

=head2 $obj->getSceneNode($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item SceneNode *

=back

=head2 $obj->hasSceneNode($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item bool

=back

=head2 $obj->createEntity($entityName, $meshName)

I<Parameter types>

=over

=item $entityName : String

=item $meshName : String

=back

I<Returns>

=over

=item Entity *

=back

=head2 $obj->getEntity($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item Entity *

=back

=head2 $obj->hasEntity($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item bool

=back

=head2 $obj->destroyEntity($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item void

=back

=head2 $obj->destroyAllEntities()

I<Returns>

=over

=item void

=back

=head2 $obj->createManualObject($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item ManualObject *

=back

=head2 $obj->getManualObject($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item ManualObject *

=back

=head2 $obj->hasManualObject($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item bool

=back

=head2 $obj->destroyManualObject($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item void

=back

=head2 $obj->destroyAllManualObjects()

I<Returns>

=over

=item void

=back

=head2 $obj->createBillboardChain($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item BillboardChain *

=back

=head2 $obj->getBillboardChain($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item BillboardChain *

=back

=head2 $obj->hasBillboardChain($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item bool

=back

=head2 $obj->destroyBillboardChain($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item void

=back

=head2 $obj->destroyAllBillboardChains()

I<Returns>

=over

=item void

=back

=head2 $obj->createRibbonTrail($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item RibbonTrail *

=back

=head2 $obj->getRibbonTrail($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item RibbonTrail *

=back

=head2 $obj->hasRibbonTrail($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item bool

=back

=head2 $obj->destroyRibbonTrail($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item void

=back

=head2 $obj->destroyAllRibbonTrails()

I<Returns>

=over

=item void

=back

=head2 $obj->createParticleSystem($name, $templateName)

I<Parameter types>

=over

=item $name : String

=item $templateName : String

=back

I<Returns>

=over

=item ParticleSystem *

=back

=head2 $obj->createAndAttachParticleSystem($name, $templateName, $node)

I<Parameter types>

=over

=item $name : String

=item $templateName : String

=item $node : SceneNode *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getParticleSystem($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item ParticleSystem *

=back

=head2 $obj->hasParticleSystem($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item bool

=back

=head2 $obj->destroyParticleSystem($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item void

=back

=head2 $obj->destroyAllParticleSystems()

I<Returns>

=over

=item void

=back

=head2 $obj->clearScene()

I<Returns>

=over

=item void

=back

=head2 $obj->setAmbientLight($colour)

I<Parameter types>

=over

=item $colour : ColourValue *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setWorldGeometry($filename)

I<Parameter types>

=over

=item $filename : String

=back

I<Returns>

=over

=item void

=back

=head2 $obj->estimateWorldGeometry($filename)

I<Parameter types>

=over

=item $filename : String

=back

I<Returns>

=over

=item size_t

=back

=head2 $obj->hasOption($strKey)

I<Parameter types>

=over

=item $strKey : String

=back

I<Returns>

=over

=item bool

=back

=head2 $obj->setSkyPlane($enable, $plane, $materialName, $scale=1000, $tiling=10, $drawFirst=true, $bow=0, $xsegments=1, $ysegments=1, $groupName=ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME)

I<Parameter types>

=over

=item $enable : bool

=item $plane : Plane *

=item $materialName : String

=item $scale=1000 : Real

=item $tiling=10 : Real

=item $drawFirst=true : bool

=item $bow=0 : Real

=item $xsegments=1 : int

=item $ysegments=1 : int

=item $groupName=ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME : String

=back

I<Returns>

=over

=item void

=back

=head2 $obj->isSkyPlaneEnabled()

I<Returns>

=over

=item bool

=back

=head2 $obj->getSkyPlaneNode()

I<Returns>

=over

=item SceneNode *

=back

=head2 $obj->setSkyBox($enable, $materialName, $distance=5000, $drawFirst=true, $orientation=&Quaternion::IDENTITY, $groupName=ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME)

I<Parameter types>

=over

=item $enable : bool

=item $materialName : String

=item $distance=5000 : Real

=item $drawFirst=true : bool

=item $orientation=&Quaternion::IDENTITY : const Quaternion *

=item $groupName=ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME : String

=back

I<Returns>

=over

=item void

=back

=head2 $obj->isSkyBoxEnabled()

I<Returns>

=over

=item bool

=back

=head2 $obj->getSkyBoxNode()

I<Returns>

=over

=item SceneNode *

=back

=head2 $obj->setSkyDome($enable, $materialName, $curvature=10, $tiling=8, $distance=4000, $drawFirst=true, $orientation=&Quaternion::IDENTITY, $xsegments=16, $ysegments=16, $ysegments_keep=-1, $groupName=ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME)

I<Parameter types>

=over

=item $enable : bool

=item $materialName : String

=item $curvature=10 : Real

=item $tiling=8 : Real

=item $distance=4000 : Real

=item $drawFirst=true : bool

=item $orientation=&Quaternion::IDENTITY : const Quaternion *

=item $xsegments=16 : int

=item $ysegments=16 : int

=item $ysegments_keep=-1 : int

=item $groupName=ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME : String

=back

I<Returns>

=over

=item void

=back

=head2 $obj->isSkyDomeEnabled()

I<Returns>

=over

=item bool

=back

=head2 $obj->getSkyDomeNode()

I<Returns>

=over

=item SceneNode *

=back

=head2 $obj->setFog($mode=FOG_NONE, $colour=&ColourValue::White, $expDensity=0.001, $linearStart=0.0, $linearEnd=1.0)

I<Parameter types>

=over

=item $mode=FOG_NONE : int

=item $colour=&ColourValue::White : const ColourValue *

=item $expDensity=0.001 : Real

=item $linearStart=0.0 : Real

=item $linearEnd=1.0 : Real

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getFogMode()

I<Returns>

=over

=item int

=back

=head2 $obj->getFogStart()

I<Returns>

=over

=item Real

=back

=head2 $obj->getFogEnd()

I<Returns>

=over

=item Real

=back

=head2 $obj->getFogDensity()

I<Returns>

=over

=item Real

=back

=head2 $obj->createBillboardSet($name, $poolSize=20)

I<Parameter types>

=over

=item $name : String

=item $poolSize=20 : unsigned int

=back

I<Returns>

=over

=item BillboardSet *

=back

=head2 $obj->getBillboardSet($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item BillboardSet *

=back

=head2 $obj->hasBillboardSet($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item bool

=back

=head2 $obj->destroyBillboardSet($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item void

=back

=head2 $obj->destroyAllBillboardSets()

I<Returns>

=over

=item void

=back

=head2 $obj->setDisplaySceneNodes($display)

I<Parameter types>

=over

=item $display : bool

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getDisplaySceneNodes()

I<Returns>

=over

=item bool

=back

=head2 $obj->createAnimation($name, $length)

I<Parameter types>

=over

=item $name : String

=item $length : Real

=back

I<Returns>

=over

=item Animation *

=back

=head2 $obj->getAnimation($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item Animation *

=back

=head2 $obj->hasAnimation($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item bool

=back

=head2 $obj->destroyAnimation($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item void

=back

=head2 $obj->destroyAllAnimations()

I<Returns>

=over

=item void

=back

=head2 $obj->createAnimationState($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item AnimationState *

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

=head2 $obj->hasAnimationState($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item bool

=back

=head2 $obj->destroyAnimationState($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item void

=back

=head2 $obj->destroyAllAnimationStates()

I<Returns>

=over

=item void

=back

=head2 $obj->manualRender($rend, $pass, $vp, $worldMatrix, $viewMatrix, $projMatrix, $doBeginEndFrame=false)

I<Parameter types>

=over

=item $rend : RenderOperation *

=item $pass : Pass *

=item $vp : Viewport *

=item $worldMatrix : const Matrix4 *

=item $viewMatrix : const Matrix4 *

=item $projMatrix : const Matrix4 *

=item $doBeginEndFrame=false : bool

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getRenderQueue()

I<Returns>

=over

=item RenderQueue *

=back

=head2 $obj->addSpecialCaseRenderQueue($uint8 qid)

I<Parameter types>

=over

=item $uint8 qid : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->removeSpecialCaseRenderQueue($uint8 qid)

I<Parameter types>

=over

=item $uint8 qid : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->clearSpecialCaseRenderQueues()

I<Returns>

=over

=item void

=back

=head2 $obj->setSpecialCaseRenderQueueMode($int mode)

I<Parameter types>

=over

=item $int mode : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getSpecialCaseRenderQueueMode()

I<Returns>

=over

=item int

=back

=head2 $obj->isRenderQueueToBeProcessed($uint8 qid)

I<Parameter types>

=over

=item $uint8 qid : (no info available)

=back

I<Returns>

=over

=item bool

=back

=head2 $obj->setWorldGeometryRenderQueue($uint8 qid)

I<Parameter types>

=over

=item $uint8 qid : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getWorldGeometryRenderQueue()

I<Returns>

=over

=item uint8

=back

=head2 $obj->showBoundingBoxes($bShow)

I<Parameter types>

=over

=item $bShow : bool

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getShowBoundingBoxes()

I<Returns>

=over

=item bool

=back

=head2 $obj->createAABBQuery($box, $mask=0xFFFFFFFF)

I<Parameter types>

=over

=item $box : AxisAlignedBox *

=item $mask=0xFFFFFFFF : unsigned long

=back

I<Returns>

=over

=item AxisAlignedBoxSceneQuery *

=back

=head2 $obj->createSphereQuery($sphere, $mask=0xFFFFFFFF)

I<Parameter types>

=over

=item $sphere : Sphere *

=item $mask=0xFFFFFFFF : unsigned long

=back

I<Returns>

=over

=item SphereSceneQuery *

=back

=head2 $obj->createRayQuery($ray, $mask=0xFFFFFFFF)

I<Parameter types>

=over

=item $ray : Ray *

=item $mask=0xFFFFFFFF : unsigned long

=back

I<Returns>

=over

=item RaySceneQuery *

=back

=head2 $obj->createIntersectionQuery($unsigned long mask=0xFFFFFFFF)

I<Parameter types>

=over

=item $unsigned long mask=0xFFFFFFFF : (no info available)

=back

I<Returns>

=over

=item IntersectionSceneQuery *

=back

=head2 $obj->destroyQuery($query)

I<Parameter types>

=over

=item $query : SceneQuery *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setShadowTechnique($technique)

I<Parameter types>

=over

=item $technique : int

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getShadowTechnique()

I<Returns>

=over

=item int

=back

=head2 $obj->setShowDebugShadows($debug)

I<Parameter types>

=over

=item $debug : bool

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getShowDebugShadows()

I<Returns>

=over

=item bool

=back

=head2 $obj->setShadowColour($colour)

I<Parameter types>

=over

=item $colour : ColourValue *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setShadowDirectionalLightExtrusionDistance($dist)

I<Parameter types>

=over

=item $dist : Real

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getShadowDirectionalLightExtrusionDistance()

I<Returns>

=over

=item Real

=back

=head2 $obj->setShadowFarDistance($distance)

I<Parameter types>

=over

=item $distance : Real

=back

I<Returns>

=over

=item void 

=back

=head2 $obj->getShadowFarDistance()

I<Returns>

=over

=item Real

=back

=head2 $obj->setShadowIndexBufferSize($size)

I<Parameter types>

=over

=item $size : size_t

=back

I<Returns>

=over

=item void 

=back

=head2 $obj->getShadowIndexBufferSize()

I<Returns>

=over

=item size_t 

=back

=head2 $obj->setShadowTextureSize($size)

I<Parameter types>

=over

=item $size : unsigned short

=back

I<Returns>

=over

=item void 

=back

=head2 $obj->setShadowTextureConfig($size_t shadowIndex, $unsigned short width, $unsigned short height, $int format)

I<Parameter types>

=over

=item $size_t shadowIndex : (no info available)

=item $unsigned short width : (no info available)

=item $unsigned short height : (no info available)

=item $int format : (no info available)

=back

I<Returns>

=over

=item void 

=back

=head2 $obj->setShadowTexturePixelFormat($int fmt)

I<Parameter types>

=over

=item $int fmt : (no info available)

=back

I<Returns>

=over

=item void 

=back

=head2 $obj->setShadowTextureCount($size_t count)

I<Parameter types>

=over

=item $size_t count : (no info available)

=back

I<Returns>

=over

=item void 

=back

=head2 $obj->getShadowTextureCount()

I<Returns>

=over

=item size_t 

=back

=head2 $obj->setShadowTextureSettings($unsigned short size, $unsigned short count, $int fmt=PF_X8R8G8B8)

I<Parameter types>

=over

=item $unsigned short size : (no info available)

=item $unsigned short count : (no info available)

=item $int fmt=PF_X8R8G8B8 : (no info available)

=back

I<Returns>

=over

=item void 

=back

=head2 $obj->setShadowDirLightTextureOffset($Real offset)

I<Parameter types>

=over

=item $Real offset : (no info available)

=back

I<Returns>

=over

=item void 

=back

=head2 $obj->getShadowDirLightTextureOffset()

I<Returns>

=over

=item Real 

=back

=head2 $obj->setShadowTextureFadeStart($Real fadeStart)

I<Parameter types>

=over

=item $Real fadeStart : (no info available)

=back

I<Returns>

=over

=item void 

=back

=head2 $obj->setShadowTextureFadeEnd($Real fadeEnd)

I<Parameter types>

=over

=item $Real fadeEnd : (no info available)

=back

I<Returns>

=over

=item void 

=back

=head2 $obj->setShadowTextureSelfShadow($bool selfShadow)

I<Parameter types>

=over

=item $bool selfShadow : (no info available)

=back

I<Returns>

=over

=item void 

=back

=head2 $obj->getShadowTextureSelfShadow()

I<Returns>

=over

=item bool 

=back

=head2 $obj->setShadowTextureCasterMaterial($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item void 

=back

=head2 $obj->setShadowTextureReceiverMaterial($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item void 

=back

=head2 $obj->setShadowCasterRenderBackFaces($bool bf)

I<Parameter types>

=over

=item $bool bf : (no info available)

=back

I<Returns>

=over

=item void 

=back

=head2 $obj->getShadowCasterRenderBackFaces()

I<Returns>

=over

=item bool 

=back

=head2 $obj->setShadowUseInfiniteFarPlane($bool enable)

I<Parameter types>

=over

=item $bool enable : (no info available)

=back

I<Returns>

=over

=item void 

=back

=head2 $obj->isShadowTechniqueStencilBased()

I<Returns>

=over

=item bool 

=back

=head2 $obj->isShadowTechniqueTextureBased()

I<Returns>

=over

=item bool 

=back

=head2 $obj->isShadowTechniqueModulative()

I<Returns>

=over

=item bool 

=back

=head2 $obj->isShadowTechniqueAdditive()

I<Returns>

=over

=item bool 

=back

=head2 $obj->isShadowTechniqueIntegrated()

I<Returns>

=over

=item bool 

=back

=head2 $obj->isShadowTechniqueInUse()

I<Returns>

=over

=item bool 

=back

=head2 $obj->createStaticGeometry($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item StaticGeometry *

=back

=head2 $obj->getStaticGeometry($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item StaticGeometry *

=back

=head2 $obj->hasStaticGeometry($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item bool

=back

=head2 $obj->destroyStaticGeometry($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item void

=back

=head2 $obj->destroyAllStaticGeometry()

I<Returns>

=over

=item void

=back

=head2 $obj->createInstancedGeometry($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item InstancedGeometry *

=back

=head2 $obj->getInstancedGeometry($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item InstancedGeometry *

=back

=head2 $obj->destroyInstancedGeometry($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item void

=back

=head2 $obj->destroyAllInstancedGeometry()

I<Returns>

=over

=item void

=back

=head2 $obj->createMovableObject($name, $typeName)

I<Parameter types>

=over

=item $name : String

=item $typeName : String

=back

I<Returns>

=over

=item MovableObject *

=back

=head2 $obj->destroyMovableObject($name, $typeName)

I<Parameter types>

=over

=item $name : String

=item $typeName : String

=back

I<Returns>

=over

=item void

=back

=head2 $obj->destroyAllMovableObjectsByType($typeName)

I<Parameter types>

=over

=item $typeName : String

=back

I<Returns>

=over

=item void

=back

=head2 $obj->destroyAllMovableObjects()

I<Returns>

=over

=item void

=back

=head2 $obj->getMovableObject($name, $typeName)

I<Parameter types>

=over

=item $name : String

=item $typeName : String

=back

I<Returns>

=over

=item MovableObject *

=back

=head2 $obj->hasMovableObject($name, $typeName)

I<Parameter types>

=over

=item $name : String

=item $typeName : String

=back

I<Returns>

=over

=item bool

=back

=head2 $obj->injectMovableObject($m)

I<Parameter types>

=over

=item $m : MovableObject *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->extractMovableObject($name, $typeName)

I<Parameter types>

=over

=item $name : String

=item $typeName : String

=back

I<Returns>

=over

=item void

=back

=head2 $obj->extractAllMovableObjectsByType($typeName)

I<Parameter types>

=over

=item $typeName : String

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setVisibilityMask($uint32 vmask)

I<Parameter types>

=over

=item $uint32 vmask : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getVisibilityMask()

I<Returns>

=over

=item uint32

=back

=head2 $obj->setFindVisibleObjects($bool find)

I<Parameter types>

=over

=item $bool find : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getFindVisibleObjects()

I<Returns>

=over

=item bool

=back

=head2 $obj->getDestinationRenderSystem()

I<Returns>

=over

=item RenderSystem *

=back

=head2 $obj->getCurrentViewport()

I<Returns>

=over

=item Viewport *

=back

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

For licensing information, see README.txt .

=cut
