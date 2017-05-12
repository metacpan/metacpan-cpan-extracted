MODULE = Ogre     PACKAGE = Ogre::Sphere

## xxx: constructors, destructor, then tests thereof
## do intersects below

Real
Sphere::getRadius()

void
Sphere::setRadius(Real radius)

## const Vector3 & 	getCenter (void)

void
Sphere::setCenter(center)
    Vector3 * center
  C_ARGS:
    *center

#bool
#Sphere::intersects(s)
#    Sphere * s
#  C_ARGS:
#    *s
#
#bool
#Sphere::intersects(box)
#    AxisAlignedBox * box
#  C_ARGS:
#    *box
#
#bool
#Sphere::intersects(plane)
#    Plane * plane
#  C_ARGS:
#    *plane
#
#bool
#Sphere::intersects(v)
#    Vector3 * v
#  C_ARGS:
#    *v
