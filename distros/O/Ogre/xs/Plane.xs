MODULE = Ogre     PACKAGE = Ogre::Plane

Plane *
Plane::new(...)
  PREINIT:
    char *usage = "Usage: Ogre::Plane::new(CLASS [, Plane]) or new(CLASS, Vector3, Real) or...\n";
  CODE:
    // Plane()
    if (items == 1) {
        RETVAL = new Plane();
    }
    // 1st arg is a Vector3
    else if (sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::Vector3")) {
        Vector3 *vec = (Vector3 *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN

        // Plane (const Vector3 &rkNormal, Real fConstant)
        if (looks_like_number(ST(2))) {
            RETVAL = new Plane(*vec, (Real)SvNV(ST(2)));
        }
        else if (sv_isobject(ST(2)) && sv_derived_from(ST(2), "Ogre::Vector3")) {
            Vector3 *vec2 = (Vector3 *) SvIV((SV *) SvRV(ST(2)));   // TMOGRE_IN

            // Plane (const Vector3 &rkNormal, const Vector3 &rkPoint)
            if (items == 3) {
                RETVAL = new Plane(*vec, *vec2);
            }
            // Plane(const Vector3 &rkPoint0, const Vector3 &rkPoint1, const Vector3 &rkPoint2)
            else if (sv_isobject(ST(3)) && sv_derived_from(ST(3), "Ogre::Vector3")) {
                Vector3 *vec3 = (Vector3 *) SvIV((SV *) SvRV(ST(3)));   // TMOGRE_IN
                RETVAL = new Plane(*vec, *vec2, *vec3);
            }
            else {
                croak("%s", usage);
            }
        }
        else {
            croak("%s", usage);
        }
    }
    // Plane (const Plane &rhs)
    else if (sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::Plane")) {
        Plane *plane = (Plane *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN
        RETVAL = new Plane(*plane);
    }
    else {
        croak("%s", usage);
    }
  OUTPUT:
    RETVAL

void
Plane::DESTROY()


# OVERLOAD: == !=


## xxx: 3 x getSide

Real
Plane::getDistance(rkPoint)
    Vector3 * rkPoint
  C_ARGS:
    *rkPoint

## xxx: 2 x redefine

## Vector3 	projectVector (const Vector3 &v) const
#Vector3 *
#Plane::projectVector(v)
#    Vector3 * v
#  C_ARGS:
#    *v

Real
Plane::normalise()




Real
Plane::d()
  CODE:
    RETVAL = (*THIS).d;
  OUTPUT:
    RETVAL

# xxx: note: this is just:  Plane p; p.d = d;  in C++....
void
Plane::setD(d)
    Real  d
  CODE:
    (*THIS).d = d;

Vector3 *
Plane::normal()
  CODE:
    RETVAL = new Vector3;
    *RETVAL = (*THIS).normal;
  OUTPUT:
    RETVAL

# xxx: this does not exist in C++ either
void
Plane::setNormal(normal)
    Vector3 * normal
  CODE:
    (*THIS).normal = *normal;
