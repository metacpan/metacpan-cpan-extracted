MODULE = Ogre     PACKAGE = Ogre::Matrix4

## xxx: constructors, destructor, operators


## Matrix4 	transpose (void) const

void
Matrix4::setTrans(v)
    Vector3 * v
  C_ARGS:
    *v

## Vector3 	getTrans () const

## xxx:  void 	makeTrans (Real tx, Real ty, Real tz)
void
Matrix4::makeTrans(v)
    Vector3 * v
  C_ARGS:
    *v

void
Matrix4::setScale(v)
    Vector3 * v
  C_ARGS:
    *v

## void 	extract3x3Matrix (Matrix3 &m3x3) const

## Quaternion 	extractQuaternion () const

## Matrix4 	adjoint () const

Real
Matrix4::determinant()

## Matrix4 	inverse () const

void
Matrix4::makeTransform(position, scale, orientation)
    Vector3 * position
    Vector3 * scale
    Quaternion * orientation
  C_ARGS:
    *position, *scale, *orientation

void
Matrix4::makeInverseTransform(position, scale, orientation)
    Vector3 * position
    Vector3 * scale
    Quaternion * orientation
  C_ARGS:
    *position, *scale, *orientation

bool
Matrix4::isAffine()

## Matrix4 	inverseAffine (void) const

## Matrix4 	concatenateAffine (const Matrix4 &m2) const

## Vector3 	transformAffine (const Vector3 &v) const

## Vector4 	transformAffine (const Vector4 &v) const
