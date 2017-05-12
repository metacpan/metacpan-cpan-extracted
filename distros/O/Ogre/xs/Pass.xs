MODULE = Ogre     PACKAGE = Ogre::Pass

### note: Material, Technique, and Pass have a lot of methods in common

bool
Pass::isProgrammable()

bool
Pass::hasVertexProgram()

bool
Pass::hasFragmentProgram()

bool
Pass::hasShadowCasterVertexProgram()

bool
Pass::hasShadowReceiverVertexProgram()

bool
Pass::hasShadowReceiverFragmentProgram()

unsigned short
Pass::getIndex()

void
Pass::setName(String name)

String
Pass::getName()

void
Pass::setAmbient(...)
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
        croak("Usage: Ogre::Pass::setAmbient(THIS, col) or (THIS, r, g, b)\n");
    }

void
Pass::setDiffuse(...)
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
        croak("Usage: Ogre::Pass::setDiffuse(THIS, col) or (THIS, r, g, b, a)\n");
    }

void
Pass::setSpecular(...)
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
        croak("Usage: Ogre::Pass::setSpecular(THIS, col) or (THIS, r, g, b, a)\n");
    }

void
Pass::setShininess(Real val)

void
Pass::setSelfIllumination(...)
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
        croak("Usage: Ogre::Pass::setSelfIllumination(THIS, col) or (THIS, r, g, b)\n");
    }

void
Pass::setVertexColourTracking(int tracking)
  C_ARGS:
    (TrackVertexColourType)tracking

Real
Pass::getPointSize()

void
Pass::setPointSize(Real ps)

void
Pass::setPointSpritesEnabled(bool enabled)

bool
Pass::getPointSpritesEnabled()

void
Pass::setPointAttenuation(bool enabled, Real constant=0.0f, Real linear=1.0f, Real quadratic=0.0f)

bool
Pass::isPointAttenuationEnabled()

Real
Pass::getPointAttenuationConstant()

Real
Pass::getPointAttenuationLinear()

Real
Pass::getPointAttenuationQuadratic()

void
Pass::setPointMinSize(Real min)

Real
Pass::getPointMinSize()

void
Pass::setPointMaxSize(Real max)

Real
Pass::getPointMaxSize()

ColourValue *
Pass::getAmbient()
  CODE:
    RETVAL = new ColourValue;
    *RETVAL = THIS->getAmbient();
  OUTPUT:
    RETVAL

ColourValue *
Pass::getDiffuse()
  CODE:
    RETVAL = new ColourValue;
    *RETVAL = THIS->getDiffuse();
  OUTPUT:
    RETVAL

ColourValue *
Pass::getSpecular()
  CODE:
    RETVAL = new ColourValue;
    *RETVAL = THIS->getSpecular();
  OUTPUT:
    RETVAL


ColourValue *
Pass::getSelfIllumination()
  CODE:
    RETVAL = new ColourValue;
    *RETVAL = THIS->getSelfIllumination();
  OUTPUT:
    RETVAL

Real
Pass::getShininess()

int
Pass::getVertexColourTracking()

TextureUnitState *
Pass::createTextureUnitState(...)
  CODE:
    if (items == 1) {
        RETVAL = THIS->createTextureUnitState();
    }
    else if (items >= 2) {
        char * xstmpchr = (char *) SvPV_nolen(ST(1));
        String textureName = xstmpchr;

        unsigned short texCoordSet = 0;
        if (items == 3) texCoordSet = (unsigned short)SvUV(ST(2));

        RETVAL = THIS->createTextureUnitState(textureName, texCoordSet);
    }
  OUTPUT:
    RETVAL

void
Pass::addTextureUnitState(TextureUnitState *state)

TextureUnitState *
Pass::getTextureUnitState(...)
  CODE:
    // xxx: I duplicate this in several places... but how do I factor it out?
    if (looks_like_number(ST(1))) {
        unsigned short index = (unsigned short)SvUV(ST(1));
        RETVAL = THIS->getTextureUnitState(index);
    }
    else {
        char * xstmpchr = (char *) SvPV_nolen(ST(1));
        String name = xstmpchr;
        RETVAL = THIS->getTextureUnitState(name);
    }
  OUTPUT:
    RETVAL

unsigned short
Pass::getTextureUnitStateIndex(const TextureUnitState *state)

