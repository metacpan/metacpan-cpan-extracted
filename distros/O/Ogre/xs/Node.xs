MODULE = Ogre     PACKAGE = Ogre::Node

static void
Node::queueNeedUpdate(Node *n)

static void
Node::processQueuedUpdates()


String
Node::getName()

Node *
Node::getParent()

Quaternion *
Node::getOrientation()
  CODE:
    RETVAL = new Quaternion;
    *RETVAL = THIS->getOrientation();
  OUTPUT:
    RETVAL

void
Node::setOrientation(...)
  CODE:
    // void Node::setOrientation(Real w, Real x, Real y, Real z)
    if (items == 5) {
        THIS->setOrientation((Real)SvNV(ST(1)), (Real)SvNV(ST(2)), (Real)SvNV(ST(3)), (Real)SvNV(ST(4)));
    }
    // void Node::setOrientation(const Quaternion &q)
    else if (items == 2 && sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::Quaternion")) {
        Quaternion *q = (Quaternion *) SvIV((SV *) SvRV(ST(1)));
        THIS->setOrientation(*q);
    }
    else {
        croak("Usage: Ogre::Node::setOrientation(THIS, w, x, y, z]) or (THIS, quat)\n");
    }

void
Node::resetOrientation()

void
Node::setPosition(...)
  CODE:
    // void Node::setPosition(Real x, Real y, Real z)
    if (items == 4) {
        THIS->setPosition((Real)SvNV(ST(1)), (Real)SvNV(ST(2)), (Real)SvNV(ST(3)));
    }
    // void Node::setPosition(const Vector3 &pos)
    else if (items == 2 && sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::Vector3")) {
        Vector3 *pos = (Vector3 *) SvIV((SV *) SvRV(ST(1)));
        THIS->setPosition(*pos);
    }
    else {
        croak("Usage: Ogre::Node::setPosition(THIS, x, y, z]) or (THIS, vec)\n");
    }

Vector3 *
Node::getPosition()
  CODE:
    RETVAL = new Vector3;
    *RETVAL = THIS->getPosition();
  OUTPUT:
    RETVAL

void
Node::setScale(...)
  CODE:
    // void Node::setScale(Real x, Real y, Real z)
    if (items == 4) {
        THIS->setScale((Real)SvNV(ST(1)), (Real)SvNV(ST(2)), (Real)SvNV(ST(3)));
    }
    // void Node::setScale(const Vector3 &scale)
    else if (items == 2 && sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::Vector3")) {
        Vector3 *scale = (Vector3 *) SvIV((SV *) SvRV(ST(1)));
        THIS->setScale(*scale);
    }
    else {
        croak("Usage: Ogre::Node::setScale(THIS, x, y, z]) or (THIS, vec)\n");
    }

Vector3 *
Node::getScale()
  CODE:
    RETVAL = new Vector3;
    *RETVAL = THIS->getScale();
  OUTPUT:
    RETVAL

void
Node::setInheritOrientation(bool inherit)

bool
Node::getInheritOrientation()

void
Node::setInheritScale(bool inherit)

bool
Node::getInheritScale()

void
Node::scale(...)
  CODE:
    // void Node::scale(Real x, Real y, Real z)
    if (items == 4) {
        THIS->scale((Real)SvNV(ST(1)), (Real)SvNV(ST(2)), (Real)SvNV(ST(3)));
    }
    // void Node::scale(const Vector3 &scale)
    else if (items == 2 && sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::Vector3")) {
        Vector3 *scale = (Vector3 *) SvIV((SV *) SvRV(ST(1)));
        THIS->scale(*scale);
    }
    else {
        croak("Usage: Ogre::Node::scale(THIS, x, y, z]) or (THIS, vec)\n");
    }

