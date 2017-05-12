MODULE = Ogre     PACKAGE = Ogre::ParticleSystem

## note: if constructor/destructor ever added, refer to BillboardSet.xs

static void
ParticleSystem::setDefaultIterationInterval(Real iterationInterval)

static Real
ParticleSystem::getDefaultIterationInterval()

static void
ParticleSystem::setDefaultNonVisibleUpdateTimeout(Real timeout)

static Real
ParticleSystem::getDefaultNonVisibleUpdateTimeout()

static void
ParticleSystem::cleanupDictionary()

static void
ParticleSystem::setDefaultQueryFlags(uint32 flags)

static uint32
ParticleSystem::getDefaultQueryFlags()

static void
ParticleSystem::setDefaultVisibilityFlags(uint32 flags)

static uint32
ParticleSystem::getDefaultVisibilityFlags()

static void
ParticleSystem::extrudeVertices(vertexBuffer, originalVertexCount, lightPos, extrudeDist)
    HardwareVertexBuffer * vertexBuffer
    size_t originalVertexCount
    const Vector4 * lightPos
    Real extrudeDist
  CODE:
    const HardwareVertexBufferSharedPtr vertexBufferPtr = HardwareVertexBufferSharedPtr(vertexBuffer);
    Ogre::ParticleSystem::extrudeVertices(vertexBufferPtr, originalVertexCount, *lightPos, extrudeDist);


void
ParticleSystem::setRenderer(typeName)
    String  typeName

ParticleSystemRenderer *
ParticleSystem::getRenderer()

String
ParticleSystem::getRendererName()

ParticleEmitter *
ParticleSystem::addEmitter(emitterType)
    String  emitterType

ParticleEmitter *
ParticleSystem::getEmitter(unsigned short index)

unsigned short
ParticleSystem::getNumEmitters()

void
ParticleSystem::removeEmitter(unsigned short index)

void
ParticleSystem::removeAllEmitters()

ParticleAffector *
ParticleSystem::addAffector(affectorType)
    String  affectorType

ParticleAffector *
ParticleSystem::getAffector(unsigned short index)

unsigned short
ParticleSystem::getNumAffectors()

void
ParticleSystem::removeAffector(unsigned short index)

void
ParticleSystem::removeAllAffectors()

void
ParticleSystem::clear()

size_t
ParticleSystem::getNumParticles()

Particle *
ParticleSystem::createParticle()

Particle *
ParticleSystem::createEmitterParticle(emitterName)
    String  emitterName

Particle *
ParticleSystem::getParticle(size_t index)

size_t
ParticleSystem::getParticleQuota()

void
ParticleSystem::setParticleQuota(size_t quota)

size_t
ParticleSystem::getEmittedEmitterQuota()

void
ParticleSystem::setEmittedEmitterQuota(size_t quota)

void
ParticleSystem::setMaterialName(name)
    String  name

String
ParticleSystem::getMaterialName()

## xxx: const AxisAlignedBox & ParticleSystem::getBoundingBox()

Real
ParticleSystem::getBoundingRadius()

void
ParticleSystem::fastForward(Real time, Real interval=0.1)

void
ParticleSystem::setSpeedFactor(Real speedFactor)

Real
ParticleSystem::getSpeedFactor()

void
ParticleSystem::setIterationInterval(Real iterationInterval)

Real
ParticleSystem::getIterationInterval()

void
ParticleSystem::setNonVisibleUpdateTimeout(Real timeout)

Real
ParticleSystem::getNonVisibleUpdateTimeout()

String
ParticleSystem::getMovableType()

void
ParticleSystem::setDefaultDimensions(Real width, Real height)

void
ParticleSystem::setDefaultWidth(Real width)

Real
ParticleSystem::getDefaultWidth()

void
ParticleSystem::setDefaultHeight(Real height)

Real
ParticleSystem::getDefaultHeight()

bool
ParticleSystem::getCullIndividually()

void
ParticleSystem::setCullIndividually(bool cullIndividual)

String
ParticleSystem::getResourceGroupName()

String
ParticleSystem::getOrigin()

void
ParticleSystem::setRenderQueueGroup(uint8 queueID)

void
ParticleSystem::setSortingEnabled(bool enabled)

bool
ParticleSystem::getSortingEnabled()

void
ParticleSystem::setBounds(aabb)
    const AxisAlignedBox * aabb
  C_ARGS:
    *aabb

void
ParticleSystem::setBoundsAutoUpdated(bool autoUpdate, Real stopIn=0.0f)

void
ParticleSystem::setKeepParticlesInLocalSpace(bool keepLocal)

bool
ParticleSystem::getKeepParticlesInLocalSpace()

uint32
ParticleSystem::getTypeFlags()