## TextureUnitStateIterator Pass::getTextureUnitStateIterator()
## ConstTextureUnitStateIterator Pass::getTextureUnitStateIterator()

void
Pass::removeTextureUnitState(unsigned short index)

void
Pass::removeAllTextureUnitStates()

unsigned short
Pass::getNumTextureUnitStates()

void
Pass::setSceneBlending(...)
  CODE:
    if (items == 2) {
        THIS->setSceneBlending((SceneBlendType)SvIV(ST(1)));
    }
    else if (items == 3) {
        THIS->setSceneBlending((SceneBlendFactor)SvIV(ST(1)), (SceneBlendFactor)SvIV(ST(2)));
    }

int
Pass::getSourceBlendFactor()

int
Pass::getDestBlendFactor()

bool
Pass::isTransparent()

void
Pass::setDepthCheckEnabled(bool enabled)

bool
Pass::getDepthCheckEnabled()

void
Pass::setDepthWriteEnabled(bool enabled)

bool
Pass::getDepthWriteEnabled()

void
Pass::setDepthFunction(int func)
  C_ARGS:
    (CompareFunction)func

int
Pass::getDepthFunction()

void
Pass::setColourWriteEnabled(bool enabled)

bool
Pass::getColourWriteEnabled()

void
Pass::setCullingMode(int mode)
  C_ARGS:
    (CullingMode)mode

int
Pass::getCullingMode()

void
Pass::setManualCullingMode(int mode)
  C_ARGS:
    (ManualCullingMode)mode

int
Pass::getManualCullingMode()

void
Pass::setLightingEnabled(bool enabled)

bool
Pass::getLightingEnabled()

void
Pass::setMaxSimultaneousLights(unsigned short maxLights)

unsigned short
Pass::getMaxSimultaneousLights()

void
Pass::setStartLight(unsigned short startLight)

unsigned short
Pass::getStartLight()

void
Pass::setShadingMode(int mode)
  C_ARGS:
    (ShadeOptions)mode

int
Pass::getShadingMode()

void
Pass::setPolygonMode(int mode)
  C_ARGS:
    (PolygonMode)mode

int
Pass::getPolygonMode()

void
Pass::setFog(bool overrideScene, int mode=FOG_NONE, const ColourValue *colour=&ColourValue::White, Real expDensity=0.001, Real linearStart=0.0, Real linearEnd=1.0)
  C_ARGS:
    overrideScene, (FogMode)mode, *colour, expDensity, linearStart, linearEnd

bool
Pass::getFogOverride()

int
Pass::getFogMode()

ColourValue *
Pass::getFogColour()
  CODE:
    RETVAL = new ColourValue;
    *RETVAL = THIS->getFogColour();
  OUTPUT:
    RETVAL

Real
Pass::getFogStart()

Real
Pass::getFogEnd()

Real
Pass::getFogDensity()

void
Pass::setDepthBias(float constantBias, float slopeScaleBias=0.0f)

float
Pass::getDepthBiasConstant()

float
Pass::getDepthBiasSlopeScale()

void
Pass::setAlphaRejectSettings(int func, unsigned char value)
  C_ARGS:
    (CompareFunction)func, value

void
Pass::setAlphaRejectFunction(int func)
  C_ARGS:
    (CompareFunction)func

void
Pass::setAlphaRejectValue(unsigned char val)

int
Pass::getAlphaRejectFunction()

unsigned char
Pass::getAlphaRejectValue()

void
Pass::setIteratePerLight(bool enabled, bool onlyForOneLightType=true, int lightType=Light::LT_POINT)
  C_ARGS:
    enabled, onlyForOneLightType, (Light::LightTypes) lightType

bool
Pass::getIteratePerLight()

bool
Pass::getRunOnlyForOneLightType()

int
Pass::getOnlyLightType()

void
Pass::setLightCountPerIteration(unsigned short c)

unsigned short
Pass::getLightCountPerIteration()

Technique *
Pass::getParent()

String
Pass::getResourceGroup()

# note: vertex program means "GpuProgram"
void
Pass::setVertexProgram(String name, bool resetParams=true)

void
Pass::setVertexProgramParameters(GpuProgramParameters * params)
  CODE:
    GpuProgramParametersSharedPtr paramsptr = GpuProgramParametersSharedPtr(params);
    THIS->setVertexProgramParameters(paramsptr);

