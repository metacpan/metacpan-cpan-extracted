MODULE = Ogre     PACKAGE = Ogre::Light

## I finally figured out why DESTROY methods
## cause segfaults; for objects like this (a MovableObject)
## that are managed by SceneManager,
## there is a method destroyAllMovableObjects being called,
## and this was implicitly calling "delete THIS" here
## before that. But if I destroyLight here, basically it seems
## to get destroyed as soon as the Perl object goes out of scope,
## which is rarely what we want... So you have to just create
## these through SceneManager instead of using ->new.
##Light *
##Light::new(name)
##    String  name
##
##void
##Light::DESTROY()
##  CODE:
##    SceneManager *sm = THIS->_getManager();
##    if (sm)
##      sm->destroyLight(THIS);

void
Light::setType(type)
    int  type
  C_ARGS:
    (Ogre::Light::LightTypes)type

int
Light::getType()

void
Light::setDiffuseColour(...)
  CODE:
    if (items == 2 && sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::ColourValue")) {
        ColourValue *colour = (ColourValue *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN
        THIS->setDiffuseColour(*colour);
    }
    else if (items == 4) {
        THIS->setDiffuseColour((Real)SvNV(ST(1)), (Real)SvNV(ST(2)), (Real)SvNV(ST(3)));
    }
    else {
        croak("Usage: Ogre::Light::setDiffuseColour(THIS, col) or (THIS, r, g, b)\n");
    }

ColourValue *
Light::getDiffuseColour()
  CODE:
    RETVAL = new ColourValue;
    *RETVAL = THIS->getDiffuseColour();
  OUTPUT:
    RETVAL

void
Light::setSpecularColour(...)
  CODE:
    if (items == 2 && sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::ColourValue")) {
        ColourValue *colour = (ColourValue *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN
        THIS->setSpecularColour(*colour);
    }
    else if (items == 4) {
        THIS->setSpecularColour((Real)SvNV(ST(1)), (Real)SvNV(ST(2)), (Real)SvNV(ST(3)));
    }
    else {
        croak("Usage: Ogre::Light::setSpecularColour(THIS, col) or (THIS, r, g, b)\n");
    }

ColourValue *
Light::getSpecularColour()
  CODE:
    RETVAL = new ColourValue;
    *RETVAL = THIS->getSpecularColour();
  OUTPUT:
    RETVAL

void
Light::setAttenuation(Real range, Real constant, Real linear, Real quadratic)

Real
Light::getAttenuationRange()

Real
Light::getAttenuationConstant()

Real
Light::getAttenuationLinear()

Real
Light::getAttenuationQuadric()

void
Light::setPosition(...)
  CODE:
    if (items == 2 && sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::Vector3")) {
        Vector3 *vec = (Vector3 *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN
        THIS->setPosition(*vec);
    }
    else if (items == 4) {
        THIS->setPosition((Real)SvNV(ST(1)), (Real)SvNV(ST(2)), (Real)SvNV(ST(3)));
    }
    else {
        croak("Usage: Ogre::Light::setPosition(THIS, vec) or (THIS, x, y, z)\n");
    }

Vector3 *
Light::getPosition()
  CODE:
    RETVAL = new Vector3;
    *RETVAL = THIS->getPosition();
  OUTPUT:
    RETVAL

void
Light::setDirection(...)
  CODE:
    if (items == 2 && sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::Vector3")) {
        Vector3 *vec = (Vector3 *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN
        THIS->setDirection(*vec);
    }
    else if (items == 4) {
        THIS->setDirection((Real)SvNV(ST(1)), (Real)SvNV(ST(2)), (Real)SvNV(ST(3)));
    }
    else {
        croak("Usage: Ogre::Light::setDirection(THIS, vec) or (THIS, x, y, z)\n");
    }

Vector3 *
Light::getDirection()
  CODE:
    RETVAL = new Vector3;
    *RETVAL = THIS->getDirection();
  OUTPUT:
    RETVAL

void
Light::setSpotlightRange(innerAngle, outerAngle, falloff=1.0)
    DegRad * innerAngle
    DegRad * outerAngle
    Real  falloff
  C_ARGS:
    *innerAngle, *outerAngle, falloff

Radian *
Light::getSpotlightInnerAngle()
  CODE:
    RETVAL = new Radian;
    *RETVAL = THIS->getSpotlightInnerAngle();
  OUTPUT:
    RETVAL

Radian *
Light::getSpotlightOuterAngle()
  CODE:
    RETVAL = new Radian;
    *RETVAL = THIS->getSpotlightOuterAngle();
  OUTPUT:
    RETVAL

Real
Light::getSpotlightFalloff()

void
Light::setSpotlightInnerAngle(val)
    DegRad * val
  C_ARGS:
    *val

void
Light::setSpotlightOuterAngle(val)
    DegRad * val
  C_ARGS:
    *val

void
Light::setSpotlightFalloff(Real val)

void
Light::setPowerScale(Real power)

Real
Light::getPowerScale()

AxisAlignedBox *
Light::getBoundingBox()
  CODE:
    RETVAL = new AxisAlignedBox;
    *RETVAL = THIS->getBoundingBox();
  OUTPUT:
    RETVAL

String
Light::getMovableType()

Vector3 *
Light::getDerivedPosition()
  CODE:
    RETVAL = new Vector3;
    *RETVAL = THIS->getDerivedPosition();
  OUTPUT:
    RETVAL

Vector3 *
Light::getDerivedDirection()
  CODE:
    RETVAL = new Vector3;
    *RETVAL = THIS->getDerivedDirection();
  OUTPUT:
    RETVAL

void
Light::setVisible(bool visible)

Real
Light::getBoundingRadius()

## Vector4 getAs4DVector()

uint32
Light::getTypeFlags()

AnimableValue *
Light::createAnimableValue(valueName)
    String valueName
  CODE:
    RETVAL = THIS->createAnimableValue(valueName).getPointer();
  OUTPUT:
    RETVAL

## void Light::setCustomShadowCameraSetup(const ShadowCameraSetupPtr &customShadowSetup)

void
Light::resetCustomShadowCameraSetup()

## const ShadowCameraSetupPtr & getCustomShadowCameraSetup()

