MODULE = Ogre     PACKAGE = Ogre::RenderSystemCapabilities

void
RenderSystemCapabilities::setNumWorldMatrices(unsigned short num)

void
RenderSystemCapabilities::setNumTextureUnits(unsigned short num)

void
RenderSystemCapabilities::setStencilBufferBitDepth(unsigned short num)

void
RenderSystemCapabilities::setNumVertexBlendMatrices(unsigned short num)

void
RenderSystemCapabilities::setNumMultiRenderTargets(unsigned short num)

unsigned short
RenderSystemCapabilities::getNumWorldMatrices()

unsigned short
RenderSystemCapabilities::getNumTextureUnits()

unsigned short
RenderSystemCapabilities::getStencilBufferBitDepth()

unsigned short
RenderSystemCapabilities::getNumVertexBlendMatrices()

unsigned short
RenderSystemCapabilities::getNumMultiRenderTargets()

void
RenderSystemCapabilities::setCapability(int c)
  C_ARGS:
    (Capabilities)c

bool
RenderSystemCapabilities::hasCapability(int c)
  C_ARGS:
    (Capabilities)c

unsigned short
RenderSystemCapabilities::getVertexProgramConstantFloatCount()

unsigned short
RenderSystemCapabilities::getVertexProgramConstantIntCount()

unsigned short
RenderSystemCapabilities::getVertexProgramConstantBoolCount()

unsigned short
RenderSystemCapabilities::getFragmentProgramConstantFloatCount()

unsigned short
RenderSystemCapabilities::getFragmentProgramConstantIntCount()

unsigned short
RenderSystemCapabilities::getFragmentProgramConstantBoolCount()

##String
##RenderSystemCapabilities::getMaxVertexProgramVersion()
##
##void
##RenderSystemCapabilities::setMaxVertexProgramVersion(String ver)
##
##String
##RenderSystemCapabilities::getMaxFragmentProgramVersion()
##
##void
##RenderSystemCapabilities::setMaxFragmentProgramVersion(String ver)

void
RenderSystemCapabilities::setVertexProgramConstantFloatCount(unsigned short c)

void
RenderSystemCapabilities::setVertexProgramConstantIntCount(unsigned short c)

void
RenderSystemCapabilities::setVertexProgramConstantBoolCount(unsigned short c)

void
RenderSystemCapabilities::setFragmentProgramConstantFloatCount(unsigned short c)

void
RenderSystemCapabilities::setFragmentProgramConstantIntCount(unsigned short c)

void
RenderSystemCapabilities::setFragmentProgramConstantBoolCount(unsigned short c)

void
RenderSystemCapabilities::setMaxPointSize(Real s)

Real
RenderSystemCapabilities::getMaxPointSize()

void
RenderSystemCapabilities::setNonPOW2TexturesLimited(bool l)

bool
RenderSystemCapabilities::getNonPOW2TexturesLimited()

void
RenderSystemCapabilities::setNumVertexTextureUnits(unsigned short n)

unsigned short
RenderSystemCapabilities::getNumVertexTextureUnits()

void
RenderSystemCapabilities::setVertexTextureUnitsShared(bool shared)

bool
RenderSystemCapabilities::getVertexTextureUnitsShared()

void
RenderSystemCapabilities::log(Log *pLog)
