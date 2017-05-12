MODULE = Ogre     PACKAGE = Ogre::SubEntity

String
SubEntity::getMaterialName()

void
SubEntity::setMaterialName(String name)

void
SubEntity::setVisible(bool visible)

bool
SubEntity::isVisible()

SubMesh *
SubEntity::getSubMesh()

Entity *
SubEntity::getParent()

const Material *
SubEntity::getMaterial()
  CODE:
    RETVAL = THIS->getMaterial().getPointer();
  OUTPUT:
    RETVAL

Technique *
SubEntity::getTechnique()

# note: returned instead of gotten by reference
void
SubEntity::getRenderOperation(OUTLIST RenderOperation *op)
  C_ARGS:
    *op

## xxx: is xform an array?
## void SubEntity::getWorldTransforms(Matrix4 *xform)


##bool
##SubEntity::getNormaliseNormals()

unsigned short
SubEntity::getNumWorldTransforms()

Real
SubEntity::getSquaredViewDepth(const Camera *cam)

## const LightList & SubEntity::getLights()

bool
SubEntity::getCastsShadows()

VertexData *
SubEntity::getVertexDataForBinding()
