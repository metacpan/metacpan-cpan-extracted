MODULE = Ogre     PACKAGE = Ogre::SceneManager

## no constructor

String
SceneManager::getName()

String
SceneManager::getTypeName()

Camera *
SceneManager::createCamera(name)
    String  name

Camera *
SceneManager::getCamera(name)
    String  name

bool
SceneManager::hasCamera(name)
    String  name

## xxx: missing: virtual void 	destroyCamera (Camera *cam)
void
SceneManager::destroyCamera(name)
    String  name

void
SceneManager::destroyAllCameras()

Light *
SceneManager::createLight(name)
    String  name

Light *
SceneManager::getLight(name)
    String  name

bool
SceneManager::hasLight(name)
    String  name

## virtual const PlaneList & 	getLightClippingPlanes (Light *l)
## virtual const RealRect & 	getLightScissorRect (Light *l, const Camera *cam)

## xxx: virtual void 	destroyLight (Light *light)
void
SceneManager::destroyLight(name)
    String  name

void
SceneManager::destroyAllLights()

## xxx: virtual SceneNode * 	createSceneNode (void)
SceneNode *
SceneManager::createSceneNode(name)
    String  name

## xxx: virtual void 	destroySceneNode (SceneNode *sn)
void
SceneManager::destroySceneNode(name)
    String  name

SceneNode *
SceneManager::getRootSceneNode()

SceneNode *
SceneManager::getSceneNode(name)
    String  name

bool
SceneManager::hasSceneNode(name)
    String  name

## xxx:   Entity * createEntity (const String &entityName, PrefabType ptype)
Entity *
SceneManager::createEntity(entityName, meshName)
    String entityName
    String meshName

Entity *
SceneManager::getEntity(name)
    String  name

bool
SceneManager::hasEntity(name)
    String  name

## xxx: virtual void 	destroyEntity (Entity *ent)
void
SceneManager::destroyEntity(name)
    String  name

void
SceneManager::destroyAllEntities()

ManualObject *
SceneManager::createManualObject(name)
    String  name

ManualObject *
SceneManager::getManualObject(name)
    String  name

bool
SceneManager::hasManualObject(name)
    String  name

## xxx: virtual void 	destroyManualObject (ManualObject *obj)
void
SceneManager::destroyManualObject(name)
    String  name

void
SceneManager::destroyAllManualObjects()

BillboardChain *
SceneManager::createBillboardChain(name)
    String  name

BillboardChain *
SceneManager::getBillboardChain(name)
    String  name

bool
SceneManager::hasBillboardChain(name)
    String  name

## xxx: void 	destroyBillboardChain (BillboardChain *obj)
void
SceneManager::destroyBillboardChain(name)
    String  name

void
SceneManager::destroyAllBillboardChains()

RibbonTrail *
SceneManager::createRibbonTrail(name)
    String  name

RibbonTrail *
SceneManager::getRibbonTrail(name)
    String  name

bool
SceneManager::hasRibbonTrail(name)
    String  name

## xxx: void 	destroyRibbonTrail (RibbonTrail *obj)
void
SceneManager::destroyRibbonTrail(name)
    String  name

void
SceneManager::destroyAllRibbonTrails()

## xxx:   ParticleSystem * 	createParticleSystem (const String &name, size_t quota=500, const String &resourceGroup=ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME)
ParticleSystem *
SceneManager::createParticleSystem(name, templateName)
    String  name
    String  templateName

## xxx: this is a workaround; otherwise, for some reason,
## the ParticleSystem is returned attached by createParticleSystem
void
SceneManager::createAndAttachParticleSystem(name, templateName, node)
    String  name
    String  templateName
    SceneNode * node
  CODE:
    node->attachObject( THIS->createParticleSystem(name, templateName) );

ParticleSystem *
SceneManager::getParticleSystem(name)
    String  name

bool
SceneManager::hasParticleSystem(name)
    String  name

## xxx: void 	destroyParticleSystem (ParticleSystem *obj)
void
SceneManager::destroyParticleSystem(name)
    String  name

void
SceneManager::destroyAllParticleSystems()

void
SceneManager::clearScene()

