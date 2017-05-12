MODULE = Ogre     PACKAGE = Ogre::AxisAlignedBox

## need to add tests

## xxx: need to add operator overloads, == != =

## xxx: this probably will end up not working right,
## in particular the destructor might destroy things
## when it should not (and cause segfaults)

AxisAlignedBox *
AxisAlignedBox::new(...)
  CODE:
    if (items == 1) {
        RETVAL = new AxisAlignedBox;
    }
    else if (sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::Vector3")
             && sv_isobject(ST(2)) && sv_derived_from(ST(2), "Ogre::Vector3"))
    {
        Vector3 *vecmin = (Vector3 *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN
        Vector3 *vecmax = (Vector3 *) SvIV((SV *) SvRV(ST(2)));   // TMOGRE_IN
        RETVAL = new AxisAlignedBox(*vecmin, *vecmax);
    }
    else if (items == 7) {
        RETVAL = new AxisAlignedBox((Real)SvNV(ST(1)), (Real)SvNV(ST(2)), (Real)SvNV(ST(3)),
                                    (Real)SvNV(ST(4)), (Real)SvNV(ST(5)), (Real)SvNV(ST(6)));
    }
    else if (sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::AxisAlignedBox")) {
        AxisAlignedBox *box = (AxisAlignedBox *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN
        RETVAL = new AxisAlignedBox(*box);
    }
    else {
        croak("Usage: Ogre::AxisAlignedBox::new(...)\n");
    }
  OUTPUT:
    RETVAL

## const Vector3 & AxisAlignedBox::getMinimum()
## Vector3 & AxisAlignedBox::getMinimum()
## const Vector3 & AxisAlignedBox::getMaximum()
## Vector3 & AxisAlignedBox::getMaximum()

void
AxisAlignedBox::setMinimum(...)
  CODE:
    if (sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::Vector3")) {
        Vector3 *vec = (Vector3 *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN
        THIS->setMinimum(*vec);
    }
    else if (items == 4) {
        THIS->setMinimum((Real)SvNV(ST(1)), (Real)SvNV(ST(2)), (Real)SvNV(ST(3)));
    }
    else {
        croak("Usage: Ogre::AxisAlignedBox::setMinimum(THIS, vec) or (THIS, x, y, z)\n");
    }

void
AxisAlignedBox::setMinimumX(Real x)

void
AxisAlignedBox::setMinimumY(Real y)

void
AxisAlignedBox::setMinimumZ(Real z)

void
AxisAlignedBox::setMaximum(...)
  CODE:
    if (sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::Vector3")) {
        Vector3 *vec = (Vector3 *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN
        THIS->setMaximum(*vec);
    }
    else if (items == 4) {
        THIS->setMaximum((Real)SvNV(ST(1)), (Real)SvNV(ST(2)), (Real)SvNV(ST(3)));
    }
    else {
        croak("Usage: Ogre::AxisAlignedBox::setMaximum(THIS, vec) or (THIS, x, y, z)\n");
    }

void
AxisAlignedBox::setMaximumX(Real x)

void
AxisAlignedBox::setMaximumY(Real y)

void
AxisAlignedBox::setMaximumZ(Real z)

void
AxisAlignedBox::setExtents(...)
  CODE:
    if (sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::Vector3")
        && sv_isobject(ST(2)) && sv_derived_from(ST(2), "Ogre::Vector3"))
    {
        Vector3 *vecmin = (Vector3 *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN
        Vector3 *vecmax = (Vector3 *) SvIV((SV *) SvRV(ST(2)));   // TMOGRE_IN
        THIS->setExtents(*vecmin, *vecmax);
    }
    else if (items == 7) {
        THIS->setExtents((Real)SvNV(ST(1)), (Real)SvNV(ST(2)), (Real)SvNV(ST(3)),
                         (Real)SvNV(ST(4)), (Real)SvNV(ST(5)), (Real)SvNV(ST(6)));
    }
    else {
        croak("Usage: Ogre::AxisAlignedBox::setExtents(THIS, vec, Vec) or (THIS, x, y, z, X, Y, Z)\n");
    }

## xxx: array of Vector3*
## const Vector3 * AxisAlignedBox::getAllCorners()

## Vector3 AxisAlignedBox::getCorner(CornerEnum cornerToGet)

void
AxisAlignedBox::merge(...)
  PREINIT:
    const char *usage = "Usage: Ogre::AxisAlignedBox::merge(THIS, {Vector3|AxisAlignedBox})\n";
  CODE:
    if (sv_isobject(ST(1))) {
        if (sv_derived_from(ST(1), "Ogre::Vector3")) {
            Vector3 *w = (Vector3 *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN
            THIS->merge(*w);
        }
        else if (sv_derived_from(ST(1), "Ogre::AxisAlignedBox")) {
            AxisAlignedBox *w = (AxisAlignedBox *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN
            THIS->merge(*w);
        }
        else {
            croak("%s", usage);
        }
    }
    else {
        croak("%s", usage);
    }

void
AxisAlignedBox::transform(const Matrix4 *matrix)
  C_ARGS:
    *matrix

void
AxisAlignedBox::transformAffine(const Matrix4 *m)
  C_ARGS:
    *m

void
AxisAlignedBox::setNull()

bool
AxisAlignedBox::isNull()

bool
AxisAlignedBox::isFinite()

void
AxisAlignedBox::setInfinite()

bool
AxisAlignedBox::isInfinite()

bool
AxisAlignedBox::intersects(...)
  PREINIT:
    const char *usage = "Usage: Ogre::AxisAlignedBox::intersects(THIS, {Sphere|Vector3|Plane|AxisAlignedBox})\n";
  CODE:
    if (sv_isobject(ST(1))) {
        if (sv_derived_from(ST(1), "Ogre::Vector3")) {
            Vector3 *w = (Vector3 *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN
            RETVAL = THIS->intersects(*w);
        }
        else if (sv_derived_from(ST(1), "Ogre::Sphere")) {
            Sphere *w = (Sphere *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN
            RETVAL = THIS->intersects(*w);
        }
        else if (sv_derived_from(ST(1), "Ogre::Plane")) {
            Plane *w = (Plane *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN
            RETVAL = THIS->intersects(*w);
        }
        else if (sv_derived_from(ST(1), "Ogre::AxisAlignedBox")) {
            AxisAlignedBox *w = (AxisAlignedBox *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN
            RETVAL = THIS->intersects(*w);
        }
        else {
            croak("%s", usage);
        }
    }
    else {
        croak("%s", usage);
    }
  OUTPUT:
    RETVAL

## AxisAlignedBox AxisAlignedBox::intersection(const AxisAlignedBox &b2)

Real
AxisAlignedBox::volume()

void
AxisAlignedBox::scale(const Vector3 *s)
  C_ARGS:
    *s

## Vector3 AxisAlignedBox::getCenter()
## Vector3 AxisAlignedBox::getSize()
## Vector3 AxisAlignedBox::getHalfSize()

bool
AxisAlignedBox::contains(...)
  PREINIT:
    const char *usage = "Usage: Ogre::AxisAlignedBox::contains(THIS, {Vector3|AxisAlignedBox})\n";
  CODE:
    if (sv_isobject(ST(1))) {
        if (sv_derived_from(ST(1), "Ogre::Vector3")) {
            Vector3 *w = (Vector3 *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN
            RETVAL = THIS->intersects(*w);
        }
        else if (sv_derived_from(ST(1), "Ogre::AxisAlignedBox")) {
            AxisAlignedBox *w = (AxisAlignedBox *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN
            RETVAL = THIS->intersects(*w);
        }
        else {
            croak("%s", usage);
        }
    }
    else {
        croak("%s", usage);
    }
  OUTPUT:
    RETVAL

