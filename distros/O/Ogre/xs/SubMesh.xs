MODULE = Ogre     PACKAGE = Ogre::SubMesh

### PUBLIC ATTRIBUTES (xxx: gimpy Perl interface)

bool
SubMesh::getUseSharedVertices()
  CODE:
    RETVAL = THIS->useSharedVertices;
  OUTPUT:
    RETVAL

void
SubMesh::setUseSharedVertices(bool val)
  CODE:
    THIS->useSharedVertices = val;

int
SubMesh::getOperationType()
  CODE:
    RETVAL = THIS->operationType;
  OUTPUT:
    RETVAL

void
SubMesh::setOperationType(int val)
  CODE:
    THIS->operationType = (Ogre::RenderOperation::OperationType)val;

VertexData *
SubMesh::getVertexData()
  CODE:
    RETVAL = THIS->vertexData;
  OUTPUT:
    RETVAL

void
SubMesh::setVertexData(data)
    VertexData * data
  CODE:
    THIS->vertexData = data;

IndexData *
SubMesh::getIndexData()
  CODE:
    RETVAL = THIS->indexData;
  OUTPUT:
    RETVAL

void
SubMesh::setIndexData(data)
    IndexData * data
  CODE:
    THIS->indexData = data;

## IndexMap 	blendIndexToBoneIndexMap

## std::vector< Vector3 > 	extremityPoints

void
SubMesh::setParent(mesh)
    Mesh * mesh
  CODE:
    THIS->parent = mesh;

Mesh *
SubMesh::getParent()
  CODE:
    RETVAL = THIS->parent;
  OUTPUT:
    RETVAL

### END OF PUBLIC ATTRIBUTES ###


void
SubMesh::setMaterialName(matName)
    String  matName

String
SubMesh::getMaterialName()

bool
SubMesh::isMatInitialised()

## xxx: could pass 3 numbers instead of a struct
## void SubMesh::addBoneAssignment(const VertexBoneAssignment &vertBoneAssign)

void
SubMesh::clearBoneAssignments()

## BoneAssignmentIterator SubMesh::getBoneAssignmentIterator()

## AliasTextureIterator SubMesh::getAliasTextureIterator()

void
SubMesh::addTextureAlias(aliasName, textureName)
    String  aliasName
    String  textureName

void
SubMesh::removeTextureAlias(aliasName)
    String  aliasName

void
SubMesh::removeAllTextureAliases()

bool
SubMesh::hasTextureAliases()

size_t
SubMesh::getTextureAliasCount()

bool
SubMesh::updateMaterialUsingTextureAliases()

int
SubMesh::getVertexAnimationType()

void
SubMesh::generateExtremes(size_t count)