void
Node::translate(...)
  PREINIT:
    char *usage = "Usage: Ogre::Node::translate(THIS, ...)\n";
  CODE:
    Ogre::Node::TransformSpace relativeTo = Ogre::Node::TS_PARENT;

    // void translate(Real x, Real y, Real z, TransformSpace relativeTo=TS_PARENT)
    if (items >= 4 && looks_like_number(ST(1)) && looks_like_number(ST(2)) && looks_like_number(ST(3))) {
        if (items == 5) relativeTo = (Ogre::Node::TransformSpace)SvIV(ST(4));

        THIS->translate((Real)SvNV(ST(1)), (Real)SvNV(ST(2)), (Real)SvNV(ST(3)), relativeTo);
    }
    // void translate(const Vector3 &d, TransformSpace relativeTo=TS_PARENT)
    else if (sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::Vector3")) {
        Vector3 *d = (Vector3 *) SvIV((SV *) SvRV(ST(1)));
        if (items == 3) relativeTo = (Ogre::Node::TransformSpace)SvIV(ST(2));

        THIS->translate(*d, relativeTo);
    }
    else if (sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::Matrix3")) {
        Matrix3 *axes = (Matrix3 *) SvIV((SV *) SvRV(ST(1)));

        // void translate(const Matrix3 &axes, Real x, Real y, Real z, TransformSpace relativeTo=TS_PARENT)
        if (items >= 5 && looks_like_number(ST(2)) && looks_like_number(ST(3)) && looks_like_number(ST(4))) {
            if (items == 6) relativeTo = (Ogre::Node::TransformSpace)SvIV(ST(5));

            THIS->translate(*axes, (Real)SvNV(ST(2)), (Real)SvNV(ST(3)), (Real)SvNV(ST(4)), relativeTo);
        }
        // void translate(const Matrix3 &axes, const Vector3 &move, TransformSpace relativeTo=TS_PARENT)
        else if (sv_isobject(ST(2)) && sv_derived_from(ST(2), "Ogre::Vector3")) {
            Vector3 *move = (Vector3 *) SvIV((SV *) SvRV(ST(2)));
            if (items == 4) relativeTo = (Ogre::Node::TransformSpace)SvIV(ST(3));

            THIS->translate(*axes, *move, relativeTo);
        }
        else {
            croak("%s", usage);
        }
    }
    else {
        croak("%s", usage);
    }

void
Node::roll(DegRad *angle, int relativeTo=Node::TS_LOCAL)
  C_ARGS:
    *angle, (Ogre::Node::TransformSpace)relativeTo

void
Node::pitch(DegRad *angle, int relativeTo=Node::TS_LOCAL)
  C_ARGS:
    *angle, (Ogre::Node::TransformSpace)relativeTo

void
Node::yaw(DegRad *angle, int relativeTo=Node::TS_LOCAL)
  C_ARGS:
    *angle, (Ogre::Node::TransformSpace)relativeTo

void
Node::rotate(...)
  PREINIT:
    char *usage = "Usage: Ogre::Node::rotate(THIS, vec, angle [, int]) or (THIS, quat [, int])\n";
  CODE:
    Ogre::Node::TransformSpace relativeTo = Ogre::Node::TS_LOCAL;

    // void rotate (const Vector3 &axis, const Radian &angle, TransformSpace relativeTo=TS_LOCAL)
    if (sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::Vector3") && sv_isobject(ST(2))) {
        Vector3 *axis = (Vector3 *) SvIV((SV *) SvRV(ST(1)));

        DegRad *angle;
        TMOGRE_DEGRAD_IN(ST(2), angle, Ogre::Node, rotate);

        if (items > 3) relativeTo = (Ogre::Node::TransformSpace)SvIV(ST(3));

        THIS->rotate(*axis, *angle, relativeTo);
    }
    // void rotate (const Quaternion &q, TransformSpace relativeTo=TS_LOCAL)
    else if (sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::Quaternion")) {
        Quaternion *q = (Quaternion *) SvIV((SV *) SvRV(ST(1)));
        if (items > 2) relativeTo = (Ogre::Node::TransformSpace)SvIV(ST(2));

        THIS->rotate(*q, relativeTo);
    }
    else {
        croak("%s", usage);
    }

Matrix3 *
Node::getLocalAxes()
  CODE:
    RETVAL = new Matrix3;
    *RETVAL = THIS->getLocalAxes();
  OUTPUT:
    RETVAL

