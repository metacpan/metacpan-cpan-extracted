MODULE = Ogre     PACKAGE = Ogre::VertexElement

static size_t
VertexElement::getTypeSize(int etype)
  C_ARGS:
    (VertexElementType)etype

static unsigned short
VertexElement::getTypeCount(int etype)
  C_ARGS:
    (VertexElementType)etype

static int
VertexElement::multiplyTypeCount(int baseType, unsigned short count)
  C_ARGS:
    (VertexElementType)baseType, count

static int
VertexElement::getBaseType(int multiType)
  C_ARGS:
    (VertexElementType)multiType

## static void VertexElement::convertColourValue(VertexElementType srcType, VertexElementType dstType, uint32 *ptr)
## static uint32 VertexElement::convertColourValue(const ColourValue &src, VertexElementType dst)

static int
VertexElement::getBestColourVertexElementType()


unsigned short
VertexElement::getSource()

size_t
VertexElement::getOffset()

int
VertexElement::getType()

int
VertexElement::getSemantic()

unsigned short
VertexElement::getIndex()

size_t
VertexElement::getSize()

## void VertexElement::baseVertexPointerToElement(void *pBase, void **pElem)
## void VertexElement::baseVertexPointerToElement(void *pBase, float **pElem)
## void VertexElement::baseVertexPointerToElement(void *pBase, RGBA **pElem)
## void VertexElement::baseVertexPointerToElement(void *pBase, unsigned char **pElem)
## void VertexElement::baseVertexPointerToElement(void *pBase, unsigned short **pElem)
