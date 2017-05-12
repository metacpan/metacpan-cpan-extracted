MODULE = Ogre     PACKAGE = Ogre::HardwareBufferManager

static HardwareBufferManager *
HardwareBufferManager::getSingletonPtr()

HardwareVertexBuffer *
HardwareBufferManager::createVertexBuffer(size_t vertexSize, size_t numVerts, int usage, bool useShadowBuffer=false)
  CODE:
    RETVAL = THIS->createVertexBuffer(vertexSize, numVerts, (Ogre::HardwareBuffer::Usage)usage, useShadowBuffer).getPointer();
  OUTPUT:
    RETVAL

HardwareIndexBuffer *
HardwareBufferManager::createIndexBuffer(int itype, size_t numIndexes, int usage, bool useShadowBuffer=false)
  CODE:
    RETVAL = THIS->createIndexBuffer((HardwareIndexBuffer::IndexType)itype, numIndexes, (HardwareBuffer::Usage)usage, useShadowBuffer).getPointer();
  OUTPUT:
    RETVAL

VertexDeclaration *
HardwareBufferManager::createVertexDeclaration()

void
HardwareBufferManager::destroyVertexDeclaration(VertexDeclaration *decl)

VertexBufferBinding *
HardwareBufferManager::createVertexBufferBinding()

void
HardwareBufferManager::destroyVertexBufferBinding(VertexBufferBinding *binding)

void
HardwareBufferManager::registerVertexBufferSourceAndCopy(sourceBuffer, copy)
    HardwareVertexBuffer * sourceBuffer
    HardwareVertexBuffer * copy
  CODE:
    const HardwareVertexBufferSharedPtr sourceBufferPtr = HardwareVertexBufferSharedPtr(sourceBuffer);
    const HardwareVertexBufferSharedPtr copyPtr = HardwareVertexBufferSharedPtr(copy);
    THIS->registerVertexBufferSourceAndCopy(sourceBufferPtr, copyPtr);

## xxx: too lazy to wrap this right now
## HardwareVertexBufferSharedPtr  HardwareBufferManager::allocateVertexBufferCopy(const HardwareVertexBufferSharedPtr &sourceBuffer, BufferLicenseType licenseType, HardwareBufferLicensee *licensee, bool copyData=false)

void
HardwareBufferManager::releaseVertexBufferCopy(bufferCopy)
    HardwareVertexBuffer * bufferCopy
  CODE:
    const HardwareVertexBufferSharedPtr bufferCopyPtr = HardwareVertexBufferSharedPtr(bufferCopy);
    THIS->releaseVertexBufferCopy(bufferCopyPtr);

void
HardwareBufferManager::touchVertexBufferCopy(bufferCopy)
    HardwareVertexBuffer * bufferCopy
  CODE:
    const HardwareVertexBufferSharedPtr bufferCopyPtr = HardwareVertexBufferSharedPtr(bufferCopy);
    THIS->touchVertexBufferCopy(bufferCopyPtr);
