MODULE = Ogre     PACKAGE = Ogre::Mesh

SubMesh *
Mesh::createSubMesh(...)
  CODE:
    if (items == 1) {
        RETVAL = THIS->createSubMesh();
    }
    else if (items == 2) {
        char * xstmpchr = (char *) SvPV_nolen(ST(1));
        String name = xstmpchr;
        RETVAL = THIS->createSubMesh(name);
    }
    else {
        croak("Usage: Ogre::Mesh::createSubMesh(CLASS, [name])\n");
    }
  OUTPUT:
    RETVAL

void
Mesh::nameSubMesh(name, index)
    String  name
    unsigned short  index

unsigned short
Mesh::getNumSubMeshes()

### xxx: for some reason, it won't let the unsigned short version convert...
##SubMesh *
##Mesh::getSubMesh(...)
##  CODE:
##    if (items == 2) {
##        // xxx: hope they don't use a numeric name...
##        if (looks_like_number(ST(1))) {
##            unsigned short i = (unsigned short)SvUV(ST(1));
##            RETVAL = THIS->createSubMesh(i);
##        }
##        else {
##            char * xstmpchr_$var = (char *) SvPV_nolen(ST(1));
##            String name = xstmpchr_$var;
##            RETVAL = THIS->createSubMesh(name);
##        }
##    }
##    else {
##        croak("Usage: Ogre::Mesh::getSubMesh(CLASS, name) or getSubMesh(CLASS, index)\n");
##    }
##  OUTPUT:
##    RETVAL

SubMesh *
Mesh::getSubMesh(name)
    String  name

## SubMeshIterator Mesh::getSubMeshIterator(void)

Mesh *
Mesh::clone(newName, newGroup=StringUtil::BLANK)
    String  newName
    String  newGroup
  CODE:
    RETVAL = THIS->clone(newName, (const String)newGroup).getPointer();
  OUTPUT:
    RETVAL

## const AxisAlignedBox & Mesh::getBounds(void)

Real
Mesh::getBoundingSphereRadius()

void
Mesh::setSkeletonName(skelName)
    String  skelName

bool
Mesh::hasSkeleton()

bool
Mesh::hasVertexAnimation()

Skeleton *
Mesh::getSkeleton()
  CODE:
    RETVAL = THIS->getSkeleton().getPointer();
  OUTPUT:
    RETVAL

String
Mesh::getSkeletonName()

## xxx: VertexBoneAssignment is a struct; could just pass three numbers instead
##void
##Mesh::addBoneAssignment(const VertexBoneAssignment &vertBoneAssign)

void
Mesh::clearBoneAssignments()

## BoneAssignmentIterator Mesh::getBoneAssignmentIterator(void)

unsigned short
Mesh::getNumLodLevels()

## xxx: MeshLodUsage is a struct
##const MeshLodUsage & Mesh::getLodLevel(ushort index)

void
Mesh::createManualLodLevel(fromDepth, meshName)
    Real  fromDepth
    String  meshName

void
Mesh::updateManualLodLevel(index, meshName)
    unsigned short  index
    String  meshName

unsigned short
Mesh::getLodIndex(Real depth)
  CODE:
    RETVAL = THIS->getLodStrategy()->transformUserValue(depth);
  OUTPUT:
    RETVAL

bool
Mesh::isLodManual()

void
Mesh::removeLodLevels()

void
Mesh::setVertexBufferPolicy(int usage, bool shadowBuffer=false)
  C_ARGS:
    (HardwareBuffer::Usage)usage, shadowBuffer

void
Mesh::setIndexBufferPolicy(int usage, bool shadowBuffer=false)
  C_ARGS:
    (HardwareBuffer::Usage)usage, shadowBuffer

int
Mesh::getVertexBufferUsage()

int
Mesh::getIndexBufferUsage()

bool
Mesh::isVertexBufferShadowed()

bool
Mesh::isIndexBufferShadowed()

void
Mesh::buildTangentVectors(int targetSemantic=VES_TANGENT, unsigned short sourceTexCoordSet=0, unsigned short index=0)
  C_ARGS:
    (VertexElementSemantic)targetSemantic, sourceTexCoordSet, index

bool
Mesh::suggestTangentVectorBuildParams(int targetSemantic, OUTLIST unsigned short outSourceCoordSet, OUTLIST unsigned short outIndex)
  C_ARGS:
    (VertexElementSemantic)targetSemantic, outSourceCoordSet, outIndex

void
Mesh::buildEdgeList()

void
Mesh::freeEdgeList()

void
Mesh::prepareForShadowVolume()

# there are two versions, this too:
#const EdgeData * Mesh::getEdgeList(unsigned int lodIndex=0)
EdgeData *
Mesh::getEdgeList(unsigned int lodIndex=0)

bool
Mesh::isPreparedForShadowVolumes()

bool
Mesh::isEdgeListBuilt()

## HashMap<String, ushort>
##const SubMeshNameMap & Mesh::getSubMeshNameMap(void)

void
Mesh::setAutoBuildEdgeLists(bool autobuild)

bool
Mesh::getAutoBuildEdgeLists()

int
Mesh::getSharedVertexDataAnimationType()

Animation *
Mesh::createAnimation(name, length)
    String  name
    Real  length

## this too, but I assume it will have the same problem as getSubMesh:
## Animation * Mesh::getAnimation(unsigned short index)
Animation *
Mesh::getAnimation(name)
    String  name

bool
Mesh::hasAnimation(name)
    String  name

void
Mesh::removeAnimation(name)
    String  name

unsigned short
Mesh::getNumAnimations()

void
Mesh::removeAllAnimations()

VertexData *
Mesh::getVertexDataByTrackHandle(unsigned short handle)

void
Mesh::updateMaterialForAllSubMeshes()

Pose *
Mesh::createPose(target, name=StringUtil::BLANK)
    unsigned short  target
    String  name
  CODE:
    RETVAL = THIS->createPose(target, (const String)name);
  OUTPUT:
    RETVAL

size_t
Mesh::getPoseCount()

## also this:  Pose * Mesh::getPose(ushort index)
Pose *
Mesh::getPose(name)
    String  name

## also this: void Mesh::removePose(ushort index)
void
Mesh::removePose(name)
    String name

void
Mesh::removeAllPoses()

## PoseIterator Mesh::getPoseIterator(void)
## ConstPoseIterator Mesh::getPoseIterator(void)

## std::vector<Pose*>
## const PoseList & Mesh::getPoseList(void)

