MODULE = Ogre     PACKAGE = Ogre::Entity

## note: if constructor/destructor ever added, refer to BillboardSet.xs

const Mesh *
Entity::getMesh()
  CODE:
    RETVAL = THIS->getMesh().getPointer();
  OUTPUT:
    RETVAL

SubEntity *
Entity::getSubEntity(...)
  CODE:
    if (looks_like_number(ST(1))) {
        unsigned int index = (unsigned int)SvUV(ST(1));
        RETVAL = THIS->getSubEntity(index);
    }
    else {
        char * xstmpchr = (char *) SvPV_nolen(ST(1));
        String name = xstmpchr;
        RETVAL = THIS->getSubEntity(name);
    }
  OUTPUT:
    RETVAL

unsigned int
Entity::getNumSubEntities()

Entity *
Entity::clone(name)
    String  name

void
Entity::setMaterialName(name)
    String  name

void
Entity::setRenderQueueGroup(uint8 queueID)

## const AxisAlignedBox & 	getBoundingBox (void) const

## AxisAlignedBox 	getChildObjectsBoundingBox (void) const

String
Entity::getMovableType()

AnimationState *
Entity::getAnimationState(name)
    String  name

AnimationStateSet *
Entity::getAllAnimationStates()

void
Entity::setDisplaySkeleton(display)
    bool  display

bool
Entity::getDisplaySkeleton()

Entity *
Entity::getManualLodLevel(index)
    size_t  index

size_t
Entity::getNumManualLodLevels()

void
Entity::setMeshLodBias(factor, maxDetailIndex=0, minDetailIndex=99)
    Real           factor
    unsigned short  maxDetailIndex
    unsigned short  minDetailIndex

void
Entity::setMaterialLodBias(factor, maxDetailIndex=0, minDetailIndex=99)
    Real           factor
    unsigned short  maxDetailIndex
    unsigned short  minDetailIndex

void
Entity::setPolygonModeOverrideable(PolygonModeOverrideable)
    bool  PolygonModeOverrideable



TagPoint *
Entity::attachObjectToBone(boneName, pMovable, offsetOrientation=&Quaternion::IDENTITY, offsetPosition=&Vector3::ZERO)
    String  boneName
    MovableObject * pMovable
    const Quaternion * offsetOrientation
    const Vector3 * offsetPosition
  CODE:
    RETVAL = THIS->attachObjectToBone(boneName, pMovable, *offsetOrientation, *offsetPosition);
  OUTPUT:
    RETVAL

MovableObject *
Entity::detachObjectFromBone(...)
  CODE:
    if (sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::MovableObject")) {
        MovableObject *obj = (MovableObject *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN
        THIS->detachObjectFromBone(obj);

        // probably shouldn't do this, but the return value has to be
        // ignored here, but not below when a String is passed,
        // so for convenience I just stick the old object in RETVAL
        RETVAL = obj;
    }
    else {
        char * xstmpchr = (char *) SvPV_nolen(ST(1));
        String movableName = xstmpchr;
        RETVAL = THIS->detachObjectFromBone(movableName);
    }
  OUTPUT:
    RETVAL

void
Entity::detachAllObjectsFromBone()

## ChildObjectListIterator Entity::getAttachedObjectIterator()

Real
Entity::getBoundingRadius()

## const AxisAlignedBox & Entity::getWorldBoundingBox(bool derive=false)

## const Sphere & Entity::getWorldBoundingSphere(bool derive=false)

EdgeData *
Entity::getEdgeList()

bool
Entity::hasEdgeList()

## ShadowRenderableListIterator Entity::getShadowVolumeRenderableIterator(ShadowTechnique shadowTechnique, const Light *light, HardwareIndexBufferSharedPtr *indexBuffer, bool extrudeVertices, Real extrusionDistance, unsigned long flags=0)

bool
Entity::hasSkeleton()

SkeletonInstance *
Entity::getSkeleton()

bool
Entity::isHardwareAnimationEnabled()

int
Entity::getSoftwareAnimationRequests()

int
Entity::getSoftwareAnimationNormalsRequests()

void
Entity::addSoftwareAnimationRequest(bool normalsAlso)

void
Entity::removeSoftwareAnimationRequest(bool normalsAlso)

void
Entity::shareSkeletonInstanceWith(entity)
    Entity * entity

bool
Entity::hasVertexAnimation()

void
Entity::stopSharingSkeletonInstance()

bool
Entity::sharesSkeletonInstance()

## xxx: std::set<Entity*>
## const EntitySet * Entity::getSkeletonInstanceSharingSet()

void
Entity::refreshAvailableAnimationState()

uint32
Entity::getTypeFlags()

VertexData *
Entity::getVertexDataForBinding()

int
Entity::chooseVertexDataForBinding(bool hasVertexAnim)

bool
Entity::isInitialised()

void
Entity::backgroundLoadingComplete(res)
    Resource * res
