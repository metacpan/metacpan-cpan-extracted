#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

/* rotate/flip a quadrant appropriately */
static void hilbert_rot(IV n, IV *x, IV *y, IV rx, IV ry) {
  if (ry) {
    return;
  }

  if (rx) {
    *x = n - 1 - *x;
    *y = n - 1 - *y;
  }

  /* swap x and y, reusing ry shamelessly */
  ry  = *x;
  *x = *y;
  *y = ry;
}

static IV hilbert_valid_n(IV side) {
  int count = 0;
  for (count = 0; side > 0; ++count) {
    side >>= 1;
  }
  return 1 << (count - 1);
}

/* convert (x,y) to d */
static IV hilbert_xy2d(IV side, IV x, IV y) {
    IV n = hilbert_valid_n(side);
    IV d = 0;
    IV s;

    for (s = n / 2; s > 0; s /= 2) {
      IV rx = (x & s) > 0;
      IV ry = (y & s) > 0;
      d += s * s * ((3 * rx) ^ ry);
      hilbert_rot(s, &x, &y, rx, ry);
    }

    return d * side / n;
}

/* convert d to (x,y) */
static void hilbert_d2xy(IV side, IV d, IV *x, IV *y) {
    IV n = hilbert_valid_n(side);
    IV t = d;
    IV s;

    *x = 0;
    *y = 0;

    for (s = 1; s < n; s *= 2) {
      IV rx = 1 & (t / 2);
      IV ry = 1 & (t ^ rx);
      hilbert_rot(s, x, y, rx, ry);
      *x += s * rx;
      *y += s * ry;
      t /= 4;
    }
    *x *= side / n;
    *y *= side / n;
}


MODULE = Path::Hilbert::XS		PACKAGE = Path::Hilbert::XS
PROTOTYPES: DISABLE

# convert (x,y) to d
IV
xy2d(IV side, IV x, IV y)

  CODE:
    RETVAL = hilbert_xy2d(side, x, y);

  OUTPUT: RETVAL


# convert d to (x,y)
void
d2xy(IV side, IV d)

  PREINIT:
    IV x;
    IV y;

  PPCODE:
    hilbert_d2xy(side, d, &x, &y);

    EXTEND(SP, 2);
    mPUSHi(x);
    mPUSHi(y);
