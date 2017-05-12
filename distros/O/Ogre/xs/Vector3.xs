MODULE = Ogre     PACKAGE = Ogre::Vector3

Vector3 *
Vector3::new(...)
  PREINIT:
    char *usage = "Usage: Ogre::Vector3::new(CLASS, x [, y, z]) or new(CLASS, Vector3)\n";
  CODE:
    // Vector3(const Real fX, const Real fY, const Real fZ)
    if (items == 4) {
        RETVAL = new Vector3((Real)SvNV(ST(1)), (Real)SvNV(ST(2)), (Real)SvNV(ST(3)));
    }
    else if (items == 2) {
        // Vector3(const Vector3 &rkVector)
        if (sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::Vector3")) {
            Vector3 *vec = (Vector3 *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN
            RETVAL = new Vector3(*vec);
        }
        // Vector3(const Real scalar)
        else if (looks_like_number(ST(1))) {
            RETVAL = new Vector3((Real)SvNV(ST(1)));
        }
        else {
            croak("%s", usage);
        }
    }
    else if (items == 1) {
        RETVAL = new Vector3();
    }
    else {
        croak("%s", usage);
    }
  OUTPUT:
    RETVAL

void
Vector3::DESTROY()

## xxx: need to check assignment operator

# ==, !=, <, >
bool
vec3_eq_xs(lobj, robj, swap)
    Vector3 * lobj
    Vector3 * robj
    IV        swap
  ALIAS:
    vec3_ne_xs = 1
    vec3_lt_xs = 2
    vec3_gt_xs = 3
  CODE:
    switch(ix) {
        case 0: RETVAL = (*lobj == *robj); break;
        case 1: RETVAL = (*lobj != *robj); break;
        case 2: RETVAL = (*lobj < *robj); break;
        case 3: RETVAL = (*lobj > *robj); break;
    }
  OUTPUT:
    RETVAL

# +, -, /   (need Real also)
Vector3 *
vec3_plus_xs(lobj, robj, swap)
    Vector3 * lobj
    Vector3 * robj
    IV        swap
  ALIAS:
    vec3_minus_xs = 1
    vec3_div_xs = 2
  PREINIT:
    Vector3 *vec = new Vector3;
  CODE:
    switch(ix) {
        case 0: *vec = *lobj + *robj; break;
        case 1: *vec = swap ? (*robj - *lobj) : (*lobj - *robj); break;
        case 2: *vec = swap ? (*robj / *lobj) : (*lobj / *robj); break;
    }
    RETVAL = vec;
  OUTPUT:
    RETVAL

# * (handles Quaternion also)
Vector3 *
vec3_mult_xs(lobj, robj, swap)
    Vector3 * lobj
    SV * robj
    IV swap
  PREINIT:
    Vector3 *vec = new Vector3;
  CODE:
    if (sv_isobject(robj) && sv_derived_from(robj, "Ogre::Vector3")) {
        const Vector3 *rhs = (Vector3 *) SvIV((SV *) SvRV(robj));
        *vec = swap ? (*rhs * *lobj) : (*lobj * *rhs);
    }
    else if (sv_isobject(robj) && sv_derived_from(robj, "Ogre::Quaternion")) {
        const Quaternion *rhs = (Quaternion *) SvIV((SV *) SvRV(robj));
        // note reversal - only Q * V is allowed, so args must be reversed
        if (swap) {
            *vec = (*rhs) * (*lobj);
        }
        else {
            croak("Vector3::mult_xs: reversed args (Quaternion must precede Vector3\n");
        }
    }
    else if (looks_like_number(robj)) {
        Real rhs = (Real)SvNV(robj);
        *vec = *lobj * rhs;
    }
    else {
        croak("Vector3::vec3_mult_xs: unknown argument!\n");
    }
    RETVAL = vec;
  OUTPUT:
    RETVAL

# neg
Vector3 *
vec3_neg_xs(lobj, robj, swap)
    Vector3 * lobj
    SV * robj
    IV swap
  PREINIT:
    Vector3 *vec = new Vector3;
  CODE:
    *vec = - (*lobj);
    RETVAL = vec;
  OUTPUT:
    RETVAL

## xxx: +=, -=, *=, /= (with Real too)

Real
Vector3::length()

Real
Vector3::squaredLength()

Real
Vector3::distance(rhs)
    Vector3 * rhs
  C_ARGS:
    *rhs

Real
Vector3::squaredDistance(rhs)
    Vector3 * rhs
  C_ARGS:
    *rhs

Real
Vector3::dotProduct(vec)
    Vector3 * vec
  C_ARGS:
    *vec

Real
Vector3::absDotProduct(vec)
    Vector3 * vec
  C_ARGS:
    *vec

Real
Vector3::normalise()

Vector3 *
Vector3::crossProduct(rkVector)
    const Vector3 * rkVector
  CODE:
    RETVAL = new Vector3;
    *RETVAL = THIS->crossProduct(*rkVector);
  OUTPUT:
    RETVAL

Vector3 *
Vector3::midPoint(rkVector)
    const Vector3 * rkVector
  CODE:
    RETVAL = new Vector3;
    *RETVAL = THIS->midPoint(*rkVector);
  OUTPUT:
    RETVAL

void
Vector3::makeFloor(cmp)
    Vector3 * cmp
  C_ARGS:
    *cmp

void
Vector3::makeCeil(cmp)
    Vector3 * cmp
  C_ARGS:
    *cmp

Vector3 *
Vector3::perpendicular()
  CODE:
    RETVAL = new Vector3;
    *RETVAL = THIS->perpendicular();
  OUTPUT:
    RETVAL

Vector3 *
Vector3::randomDeviant(angle, up=&Vector3::ZERO)
    DegRad * angle
    const Vector3 * up
  CODE:
    RETVAL = new Vector3;
    *RETVAL = THIS->randomDeviant(*angle, *up);
  OUTPUT:
    RETVAL

Quaternion *
Vector3::getRotationTo(dest, fallbackAxis=&Vector3::ZERO)
    const Vector3 * dest
    const Vector3 * fallbackAxis
  CODE:
    RETVAL = new Quaternion;
    *RETVAL = THIS->getRotationTo(*dest, *fallbackAxis);
  OUTPUT:
    RETVAL

bool
Vector3::isZeroLength()

Vector3 *
Vector3::normalisedCopy()
  CODE:
    RETVAL = new Vector3;
    *RETVAL = THIS->normalisedCopy();
  OUTPUT:
    RETVAL

Vector3 *
Vector3::reflect(normal)
    const Vector3 * normal
  CODE:
    RETVAL = new Vector3;
    *RETVAL = THIS->reflect(*normal);
  OUTPUT:
    RETVAL

bool
Vector3::positionEquals(rhs, tolerance=0.001)
    Vector3 * rhs
    Real  tolerance
  C_ARGS:
    *rhs, tolerance

bool
Vector3::positionCloses(rhs, tolerance=0.001)
    Vector3 * rhs
    Real  tolerance
  C_ARGS:
    *rhs, tolerance

bool
Vector3::directionEquals(rhs, tolerance)
    Vector3 * rhs
    DegRad * tolerance
  C_ARGS:
    *rhs, *tolerance


## xxx: it would be nice to be able to do this: $v->{x} = 20;
## but how is that done (the object is a pointer to a C++ object,
## not a hash). For now, we have this gimpy interface with setX, etc.

Real
Vector3::x()
  CODE:
    RETVAL = (*THIS).x;
  OUTPUT:
    RETVAL

Real
Vector3::y()
  CODE:
    RETVAL = (*THIS).y;
  OUTPUT:
    RETVAL

Real
Vector3::z()
  CODE:
    RETVAL = (*THIS).z;
  OUTPUT:
    RETVAL

void
Vector3::setX(x)
    Real  x
  CODE:
    (*THIS).x = x;

void
Vector3::setY(y)
    Real  y
  CODE:
    (*THIS).y = y;

void
Vector3::setZ(z)
    Real  z
  CODE:
    (*THIS).z = z;
