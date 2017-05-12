MODULE = Ogre     PACKAGE = Ogre::ControllerManager

static ControllerManager *
ControllerManager::getSingletonPtr()

## Controller< Real > * ControllerManager::createController(const ControllerValueRealPtr &src, const ControllerValueRealPtr &dest, const ControllerFunctionRealPtr &func)
## note: this has to be callable like this:
##   $cont = $contman->createController($contman->getFrameTimeSource, $perlcontval, $perlcontfunc);
## that is, the ControllerValues and ControllerFunctions that are passed in
## could be either C++ objects or Perl objects.
ControllerReal *
ControllerManager::createController(ControllerValueReal *src, ControllerValueReal *dest, ControllerFunctionReal *func)
  CODE:
    ControllerValueRealPtr srcptr = ControllerValueRealPtr(src);
    ControllerValueRealPtr destptr = ControllerValueRealPtr(dest);
    ControllerFunctionRealPtr funcptr = ControllerFunctionRealPtr(func);
    RETVAL = THIS->createController(srcptr, destptr, funcptr);
  OUTPUT:
    RETVAL

## Controller< Real > * ControllerManager::createFrameTimePassthroughController(const ControllerValueRealPtr &dest)
ControllerReal *
ControllerManager::createFrameTimePassthroughController(ControllerValueReal *dest)
  CODE:
    ControllerValueRealPtr destptr = ControllerValueRealPtr(dest);
    RETVAL = THIS->createFrameTimePassthroughController(destptr);
  OUTPUT:
    RETVAL

void
ControllerManager::clearControllers()

void
ControllerManager::updateAllControllers()

## const ControllerValueRealPtr & ControllerManager::getFrameTimeSource()
ControllerValueReal *
ControllerManager::getFrameTimeSource()
  CODE:
    RETVAL = THIS->getFrameTimeSource().getPointer();
  OUTPUT:
    RETVAL

## const ControllerFunctionRealPtr & ControllerManager::getPassthroughControllerFunction()
ControllerFunctionReal *
ControllerManager::getPassthroughControllerFunction()
  CODE:
    RETVAL = THIS->getPassthroughControllerFunction().getPointer();
  OUTPUT:
    RETVAL

ControllerReal *
ControllerManager::createTextureAnimator(TextureUnitState *layer, Real sequenceTime)

ControllerReal *
ControllerManager::createTextureUVScroller(TextureUnitState *layer, Real speed)

ControllerReal *
ControllerManager::createTextureUScroller(TextureUnitState *layer, Real uSpeed)

ControllerReal *
ControllerManager::createTextureVScroller(TextureUnitState *layer, Real vSpeed)

ControllerReal *
ControllerManager::createTextureRotater(TextureUnitState *layer, Real speed)

ControllerReal *
ControllerManager::createTextureWaveTransformer(TextureUnitState *layer, int ttype, int waveType, Real base=0, Real frequency=1, Real phase=0, Real amplitude=1)
  C_ARGS:
    layer, (TextureUnitState::TextureTransformType)ttype, (WaveformType)waveType, base, frequency, phase, amplitude

ControllerReal *
ControllerManager::createGpuProgramTimerParam(GpuProgramParameters *params, size_t paramIndex, Real timeFactor=1.0f)
  CODE:
    GpuProgramParametersSharedPtr paramsPtr = GpuProgramParametersSharedPtr(params);
    RETVAL = THIS->createGpuProgramTimerParam(paramsPtr, paramIndex, timeFactor);
  OUTPUT:
    RETVAL

## xxx: would need a manager (like for the Listeners) for the Perl-created objects
## in order to make this work; for now you have to call clear Controllers, I guess
## void ControllerManager::destroyController(ControllerReal *controller)

Real
ControllerManager::getTimeFactor()

void
ControllerManager::setTimeFactor(Real tf)

Real
ControllerManager::getFrameDelay()

void
ControllerManager::setFrameDelay(Real fd)

Real
ControllerManager::getElapsedTime()

void
ControllerManager::setElapsedTime(Real elapsedTime)
