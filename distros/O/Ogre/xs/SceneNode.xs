MODULE = Ogre     PACKAGE = Ogre::SceneNode

void
SceneNode::attachObject(obj)
    MovableObject * obj

unsigned short
SceneNode::numAttachedObjects()


##also virtual MovableObject * 	getAttachedObject (unsigned short index)
MovableObject *
SceneNode::getAttachedObject(name)
    String  name

##also virtual MovableObject * 	detachObject (unsigned short index)
void
SceneNode::detachObject(obj)
    MovableObject * obj

void
SceneNode::detachAllObjects()

bool
SceneNode::isInSceneGraph()

## virtual void 	_notifyRootNode (void)
## virtual void 	_updateBounds (void)

## virtual ObjectIterator 	getAttachedObjectIterator (void)
## virtual ConstObjectIterator 	getAttachedObjectIterator (void) const 

SceneManager *
SceneNode::getCreator()

##also virtual void 	removeAndDestroyChild (unsigned short index)
void
SceneNode::removeAndDestroyChild(name)
    String  name

void
SceneNode::removeAndDestroyAllChildren()

void
SceneNode::showBoundingBox(bShow)
    bool  bShow

bool
SceneNode::getShowBoundingBox()

# SceneNode * createChildSceneNode(const Vector3 &translate=Vector3::ZERO, const Quaternion &rotate=Quaternion::IDENTITY)
# SceneNode * createChildSceneNode(const String &name, const Vector3 &translate=Vector3::ZERO, const Quaternion &rotate=Quaternion::IDENTITY)
SceneNode *
SceneNode::createChildSceneNode(...)
  CODE:
    // Alrighty then, here we go...

    // 0 args passed, must not be 2nd version, so pass no args
    if (items == 1) {
        RETVAL = THIS->createChildSceneNode();
    }
    else {
        // 1st arg is Vector3
        if (sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::Vector3")) {
            Vector3 *vec = (Vector3 *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN

            // 1 arg passed
            if (items == 2) {
                RETVAL = THIS->createChildSceneNode(*vec);
            }
            // 2 args passed
            else if (items == 3) {
                if (sv_isobject(ST(2)) && sv_derived_from(ST(2), "Ogre::Quaternion")) {
                    Quaternion *q = (Quaternion *) SvIV((SV *) SvRV(ST(2)));  // TMOGRE_IN

                    RETVAL = THIS->createChildSceneNode(*vec, *q);
                }
                else {
                  croak("Usage: Ogre::SceneNode::createChildSceneNode(THIS, Vector3, Quaternion)\n");
                }
            }
        }
        // 1st arg is String
        else {
            char * xstmpchr = (char *) SvPV_nolen(ST(1));
            String name = xstmpchr;

            // 1 arg passed
            if (items == 2) {
                RETVAL = THIS->createChildSceneNode(name);
            }
            // 2 args passed
            else if (items == 3) {
                if (sv_isobject(ST(2)) && sv_derived_from(ST(2), "Ogre::Vector3")) {
                    Vector3 *vec = (Vector3 *) SvIV((SV *) SvRV(ST(2)));     // TMOGRE_IN

                    RETVAL = THIS->createChildSceneNode(name, *vec);
                }
                else {
                  croak("Usage: Ogre::SceneNode::createChildSceneNode(THIS, String, Vector3)\n");
                }
            }
            // 3 args passed
            else if (items == 4) {
                if (sv_isobject(ST(2)) && sv_derived_from(ST(2), "Ogre::Vector3")) {
                    Vector3 *vec = (Vector3 *) SvIV((SV *) SvRV(ST(2)));     // TMOGRE_IN

                    if (sv_isobject(ST(3)) && sv_derived_from(ST(3), "Ogre::Quaternion")) {
                        Quaternion *q = (Quaternion *) SvIV((SV *) SvRV(ST(3)));  // TMOGRE_IN

                        RETVAL = THIS->createChildSceneNode(name, *vec, *q);
                    }
                    else {
                      croak("Usage: Ogre::SceneNode::createChildSceneNode(THIS, String, Vector3, Quaternion)\n");
                    }
                }
                else {
                  croak("Usage: Ogre::SceneNode::createChildSceneNode(THIS, String, Vector3, Quaternion)\n");
                }
            }
        }

    }
  OUTPUT:
    RETVAL

## virtual void 	findLights (LightList &destList, Real radius, uint32 lightMask=0xFFFFFFFF) const

void
SceneNode::setFixedYawAxis(useFixed, fixedAxis)
    bool  useFixed
    Vector3 * fixedAxis
  C_ARGS:
    useFixed, *fixedAxis

void
SceneNode::yaw(DegRad *angle, int relativeTo=Node::TS_LOCAL)
  C_ARGS:
    *angle, (Ogre::Node::TransformSpace)relativeTo

## virtual void 	setDirection (Real x, Real y, Real z, TransformSpace relativeTo=TS_LOCAL, const Vector3 &localDirectionVector=Vector3::NEGATIVE_UNIT_Z)
## virtual void 	setDirection (const Vector3 &vec, TransformSpace relativeTo=TS_LOCAL, const Vector3 &localDirectionVector=Vector3::NEGATIVE_UNIT_Z)
void
SceneNode::setDirection(x, y, z, relativeTo, localDirectionVector)
    Real  x
    Real  y
    Real  z
    int    relativeTo
    Vector3 * localDirectionVector
  C_ARGS:
    x, y, z, (Ogre::Node::TransformSpace)relativeTo, *localDirectionVector

## virtual void 	lookAt (const Vector3 &targetPoint, TransformSpace relativeTo, const Vector3 &localDirectionVector=Vector3::NEGATIVE_UNIT_Z)
void
SceneNode::lookAt(targetPoint, relativeTo, localDirectionVector)
    Vector3 * targetPoint
    int    relativeTo
    Vector3 * localDirectionVector
  C_ARGS:
    *targetPoint, (Ogre::Node::TransformSpace)relativeTo, *localDirectionVector

## virtual void 	setAutoTracking (bool enabled, SceneNode *target=0, const Vector3 &localDirectionVector=Vector3::NEGATIVE_UNIT_Z, const Vector3 &offset=Vector3::ZERO)
void
SceneNode::setAutoTracking(enabled, target, localDirectionVector, offset)
    bool        enabled
    SceneNode * target
    Vector3 *   localDirectionVector
    Vector3 *   offset
  C_ARGS:
    enabled, target, *localDirectionVector, *offset

SceneNode *
SceneNode::getAutoTrackTarget()

## virtual const Vector3 & 	getAutoTrackOffset (void)
## virtual const Vector3 & 	getAutoTrackLocalDirection (void)

SceneNode *
SceneNode::getParentSceneNode()

void
SceneNode::setVisible(bool enabled, bool cascade=true)

void
SceneNode::flipVisibility(bool cascade=true)

void
SceneNode::setDebugDisplayEnabled(bool enabled, bool cascade=true)


## static void 	queueNeedUpdate (Node *n)
## static void 	processQueuedUpdates (void)
