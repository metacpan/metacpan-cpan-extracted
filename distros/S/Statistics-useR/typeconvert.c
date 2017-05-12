#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdio.h>
#include <stdlib.h>
#include <Rembedded.h>
#include <Rmath.h>
#include <Rinterface.h>
#include <Rinternals.h>
#include <R_ext/Parse.h>
#include <Rdefines.h>

void * get_mortalspace(int bytescount) {
  SV * mortal;
  mortal = sv_2mortal(NEWSV(0, bytescount));
  return SvPVX(mortal);
}

char ** XS_unpack_charPtrPtr(SV* arg) {
  AV * avref;
  char ** array;
  int len;
  SV ** elem;
  int i;

  if(SvROK(arg) && SvTYPE(SvRV(arg))==SVt_PVAV) {
    avref = (AV*)SvRV(arg);
    len = av_len(avref) + 1;
    array = (char**)get_mortalspace( (len+1) * sizeof(*array) );

    for(i=0;i<len;i++) {
      elem = av_fetch(avref, i, 0);
      array[i] = SvPV_nolen(*elem);
    }
    array[len] = NULL;
  }
  else {
    array = NULL;
  }

  return array;
}

void XS_pack_charPtrPtr(SV* arg, char** array, int count) {
  int i;
  AV * avref;

  avref = (AV*)sv_2mortal((SV*)newAV());
  for(i=0;i<count;i++) {
    av_push(avref, newSVpv(array[i], strlen(array[i])));
  }
  SvSetSV(arg, newRV((SV*)avref));
}