void
SceneManager::setAmbientLight(colour)
    ColourValue * colour
  C_ARGS:
    *colour

## const ColourValue & getAmbientLight()

## xxx: virtual void 	prepareWorldGeometry (DataStreamPtr &stream, const String &typeName=StringUtil::BLANK)
void
SceneManager::prepareWorldGeometry(filename)
    String filename

## xxx: void 	setWorldGeometry (DataStreamPtr &stream, const String &typeName=StringUtil::BLANK)
void
SceneManager::setWorldGeometry(filename)
    String  filename

## xxx: size_t 	estimateWorldGeometry (DataStreamPtr &stream, const String &typeName=StringUtil::BLANK)
size_t
SceneManager::estimateWorldGeometry(filename)
    String  filename

## ViewPoint is a struct with a Vector3 and Quaternion
## xxx: ViewPoint 	getSuggestedViewpoint (bool random=false)

## xxx: void*
## bool 	setOption (const String &strKey, const void *pValue)
## bool 	getOption (const String &strKey, void *pDestValue)

bool
SceneManager::hasOption(strKey)
    String  strKey

## xxx: std::vector<String>
## virtual bool 	getOptionValues (const String &strKey, StringVector &refValueList)
## virtual bool 	getOptionKeys (StringVector &refKeys)

void
SceneManager::setSkyPlane(enable, plane, materialName, scale=1000, tiling=10, drawFirst=true, bow=0, xsegments=1, ysegments=1, groupName=ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME)
    bool    enable
    Plane * plane
    String  materialName
    Real   scale
    Real   tiling
    bool    drawFirst
    Real   bow
    int     xsegments
    int     ysegments
    String  groupName
  C_ARGS:
    enable, *plane, materialName, scale, tiling, drawFirst, bow, xsegments, ysegments, (const String)groupName

bool
SceneManager::isSkyPlaneEnabled()

SceneNode *
SceneManager::getSkyPlaneNode()

## xxx: this returns a struct; could return a hashref instead
## virtual const SkyPlaneGenParameters & 	getSkyPlaneGenParameters (void) const

void
SceneManager::setSkyBox(enable, materialName, distance=5000, drawFirst=true, orientation=&Quaternion::IDENTITY, groupName=ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME)
    bool         enable
    String       materialName
    Real        distance
    bool         drawFirst
    const Quaternion * orientation
    String       groupName
  C_ARGS:
    enable, materialName, distance, drawFirst, *orientation, groupName

bool
SceneManager::isSkyBoxEnabled()

SceneNode *
SceneManager::getSkyBoxNode()

## xxx: this returns a struct; could return a hashref instead
## virtual const SkyBoxGenParameters & 	getSkyBoxGenParameters (void) const

void
SceneManager::setSkyDome(enable, materialName, curvature=10, tiling=8, distance=4000, drawFirst=true, orientation=&Quaternion::IDENTITY, xsegments=16, ysegments=16, ysegments_keep=-1, groupName=ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME)
    bool         enable
    String       materialName
    Real        curvature
    Real        tiling
    Real        distance
    bool         drawFirst
    const Quaternion * orientation
    int          xsegments
    int          ysegments
    int          ysegments_keep
    String       groupName
  C_ARGS:
    enable, materialName, curvature, tiling, distance, drawFirst, *orientation, xsegments, ysegments, ysegments_keep, groupName

bool
SceneManager::isSkyDomeEnabled()

SceneNode *
SceneManager::getSkyDomeNode()

## xxx: this returns a struct; could return a hashref instead
## virtual const SkyDomeGenParameters & 	getSkyDomeGenParameters (void) const

void
SceneManager::setFog(mode=FOG_NONE, colour=&ColourValue::White, expDensity=0.001, linearStart=0.0, linearEnd=1.0)
    int           mode
    const ColourValue * colour
    Real         expDensity
    Real         linearStart
    Real         linearEnd
  C_ARGS:
    (FogMode)mode, *colour, expDensity, linearStart, linearEnd

int
SceneManager::getFogMode()

## xxx: const ColourValue & 	getFogColour (void) const

Real
SceneManager::getFogStart()

Real
SceneManager::getFogEnd()

