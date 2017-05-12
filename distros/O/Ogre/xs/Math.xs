MODULE = Ogre     PACKAGE = Ogre::Math

static int
Math::IAbs(int iValue)

static int
Math::ICeil(float fValue)

static int
Math::IFloor(float fValue)

static int
Math::ISign(int iValue)

## XXX: there are also Degree and Radian versions of this
static Real
Math::Abs(Real fValue)

#static Radian *
#Math::ACos(Real fValue)
#
#static Radian *
#Math::ASin(Real fValue)
#
#static Radian *
#Math::ATan(Real fValue)
#
#static Radian *
#Math::ATan2(Real fY, Real fX)

static Real
Math::Ceil(Real fValue)

## XXX: there is also a Real (not Degree??) version of this
static Real
Math::Cos(fValue, useTables=false)
    Radian * fValue
    bool  useTables
  C_ARGS:
    *fValue, useTables

static Real
Math::Exp(Real fValue)

static Real
Math::Floor(Real fValue)

static Real
Math::Log(Real fValue)

static Real
Math::Pow(Real fBase, Real fExponent)

## XXX: there are also Radian and Degree versions of this
static Real
Math::Sign(Real fValue)

## XXX: there is also a Real (not Degree??) version of this
static Real
Math::Sin(fValue, useTables=false)
    Radian * fValue
    bool  useTables
  C_ARGS:
    *fValue, useTables

static Real
Math::Sqr(Real fValue)

## XXX: there are also Radian and Degree versions of this
static Real
Math::Sqrt(Real fValue)

static Real
Math::InvSqrt(Real fValue)

static Real
Math::UnitRandom()

static Real
Math::RangeRandom(Real fLow, Real fHigh)

static Real
Math::SymmetricRandom()

## XXX: there is also a Real (not Degree??) version of this
static Real
Math::Tan(fValue, useTables=false)
    Radian * fValue
    bool  useTables
  C_ARGS:
    *fValue, useTables

static Real
Math::DegreesToRadians(Real degrees)

static Real
Math::RadiansToDegrees(Real radians)

## XXX: this is deprecated
static void
Math::setAngleUnit(unit)
    int  unit
  C_ARGS:
    (Ogre::Math::AngleUnit)unit

static int
Math::getAngleUnit()

static Real
Math::AngleUnitsToRadians(Real units)

static Real
Math::RadiansToAngleUnits(Real radians)

static Real
Math::AngleUnitsToDegrees(Real units)

static Real
Math::DegreesToAngleUnits(Real degrees)

static bool
Math::pointInTri2D(p, a, b, c)
    Vector2 * p
    Vector2 * a
    Vector2 * b
    Vector2 * c
  C_ARGS:
    *p, *a, *b, *c

static bool
Math::pointInTri3D(p, a, b, c, normal)
    Vector3 * p
    Vector3 * a
    Vector3 * b
    Vector3 * c
    Vector3 * normal
  C_ARGS:
    *p, *a, *b, *c, *normal


#static std::pair< bool, Real >
#Math::intersects(const Ray &ray, const Plane &plane)
#
#static std::pair< bool, Real >
#Math::intersects(const Ray &ray, const Sphere &sphere, bool discardInside=true)
#
#static std::pair< bool, Real >
#Math::intersects(const Ray &ray, const AxisAlignedBox &box)
#
#static bool
#Math::intersects(const Ray &ray, const AxisAlignedBox &box, Real *d1, Real *d2)
#
#static std::pair< bool, Real >
#Math::intersects(const Ray &ray, const Vector3 &a, const Vector3 &b, const Vector3 &c, const Vector3 &normal, bool positiveSide=true, bool negativeSide=true)
#
#static std::pair< bool, Real >
#Math::intersects(const Ray &ray, const Vector3 &a, const Vector3 &b, const Vector3 &c, bool positiveSide=true, bool negativeSide=true)
#
#static bool
#Math::intersects(const Sphere &sphere, const AxisAlignedBox &box)
#
#static bool
#Math::intersects(const Plane &plane, const AxisAlignedBox &box)
#
#static std::pair< bool, Real >
#Math::intersects(const Ray &ray, const std::vector< Plane > &planeList, bool normalIsOutside)
#
#static std::pair< bool, Real >
#Math::intersects(const Ray &ray, const std::list< Plane > &planeList, bool normalIsOutside)
#
#static bool
#Math::intersects(const Sphere &sphere, const Plane &plane)


## XXX: left out 3rd arg
## static bool 	RealEqual (Real a, Real b, Real tolerance=std::numeric_limits< Real >::epsilon())
static bool
Math::RealEqual(Real a, Real b)
  CODE:
    RETVAL = Math::RealEqual(a, b);
  OUTPUT:
    RETVAL


#static Vector3
#Math::calculateTangentSpaceVector(const Vector3 &position1, const Vector3 &position2, const Vector3 &position3, Real u1, Real v1, Real u2, Real v2, Real u3, Real v3)
#
#static Matrix4
#Math::buildReflectionMatrix(const Plane &p)
#
#static Vector4
#Math::calculateFaceNormal(const Vector3 &v1, const Vector3 &v2, const Vector3 &v3)
#
#static Vector3
#Math::calculateBasicFaceNormal(const Vector3 &v1, const Vector3 &v2, const Vector3 &v3)
#
#static Vector4
#Math::calculateFaceNormalWithoutNormalize(const Vector3 &v1, const Vector3 &v2, const Vector3 &v3)
#
#static Vector3
#Math::calculateBasicFaceNormalWithoutNormalize(const Vector3 &v1, const Vector3 &v2, const Vector3 &v3)


static Real
Math::gaussianDistribution(Real x, Real offset=0.0f, Real scale=1.0f)



### note: there are also Static Public Attributes, like TWO_PI,
### at the bottom of Ogre.xs
