MODULE = Ogre     PACKAGE = Ogre::Technique

### note: Material, Technique, and Pass have a lot of methods in common

bool
Technique::isSupported()

Pass *
Technique::createPass()

Pass *
Technique::getPass(...)
  CODE:
    // xxx: I duplicate this in several places... but how do I factor it out?
    if (looks_like_number(ST(1))) {
        unsigned short index = (unsigned short)SvUV(ST(1));
        RETVAL = THIS->getPass(index);
    }
    else {
        char * xstmpchr = (char *) SvPV_nolen(ST(1));
        String name = xstmpchr;
        RETVAL = THIS->getPass(name);
    }
  OUTPUT:
    RETVAL

unsigned short
Technique::getNumPasses()

void
Technique::removePass(unsigned short index)

void
Technique::removeAllPasses()

bool
Technique::movePass(unsigned short sourceIndex, unsigned short destinationIndex)

## const PassIterator Technique::getPassIterator()
## const IlluminationPassIterator Technique::getIlluminationPassIterator()

Material *
Technique::getParent()

String
Technique::getResourceGroup()

bool
Technique::isTransparent()

bool
Technique::isLoaded()

void
Technique::setPointSize(Real ps)

void
Technique::setAmbient(...)
  CODE:
    // xxx: also duplicated this in several places (also Light.xs)
    if (items == 2 && sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::Colour")) {
        ColourValue *colour = (ColourValue *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN
        THIS->setAmbient(*colour);
    }
    else if (items == 4) {
        THIS->setAmbient((Real)SvNV(ST(1)), (Real)SvNV(ST(2)), (Real)SvNV(ST(3)));
    }
    else {
        croak("Usage: Ogre::Technique::setAmbient(THIS, col) or (THIS, r, g, b)\n");
    }

void
Technique::setDiffuse(...)
  CODE:
    // xxx: also duplicated this in several places (also Light.xs)
    if (items == 2 && sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::Colour")) {
        ColourValue *colour = (ColourValue *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN
        THIS->setDiffuse(*colour);
    }
    else if (items == 5) {
        THIS->setDiffuse((Real)SvNV(ST(1)), (Real)SvNV(ST(2)), (Real)SvNV(ST(3)), (Real)SvNV(ST(4)));
    }
    else {
        croak("Usage: Ogre::Technique::setDiffuse(THIS, col) or (THIS, r, g, b, a)\n");
    }

void
Technique::setSpecular(...)
  CODE:
    // xxx: also duplicated this in several places (also Light.xs)
    if (items == 2 && sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::Colour")) {
        ColourValue *colour = (ColourValue *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN
        THIS->setSpecular(*colour);
    }
    else if (items == 5) {
        THIS->setSpecular((Real)SvNV(ST(1)), (Real)SvNV(ST(2)), (Real)SvNV(ST(3)), (Real)SvNV(ST(4)));
    }
    else {
        croak("Usage: Ogre::Technique::setSpecular(THIS, col) or (THIS, r, g, b, a)\n");
    }

void
Technique::setShininess(Real val)

void
Technique::setSelfIllumination(...)
  CODE:
    // xxx: also duplicated this in several places (also Light.xs)
    if (items == 2 && sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::Colour")) {
        ColourValue *colour = (ColourValue *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN
        THIS->setSelfIllumination(*colour);
    }
    else if (items == 4) {
        THIS->setSelfIllumination((Real)SvNV(ST(1)), (Real)SvNV(ST(2)), (Real)SvNV(ST(3)));
    }
    else {
        croak("Usage: Ogre::Technique::setSelfIllumination(THIS, col) or (THIS, r, g, b)\n");
    }

void
Technique::setDepthCheckEnabled(bool enabled)

void
Technique::setDepthWriteEnabled(bool enabled)

void
Technique::setDepthFunction(int func)
  C_ARGS:
    (CompareFunction)func

void
Technique::setColourWriteEnabled(bool enabled)

void
Technique::setCullingMode(int mode)
  C_ARGS:
    (CullingMode)mode

void
Technique::setManualCullingMode(int mode)
  C_ARGS:
    (ManualCullingMode)mode

void
Technique::setLightingEnabled(bool enabled)

void
Technique::setShadingMode(int mode)
  C_ARGS:
    (ShadeOptions)mode

### a lot of these methods are identical to those in Material...
void
Technique::setFog(bool overrideScene, int mode=FOG_NONE, const ColourValue *colour=&ColourValue::White, Real expDensity=0.001, Real linearStart=0.0, Real linearEnd=1.0)
  C_ARGS:
    overrideScene, (FogMode)mode, *colour, expDensity, linearStart, linearEnd

void
Technique::setDepthBias(float constantBias, float slopeScaleBias)

void
Technique::setTextureFiltering(int filterType)
  C_ARGS:
    (TextureFilterOptions)filterType

void
Technique::setTextureAnisotropy(unsigned int maxAniso)

void
Technique::setSceneBlending(...)
  CODE:
    if (items == 2) {
        THIS->setSceneBlending((SceneBlendType)SvIV(ST(1)));
    }
    else if (items == 3) {
        THIS->setSceneBlending((SceneBlendFactor)SvIV(ST(1)), (SceneBlendFactor)SvIV(ST(2)));
    }

void
Technique::setLodIndex(unsigned short index)

unsigned short
Technique::getLodIndex()

void
Technique::setSchemeName(String schemeName)

String
Technique::getSchemeName()

bool
Technique::isDepthWriteEnabled()

bool
Technique::isDepthCheckEnabled()

bool
Technique::hasColourWriteDisabled()

void
Technique::setName(String name)

String
Technique::getName()

## bool Technique::applyTextureAliases(const AliasTextureNamePairList &aliasList, const bool apply=true)
