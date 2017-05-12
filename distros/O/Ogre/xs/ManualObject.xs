MODULE = Ogre     PACKAGE = Ogre::ManualObject

## note: if constructor/destructor ever added, refer to BillboardSet.xs
## (really need to fix that....)

void
ManualObject::clear()

void
ManualObject::estimateVertexCount(size_t vcount)

void
ManualObject::estimateIndexCount(size_t icount)

void
ManualObject::begin(String materialName, int opType=RenderOperation::OT_TRIANGLE_LIST)
  C_ARGS:
    materialName, (RenderOperation::OperationType)opType

void
ManualObject::setDynamic(bool dyn)

bool
ManualObject::getDynamic()

void
ManualObject::beginUpdate(size_t sectionIndex)

void
ManualObject::position(...)
  CODE:
    if (sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::Vector3")) {
        Vector3 *vec = (Vector3 *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN
        THIS->position(*vec);
    }
    else if (items == 4) {
        THIS->position((Real)SvNV(ST(1)), (Real)SvNV(ST(2)), (Real)SvNV(ST(3)));
    }
    else {
        croak("Usage: Ogre::ManualObject::position(THIS, vec) or (THIS, x , y, z)\n");
    }

## XXX: one day when I am a big boy I will know how to typemap Vector3 OR Reals
void
ManualObject::normal(...)
  CODE:
    if (sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::Vector3")) {
        Vector3 *vec = (Vector3 *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN
        THIS->normal(*vec);
    }
    else if (items == 4) {
        THIS->normal((Real)SvNV(ST(1)), (Real)SvNV(ST(2)), (Real)SvNV(ST(3)));
    }
    else {
        croak("Usage: Ogre::ManualObject::normal(THIS, vec) or (THIS, x , y, z)\n");
    }

void
ManualObject::textureCoord(...)
  PREINIT:
    char *usage = "Usage: Ogre::ManualObject::textureCoord(THIS, vec2) or (THIS, vec3) or (THIS, u [, v [, w]])\n";
  CODE:
    if (items == 2) {
        if (sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::Vector2")) {
            Vector2 *vec = (Vector2 *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN
            THIS->textureCoord(*vec);
        }
        else if (sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::Vector3")) {
            Vector3 *vec = (Vector3 *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN
            THIS->textureCoord(*vec);
        }
        else if (looks_like_number(ST(1))) {
            THIS->textureCoord((Real)SvNV(ST(1)));
        }
        else {
            croak("%s", usage);
        }
    }
    else if (items == 3) {  // assuming Real
        THIS->textureCoord((Real)SvNV(ST(1)), (Real)SvNV(ST(2)));
    }
    else if (items == 4) {  // assuming Real
        THIS->textureCoord((Real)SvNV(ST(1)), (Real)SvNV(ST(2)), (Real)SvNV(ST(3)));
    }
    else {
        croak("%s", usage);
    }

## XXX: one day when I am a big boy I will know how to typemap ColourValue OR Reals
void
ManualObject::colour(...)
  CODE:
    if (items == 2 && sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::ColourValue")) {
        ColourValue *colour = (ColourValue *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN
        THIS->colour(*colour);
    }
    else if (items >= 4) {
        Real a = 1.0f;
        if (items == 5) a = (Real)SvNV(ST(4));
        THIS->colour((Real)SvNV(ST(1)), (Real)SvNV(ST(2)), (Real)SvNV(ST(3)), a);
    }
    else {
        croak("Usage: Ogre::ManualObject::colour(THIS, col) or (THIS, r, g, b [, a])\n");
    }

void
ManualObject::index(uint16 idx)

void
ManualObject::triangle(uint16 i1, uint16 i2, uint16 i3)

void
ManualObject::quad(uint16 i1, uint16 i2, uint16 i3, uint16 i4)

ManualObjectSection *
ManualObject::end()

void
ManualObject::setMaterialName(size_t subindex, String name)

Mesh *
ManualObject::convertToMesh(String meshName, String groupName=ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME)
  CODE:
    RETVAL = THIS->convertToMesh(meshName, groupName).getPointer();
  OUTPUT:
    RETVAL

void
ManualObject::setUseIdentityProjection(bool useIdentityProjection)

bool
ManualObject::getUseIdentityProjection()

void
ManualObject::setUseIdentityView(bool useIdentityView)

bool
ManualObject::getUseIdentityView()

void
ManualObject::setBoundingBox(const AxisAlignedBox *box)
  C_ARGS:
    *box

ManualObjectSection *
ManualObject::getSection(unsigned int index)

unsigned int
ManualObject::getNumSections()

String
ManualObject::getMovableType()

## const AxisAlignedBox & ManualObject::getBoundingBox()

Real
ManualObject::getBoundingRadius()

EdgeData *
ManualObject::getEdgeList()

bool
ManualObject::hasEdgeList()

## ShadowRenderableListIterator ManualObject::getShadowVolumeRenderableIterator(ShadowTechnique shadowTechnique, const Light *light, HardwareIndexBufferSharedPtr *indexBuffer, bool extrudeVertices, Real extrusionDist, unsigned long flags=0)
