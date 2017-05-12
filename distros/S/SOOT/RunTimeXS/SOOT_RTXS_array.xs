#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "SOOT_RTXS.h"
#include "SOOT_RTXS_macros.h"
#include "CPerlTypeConversion.h"

#define SOOT_ToIntegerAV(type) \
  XPUSHs(sv_2mortal(           \
    SOOT::IntegerVecToAV<type>(aTHX_ (type*)dataAddr, idxdata.maxIndex) \
  ));

#define SOOT_ToUIntegerAV(type) \
  XPUSHs(sv_2mortal(            \
    SOOT::UIntegerVecToAV<type>(aTHX_ (type*)dataAddr, idxdata.maxIndex) \
  ));

#define SOOT_ToFloatAV(type) \
  XPUSHs(sv_2mortal(         \
    SOOT::FloatVecToAV<type>(aTHX_ (type*)dataAddr, idxdata.maxIndex) \
  ));

#define SOOT_AVToIntegerAry(type, src) \
  size_t len; \
  SOOT::AVToIntegerVecInPlace<type>(aTHX_ (AV*)SvRV(src), len, (type*)dataAddr, idxdata.maxIndex);

#define SOOT_AVToUIntegerAry(type, src) \
  size_t len; \
  SOOT::AVToUIntegerVecInPlace<type>(aTHX_ (AV*)SvRV(src), len, (type*)dataAddr, idxdata.maxIndex);

#define SOOT_AVToFloatAry(type, src) \
  size_t len; \
  SOOT::AVToFloatVecInPlace<type>(aTHX_ (AV*)SvRV(src), len, (type*)dataAddr, idxdata.maxIndex);

#define SOOT_IntegerConversion(type) \
    SOOT_RTXS_CALCADDRESS_ARRAY \
    if (items > 1) { \
      SOOT_AVToIntegerAry(type, ST(1)) \
    } else { \
      SOOT_ToIntegerAV(type) \
    }

#define SOOT_UIntegerConversion(type) \
    SOOT_RTXS_CALCADDRESS_ARRAY \
    if (items > 1) { \
      SOOT_AVToUIntegerAry(type, ST(1)) \
    } else { \
      SOOT_ToUIntegerAV(type) \
    }

#define SOOT_FloatConversion(type) \
    SOOT_RTXS_CALCADDRESS_ARRAY \
    if (items > 1) { \
      SOOT_AVToFloatAry(type, ST(1)) \
    } else { \
      SOOT_ToFloatAV(type) \
    }

MODULE = SOOT        PACKAGE = SOOT::RTXS
PROTOTYPES: DISABLE


void
access_struct_array_Bool_t(self, ...)
    SV* self;
  ALIAS:
  INIT:
    SOOT_RTXS_INIT_ARRAY
  PPCODE:
    SOOT_IntegerConversion(Bool_t)

void
access_struct_array_Char_t(self, ...)
    SV* self;
  ALIAS:
  INIT:
    SOOT_RTXS_INIT_ARRAY
  PPCODE:
    SOOT_RTXS_CALCADDRESS_ARRAY
    if (items > 1) {
      // FIXME investigate null-padding issues. In general the Char_t[5] thingies might not need it
      size_t len;
      char* buf = SvPV(ST(1), len);
      if (idxdata.maxIndex < len)
        len = idxdata.maxIndex;
      strncpy( (char*)dataAddr, buf, len );
      ((char*)dataAddr)[len] = '\0'; // FIXME is this right?
    } else {
      XPUSHs(sv_2mortal(
        newSVpvn((char*)dataAddr, idxdata.maxIndex)
      ));
    }


void
access_struct_array_UChar_t(self, ...)
    SV* self;
  ALIAS:
  INIT:
    SOOT_RTXS_INIT_ARRAY
  PPCODE:
    SOOT_UIntegerConversion(UChar_t)

void
access_struct_array_Short_t(self, ...)
    SV* self;
  ALIAS:
  INIT:
    SOOT_RTXS_INIT_ARRAY
  PPCODE:
    SOOT_IntegerConversion(Short_t)

void
access_struct_array_UShort_t(self, ...)
    SV* self;
  ALIAS:
  INIT:
    SOOT_RTXS_INIT_ARRAY
  PPCODE:
    SOOT_UIntegerConversion(UShort_t)

void
access_struct_array_Int_t(self, ...)
    SV* self;
  ALIAS:
  INIT:
    SOOT_RTXS_INIT_ARRAY
  PPCODE:
    SOOT_IntegerConversion(Int_t)

void
access_struct_array_UInt_t(self, ...)
    SV* self;
  ALIAS:
  INIT:
    SOOT_RTXS_INIT_ARRAY
  PPCODE:
    SOOT_UIntegerConversion(UInt_t)

void
access_struct_array_Long_t(self, ...)
    SV* self;
  ALIAS:
  INIT:
    SOOT_RTXS_INIT_ARRAY
  PPCODE:
    SOOT_IntegerConversion(Long_t)

void
access_struct_array_ULong_t(self, ...)
    SV* self;
  ALIAS:
  INIT:
    SOOT_RTXS_INIT_ARRAY
  PPCODE:
    SOOT_UIntegerConversion(ULong_t)

void
access_struct_array_Long64_t(self, ...)
    SV* self;
  ALIAS:
  INIT:
    SOOT_RTXS_INIT_ARRAY
  PPCODE:
    SOOT_IntegerConversion(Long64_t)

void
access_struct_array_ULong64_t(self, ...)
    SV* self;
  ALIAS:
  INIT:
    SOOT_RTXS_INIT_ARRAY
  PPCODE:
    SOOT_UIntegerConversion(ULong64_t)

void
access_struct_array_Float_t(self, ...)
    SV* self;
  ALIAS:
  INIT:
    SOOT_RTXS_INIT_ARRAY
  PPCODE:
    SOOT_FloatConversion(Float_t)

void
access_struct_array_Double_t(self, ...)
    SV* self;
  ALIAS:
  INIT:
    SOOT_RTXS_INIT_ARRAY
  PPCODE:
    SOOT_FloatConversion(Double_t)

#undef SOOT_ToFloatAV
#undef SOOT_ToUIntegerAV
#undef SOOT_ToIntegerAV
#undef SOOT_AVToIntegerAry
#undef SOOT_AVToUIntegerAry
#undef SOOT_AVToFloatAry
#undef SOOT_IntegerConversion
#undef SOOT_UIntegerConversion
#undef SOOT_FloatConversion