String
Pass::getVertexProgramName()

GpuProgramParameters *
Pass::getVertexProgramParameters()
  CODE:
    RETVAL = THIS->getVertexProgramParameters().getPointer();
  OUTPUT:
    RETVAL

GpuProgram *
Pass::getVertexProgram()
  CODE:
    RETVAL = THIS->getVertexProgram().getPointer();
  OUTPUT:
    RETVAL

void
Pass::setShadowCasterVertexProgram(String name)

void
Pass::setShadowCasterVertexProgramParameters(GpuProgramParameters *params)
  CODE:
    GpuProgramParametersSharedPtr paramsptr = GpuProgramParametersSharedPtr(params);
    THIS->setShadowCasterVertexProgramParameters(paramsptr);

String
Pass::getShadowCasterVertexProgramName()

GpuProgramParameters *
Pass::getShadowCasterVertexProgramParameters()
  CODE:
    RETVAL = THIS->getShadowCasterVertexProgramParameters().getPointer();
  OUTPUT:
    RETVAL

GpuProgram *
Pass::getShadowCasterVertexProgram()
  CODE:
    RETVAL = THIS->getShadowCasterVertexProgram().getPointer();
  OUTPUT:
    RETVAL

void
Pass::setShadowReceiverVertexProgram(String name)

void
Pass::setShadowReceiverVertexProgramParameters(GpuProgramParameters *params)
  CODE:
    GpuProgramParametersSharedPtr paramsptr = GpuProgramParametersSharedPtr(params);
    THIS->setShadowReceiverVertexProgramParameters(paramsptr);

void
Pass::setShadowReceiverFragmentProgram(String name)

void
Pass::setShadowReceiverFragmentProgramParameters(GpuProgramParameters *params)
  CODE:
    GpuProgramParametersSharedPtr paramsptr = GpuProgramParametersSharedPtr(params);
    THIS->setShadowReceiverFragmentProgramParameters(paramsptr);

String
Pass::getShadowReceiverVertexProgramName()

GpuProgramParameters *
Pass::getShadowReceiverVertexProgramParameters()
  CODE:
    RETVAL = THIS->getShadowReceiverVertexProgramParameters().getPointer();
  OUTPUT:
    RETVAL

GpuProgram *
Pass::getShadowReceiverVertexProgram()
  CODE:
    RETVAL = THIS->getShadowReceiverVertexProgram().getPointer();
  OUTPUT:
    RETVAL

String
Pass::getShadowReceiverFragmentProgramName()

GpuProgramParameters *
Pass::getShadowReceiverFragmentProgramParameters()
  CODE:
    RETVAL = THIS->getShadowReceiverFragmentProgramParameters().getPointer();
  OUTPUT:
    RETVAL

GpuProgram *
Pass::getShadowReceiverFragmentProgram()
  CODE:
    RETVAL = THIS->getShadowReceiverFragmentProgram().getPointer();
  OUTPUT:
    RETVAL

void
Pass::setFragmentProgram(String name, bool resetParams=true)

void
Pass::setFragmentProgramParameters(GpuProgramParameters *params)
  CODE:
    GpuProgramParametersSharedPtr paramsptr = GpuProgramParametersSharedPtr(params);
    THIS->setFragmentProgramParameters(paramsptr);

String
Pass::getFragmentProgramName()

GpuProgramParameters *
Pass::getFragmentProgramParameters()
  CODE:
    RETVAL = THIS->getFragmentProgramParameters().getPointer();
  OUTPUT:
    RETVAL

GpuProgram *
Pass::getFragmentProgram()
  CODE:
    RETVAL = THIS->getFragmentProgram().getPointer();
  OUTPUT:
    RETVAL

bool
Pass::isLoaded()

uint32
Pass::getHash()

void
Pass::setTextureFiltering(int filterType)
  C_ARGS:
    (TextureFilterOptions)filterType

void
Pass::setTextureAnisotropy(unsigned int maxAniso)

void
Pass::queueForDeletion()

bool
Pass::isAmbientOnly()

void
Pass::setPassIterationCount(size_t count)

size_t
Pass::getPassIterationCount()

## bool Pass::applyTextureAliases(const AliasTextureNamePairList &aliasList, const bool apply=true)
