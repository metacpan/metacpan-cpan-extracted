MODULE = Ogre     PACKAGE = Ogre::VertexDeclaration

## xxx: operators == and !=, static vertexElementLess


size_t
VertexDeclaration::getElementCount()

## const VertexElementList & 	getElements()

const VertexElement *
VertexDeclaration::getElement(unsigned short index)

void
VertexDeclaration::sort()

void
VertexDeclaration::closeGapsInSource()

#if OGRE_VERSION >= 0x010800

VertexDeclaration *
VertexDeclaration::getAutoOrganisedDeclaration(bool skeletalAnimation, bool vertexAnimation, bool vertexAnimationNormals)

#else

VertexDeclaration *
VertexDeclaration::getAutoOrganisedDeclaration(bool skeletalAnimation, bool vertexAnimation)

#endif

unsigned short
VertexDeclaration::getMaxSource()

## XXX: for now, not returning anything...
## const VertexElement & 	addElement(unsigned short source, size_t offset, VertexElementType theType, VertexElementSemantic semantic, unsigned short index=0)
void
VertexDeclaration::addElement(source, offset, theType, semantic, index=0)
    unsigned short source
    size_t offset
    int theType
    int semantic
    unsigned short index
  C_ARGS:
    source, offset, (VertexElementType)theType, (VertexElementSemantic)semantic, index


## XXX: for now, not returning anything...
## const VertexElement & 	insertElement(unsigned short atPosition, unsigned short source, size_t offset, VertexElementType theType, VertexElementSemantic semantic, unsigned short index=0)
void
VertexDeclaration::insertElement(atPosition, source, offset, theType, semantic, index=0)
    unsigned short atPosition
    unsigned short source
    size_t offset
    int theType
    int semantic
    unsigned short index
  C_ARGS:
    atPosition, source, offset, (VertexElementType)theType, (VertexElementSemantic)semantic, index

void
VertexDeclaration::removeElement(unsigned short elem_index)

## xxx: if 2nd arg not passed, same as previous removeElement
## as far as Perl is concerned...
void
VertexDeclaration::removeElementBySemantic(int semantic, unsigned short index=0)
  CODE:
    THIS->removeElement((VertexElementSemantic)semantic, index);

void
VertexDeclaration::removeAllElements()

void
VertexDeclaration::modifyElement(elem_index, source, offset, theType, semantic, index=0)
    unsigned short elem_index
    unsigned short source
    size_t offset
    int theType
    int semantic
    unsigned short index
  C_ARGS:
    elem_index, source, offset, (VertexElementType)theType, (VertexElementSemantic)semantic, index

const VertexElement *
VertexDeclaration::findElementBySemantic(int sem, unsigned short index=0)
  C_ARGS:
    (VertexElementSemantic)sem, index

## VertexElementList 	findElementsBySource(unsigned short source)

size_t
VertexDeclaration::getVertexSize(unsigned short source)

VertexDeclaration *
VertexDeclaration::clone()