Real
SceneManager::getFogDensity()

BillboardSet *
SceneManager::createBillboardSet(name, poolSize=20)
    String  name
    unsigned int  poolSize

BillboardSet *
SceneManager::getBillboardSet(name)
    String        name

bool
SceneManager::hasBillboardSet(name)
    String  name

## xxx: also   void destroyBillboardSet (BillboardSet *set)
void
SceneManager::destroyBillboardSet(name)
    String  name

void
SceneManager::destroyAllBillboardSets()

void
SceneManager::setDisplaySceneNodes(display)
    bool  display

bool
SceneManager::getDisplaySceneNodes()

Animation *
SceneManager::createAnimation(name, length)
    String  name
    Real  length

Animation *
SceneManager::getAnimation(name)
    String        name

bool
SceneManager::hasAnimation(name)
    String  name

void
SceneManager::destroyAnimation(name)
    String  name

void
SceneManager::destroyAllAnimations()

AnimationState *
SceneManager::createAnimationState(name)
    String  name

AnimationState *
SceneManager::getAnimationState(name)
    String  name

bool
SceneManager::hasAnimationState(name)
    String  name

void
SceneManager::destroyAnimationState(name)
    String  name

void
SceneManager::destroyAllAnimationStates()

void
SceneManager::manualRender(rend, pass, vp, worldMatrix, viewMatrix, projMatrix, doBeginEndFrame=false)
    RenderOperation * rend
    Pass * pass
    Viewport * vp
    const Matrix4 * worldMatrix
    const Matrix4 * viewMatrix
    const Matrix4 * projMatrix
    bool  doBeginEndFrame
  C_ARGS:
    rend, pass, vp, *worldMatrix, *viewMatrix, *projMatrix, doBeginEndFrame

RenderQueue *
SceneManager::getRenderQueue()

## xxx:
## void 	addRenderQueueListener (RenderQueueListener *newListener)
## void 	removeRenderQueueListener (RenderQueueListener *delListener)

void
SceneManager::addSpecialCaseRenderQueue(uint8 qid)

void
SceneManager::removeSpecialCaseRenderQueue(uint8 qid)

void
SceneManager::clearSpecialCaseRenderQueues()

void
SceneManager::setSpecialCaseRenderQueueMode(int mode)
  C_ARGS:
    (Ogre::SceneManager::SpecialCaseRenderQueueMode)mode

int
SceneManager::getSpecialCaseRenderQueueMode()

bool
SceneManager::isRenderQueueToBeProcessed(uint8 qid)

void
SceneManager::setWorldGeometryRenderQueue(uint8 qid)

uint8
SceneManager::getWorldGeometryRenderQueue()

void
SceneManager::showBoundingBoxes(bShow)
    bool  bShow

bool
SceneManager::getShowBoundingBoxes()

AxisAlignedBoxSceneQuery *
SceneManager::createAABBQuery(box, mask=0xFFFFFFFF)
    AxisAlignedBox * box
    unsigned long  mask
  C_ARGS:
    *box, mask

SphereSceneQuery *
SceneManager::createSphereQuery(sphere, mask=0xFFFFFFFF)
    Sphere * sphere
    unsigned long  mask
  C_ARGS:
    *sphere, mask

## PlaneBoundedVolumeListSceneQuery * createPlaneBoundedVolumeQuery (const PlaneBoundedVolumeList &volumes, unsigned long mask=0xFFFFFFFF)
## note: pass an aref instead of PlaneBoundedVolumeList
## xxx: this could be a little better, letting volumes be optional
PlaneBoundedVolumeListSceneQuery *
SceneManager::createPlaneBoundedVolumeQuery(SV *volumes_sv, unsigned long mask=0xFFFFFFFF)
  CODE:
    PlaneBoundedVolumeList *volumes = perlOGRE_aref2PBVL(volumes_sv,
                                                         "Ogre::SceneManager::createPlaneBoundedVolumeQuery");
    RETVAL = THIS->createPlaneBoundedVolumeQuery(*volumes, mask);
    delete volumes;
  OUTPUT:
    RETVAL

