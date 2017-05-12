MODULE = Ogre     PACKAGE = Ogre::Material

### note: Material, Technique, and Pass have a lot of methods in common

bool
Material::isTransparent()

void
Material::setReceiveShadows(bool enabled)

bool
Material::getReceiveShadows()

void
Material::setTransparencyCastsShadows(bool enabled)

bool
Material::getTransparencyCastsShadows()

Technique *
Material::createTechnique()

Technique *
Material::getTechnique(...)
  CODE:
    if (looks_like_number(ST(1))) {
        unsigned short index = (unsigned short)SvUV(ST(1));
        RETVAL = THIS->getTechnique(index);
    }
    else {
        char * xstmpchr = (char *) SvPV_nolen(ST(1));
        String name = xstmpchr;
        RETVAL = THIS->getTechnique(name);
    }
  OUTPUT:
    RETVAL

unsigned short
Material::getNumTechniques()

void
Material::removeTechnique(unsigned short index)

void
Material::removeAllTechniques()

## TechniqueIterator Material::getTechniqueIterator()

## TechniqueIterator Material::getSupportedTechniqueIterator()

Technique *
Material::getSupportedTechnique(unsigned short index)

unsigned short
Material::getNumSupportedTechniques()

String
Material::getUnsupportedTechniquesExplanation()

unsigned short
Material::getNumLodLevels(...)
  CODE:
    // xxx: I duplicate this in several places... but how do I factor it out?
    if (looks_like_number(ST(1))) {
        unsigned short schemeIndex = (unsigned short)SvUV(ST(1));
        RETVAL = THIS->getNumLodLevels(schemeIndex);
    }
    else {
        char * xstmpchr = (char *) SvPV_nolen(ST(1));
        String schemeName = xstmpchr;
        RETVAL = THIS->getNumLodLevels(schemeName);
    }
  OUTPUT:
    RETVAL

Technique *
Material::getBestTechnique(unsigned short lodIndex=0)

Material *
Material::clone(String newName, bool changeGroup=false, String newGroup=StringUtil::BLANK)
  CODE:
    RETVAL = THIS->clone(newName, changeGroup, (const String)newGroup).getPointer();
  OUTPUT:
    RETVAL

void
Material::copyDetailsTo(Material *mat)
  CODE:
    MaterialPtr matptr = MaterialPtr(mat);
    THIS->copyDetailsTo(matptr);

void
Material::compile(bool autoManageTextureUnits=true)

void
Material::setPointSize(Real ps)

void
Material::setAmbient(...)
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
        croak("Usage: Ogre::Material::setAmbient(THIS, col) or (THIS, r, g, b)\n");
    }

void
Material::setDiffuse(...)
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
        croak("Usage: Ogre::Material::setDiffuse(THIS, col) or (THIS, r, g, b, a)\n");
    }

void
Material::setSpecular(...)
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
        croak("Usage: Ogre::Material::setSpecular(THIS, col) or (THIS, r, g, b, a)\n");
    }

void
Material::setShininess(Real val)

void
Material::setSelfIllumination(...)
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
        croak("Usage: Ogre::Material::setSelfIllumination(THIS, col) or (THIS, r, g, b)\n");
    }

void
Material::setDepthCheckEnabled(bool enabled)

void
Material::setDepthWriteEnabled(bool enabled)

void
Material::setDepthFunction(int func)
  C_ARGS:
    (CompareFunction)func

void
Material::setColourWriteEnabled(bool enabled)

void
Material::setCullingMode(int mode)
  C_ARGS:
    (CullingMode)mode

void
Material::setManualCullingMode(int mode)
  C_ARGS:
    (ManualCullingMode)mode

void
Material::setLightingEnabled(bool enabled)

void
Material::setShadingMode(int mode)
  C_ARGS:
    (ShadeOptions)mode

void
Material::setFog(bool overrideScene, int mode=FOG_NONE, const ColourValue *colour=&ColourValue::White, Real expDensity=0.001, Real linearStart=0.0, Real linearEnd=1.0)
  C_ARGS:
    overrideScene, (FogMode)mode, *colour, expDensity, linearStart, linearEnd

# why not Real instead of float ?
void
Material::setDepthBias(float constantBias, float slopeScaleBias)

void
Material::setTextureFiltering(int filterType)
  C_ARGS:
    (TextureFilterOptions)filterType

void
Material::setTextureAnisotropy(int maxAniso)

void
Material::setSceneBlending(...)
  CODE:
    if (items == 2) {
        THIS->setSceneBlending((SceneBlendType)SvIV(ST(1)));
    }
    else if (items == 3) {
        THIS->setSceneBlending((SceneBlendFactor)SvIV(ST(1)), (SceneBlendFactor)SvIV(ST(2)));
    }

## void Material::setLodLevels(const LodDistanceList &lodDistances)

## LodDistanceIterator Material::getLodDistanceIterator()

unsigned short
Material::getLodIndex(Real d)

void
Material::touch()

## bool Material::applyTextureAliases(const AliasTextureNamePairList &aliasList, const bool apply=true)

bool
Material::getCompilationRequired()
