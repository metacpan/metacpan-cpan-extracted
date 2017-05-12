#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "SOOT_RTXS.h"
#include "SOOT_RTXS_macros.h"

MODULE = SOOT        PACKAGE = SOOT::RTXS
PROTOTYPES: DISABLE

void
access_struct_Bool_t(self, ...)
    SV* self;
  ALIAS:
  INIT:
    SOOT_RTXS_INIT
  PPCODE:
    SOOT_RTXS_CALCADDRESS
    if (items > 1) {
      SV* src = ST(1);
      *((Bool_t*)dataAddr) = (Bool_t)SvIV(src);
    } else {
      XPUSHs(sv_2mortal(
        newSViv((IV) *((Bool_t*)dataAddr))
      ));
    }

void
access_struct_Char_t(self, ...)
    SV* self;
  ALIAS:
  INIT:
    SOOT_RTXS_INIT
  PPCODE:
    SOOT_RTXS_CALCADDRESS
    if (items > 1) {
      SV* src = ST(1);
      *((Char_t*)dataAddr) = (Char_t)SvIV(src);
    } else {
      XPUSHs(sv_2mortal(
        newSViv((IV) *((Char_t*)dataAddr))
      ));
    }

void
access_struct_UChar_t(self, ...)
    SV* self;
  ALIAS:
  INIT:
    SOOT_RTXS_INIT
  PPCODE:
    SOOT_RTXS_CALCADDRESS
    if (items > 1) {
      SV* src = ST(1);
      *((UChar_t*)dataAddr) = (UChar_t)SvUV(src);
    } else {
      XPUSHs(sv_2mortal(
        newSVuv((UV) *((UChar_t*)dataAddr))
      ));
    }

void
access_struct_Short_t(self, ...)
    SV* self;
  ALIAS:
  INIT:
    SOOT_RTXS_INIT
  PPCODE:
    SOOT_RTXS_CALCADDRESS
    if (items > 1) {
      SV* src = ST(1);
      *((Short_t*)dataAddr) = (Short_t)SvIV(src);
    } else {
      XPUSHs(sv_2mortal(
        newSViv((IV) *((Short_t*)dataAddr))
      ));
    }

void
access_struct_UShort_t(self, ...)
    SV* self;
  ALIAS:
  INIT:
    SOOT_RTXS_INIT
  PPCODE:
    SOOT_RTXS_CALCADDRESS
    if (items > 1) {
      SV* src = ST(1);
      *((UShort_t*)dataAddr) = (UShort_t)SvUV(src);
    } else {
      XPUSHs(sv_2mortal(
        newSVuv((UV) *((UShort_t*)dataAddr))
      ));
    }

void
access_struct_Int_t(self, ...)
    SV* self;
  ALIAS:
  INIT:
    SOOT_RTXS_INIT
  PPCODE:
    SOOT_RTXS_CALCADDRESS
    if (items > 1) {
      SV* src = ST(1);
      *((Int_t*)dataAddr) = (Int_t)SvIV(src);
    } else {
      XPUSHs(sv_2mortal(
        newSViv((IV) *((Int_t*)dataAddr))
      ));
    }

void
access_struct_UInt_t(self, ...)
    SV* self;
  ALIAS:
  INIT:
    SOOT_RTXS_INIT
  PPCODE:
    SOOT_RTXS_CALCADDRESS
    if (items > 1) {
      SV* src = ST(1);
      *((UInt_t*)dataAddr) = (UInt_t)SvUV(src);
    } else {
      XPUSHs(sv_2mortal(
        newSVuv((UV) *((UInt_t*)dataAddr))
      ));
    }

void
access_struct_Long_t(self, ...)
    SV* self;
  ALIAS:
  INIT:
    SOOT_RTXS_INIT
  PPCODE:
    SOOT_RTXS_CALCADDRESS
    if (items > 1) {
      SV* src = ST(1);
      *((Long_t*)dataAddr) = (Long_t)SvIV(src);
    } else {
      XPUSHs(sv_2mortal(
        newSViv((IV) *((Long_t*)dataAddr))
      ));
    }

void
access_struct_ULong_t(self, ...)
    SV* self;
  ALIAS:
  INIT:
    SOOT_RTXS_INIT
  PPCODE:
    SOOT_RTXS_CALCADDRESS
    if (items > 1) {
      SV* src = ST(1);
      *((ULong_t*)dataAddr) = (ULong_t)SvUV(src);
    } else {
      XPUSHs(sv_2mortal(
        newSVuv((UV) *((ULong_t*)dataAddr))
      ));
    }

void
access_struct_Long64_t(self, ...)
    SV* self;
  ALIAS:
  INIT:
    SOOT_RTXS_INIT
  PPCODE:
    SOOT_RTXS_CALCADDRESS
    if (items > 1) {
      SV* src = ST(1);
      *((Long64_t*)dataAddr) = (Long64_t)SvIV(src);
    } else {
      XPUSHs(sv_2mortal(
        newSViv((IV) *((Long64_t*)dataAddr))
      ));
    }

void
access_struct_ULong64_t(self, ...)
    SV* self;
  ALIAS:
  INIT:
    SOOT_RTXS_INIT
  PPCODE:
    SOOT_RTXS_CALCADDRESS
    if (items > 1) {
      SV* src = ST(1);
      *((ULong64_t*)dataAddr) = (ULong64_t)SvUV(src);
    } else {
      XPUSHs(sv_2mortal(
        newSVuv((UV) *((ULong64_t*)dataAddr))
      ));
    }

void
access_struct_Float_t(self, ...)
    SV* self;
  ALIAS:
  INIT:
    SOOT_RTXS_INIT
  PPCODE:
    SOOT_RTXS_CALCADDRESS
    if (items > 1) {
      SV* src = ST(1);
      *((Float_t*)dataAddr) = (Float_t)SvNV(src);
    } else {
      XPUSHs(sv_2mortal(
        newSVnv((NV) *((Float_t*)dataAddr))
      ));
    }

void
access_struct_Double_t(self, ...)
    SV* self;
  ALIAS:
  INIT:
    SOOT_RTXS_INIT
  PPCODE:
    SOOT_RTXS_CALCADDRESS
    if (items > 1) {
      SV* src = ST(1);
      *((Double_t*)dataAddr) = (Double_t)SvNV(src);
    } else {
      XPUSHs(sv_2mortal(
        newSVnv((NV) *((Double_t*)dataAddr))
      ));
    }

void
access_struct_CharStar(self, ...)
    SV* self;
  ALIAS:
  INIT:
    SOOT_RTXS_INIT
  PPCODE:
    SOOT_RTXS_CALCADDRESS
    if (items > 1) {
      // FIXME investigate null-padding issues. In general the Char_t[5] thingies might not need it
      char* buf = strdup(SvPV_nolen(ST(1)));
      free(*((char**)dataAddr));
      dataAddr = (void*)&buf;
    } else {
      XPUSHs(sv_2mortal(
        newSVpvn(*((char**)dataAddr), strlen(*((char**)dataAddr)))
      ));
    }

