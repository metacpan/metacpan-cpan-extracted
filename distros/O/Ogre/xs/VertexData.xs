MODULE = Ogre     PACKAGE = Ogre::VertexData

### PUBLIC ATTRIBUTES (xxx: gimpy Perl interface)

void
VertexData::setVertexDeclaration(val)
    VertexDeclaration * val
  CODE:
    THIS->vertexDeclaration = val;

VertexDeclaration *
VertexData::getVertexDeclaration()
  CODE:
    RETVAL = THIS->vertexDeclaration;
  OUTPUT:
    RETVAL

void
VertexData::setVertexBufferBinding(val)
    VertexBufferBinding * val
  CODE:
    THIS->vertexBufferBinding = val;

VertexBufferBinding *
VertexData::getVertexBufferBinding()
  CODE:
    RETVAL = THIS->vertexBufferBinding;
  OUTPUT:
    RETVAL

void
VertexData::setVertexStart(size_t val)
  CODE:
    THIS->vertexStart = val;

size_t
VertexData::getVertexStart()
  CODE:
    RETVAL = THIS->vertexStart;
  OUTPUT:
    RETVAL

void
VertexData::setVertexCount(size_t val)
  CODE:
    THIS->vertexCount = val;

size_t
VertexData::getVertexCount()
  CODE:
    RETVAL = THIS->vertexCount;
  OUTPUT:
    RETVAL

## HardwareAnimationDataList 	hwAnimationDataList

void
VertexData::setHwAnimDataItemsUsed(size_t val)
  CODE:
    THIS->hwAnimDataItemsUsed = val;

size_t
VertexData::getHwAnimDataItemsUsed()
  CODE:
    RETVAL = THIS->hwAnimDataItemsUsed;
  OUTPUT:
    RETVAL

## HardwareVertexBufferSharedPtr 	hardwareShadowVolWBuffer

### END OF PUBLIC ATTRIBUTES ###


VertexData *
VertexData::clone(bool copyData=true)

void
VertexData::prepareForShadowVolume()

## xxx:
## std::vector<HardwareBuffer::Usage>
## void VertexData::reorganiseBuffers(VertexDeclaration *newDeclaration, const BufferUsageList &bufferUsage)
void
VertexData::reorganiseBuffers(VertexDeclaration *newDeclaration)

void
VertexData::closeGapsInBindings()

void
VertexData::removeUnusedBuffers()

void
VertexData::convertPackedColour(int srcType, int destType)
  C_ARGS:
    (VertexElementType)srcType, (VertexElementType)destType

#if OGRE_VERSION >= 0x010800

void
VertexData::allocateHardwareAnimationElements(unsigned short count, bool animateNormals)

#else

void
VertexData::allocateHardwareAnimationElements(unsigned short count)

#endif