RaySceneQuery *
SceneManager::createRayQuery(ray, mask=0xFFFFFFFF)
    Ray * ray
    unsigned long  mask
  C_ARGS:
    *ray, mask

IntersectionSceneQuery *
SceneManager::createIntersectionQuery(unsigned long mask=0xFFFFFFFF)

void
SceneManager::destroyQuery(query)
    SceneQuery * query

## xxx: we would presumably want arefs
## CameraIterator 	getCameraIterator (void)
## AnimationIterator 	getAnimationIterator (void)
## AnimationStateIterator 	getAnimationStateIterator (void)

void
SceneManager::setShadowTechnique(technique)
    int  technique
  C_ARGS:
    (ShadowTechnique)technique

int
SceneManager::getShadowTechnique()

void
SceneManager::setShowDebugShadows(debug)
    bool  debug

bool
SceneManager::getShowDebugShadows()

void
SceneManager::setShadowColour(colour)
    ColourValue * colour
  C_ARGS:
    *colour

# xxx: const ColourValue & 	getShadowColour (void) const

void
SceneManager::setShadowDirectionalLightExtrusionDistance(dist)
    Real  dist

Real
SceneManager::getShadowDirectionalLightExtrusionDistance()

void 
SceneManager::setShadowFarDistance(distance)
    Real  distance

Real
SceneManager::getShadowFarDistance()

Real
SceneManager::getShadowFarDistanceSquared()

void 
SceneManager::setShadowIndexBufferSize(size)
    size_t  size

size_t 
SceneManager::getShadowIndexBufferSize()

void 
SceneManager::setShadowTextureSize(size)
    unsigned short  size

## there is also a struct version:
## void setShadowTextureConfig (size_t shadowIndex, const ShadowTextureConfig &config)
void 
SceneManager::setShadowTextureConfig(size_t shadowIndex, unsigned short width, unsigned short height, int format)
  C_ARGS:
     shadowIndex, width, height, (PixelFormat)format

## xxx: aref
## ConstShadowTextureConfigIterator SceneManager::getShadowTextureConfigIterator()

void 
SceneManager::setShadowTexturePixelFormat(int fmt)
  C_ARGS:
    (PixelFormat)fmt

void 
SceneManager::setShadowTextureCount(size_t count)

size_t 
SceneManager::getShadowTextureCount()

void 
SceneManager::setShadowTextureCountPerLightType(type, count)
    int     type
    size_t  count
  C_ARGS:
    (Ogre::Light::LightTypes)type, count

size_t 
SceneManager::getShadowTextureCountPerLightType(int type)
  C_ARGS:
    (Ogre::Light::LightTypes)type

void 
SceneManager::setShadowTextureSettings(unsigned short size, unsigned short count, int fmt=PF_X8R8G8B8)
  C_ARGS:
    size, count, (PixelFormat)fmt

## const TexturePtr & SceneManager::getShadowTexture(size_t shadowIndex)

void 
SceneManager::setShadowDirLightTextureOffset(Real offset)

Real 
SceneManager::getShadowDirLightTextureOffset()

void 
SceneManager::setShadowTextureFadeStart(Real fadeStart)

void 
SceneManager::setShadowTextureFadeEnd(Real fadeEnd)

void 
SceneManager::setShadowTextureSelfShadow(bool selfShadow)

bool 
SceneManager::getShadowTextureSelfShadow()

void 
SceneManager::setShadowTextureCasterMaterial(name)
    String  name

void 
SceneManager::setShadowTextureReceiverMaterial(name)
    String  name

void 
SceneManager::setShadowCasterRenderBackFaces(bool bf)

bool 
SceneManager::getShadowCasterRenderBackFaces()

## xxx: void SceneManager::setShadowCameraSetup(const ShadowCameraSetupPtr &shadowSetup)
## const ShadowCameraSetupPtr & SceneManager::getShadowCameraSetup()

void 
SceneManager::setShadowUseInfiniteFarPlane(bool enable)

bool 
SceneManager::isShadowTechniqueStencilBased()

bool 
SceneManager::isShadowTechniqueTextureBased()

bool 
SceneManager::isShadowTechniqueModulative()

bool 
SceneManager::isShadowTechniqueAdditive()

