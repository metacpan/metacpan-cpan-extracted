MODULE = Ogre     PACKAGE = Ogre::Ray

Ray *
Ray::new(...)
  PREINIT:
    char *usage = "Usage: Ogre::Ray::new(CLASS) or (CLASS, vec, vec)\n";
  CODE:
    if (items == 1) {
        RETVAL = new Ray();
    }
    else if (items == 3 && sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::Vector3")
             && sv_isobject(ST(2)) && sv_derived_from(ST(2), "Ogre::Vector3"))
    {
        Vector3 *origin = (Vector3 *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN
        Vector3 *direction = (Vector3 *) SvIV((SV *) SvRV(ST(2)));   // TMOGRE_IN
        RETVAL = new Ray(*origin, *direction);
    }
    else {
        croak("%s", usage);
    }
  OUTPUT:
    RETVAL

void
Ray::DESTROY()

## Vector3 	operator * (Real t) const

void
Ray::setOrigin(origin)
    Vector3 * origin
  C_ARGS:
    *origin

Vector3 *
Ray::getOrigin()
  CODE:
    RETVAL = new Vector3;
    *RETVAL = THIS->getOrigin();
  OUTPUT:
    RETVAL

void
Ray::setDirection(dir)
    Vector3 * dir
  C_ARGS:
    *dir

Vector3 *
Ray::getDirection()
  CODE:
    RETVAL = new Vector3;
    *RETVAL = THIS->getDirection();
  OUTPUT:
    RETVAL

Vector3 *
Ray::getPoint(Real t)
  CODE:
    RETVAL = new Vector3;
    *RETVAL = THIS->getPoint(t);
  OUTPUT:
    RETVAL

##std::pair< bool, Real > 	intersects ( Plane &p) 
##std::pair< bool, Real > 	intersects ( PlaneBoundedVolume &p) 
##std::pair< bool, Real > 	intersects ( Sphere &s) 
##std::pair< bool, Real > 	intersects ( AxisAlignedBox &box)

