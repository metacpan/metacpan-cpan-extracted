MODULE = Ogre     PACKAGE = Ogre::ColourValue

ColourValue *
ColourValue::new(red=1, green=1, blue=1, alpha=1)
    Real red
    Real green
    Real blue
    Real alpha

void
ColourValue::DESTROY()

void
ColourValue::saturate()

void
ColourValue::setHSB(hue, saturation, brightness)
    Real  hue
    Real  saturation
    Real  brightness


# ==, !=
bool
eq_xs(lobj, robj, swap)
    ColourValue * lobj
    ColourValue * robj
    IV        swap
  ALIAS:
    ne_xs = 1
  CODE:
    switch(ix) {
        case 0: RETVAL = (*lobj == *robj); break;
        case 1: RETVAL = (*lobj != *robj); break;
    }
  OUTPUT:
    RETVAL


Real
ColourValue::r()
  CODE:
    RETVAL = (*THIS).r;
  OUTPUT:
    RETVAL

Real
ColourValue::g()
  CODE:
    RETVAL = (*THIS).g;
  OUTPUT:
    RETVAL

Real
ColourValue::b()
  CODE:
    RETVAL = (*THIS).b;
  OUTPUT:
    RETVAL

Real
ColourValue::a()
  CODE:
    RETVAL = (*THIS).a;
  OUTPUT:
    RETVAL
