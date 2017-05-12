MODULE = Ogre     PACKAGE = Ogre::Vector2

## xxx: operator overloading methods

Vector2 *
Vector2::new(...)
  PREINIT:
    char *usage = "Usage: Ogre::Vector2::new(CLASS, x [, y]) or new(CLASS, Vector2)\n";
  CODE:
    // Vector2(const Real fX, const Real fY)
    if (items == 3) {
        RETVAL = new Vector2((Real)SvNV(ST(1)), (Real)SvNV(ST(2)));
    }
    else if (items == 2) {
        // Vector2(const Vector2 &rkVector)
        if (sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::Vector2")) {
            Vector2 *vec = (Vector2 *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN
            RETVAL = new Vector2(*vec);
        }
        // Vector2(const Real scalar)
        else if (looks_like_number(ST(1))) {
            RETVAL = new Vector2((Real)SvNV(ST(1)));
        }
        else {
            croak("%s", usage);
        }
    }
    else if (items == 1) {
        RETVAL = new Vector2();
    }
    else {
        croak("%s", usage);
    }
  OUTPUT:
    RETVAL

void
Vector2::DESTROY()

## xxx: need to check assignment operator

# ==, !=, <, >
bool
vec2_eq_xs(lobj, robj, swap)
    Vector2 * lobj
    Vector2 * robj
    IV        swap
  ALIAS:
    vec2_ne_xs = 1
    vec2_lt_xs = 2
    vec2_gt_xs = 3
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
Vector2 *
vec2_plus_xs(lobj, robj, swap)
    Vector2 * lobj
    Vector2 * robj
    IV        swap
  ALIAS:
    vec2_minus_xs = 1
    vec2_div_xs = 2
  PREINIT:
    Vector2 *vec = new Vector2;
  CODE:
    switch(ix) {
        case 0: *vec = *lobj + *robj; break;
        case 1: *vec = swap ? (*robj - *lobj) : (*lobj - *robj); break;
        case 2: *vec = swap ? (*robj / *lobj) : (*lobj / *robj); break;
    }
    RETVAL = vec;
  OUTPUT:
    RETVAL

# *
Vector2 *
vec2_mult_xs(lobj, robj, swap)
    Vector2 * lobj
    SV * robj
    IV swap
  PREINIT:
    Vector2 *vec = new Vector2;
  CODE:
    if (sv_isobject(robj) && sv_derived_from(robj, "Ogre::Vector2")) {
        const Vector2 *rhs = (Vector2 *) SvIV((SV *) SvRV(robj));
        *vec = *lobj * *rhs;
    }
    else if (looks_like_number(robj)) {
        Real rhs = (Real)SvNV(robj);
        *vec = *lobj * rhs;
    }
    else {
        croak("Vector2::vec2_mult_xs: unknown argument!\n");
    }
    RETVAL = vec;
  OUTPUT:
    RETVAL

# neg
Vector2 *
vec2_neg_xs(lobj, robj, swap)
    Vector2 * lobj
    SV * robj
    IV swap
  PREINIT:
    Vector2 *vec = new Vector2;
  CODE:
    *vec = - (*lobj);
    RETVAL = vec;
  OUTPUT:
    RETVAL

## xxx: +=, -=, *=, /= (with Real too)

Real
Vector2::length()

Real
Vector2::squaredLength()

Real
Vector2::dotProduct(vec)
    Vector2 * vec
  C_ARGS:
    *vec

Real
Vector2::normalise()

## Vector2 	midPoint (const Vector2 &vec) const

void
Vector2::makeFloor(cmp)
    Vector2 * cmp
  C_ARGS:
    *cmp

void
Vector2::makeCeil(cmp)
    Vector2 * cmp
  C_ARGS:
    *cmp

## Vector2 	perpendicular (void) const

Real
Vector2::crossProduct(rkVector)
    Vector2 * rkVector
  C_ARGS:
    *rkVector

## Vector2 	randomDeviant (Real angle) const

bool
Vector2::isZeroLength()

## Vector2 	normalisedCopy (void) const

## Vector2 	reflect (const Vector2 &normal) const



## xxx: it would be nice to be able to do this: $v->{x} = 20;
## but how is that done (the object is a pointer to a C++ object,
## not a hash). For now, we have this gimpy interface with setX, etc.

Real
Vector2::x()
  CODE:
    RETVAL = (*THIS).x;
  OUTPUT:
    RETVAL

Real
Vector2::y()
  CODE:
    RETVAL = (*THIS).y;
  OUTPUT:
    RETVAL

void
Vector2::setX(x)
    Real  x
  CODE:
    (*THIS).x = x;

void
Vector2::setY(y)
    Real  y
  CODE:
    (*THIS).y = y;
