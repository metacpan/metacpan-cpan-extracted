#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"



static int do_compare(unsigned char *a, unsigned char *b, size_t n) {
  size_t i;
  unsigned char r = 0;

  for (i = 0; i < n; i++) {
    r |= *a++ ^ *b++;
  }

  return r;
}



MODULE = String::Compare::ConstantTime		PACKAGE = String::Compare::ConstantTime

PROTOTYPES: ENABLE



int
equals(a, b)
        SV *a
        SV *b
    CODE:
        size_t alen;
        unsigned char *ap;
        size_t blen;
        unsigned char *bp;
        int r;

        SvGETMAGIC(a);
        SvGETMAGIC(b);

        if (SvOK(a) && SvOK(b)) {
          ap = SvPV(a, alen);
          bp = SvPV(b, blen);

          if (alen == blen) {
            r = !do_compare(ap, bp, alen);
          } else {
            r = 0;
          }
        } else if (SvOK(a) || SvOK(b)) {
          r = 0;
        } else {
          r = 1;
        }

        RETVAL = r;

    OUTPUT:
        RETVAL
