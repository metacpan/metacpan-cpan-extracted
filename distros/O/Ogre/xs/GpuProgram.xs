MODULE = Ogre     PACKAGE = Ogre::GpuProgram

void
GpuProgram::setSourceFile(String filename)

void
GpuProgram::setSource(String source)

String
GpuProgram::getSyntaxCode()

void
GpuProgram::setSyntaxCode(String syntax)

String
GpuProgram::getSourceFile()

String
GpuProgram::getSource()

void
GpuProgram::setType(int t)
  C_ARGS:
    (GpuProgramType)t

int
GpuProgram::getType()

bool
GpuProgram::isSupported()

GpuProgramParameters *
GpuProgram::createParameters()
  CODE:
    RETVAL = THIS->createParameters().getPointer();
  OUTPUT:
    RETVAL

void
GpuProgram::setSkeletalAnimationIncluded(bool included)

bool
GpuProgram::isSkeletalAnimationIncluded()

void
GpuProgram::setMorphAnimationIncluded(bool included)

void
GpuProgram::setPoseAnimationIncluded(unsigned short poseCount)

bool
GpuProgram::isMorphAnimationIncluded()

bool
GpuProgram::isPoseAnimationIncluded()

unsigned short
GpuProgram::getNumberOfPosesIncluded()

void
GpuProgram::setVertexTextureFetchRequired(bool r)

bool
GpuProgram::isVertexTextureFetchRequired()

GpuProgramParameters *
GpuProgram::getDefaultParameters()
  CODE:
    RETVAL = THIS->getDefaultParameters().getPointer();
  OUTPUT:
    RETVAL

bool
GpuProgram::hasDefaultParameters()

bool
GpuProgram::getPassSurfaceAndLightStates()

bool
GpuProgram::getPassFogStates()

bool
GpuProgram::getPassTransformStates()

String
GpuProgram::getLanguage()

bool
GpuProgram::hasCompileError()

void
GpuProgram::resetCompileError()

void
GpuProgram::load(bool backgroundThread=false)