bool 
SceneManager::isShadowTechniqueIntegrated()

bool 
SceneManager::isShadowTechniqueInUse()

void
SceneManager::setShadowUseLightClipPlanes(bool enabled)

bool
SceneManager::getShadowUseLightClipPlanes()

## virtual void 	addListener (Listener *s)
## virtual void 	removeListener (Listener *s)

StaticGeometry *
SceneManager::createStaticGeometry(name)
    String  name

StaticGeometry *
SceneManager::getStaticGeometry(name)
    String  name

bool
SceneManager::hasStaticGeometry(name)
    String  name

## xxx: void 	destroyStaticGeometry (StaticGeometry *geom)
void
SceneManager::destroyStaticGeometry(name)
    String  name

void
SceneManager::destroyAllStaticGeometry()

InstancedGeometry *
SceneManager::createInstancedGeometry(name)
    String  name

InstancedGeometry *
SceneManager::getInstancedGeometry(name)
    String        name

## they should have this! :)
##bool
##SceneManager::hasInstancedGeometry(name)
##    String  name

## xxx: void 	destroyInstancedGeometry (InstancedGeometry *geom)
void
SceneManager::destroyInstancedGeometry(name)
    String  name

void
SceneManager::destroyAllInstancedGeometry()

## xxx: skipping params arg for now...
## not sure if this works even, in C++ you end up casting to a specific type,
## but those have their own methods like createRibbonTrail, etc.,
## so use those instead.
## MovableObject *createMovableObject(const String &name, const String &typeName, const NameValuePairList *params=0)
MovableObject *
SceneManager::createMovableObject(name, typeName)
    String  name
    String  typeName

## xxx: void 	destroyMovableObject (MovableObject *m)
void
SceneManager::destroyMovableObject(name, typeName)
    String  name
    String  typeName

void
SceneManager::destroyAllMovableObjectsByType(typeName)
    String  typeName

void
SceneManager::destroyAllMovableObjects()

MovableObject *
SceneManager::getMovableObject(name, typeName)
    String  name
    String  typeName

bool
SceneManager::hasMovableObject(name, typeName)
    String  name
    String  typeName

## xxx: aref
## MovableObjectIterator 	getMovableObjectIterator (const String &typeName)

void
SceneManager::injectMovableObject(m)
    MovableObject * m

## xxx: void 	extractMovableObject (MovableObject *m)
void
SceneManager::extractMovableObject(name, typeName)
    String  name
    String  typeName

void
SceneManager::extractAllMovableObjectsByType(typeName)
    String  typeName

void
SceneManager::setVisibilityMask(uint32 vmask)

uint32
SceneManager::getVisibilityMask()

void
SceneManager::setFindVisibleObjects(bool find)

bool
SceneManager::getFindVisibleObjects()

bool
SceneManager::getNormaliseNormalsOnScale()

void
SceneManager::setFlipCullingOnNegativeScale(bool n)

bool
SceneManager::getFlipCullingOnNegativeScale()

## void 	setQueuedRenderableVisitor (SceneMgrQueuedRenderableVisitor *visitor)
## SceneMgrQueuedRenderableVisitor * 	getQueuedRenderableVisitor (void) const

RenderSystem *
SceneManager::getDestinationRenderSystem()

Viewport *
SceneManager::getCurrentViewport()

## xxx: these return a struct, could return a hashref
## const VisibleObjectsBoundsInfo & 	getVisibleObjectsBoundsInfo (const Camera *cam) const
## const VisibleObjectsBoundsInfo & 	getShadowCasterBoundsInfo (const Light *light) const

void
SceneManager::setCameraRelativeRendering(bool rel)

bool
SceneManager::getCameraRelativeRendering()


### static public attributes

## xxx:
##static uint32 	WORLD_GEOMETRY_TYPE_MASK
##static uint32 	ENTITY_TYPE_MASK
##static uint32 	FX_TYPE_MASK
##static uint32 	STATICGEOMETRY_TYPE_MASK
##static uint32 	LIGHT_TYPE_MASK
##static uint32 	FRUSTUM_TYPE_MASK
##static uint32 	USER_TYPE_MASK_LIMIT
