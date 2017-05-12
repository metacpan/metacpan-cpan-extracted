#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_newRV_noinc
#include "ppport.h"

/* These functions when properly replaced could implement a PDL backend */

SV * make_container (int num, int steps) {
  return newRV_noinc((SV*)newAV());
}

int store_data (SV* holder, int num, const double t, const double y[]) {
  int i;
  AV* data = newAV();

  av_push(data, newSVnv(t));
  for (i = 0; i < num; i++) {
    av_push(data, newSVnv(y[i]));
  }

  av_push((AV *)SvRV(holder), newRV_noinc((SV *)data));

  return 0;
}


