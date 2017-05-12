MODULE = Ogre     PACKAGE = Ogre::Matrix3

Matrix3 *
Matrix3::new(...)
  PREINIT:
    char *usage = "Ogre::Matrix3::new(CLASS [Real, ...]) or new(CLASS, Matrix3)\n";
  CODE:
    // Matrix()
    if (items == 1) {
        RETVAL = new Matrix3();
    }
    else if (items == 10) {
        // assuming all these are numbers...
        RETVAL = new Matrix3((Real)SvNV(ST(1)), (Real)SvNV(ST(2)), (Real)SvNV(ST(3)),
                             (Real)SvNV(ST(4)), (Real)SvNV(ST(5)), (Real)SvNV(ST(6)),
                             (Real)SvNV(ST(7)), (Real)SvNV(ST(8)), (Real)SvNV(ST(9)));
    }
    // Matrix3 (const Matrix3 &rkMatrix)
    else if (sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::Matrix3")) {
        Matrix3 *m = (Matrix3 *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN
        RETVAL = new Matrix3(*m);
    }
    else {
        croak("%s", usage);
    }

void
Matrix3::DESTROY()

