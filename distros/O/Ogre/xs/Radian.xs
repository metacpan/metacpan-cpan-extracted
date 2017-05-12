MODULE = Ogre     PACKAGE = Ogre::Radian

Radian *
Radian::new(...)
  PREINIT:
    char *usage = "Usage: Ogre::Radian::new(CLASS [, d]) or new(CLASS, Degree)\n";
  CODE:
    // Radian()
    if (items == 1) {
        RETVAL = new Radian();
    }
    else if (items == 2) {
        // Radian(Real r)
        if (looks_like_number(ST(1))) {
            RETVAL = new Radian((Real)SvNV(ST(1)));
        }
        // Radian(const Degree &d)
        else if (sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::Degree")) {
            Degree *deg = (Degree *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN
            RETVAL = new Radian(*deg);
        }
    }
    else {
        croak("%s", usage);
    }
  OUTPUT:
    RETVAL

void
Radian::DESTROY()


# ==, !=, <, >, <=, >=
bool
rad_eq_xs(lobj, robj, swap)
    Radian * lobj
    Radian * robj
    IV        swap
  ALIAS:
    rad_ne_xs = 1
    rad_lt_xs = 2
    rad_gt_xs = 3
    rad_le_xs = 4
    rad_ge_xs = 5
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

# +, -   (still need other variations with Real, etc)
Radian *
rad_plus(lobj, robj, swap)
    Radian * lobj
    Radian * robj
    IV        swap
  ALIAS:
    rad_minus_xs = 1
  PREINIT:
    Radian *rad = new Radian;
  CODE:
    switch(ix) {
        case 0: *rad = *lobj + *robj; break;
        case 1: *rad = swap ? (*robj - *lobj) : (*lobj - *robj); break;
    }
    RETVAL = rad;
  OUTPUT:
    RETVAL

# *
Radian *
rad_mult_xs(lobj, robj, swap)
    Radian * lobj
    SV * robj
    IV swap
  PREINIT:
    Radian *rad = new Radian;
  CODE:
    if (looks_like_number(robj)) {
        Real rhs = (Real)SvNV(robj);
        *rad = *lobj * rhs;
    }
    else if (sv_isobject(robj)) {
        DegRad * rhs;
        TMOGRE_DEGRAD_IN(robj, rhs, Ogre::Radian, rad_mult_xs);
        *rad = swap ? (*rhs * *lobj) : (*lobj * *rhs);
    }
    else {
        croak("Radian::rad_mult_xs: unknown argument!\n");
    }
    RETVAL = rad;
  OUTPUT:
    RETVAL

# neg
Radian *
rad_neg_xs(lobj, robj, swap)
    Radian * lobj
    SV * robj
    IV swap
  PREINIT:
    Radian *rad = new Radian;
  CODE:
    *rad = - (*lobj);
    RETVAL = rad;
  OUTPUT:
    RETVAL


Real
Radian::valueDegrees()

Real
Radian::valueRadians()

Real
Radian::valueAngleUnits()
