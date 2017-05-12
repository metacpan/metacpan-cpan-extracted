MODULE = Ogre     PACKAGE = Ogre::RenderSystem


String
RenderSystem::getName()

## ConfigOptionMap & RenderSystem::getConfigOptions()

void
RenderSystem::setConfigOption(name, value)
    String  name
    String  value

HardwareOcclusionQuery *
RenderSystem::createHardwareOcclusionQuery()

void
RenderSystem::destroyHardwareOcclusionQuery(hq)
    HardwareOcclusionQuery * hq

String
RenderSystem::validateConfigOptions()

void
RenderSystem::reinitialise()

void
RenderSystem::shutdown()

## why are these not Real ?
void
RenderSystem::setAmbientLight(float r, float g, float b)

void
RenderSystem::setShadingType(int so)
  C_ARGS:
    (ShadeOptions)so

void
RenderSystem::setLightingEnabled(bool enabled)

void
RenderSystem::setWBufferEnabled(bool enabled)

bool
RenderSystem::getWBufferEnabled()

MultiRenderTarget *
RenderSystem::createMultiRenderTarget(name)
    String  name

void
RenderSystem::destroyRenderWindow(name)
    String  name

void
RenderSystem::destroyRenderTexture(name)
    String  name

void
RenderSystem::destroyRenderTarget(name)
    String  name

void
RenderSystem::attachRenderTarget(target)
    RenderTarget * target
  C_ARGS:
    *target

RenderTarget *
RenderSystem::getRenderTarget(name)
    String  name

RenderTarget *
RenderSystem::detachRenderTarget(name)
    String  name

## RenderTargetIterator RenderSystem::getRenderTargetIterator()

String
RenderSystem::getErrorDescription(long errorNumber)

void
RenderSystem::setWaitForVerticalBlank(bool enabled)

bool
RenderSystem::getWaitForVerticalBlank()

## void RenderSystem::convertColourValue(const ColourValue &colour, uint32 *pDest)

int
RenderSystem::getColourVertexElementType()

void
RenderSystem::setStencilCheckEnabled(bool enabled)

void
RenderSystem::setStencilBufferParams(int func=CMPF_ALWAYS_PASS, uint32 refValue, uint32 mask=0xFFFFFFFF, int stencilFailOp=SOP_KEEP, int depthFailOp=SOP_KEEP, int passOp=SOP_KEEP, bool twoSidedOperation=false)
  C_ARGS:
    (CompareFunction)func, refValue, mask, (StencilOperation)stencilFailOp, (StencilOperation)depthFailOp, (StencilOperation)passOp, twoSidedOperation

void
RenderSystem::setVertexDeclaration(VertexDeclaration *decl)

void
RenderSystem::setVertexBufferBinding(VertexBufferBinding *binding)

void
RenderSystem::setNormaliseNormals(bool normalise)

const RenderSystemCapabilities *
RenderSystem::getCapabilities()

void
RenderSystem::bindGpuProgram(GpuProgram *prg)

void
RenderSystem::bindGpuProgramParameters(gptype, params, variabilityMask)
    int  gptype
    GpuProgramParameters * params
    uint16  variabilityMask
  CODE:
    GpuProgramParametersSharedPtr paramsPtr = GpuProgramParametersSharedPtr(params);
    THIS->bindGpuProgramParameters((GpuProgramType)gptype, paramsPtr, variabilityMask);

void
RenderSystem::bindGpuProgramPassIterationParameters(int gptype)
  C_ARGS:
    (GpuProgramType)gptype

void
RenderSystem::unbindGpuProgram(int gptype)
  C_ARGS:
    (GpuProgramType)gptype

bool
RenderSystem::isGpuProgramBound(int gptype)
  C_ARGS:
    (GpuProgramType)gptype

## void RenderSystem::setClipPlanes(const PlaneList &clipPlanes)


#### void RenderSystem::setClipPlane(ushort index, Plane &p)
#### void RenderSystem::setClipPlane(ushort index, Real A, Real B, Real C, Real D)
##void
##RenderSystem::setClipPlane(index, ...)
##    unsigned short  index
##  CODE:
##    if (items == 3 && sv_isobject(ST(2)) && sv_derived_from(ST(2), "Ogre::Plane")) {
##        unsigned short index = (unsigned short)SvUV(ST(1));
##        Plane *p = (Plane *) SvIV((SV *) SvRV(ST(2)));
##        THIS->setClipPlane(index, *p);
##    }
##    else if (items == 6) {
##        THIS->setClipPlane((unsigned short)SvUV(ST(1)), (Real)SvNV(ST(2)), (Real)SvNV(ST(3)), (Real)SvNV(ST(4)), (Real)SvNV(ST(5)));
##    }
##    else {
##        croak("Usage: Ogre::RenderSystem::setClipPlane(THIS, index, plane) or (THIS, index, A, B, C, D)\n");
##    }
##
##void
##RenderSystem::enableClipPlane(unsigned short index, bool enable)

void
RenderSystem::setInvertVertexWinding(bool invert)

void
RenderSystem::setScissorTest(bool enabled, size_t left=0, size_t top=0, size_t right=800, size_t bottom=600)

void
RenderSystem::clearFrameBuffer(buffers, colour=&ColourValue::Black, depth=1.0f, stencil=0)
    unsigned int  buffers
    const ColourValue * colour
    Real  depth
    unsigned short  stencil
  C_ARGS:
    buffers, *colour, depth, stencil

Real
RenderSystem::getHorizontalTexelOffset()

Real
RenderSystem::getVerticalTexelOffset()

Real
RenderSystem::getMinimumDepthInputValue()

Real
RenderSystem::getMaximumDepthInputValue()

void
RenderSystem::setCurrentPassIterationCount(size_t count)

## void RenderSystem::addListener(Listener *l)

## void RenderSystem::removeListener(Listener *l)

## xxx: const StringVector & RenderSystem::getRenderSystemEvents()

void
RenderSystem::preExtraThreadsStarted()

void
RenderSystem::postExtraThreadsStarted()

void
RenderSystem::registerThread()

void
RenderSystem::unregisterThread()
