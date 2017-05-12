MODULE = Ogre     PACKAGE = Ogre::MeshManager

static MeshManager *
MeshManager::getSingletonPtr()

Mesh *
MeshManager::load(filename, groupName, vertexBufferUsage=(int)HardwareBuffer::HBU_STATIC_WRITE_ONLY, indexBufferUsage=(int)HardwareBuffer::HBU_STATIC_WRITE_ONLY, vertexBufferShadowed=true, indexBufferShadowed=true)
    String  filename
    String  groupName
    int  vertexBufferUsage
    int  indexBufferUsage
    bool vertexBufferShadowed
    bool indexBufferShadowed
  CODE:
    RETVAL = THIS->load(filename, groupName, (HardwareBuffer::Usage)vertexBufferUsage, (HardwareBuffer::Usage)indexBufferUsage, vertexBufferShadowed, indexBufferShadowed).getPointer();
  OUTPUT:
    RETVAL

## MeshPtr createManual(const String &name, const String &groupName, ManualResourceLoader *loader=0)
Mesh *
MeshManager::createManual(name, groupName, loader=0)
    String  name
    String  groupName
    ManualResourceLoader * loader
  CODE:
    RETVAL = THIS->createManual(name, groupName, loader).getPointer();
  OUTPUT:
    RETVAL

Mesh *
MeshManager::createPlane(name, groupName, plane, width, height, xsegments=1, ysegments=1, normals=true, numTexCoordSets=1, uTile=1.0f, vTile=1.0f, upVector=&Vector3::UNIT_Y, vertexBufferUsage=(int)HardwareBuffer::HBU_STATIC_WRITE_ONLY, indexBufferUsage=(int)HardwareBuffer::HBU_STATIC_WRITE_ONLY, vertexShadowBuffer=true, indexShadowBuffer=true)
    String    name
    String    groupName
    Plane   * plane
    Real     width
    Real     height
    int       xsegments
    int       ysegments
    bool      normals
    int       numTexCoordSets
    Real     uTile
    Real     vTile
    const Vector3 * upVector
    int  vertexBufferUsage
    int  indexBufferUsage
    bool vertexShadowBuffer
    bool indexShadowBuffer
  CODE:
    RETVAL = THIS->createPlane(name, groupName, *plane, width, height, xsegments, ysegments, normals, numTexCoordSets, uTile, vTile, *upVector, (HardwareBuffer::Usage)vertexBufferUsage, (HardwareBuffer::Usage)indexBufferUsage, vertexShadowBuffer, indexShadowBuffer).getPointer();
  OUTPUT:
    RETVAL

Mesh *
MeshManager::createCurvedIllusionPlane(name, groupName, plane, width, height, curvature, xsegments=1, ysegments=1, normals=true, numTexCoordSets=1, uTile=1.0f, vTile=1.0f, upVector=&Vector3::UNIT_Y, orientation=&Quaternion::IDENTITY, vertexBufferUsage=(int)HardwareBuffer::HBU_STATIC_WRITE_ONLY, indexBufferUsage=(int)HardwareBuffer::HBU_STATIC_WRITE_ONLY, vertexShadowBuffer=true, indexShadowBuffer=true, ySegmentsToKeep=-1)
    String    name
    String    groupName
    Plane   * plane
    Real     width
    Real     height
    Real     curvature
    int       xsegments
    int       ysegments
    bool      normals
    int       numTexCoordSets
    Real     uTile
    Real     vTile
    const Vector3 * upVector
    const Quaternion * orientation
    int  vertexBufferUsage
    int  indexBufferUsage
    bool vertexShadowBuffer
    bool indexShadowBuffer
    int       ySegmentsToKeep
  CODE:
    // what a lovely API... :)
    RETVAL = THIS->createCurvedIllusionPlane(name, groupName, *plane, width, height, curvature, xsegments, ysegments, normals, numTexCoordSets, uTile, vTile, *upVector, *orientation, (HardwareBuffer::Usage)vertexBufferUsage, (HardwareBuffer::Usage)indexBufferUsage, vertexShadowBuffer, indexShadowBuffer, ySegmentsToKeep).getPointer();
  OUTPUT:
    RETVAL

Mesh *
MeshManager::createCurvedPlane(name, groupName, plane, width, height, bow=0.5f, xsegments=1, ysegments=1, normals=false, numTexCoordSets=1, xTile=1.0f, yTile=1.0f, upVector=&Vector3::UNIT_Y, vertexBufferUsage=(int)HardwareBuffer::HBU_STATIC_WRITE_ONLY, indexBufferUsage=(int)HardwareBuffer::HBU_STATIC_WRITE_ONLY, vertexShadowBuffer=true, indexShadowBuffer=true)
    String    name
    String    groupName
    Plane   * plane
    Real     width
    Real     height
    Real     bow
    int       xsegments
    int       ysegments
    bool      normals
    int       numTexCoordSets
    Real     xTile
    Real     yTile
    const Vector3 * upVector
    int  vertexBufferUsage
    int  indexBufferUsage
    bool vertexShadowBuffer
    bool indexShadowBuffer
  CODE:
    RETVAL = THIS->createCurvedPlane(name, groupName, *plane, width, height, bow, xsegments, ysegments, normals, numTexCoordSets, xTile, yTile, *upVector, (HardwareBuffer::Usage)vertexBufferUsage, (HardwareBuffer::Usage)indexBufferUsage, vertexShadowBuffer, indexShadowBuffer).getPointer();
  OUTPUT:
    RETVAL

## XXX: void * ...
## PatchMeshPtr createBezierPatch(const String &name, const String &groupName, void *controlPointBuffer, VertexDeclaration *declaration, size_t width, size_t height, size_t uMaxSubdivisionLevel=PatchSurface::AUTO_LEVEL, size_t vMaxSubdivisionLevel=PatchSurface::AUTO_LEVEL, PatchSurface::VisibleSide visibleSide=PatchSurface::VS_FRONT, HardwareBuffer::Usage vbUsage=HardwareBuffer::HBU_STATIC_WRITE_ONLY, HardwareBuffer::Usage ibUsage=HardwareBuffer::HBU_DYNAMIC_WRITE_ONLY, bool vbUseShadow=true, bool ibUseShadow=true)

void
MeshManager::setPrepareAllMeshesForShadowVolumes(bool enable)

bool
MeshManager::getPrepareAllMeshesForShadowVolumes()

Real
MeshManager::getBoundsPaddingFactor()

void
MeshManager::setBoundsPaddingFactor(Real paddingFactor)

void
MeshManager::loadResource(res)
    Resource * res