Node *
Node::createChild(...)
  PREINIT:
    char *usage = "Usage: Ogre::Node::createChild(THIS [, name] [, trans, rot])\n";
  CODE:
    if (items == 1) {
        RETVAL = THIS->createChild();
    }
    // Node * Node::createChild(const Vector3 &translate=Vector3::ZERO, const Quaternion &rotate=Quaternion::IDENTITY)
    else if (sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::Vector3")) {
        Vector3 *translate = (Vector3 *) SvIV((SV *) SvRV(ST(1)));

        if (items == 2) {
            RETVAL = THIS->createChild(*translate);
        }
        else if (sv_isobject(ST(2)) && sv_derived_from(ST(2), "Ogre::Quaternion")) {
            Quaternion *rotate = (Quaternion *) SvIV((SV *) SvRV(ST(2)));
            RETVAL = THIS->createChild(*translate, *rotate);
        }
        else {
            croak("%s", usage);
        }
    }
    // Node * Node::createChild(String name, const Vector3 &translate=Vector3::ZERO, const Quaternion &rotate=Quaternion::IDENTITY)
    else {
        char * tmpchr = (char *) SvPV_nolen(ST(1));
        String name = tmpchr;

        if (items == 2) {
            RETVAL = THIS->createChild(name);
        }
        else if (items > 2 && sv_isobject(ST(2)) && sv_derived_from(ST(2), "Ogre::Vector3")) {
            Vector3 *translate = (Vector3 *) SvIV((SV *) SvRV(ST(2)));

            if (items > 3 && sv_isobject(ST(3)) && sv_derived_from(ST(3), "Ogre::Quaternion")) {
                Quaternion *rotate = (Quaternion *) SvIV((SV *) SvRV(ST(3)));
                RETVAL = THIS->createChild(name, *translate, *rotate);
            }
            else {
                RETVAL = THIS->createChild(name, *translate);
            }
        }
        else {
            croak("%s", usage);
        }
    }
  OUTPUT:
    RETVAL

void
Node::addChild(child)
    Node * child

unsigned short
Node::numChildren()

Node *
Node::getChild(...)
  CODE:
    // Node * Node::getChild(unsigned short index)
    if (looks_like_number(ST(1))) {
        RETVAL = THIS->getChild((unsigned short)SvUV(ST(1)));
    }
    // Node * Node::getChild(String name)
    else {
        char * tmpchr = (char *) SvPV_nolen(ST(1));
        String name = tmpchr;
        RETVAL = THIS->getChild(name);
    }
  OUTPUT:
    RETVAL

Node *
Node::removeChild(...)
  CODE:
    // Node * Node::removeChild(Node *child)
    if (sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::Node")) {
        Node *child = (Node *) SvIV((SV *) SvRV(ST(1)));
        RETVAL = THIS->removeChild(child);
    }
    // Node * Node::removeChild(unsigned short index)
    else if (looks_like_number(ST(1))) {
        RETVAL = THIS->removeChild((unsigned short)SvUV(ST(1)));
    }
    // Node * Node::removeChild(String name)
    else {
        char * tmpchr = (char *) SvPV_nolen(ST(1));
        String name = tmpchr;
        RETVAL = THIS->removeChild(name);
    }
  OUTPUT:
    RETVAL

void
Node::removeAllChildren()

## ChildNodeIterator Node::getChildIterator()
## ConstChildNodeIterator Node::getChildIterator()

## void Node::setListener(Listener *listener)
## Listener * Node::getListener()

##Quaternion *
##Node::getWorldOrientation()
##  CODE:
##    RETVAL = new Quaternion;
##    *RETVAL = THIS->getWorldOrientation();
##  OUTPUT:
##    RETVAL
##
##Vector3 *
##Node::getWorldPosition()
##  CODE:
##    RETVAL = new Vector3;
##    *RETVAL = THIS->getWorldPosition();
##  OUTPUT:
##    RETVAL

## Ogre 1.6 API change
Quaternion *
Node::_getDerivedOrientation()
  CODE:
    RETVAL = new Quaternion;
    *RETVAL = THIS->_getDerivedOrientation();
  OUTPUT:
    RETVAL

Vector3 *
Node::_getDerivedPosition()
  CODE:
    RETVAL = new Vector3;
    *RETVAL = THIS->_getDerivedPosition();
  OUTPUT:
    RETVAL



void
Node::setInitialState()

void
Node::resetToInitialState()

Vector3 *
Node::getInitialPosition()
  CODE:
    RETVAL = new Vector3;
    *RETVAL = THIS->getInitialPosition();
  OUTPUT:
    RETVAL

Quaternion *
Node::getInitialOrientation()
  CODE:
    RETVAL = new Quaternion;
    *RETVAL = THIS->getInitialOrientation();
  OUTPUT:
    RETVAL

Vector3 *
Node::getInitialScale()
  CODE:
    RETVAL = new Vector3;
    *RETVAL = THIS->getInitialScale();
  OUTPUT:
    RETVAL

Real
Node::getSquaredViewDepth(const Camera *cam)

void
Node::needUpdate(bool forceParentUpdate=false)

void
Node::requestUpdate(Node *child, bool forceParentUpdate=false)

void
Node::cancelUpdate(Node *child)

## const LightList & Node::getLights()
