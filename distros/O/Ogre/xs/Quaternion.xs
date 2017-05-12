MODULE = Ogre     PACKAGE = Ogre::Quaternion

Quaternion *
Quaternion::new(...)
  PREINIT:
    char *usage = "Usage: Ogre::Quaternion::new(CLASS [, Quaternion]) or new(CLASS, Vector3, Real) or...\n";
  CODE:
    // Quaternion (Real fW=1.0, Real fX=0.0, Real fY=0.0, Real fZ=0.0)
    if (items == 1) {
        RETVAL = new Quaternion();
    }
    else if (items == 2) {
        // Quaternion (Real fW=1.0, Real fX=0.0, Real fY=0.0, Real fZ=0.0)
        if (looks_like_number(ST(1))) {
            RETVAL = new Quaternion((Real)SvNV(ST(1)), 0.0f, 0.0f, 0.0f);
        }
        // Quaternion (const Quaternion &rkQ)
        else if (sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::Quaternion")) {
            Quaternion *q = (Quaternion *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN
            RETVAL = new Quaternion(*q);
        }
        // Quaternion (const Matrix3 &rot)
        else if (sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::Matrix3")) {
            Matrix3 *m = (Matrix3 *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN
            RETVAL = new Quaternion(*m);
        }
        else {
            croak("%s", usage);
        }
    }
    else if (items == 3) {
        // Quaternion (Real fW=1.0, Real fX=0.0, Real fY=0.0, Real fZ=0.0)
        if (looks_like_number(ST(1)) && looks_like_number(ST(2))) {
            RETVAL = new Quaternion((Real)SvNV(ST(1)), (Real)SvNV(ST(2)), 0.0f, 0.0f);
        }
        // Quaternion (const Radian &rfAngle, const Vector3 &rkAxis)
        else if (sv_isobject(ST(2)) && sv_derived_from(ST(2), "Ogre::Vector3")) {
            Vector3 *v = (Vector3 *) SvIV((SV *) SvRV(ST(2)));

            DegRad * rfAngle;
            TMOGRE_DEGRAD_IN(ST(1), rfAngle, Ogre::Quaternion, new);
            RETVAL = new Quaternion(*rfAngle, *v);
        }
        else {
            croak("%s", usage);
        }
    }
    else if (items == 4) {
        // Quaternion (Real fW=1.0, Real fX=0.0, Real fY=0.0, Real fZ=0.0)
        if (looks_like_number(ST(1)) && looks_like_number(ST(2)) && looks_like_number(ST(3))) {
            RETVAL = new Quaternion((Real)SvNV(ST(1)), (Real)SvNV(ST(2)), (Real)SvNV(ST(3)), 0.0f);
        }
        // Quaternion (const Vector3 &xaxis, const Vector3 &yaxis, const Vector3 &zaxis)
        else if (sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::Vector3")
                 && sv_isobject(ST(2)) && sv_derived_from(ST(2), "Ogre::Vector3")
                 && sv_isobject(ST(3)) && sv_derived_from(ST(3), "Ogre::Vector3"))
        {
            Vector3 *v1 = (Vector3 *) SvIV((SV *) SvRV(ST(1)));
            Vector3 *v2 = (Vector3 *) SvIV((SV *) SvRV(ST(2)));
            Vector3 *v3 = (Vector3 *) SvIV((SV *) SvRV(ST(3)));
            RETVAL = new Quaternion(*v1, *v2, *v3);
        }
        else {
            croak("%s", usage);
        }
    }
    else if (items == 5) {
        // Quaternion (Real fW=1.0, Real fX=0.0, Real fY=0.0, Real fZ=0.0)
        if (looks_like_number(ST(1)) && looks_like_number(ST(2))
            && looks_like_number(ST(3)) && looks_like_number(ST(4)))
        {
            RETVAL = new Quaternion((Real)SvNV(ST(1)), (Real)SvNV(ST(2)),
                                    (Real)SvNV(ST(3)), (Real)SvNV(ST(4)));
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

void
Quaternion::DESTROY()


# ==, !=
bool
quat_eq_xs(lobj, robj, swap)
    Quaternion * lobj
    Quaternion * robj
    IV        swap
  ALIAS:
    quat_ne_xs = 1
  CODE:
    switch(ix) {
        case 0: RETVAL = (*lobj == *robj); break;
        case 1: RETVAL = (*lobj != *robj); break;
    }
  OUTPUT:
    RETVAL

# +, -
Quaternion *
quat_plus_xs(lobj, robj, swap)
    Quaternion * lobj
    Quaternion * robj
    IV        swap
  ALIAS:
    quat_minus_xs = 1
  PREINIT:
    Quaternion *q = new Quaternion;
  CODE:
    switch(ix) {
        case 0: *q = *lobj + *robj; break;
        case 1: *q = swap ? (*robj - *lobj) : (*lobj - *robj); break;
    }
    RETVAL = q;
  OUTPUT:
    RETVAL

# * (with Vector3 also)
SV *
quat_mult_xs(lobj, robj, swap)
    Quaternion * lobj
    SV * robj
    IV swap
  CODE:
    RETVAL = newSV(0);

    // Vector3 = Quaternion * Vector3
    if (sv_isobject(robj) && sv_derived_from(robj, "Ogre::Vector3")) {
        Vector3 *rvec = (Vector3 *) SvIV((SV *) SvRV(robj));

        Vector3 *v = new Vector3;
        *v = *lobj * *rvec;
        TMOGRE_OUT(RETVAL, v, Vector3);
    }
    // Quaternion = Quaternion * Quaternion
    else if (sv_isobject(robj) && sv_derived_from(robj, "Ogre::Quaternion")) {
        Quaternion *rquat = (Quaternion *) SvIV((SV *) SvRV(robj));

        Quaternion *q = new Quaternion;
        *q = swap ? (*rquat * *lobj) : (*lobj * *rquat);
        TMOGRE_OUT(RETVAL, q, Quaternion);
    }
    else {
      croak("Quaternion::quat_mult_xs: unknown argument!\n");
    }
  OUTPUT:
    RETVAL

# neg
Quaternion *
quat_neg_xs(lobj, robj, swap)
    Quaternion * lobj
    SV * robj
    IV swap
  PREINIT:
    Quaternion *q = new Quaternion;
  CODE:
    *q = - (*lobj);
    RETVAL = q;
  OUTPUT:
    RETVAL


void
Quaternion::FromRotationMatrix(kRot)
    Matrix3 * kRot
  C_ARGS:
    *kRot

void
Quaternion::ToRotationMatrix(kRot)
    Matrix3 * kRot
  C_ARGS:
    *kRot

void
Quaternion::FromAngleAxis(rfAngle, rkAxis)
    DegRad * rfAngle
    Vector3 * rkAxis
  C_ARGS:
    *rfAngle, *rkAxis

void
Quaternion::ToAngleAxis(rfAngle, rkAxis)
    DegRad * rfAngle
    Vector3 * rkAxis
  C_ARGS:
    *rfAngle, *rkAxis

## I assume these ones are pointers to an array of Vector3??
## void FromAxes (const Vector3 *akAxis)
## void ToAxes (Vector3 *akAxis) const
void
Quaternion::FromAxes(xAxis, yAxis, zAxis)
    Vector3 * xAxis
    Vector3 * yAxis
    Vector3 * zAxis
  C_ARGS:
    *xAxis, *yAxis, *zAxis

void
Quaternion::ToAxes(xAxis, yAxis, zAxis)
    Vector3 * xAxis
    Vector3 * yAxis
    Vector3 * zAxis
  C_ARGS:
    *xAxis, *yAxis, *zAxis

Vector3 *
Quaternion::xAxis()
  CODE:
    RETVAL = new Vector3;
    *RETVAL = THIS->xAxis();
  OUTPUT:
    RETVAL

Vector3 *
Quaternion::yAxis()
  CODE:
    RETVAL = new Vector3;
    *RETVAL = THIS->yAxis();
  OUTPUT:
    RETVAL

Vector3 *
Quaternion::zAxis()
  CODE:
    RETVAL = new Vector3;
    *RETVAL = THIS->zAxis();
  OUTPUT:
    RETVAL

Real
Quaternion::Dot(rkQ)
    Quaternion * rkQ
  C_ARGS:
    *rkQ

Real
Quaternion::Norm()

Real
Quaternion::normalise()

Radian *
Quaternion::getRoll(bool reprojectAxis=true)
  CODE:
    RETVAL = new Radian;
    *RETVAL = THIS->getRoll();
  OUTPUT:
    RETVAL

Radian *
Quaternion::getPitch(bool reprojectAxis=true)
  CODE:
    RETVAL = new Radian;
    *RETVAL = THIS->getPitch();
  OUTPUT:
    RETVAL

Radian *
Quaternion::getYaw(bool reprojectAxis=true)
  CODE:
    RETVAL = new Radian;
    *RETVAL = THIS->getYaw();
  OUTPUT:
    RETVAL

bool
Quaternion::equals(rhs, tolerance)
    Quaternion * rhs
    DegRad * tolerance
  C_ARGS:
    *rhs, *tolerance


## xxx: it would be nice to be able to do this: $v->{x} = 20;
## but how is that done (the object is a pointer to a C++ object,
## not a hash). For now, we have this gimpy interface with setX, etc.

Real
Quaternion::w()
  CODE:
    RETVAL = (*THIS).w;
  OUTPUT:
    RETVAL

Real
Quaternion::x()
  CODE:
    RETVAL = (*THIS).x;
  OUTPUT:
    RETVAL

Real
Quaternion::y()
  CODE:
    RETVAL = (*THIS).y;
  OUTPUT:
    RETVAL

Real
Quaternion::z()
  CODE:
    RETVAL = (*THIS).z;
  OUTPUT:
    RETVAL

void
Quaternion::setW(w)
    Real  w
  CODE:
    (*THIS).w = w;

void
Quaternion::setX(x)
    Real  x
  CODE:
    (*THIS).x = x;

void
Quaternion::setY(y)
    Real  y
  CODE:
    (*THIS).y = y;

void
Quaternion::setZ(z)
    Real  z
  CODE:
    (*THIS).z = z;
