MODULE = Ogre     PACKAGE = Ogre::Degree

Degree *
Degree::new(...)
  PREINIT:
    char *usage = "Usage: Ogre::Degree::new(CLASS [, d]) or new(CLASS, Radian)\n";
  CODE:
    // Degree()
    if (items == 1) {
        RETVAL = new Degree();
    }
    else if (items == 2) {
        // Degree(Real d)
        if (looks_like_number(ST(1))) {
            RETVAL = new Degree((Real)SvNV(ST(1)));
        }
        // Degree(const Radian &d)
        else if (sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::Radian")) {
            Radian *rad = (Radian *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN
            RETVAL = new Degree(*rad);
        }
    }
    else {
        croak("%s", usage);
    }
  OUTPUT:
    RETVAL

void
Degree::DESTROY()


# ==, !=, <, >, <=, >=
bool
deg_eq_xs(lobj, robj, swap)
    Degree * lobj
    Degree * robj
    IV        swap
  ALIAS:
    deg_ne_xs = 1
    deg_lt_xs = 2
    deg_gt_xs = 3
    deg_le_xs = 4
    deg_ge_xs = 5
  CODE:
    switch(ix) {
        case 0: RETVAL = (*lobj == *robj); break;
        case 1: RETVAL = (*lobj != *robj); break;
        case 2: RETVAL = (*lobj < *robj); break;
        case 3: RETVAL = (*lobj > *robj); break;
        case 4: RETVAL = (*lobj <= *robj); break;
        case 5: RETVAL = (*lobj >= *robj); break;
    }
  OUTPUT:
    RETVAL

# +, -  (still need others)
Degree *
deg_plus_xs(lobj, robj, swap)
    Degree * lobj
    Degree * robj
    IV        swap
  ALIAS:
    deg_minus_xs = 1
  PREINIT:
    Degree *deg = new Degree;
  CODE:
    switch(ix) {
        case 0: *deg = *lobj + *robj; break;
        case 1: *deg = swap ? (*robj - *lobj) : (*lobj - *robj); break;
    }
    RETVAL = deg;
  OUTPUT:
    RETVAL

# *
Degree *
deg_mult_xs(lobj, robj, swap)
    Degree * lobj
    SV * robj
    IV swap
  PREINIT:
    Degree *deg = new Degree;
  CODE:
    if (looks_like_number(robj)) {
        Real rhs = (Real)SvNV(robj);
        *deg = *lobj * rhs;
    }
    else if (sv_isobject(robj)) {
        DegRad * rhs;
        TMOGRE_DEGRAD_IN(robj, rhs, Ogre::Degree, deg_mult_xs);
        // note: no swap, b/c swapped returns Radian (and also it doesn't matter)
        *deg = *lobj * *rhs;
    }
    else {
        croak("Degree::deg_mult_xs: unknown argument!\n");
    }
    RETVAL = deg;
  OUTPUT:
    RETVAL

# neg
Degree *
deg_neg_xs(lobj, robj, swap)
    Degree * lobj
    SV * robj
    IV swap
  PREINIT:
    Degree *deg = new Degree;
  CODE:
    *deg = - (*lobj);
    RETVAL = deg;
  OUTPUT:
    RETVAL


Real
Degree::valueDegrees()

Real
Degree::valueRadians()

Real
Degree::valueAngleUnits()
