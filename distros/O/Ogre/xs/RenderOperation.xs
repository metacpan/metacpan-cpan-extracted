MODULE = Ogre     PACKAGE = Ogre::RenderOperation

# Here I assume the Public Attributes are read-only;
# let me know if that is incorrect

VertexData *
RenderOperation::vertexData()
  CODE:
    RETVAL = THIS->vertexData;
  OUTPUT:
    RETVAL

int
RenderOperation::operationType()
  CODE:
    RETVAL = THIS->operationType;
  OUTPUT:
    RETVAL

bool
RenderOperation::useIndexes()
  CODE:
    RETVAL = THIS->useIndexes;
  OUTPUT:
    RETVAL

IndexData *
RenderOperation::indexData()
  CODE:
    RETVAL = THIS->indexData;
  OUTPUT:
    RETVAL

const Renderable *
RenderOperation::srcRenderable()
  CODE:
    RETVAL = THIS->srcRenderable;
  OUTPUT:
    RETVAL
