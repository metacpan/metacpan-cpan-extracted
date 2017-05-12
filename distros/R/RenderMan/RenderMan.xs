#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "ri.h"

#define XS_unpack_RtTokenPtr(b) ((RtToken*)SvPV_nolen(b))
#define XS_unpack_RtPointerPtr(b) ((RtPointer*)SvPV_nolen(b))

RtInt get_RtInt_from_array(AV* array, int index, char* funcname, char* paramname)
{
    RtInt val = 0;
    SV* sv = *av_fetch(array, index, FALSE);
    if (SvIOK(sv)) {
	val = (RtInt)SvIV(sv);
    } else if (SvNOK(sv)) {
	warn("%s parameter %s array element #%d is a double - possibly losing precision",
             funcname, paramname, index);
	val = (RtInt)SvNV(sv);
    } else {
	croak("%s parameter %s array element #%d is not an RtInt",
              funcname, paramname, index);
    }
    return(val);
}

RtInt* get_RtInt_array(RtInt nloops, SV* svp, char* funcname, char* paramname)
{
    AV* array;
    long count;
    RtInt* val = 0;
    if (!SvROK(svp))
	croak("%s parameter %s is not a reference to a %d-element RtInt array",
              funcname, paramname, nloops);
    array = (AV*)SvRV(svp);
    if (SvTYPE(array) != SVt_PVAV)
	croak("%s parameter %s is not a reference to a %d-element RtInt array",
              funcname, paramname, nloops);
    if (1 + av_len(array) != nloops)
	croak("%s parameter %s array length should be %d of RtInt but is %d",
	      funcname, paramname, nloops, 1 + av_len(array));
    if (!(val = (RtInt*)malloc(nloops*sizeof(RtInt))))
	croak("Out of memory in get_RtInt_array");
    for (count=0; count<=av_len(array); count++)
	val[count] = get_RtInt_from_array(array, count, funcname, paramname);
    return(val);
}

RtFloat get_RtFloat_from_sv(SV* sv, char* funcname, char* paramname)
{
    RtFloat val = 0.0;
    if (SvIOK(sv)) {
	val = (RtFloat)SvIV(sv);
    } else if (SvNOK(sv)) {
	val = (RtFloat)SvNV(sv);
    } else {
	croak("%s parameter %s is not an RtFloat", funcname, paramname);
    }
    return(val);
}

RtFloat get_RtFloat_from_array(AV* array, int index, char* funcname, char* paramname)
{
    RtFloat val = 0.0;
    SV* sv = *av_fetch(array, index, FALSE);
    if (SvIOK(sv)) {
	val = (RtFloat)SvIV(sv);
    } else if (SvNOK(sv)) {
	val = (RtFloat)SvNV(sv);
    } else {
	croak("%s parameter %s array element #%d is not an RtFloat",
              funcname, paramname, index);
    }
    return(val);
}

void get_RtPoint(RtPoint* p, SV* svp, char* funcname, char* paramname)
{
    AV* array;
    if (!SvROK(svp))
	croak("%s parameter %s is not a reference to a 3-element (RtPoint) array",
              funcname, paramname);
    array = (AV*)SvRV(svp);
    if (SvTYPE(array) != SVt_PVAV)
	croak("%s parameter %s is not a reference to a 3-element (RtPoint) array",
              funcname, paramname);
    if (av_len(array) != 2)
	croak("%s parameter %s array length should be 3 for RtPoint but is %d",
              funcname, paramname, 1 + av_len(array));
    (*p)[0] = get_RtFloat_from_array(array, 0, funcname, paramname);
    (*p)[1] = get_RtFloat_from_array(array, 1, funcname, paramname);
    (*p)[2] = get_RtFloat_from_array(array, 2, funcname, paramname);
}

RtFloat* get_RtFloat_array(RtInt nloops, SV* svp, char* funcname, char* paramname)
{
    AV* array;
    long count;
    RtFloat* val = 0;
    if (!SvROK(svp))
	croak("%s parameter %s is not a reference to a %d-element array of RtFloat",
              funcname, paramname, nloops);
    array = (AV*)SvRV(svp);
    if (SvTYPE(array) != SVt_PVAV)
	croak("%s parameter %s is not a reference to a %d-element array of RtFloat",
              funcname, paramname, nloops);
    if (1 + av_len(array) != nloops)
	croak("%s parameter %s RtFloat array length should be %d but is %d",
              funcname, paramname,
	      nloops, 1 + av_len(array));
    if (!(val = (RtFloat*)malloc(nloops*sizeof(RtFloat))))
	croak("Out of memory in get_RtFloat_array for function %s, parameter %s",
              funcname, paramname);
    for (count=0; count<=av_len(array); count++)
	val[count] = get_RtFloat_from_array(array, count, funcname, paramname);
    return(val);
}

RtToken get_RtToken_from_array(AV* array, int index, char* funcname, char* paramname)
{
  char* val = 0;
  SV* sv = *av_fetch(array, index, FALSE);
  if (SvPOK(sv)) {
    val = strdup(SvPV_nolen(sv));
  } else {
    croak("%s parameter %s array element #%d is not an RtToken",
          funcname, paramname, index);
  }
  return(val);
}

RtToken* get_RtToken_array(RtInt nloops, SV* svp, char* funcname, char* paramname)
{
    AV* array;
    long count;
    RtToken* val = 0;
    if (!SvROK(svp))
	croak("%s parameter %s is not a reference to a %d-element array of RtToken",
              funcname, paramname, nloops);
    array = (AV*)SvRV(svp);
    if (SvTYPE(array) != SVt_PVAV)
	croak("%s parameter %s is not a reference to a %d-element array of RtToken",
              funcname, paramname, nloops);
    if (1 + av_len(array) != nloops)
	croak("%s parameter %s RtToken array length should be %d but is %d",
              funcname, paramname,
	      nloops, 1 + av_len(array));
    if (!(val = (RtToken*)malloc(nloops*sizeof(RtToken))))
	croak("Out of memory in get_RtToken_array for function %s, parameter %s",
              funcname, paramname);
    for (count=0; count<=av_len(array); count++)
	val[count] = get_RtToken_from_array(array, count, funcname, paramname);
    return(val);
}

void get_RtColor(SV* svp, RtColor* color, char* funcname, char* paramname)
{
    AV* array;
    if (!SvROK(svp))
	croak("%s parameter %s is not a reference to a 3-element (RtColor) array",
              funcname, paramname);
    array = (AV*)SvRV(svp);
    if (SvTYPE(array) != SVt_PVAV)
	croak("%s parameter %s is not a reference to a 3-element (RtColor) array",
              funcname, paramname);
    if (1 + av_len(array) != 3)
	croak("%s parameter %s array length should be 3 for RtColor but is %d",
	      funcname, paramname, 1 + av_len(array));
    (*color)[0] = get_RtFloat_from_array(array, 0, funcname, paramname);
    (*color)[1] = get_RtFloat_from_array(array, 1, funcname, paramname);
    (*color)[2] = get_RtFloat_from_array(array, 2, funcname, paramname);
}

void get_RtBound(SV* svp, RtBound* bound, char* funcname, char* paramname)
{
    AV* array;
    if (!SvROK(svp))
	croak("%s parameter %s is not a reference to a 6-element (RtBound) array",
              funcname, paramname);
    array = (AV*)SvRV(svp);
    if (SvTYPE(array) != SVt_PVAV)
	croak("%s parameter %s is not a reference to a 6-element (RtBound) array",
              funcname, paramname);
    if (1 + av_len(array) != 6)
	croak("%s parameter %s array length should be 6 for RtBound but is %d",
	      funcname, paramname, 1 + av_len(array));
    (*bound)[0] = get_RtFloat_from_array(array, 0, funcname, paramname);
    (*bound)[1] = get_RtFloat_from_array(array, 1, funcname, paramname);
    (*bound)[2] = get_RtFloat_from_array(array, 2, funcname, paramname);
    (*bound)[3] = get_RtFloat_from_array(array, 3, funcname, paramname);
    (*bound)[4] = get_RtFloat_from_array(array, 4, funcname, paramname);
    (*bound)[5] = get_RtFloat_from_array(array, 5, funcname, paramname);
}

void get_RtBasis(SV* svp, RtBasis* basis, char* funcname, char* paramname)
{
    AV* array;
    if (!SvROK(svp))
	croak("%s parameter %s is not a reference to a 16-element (RtBasis) array",
              funcname, paramname);
    array = (AV*)SvRV(svp);
    if (SvTYPE(array) != SVt_PVAV)
	croak("%s parameter %s is not a reference to a 16-element (RtBasis) array",
              funcname, paramname);
    if (1 + av_len(array) != 16)
	croak("%s parameter %s array length should be 16 for RtBasis but is %d",
	      funcname, paramname, 1 + av_len(array));
    (*basis)[0][0] = get_RtFloat_from_array(array, 0, funcname, paramname);
    (*basis)[0][1] = get_RtFloat_from_array(array, 1, funcname, paramname);
    (*basis)[0][2] = get_RtFloat_from_array(array, 2, funcname, paramname);
    (*basis)[0][3] = get_RtFloat_from_array(array, 3, funcname, paramname);
    (*basis)[1][0] = get_RtFloat_from_array(array, 4, funcname, paramname);
    (*basis)[1][1] = get_RtFloat_from_array(array, 5, funcname, paramname);
    (*basis)[1][2] = get_RtFloat_from_array(array, 6, funcname, paramname);
    (*basis)[1][3] = get_RtFloat_from_array(array, 7, funcname, paramname);
    (*basis)[2][0] = get_RtFloat_from_array(array, 8, funcname, paramname);
    (*basis)[2][1] = get_RtFloat_from_array(array, 9, funcname, paramname);
    (*basis)[2][2] = get_RtFloat_from_array(array, 10, funcname, paramname);
    (*basis)[2][3] = get_RtFloat_from_array(array, 11, funcname, paramname);
    (*basis)[3][0] = get_RtFloat_from_array(array, 12, funcname, paramname);
    (*basis)[3][1] = get_RtFloat_from_array(array, 13, funcname, paramname);
    (*basis)[3][2] = get_RtFloat_from_array(array, 14, funcname, paramname);
    (*basis)[3][3] = get_RtFloat_from_array(array, 15, funcname, paramname);
}

/* Just in case a RtBasis changes from a RtMatrix in the future */
void get_RtMatrix(SV* svp, RtMatrix* matrix, char* funcname, char* paramname)
{
    AV* array;
    if (!SvROK(svp))
	croak("%s parameter %s is not a reference to a 16-element (RtMatrix) array",
              funcname, paramname);
    array = (AV*)SvRV(svp);
    if (SvTYPE(array) != SVt_PVAV)
	croak("%s parameter %s is not a reference to a 16-element (RtMatrix) array",
              funcname, paramname);
    if (1 + av_len(array) != 16)
	croak("%s parameter %s array length should be 16 for RtMatrix but is %d",
	      funcname, paramname, 1 + av_len(array));
    (*matrix)[0][0] = get_RtFloat_from_array(array, 0, funcname, paramname);
    (*matrix)[0][1] = get_RtFloat_from_array(array, 1, funcname, paramname);
    (*matrix)[0][2] = get_RtFloat_from_array(array, 2, funcname, paramname);
    (*matrix)[0][3] = get_RtFloat_from_array(array, 3, funcname, paramname);
    (*matrix)[1][0] = get_RtFloat_from_array(array, 4, funcname, paramname);
    (*matrix)[1][1] = get_RtFloat_from_array(array, 5, funcname, paramname);
    (*matrix)[1][2] = get_RtFloat_from_array(array, 6, funcname, paramname);
    (*matrix)[1][3] = get_RtFloat_from_array(array, 7, funcname, paramname);
    (*matrix)[2][0] = get_RtFloat_from_array(array, 8, funcname, paramname);
    (*matrix)[2][1] = get_RtFloat_from_array(array, 9, funcname, paramname);
    (*matrix)[2][2] = get_RtFloat_from_array(array, 10, funcname, paramname);
    (*matrix)[2][3] = get_RtFloat_from_array(array, 11, funcname, paramname);
    (*matrix)[3][0] = get_RtFloat_from_array(array, 12, funcname, paramname);
    (*matrix)[3][1] = get_RtFloat_from_array(array, 13, funcname, paramname);
    (*matrix)[3][2] = get_RtFloat_from_array(array, 14, funcname, paramname);
    (*matrix)[3][3] = get_RtFloat_from_array(array, 15, funcname, paramname);
}

void free_token_params(int count, RtToken* tokens, RtPointer* params)
{
    if (!count) return;
    if (tokens) free(tokens);
    if (params) {
	while (count--) free(params[count]);
	free(params);
    }
}

RtInt build_token_params(SV* svp, RtToken** ret_token, RtPointer** ret_params,
                         char* funcname, char* paramname)
{
  HV* hash;
  SV* sv;
  RtInt count = 0;
  RtToken* token = 0;
  RtPointer* params = 0;
  char* key;
  I32 retlen;
  RtFloat* val = 0;
  RtInt* ival = 0;
  char** sval = 0;
  int len;

  if (SvPOK(svp)) {
      key = SvPV_nolen(svp);
      if (key && key[0])
	  croak("Parameter list is not a hash reference or RI_NULL");
  } else {
      if (!SvROK(svp))
	  croak("Parameter list is not a hash reference or RI_NULL");
      hash = (HV*)SvRV(svp);
      if (SvTYPE(hash) != SVt_PVHV)
	  croak("Parameter list reference is not a hash reference");
      hv_iterinit(hash);
      while (hv_iternext(hash)) count++;
      if (!(token = (RtToken*)malloc(count*sizeof(RtToken))))
	  croak("Out of memory in build_token_params");
      if (!(params = (RtPointer*)malloc(count*sizeof(RtPointer))))
	  croak("Out of memory in build_token_params");
      hv_iterinit(hash);
      for (count=0; sv=hv_iternextsv(hash,&key,&retlen); ) {
	  if (SvIOK(sv)) {  /* integer value */
	      token[count] = key;
              if (strncmp(key, "integer ", 8)==0) {
                if (!(ival = (RtInt*)malloc(sizeof(RtInt))))
		  croak("Out of memory in build_token_params");
                *ival = (RtInt)SvIV(sv);
                params[count] = (RtPointer)ival;
              } else {  // Treat as a float
                if (!(val = (RtFloat*)malloc(sizeof(RtFloat))))
		  croak("Out of memory in build_token_params");
                *val = (RtFloat)SvIV(sv);
                params[count] = (RtPointer)val;
              }
	      count++;
	      /* warn("WARNING: ignoring hash key '%s'...type is integer value: %ld", key, SvIV(sv)); */
	  } else if (SvNOK(sv)) {  /* double */
	      token[count] = key;
	      if (!(val = (RtFloat*)malloc(sizeof(RtFloat))))
		  croak("Out of memory in build_token_params");
	      *val = (RtFloat)SvNV(sv);
	      params[count] = (RtPointer)val;
	      count++;
	      /* warn("WARNING: ignoring hash key '%s'...type is double value: %g", key, SvNV(sv)); */
	  } else if (SvPOK(sv)) {  /* string */
	      token[count] = key;
              if (!(sval = (char**)malloc(sizeof(char*))))
		  croak("Out of memory in build_token_params");
              *sval = (char*)strdup(SvPV_nolen(sv));
	      params[count] = (RtPointer)sval;
	      count++;
	  } else if (SvROK(sv)) {  /* reference */
	      if (SvTYPE(SvRV(sv)) == SVt_IV) {
		  token[count] = key;
		  if (!(val = (RtFloat*)malloc(sizeof(RtFloat))))
		      croak("Out of memory in build_token_params");
		  *val = (RtFloat)SvIV(SvRV(sv));
		  params[count] = (RtPointer)val;
		  count++;
		  /* warn("WARNING: ignoring hash key '%s'...type is a reference to an integer scalar", key); */
	      } else if (SvTYPE(SvRV(sv)) == SVt_NV) {
		  token[count] = key;
		  if (!(val = (RtFloat*)malloc(sizeof(RtFloat))))
		      croak("Out of memory in build_token_params");
		  *val = (RtFloat)SvNV(SvRV(sv));
		  params[count] = (RtPointer)val;
		  count++;
		  /* warn("WARNING: ignoring hash key '%s'...type is a reference to a double scalar", key); */
	      } else if (SvTYPE(SvRV(sv)) == SVt_PV) {
		  token[count] = key;
		  params[count] = (RtPointer)strdup(SvPV_nolen(SvRV(sv)));
		  count++;
		  /* warn("WARNING: ignoring hash key '%s'...type is a reference to a string scalar", key); */
	      } else if (SvTYPE(SvRV(sv)) == SVt_RV) {
		  warn("WARNING: ignoring hash key '%s'...type is a reference to a reference scalar", key);
	      } else if (SvTYPE(SvRV(sv)) == SVt_PVAV) {
		  token[count] = key;
		  len = 1 + av_len((AV*)SvRV(sv));
		  if (!(val = (RtFloat*)malloc(len*sizeof(RtFloat))))
		      croak("Out of memory in build_token_params");
		  for (len=0; len<=av_len((AV*)SvRV(sv)); len++)
		    val[len] = get_RtFloat_from_array((AV*)SvRV(sv), len, funcname, paramname);
		  params[count] = (RtPointer)val;
		  count++;
		  /* warn("WARNING: ignoring hash key '%s'...type is a reference to an array", key); */
	      } else if (SvTYPE(SvRV(sv)) == SVt_PVHV) {
		  warn("WARNING: ignoring hash key '%s'...type is a reference to a hash", key);
	      } else if (SvTYPE(SvRV(sv)) == SVt_PVCV) {
		  warn("WARNING: ignoring hash key '%s'...type is a reference to code", key);
	      } else if (SvTYPE(SvRV(sv)) == SVt_PVGV) {
		  warn("WARNING: ignoring hash key '%s'...type is a reference to a glob", key);
	      } else if (SvTYPE(SvRV(sv)) == SVt_PVMG) {
		  warn("WARNING: ignoring hash key '%s'...type is a reference to a blessed or magical scalar", key);
	      } else {
		  warn("WARNING: ignoring hash key '%s'...type is an unknown reference", key);
	      }
	  } else {
	      warn("WARNING: ignoring hash key '%s'...type is unknown", key);
	  }
      }
  }
  if (token) { *ret_token = token; } else { *ret_token = 0; }
  if (params) { *ret_params = params; } else { *ret_params = 0; };
  return(count);
}

MODULE = RenderMan		PACKAGE = RenderMan	PREFIX = Ri

######################################################################

RtToken
RI_A()
    CODE:
    RETVAL = RI_A;
    OUTPUT:
    RETVAL

RtToken
RI_ABORT()
    CODE:
    RETVAL = RI_ABORT;
    OUTPUT:
    RETVAL

RtToken
RI_AMBIENTLIGHT()
    CODE:
    RETVAL = RI_AMBIENTLIGHT;
    OUTPUT:
    RETVAL

RtToken
RI_AMPLITUDE()
    CODE:
    RETVAL = RI_AMPLITUDE;
    OUTPUT:
    RETVAL

RtToken
RI_AZ()
    CODE:
    RETVAL = RI_AZ;
    OUTPUT:
    RETVAL

RtToken
RI_BACKGROUND()
    CODE:
    RETVAL = RI_BACKGROUND;
    OUTPUT:
    RETVAL

RtToken
RI_BEAMDISTRIBUTION()
    CODE:
    RETVAL = RI_BEAMDISTRIBUTION;
    OUTPUT:
    RETVAL

RtToken
RI_BICUBIC()
    CODE:
    RETVAL = RI_BICUBIC;
    OUTPUT:
    RETVAL

RtToken
RI_BILINEAR()
    CODE:
    RETVAL = RI_BILINEAR;
    OUTPUT:
    RETVAL

RtToken
RI_BLACK()
    CODE:
    RETVAL = RI_BLACK;
    OUTPUT:
    RETVAL

RtToken
RI_BUMPY()
    CODE:
    RETVAL = RI_BUMPY;
    OUTPUT:
    RETVAL

RtToken
RI_CAMERA()
    CODE:
    RETVAL = RI_CAMERA;
    OUTPUT:
    RETVAL

RtToken
RI_CLAMP()
    CODE:
    RETVAL = RI_CLAMP;
    OUTPUT:
    RETVAL

RtToken
RI_COMMENT()
    CODE:
    RETVAL = RI_COMMENT;
    OUTPUT:
    RETVAL

RtToken
RI_CONEANGLE()
    CODE:
    RETVAL = RI_CONEANGLE;
    OUTPUT:
    RETVAL

RtToken
RI_CONEDELTAANGLE()
    CODE:
    RETVAL = RI_CONEDELTAANGLE;
    OUTPUT:
    RETVAL

RtToken
RI_CONSTANT()
    CODE:
    RETVAL = RI_CONSTANT;
    OUTPUT:
    RETVAL

RtToken
RI_CS()
    CODE:
    RETVAL = RI_CS;
    OUTPUT:
    RETVAL

RtToken
RI_DEPTHCUE()
    CODE:
    RETVAL = RI_DEPTHCUE;
    OUTPUT:
    RETVAL

RtToken
RI_DIFFERENCE()
    CODE:
    RETVAL = RI_DIFFERENCE;
    OUTPUT:
    RETVAL

RtToken
RI_DISTANCE()
    CODE:
    RETVAL = RI_DISTANCE;
    OUTPUT:
    RETVAL

RtToken
RI_DISTANTLIGHT()
    CODE:
    RETVAL = RI_DISTANTLIGHT;
    OUTPUT:
    RETVAL

RtToken
RI_FILE()
    CODE:
    RETVAL = RI_FILE;
    OUTPUT:
    RETVAL

RtToken
RI_FLATNESS()
    CODE:
    RETVAL = RI_FLATNESS;
    OUTPUT:
    RETVAL

RtToken
RI_FOG()
    CODE:
    RETVAL = RI_FOG;
    OUTPUT:
    RETVAL

RtToken
RI_FOV()
    CODE:
    RETVAL = RI_FOV;
    OUTPUT:
    RETVAL

RtToken
RI_FRAMEBUFFER()
    CODE:
    RETVAL = RI_FRAMEBUFFER;
    OUTPUT:
    RETVAL

RtToken
RI_FROM()
    CODE:
    RETVAL = RI_FROM;
    OUTPUT:
    RETVAL

RtToken
RI_HANDLER()
    CODE:
    RETVAL = RI_HANDLER;
    OUTPUT:
    RETVAL

RtToken
RI_HIDDEN()
    CODE:
    RETVAL = RI_HIDDEN;
    OUTPUT:
    RETVAL

RtToken
RI_IDENTIFIER()
    CODE:
    RETVAL = RI_IDENTIFIER;
    OUTPUT:
    RETVAL

RtToken
RI_IGNORE()
    CODE:
    RETVAL = RI_IGNORE;
    OUTPUT:
    RETVAL

RtToken
RI_INSIDE()
    CODE:
    RETVAL = RI_INSIDE;
    OUTPUT:
    RETVAL

RtToken
RI_INTENSITY()
    CODE:
    RETVAL = RI_INTENSITY;
    OUTPUT:
    RETVAL

RtToken
RI_INTERSECTION()
    CODE:
    RETVAL = RI_INTERSECTION;
    OUTPUT:
    RETVAL

RtToken
RI_KA()
    CODE:
    RETVAL = RI_KA;
    OUTPUT:
    RETVAL

RtToken
RI_KD()
    CODE:
    RETVAL = RI_KD;
    OUTPUT:
    RETVAL

RtToken
RI_KR()
    CODE:
    RETVAL = RI_KR;
    OUTPUT:
    RETVAL

RtToken
RI_KS()
    CODE:
    RETVAL = RI_KS;
    OUTPUT:
    RETVAL

RtToken
RI_LH()
    CODE:
    RETVAL = RI_LH;
    OUTPUT:
    RETVAL

RtToken
RI_LIGHTCOLOR()
    CODE:
    RETVAL = RI_LIGHTCOLOR;
    OUTPUT:
    RETVAL

RtToken
RI_MATTE()
    CODE:
    RETVAL = RI_MATTE;
    OUTPUT:
    RETVAL

RtToken
RI_MAXDISTANCE()
    CODE:
    RETVAL = RI_MAXDISTANCE;
    OUTPUT:
    RETVAL

RtToken
RI_METAL()
    CODE:
    RETVAL = RI_METAL;
    OUTPUT:
    RETVAL

RtToken
RI_MINDISTANCE()
    CODE:
    RETVAL = RI_MINDISTANCE;
    OUTPUT:
    RETVAL

RtToken
RI_N()
    CODE:
    RETVAL = RI_N;
    OUTPUT:
    RETVAL

RtToken
RI_NAME()
    CODE:
    RETVAL = RI_NAME;
    OUTPUT:
    RETVAL

RtToken
RI_NONPERIODIC()
    CODE:
    RETVAL = RI_NONPERIODIC;
    OUTPUT:
    RETVAL

RtToken
RI_NP()
    CODE:
    RETVAL = RI_NP;
    OUTPUT:
    RETVAL

RtToken
RI_OBJECT()
    CODE:
    RETVAL = RI_OBJECT;
    OUTPUT:
    RETVAL

RtToken
RI_ORIGIN()
    CODE:
    RETVAL = RI_ORIGIN;
    OUTPUT:
    RETVAL

RtToken
RI_ORTHOGRAPHIC()
    CODE:
    RETVAL = RI_ORTHOGRAPHIC;
    OUTPUT:
    RETVAL

RtToken
RI_OS()
    CODE:
    RETVAL = RI_OS;
    OUTPUT:
    RETVAL

RtToken
RI_OUTSIDE()
    CODE:
    RETVAL = RI_OUTSIDE;
    OUTPUT:
    RETVAL

RtToken
RI_P()
    CODE:
    RETVAL = RI_P;
    OUTPUT:
    RETVAL

RtToken
RI_PAINT()
    CODE:
    RETVAL = RI_PAINT;
    OUTPUT:
    RETVAL

RtToken
RI_PAINTEDPLASTIC()
    CODE:
    RETVAL = RI_PAINTEDPLASTIC;
    OUTPUT:
    RETVAL

RtToken
RI_PERIODIC()
    CODE:
    RETVAL = RI_PERIODIC;
    OUTPUT:
    RETVAL

RtToken
RI_PERSPECTIVE()
    CODE:
    RETVAL = RI_PERSPECTIVE;
    OUTPUT:
    RETVAL

RtToken
RI_PLASTIC()
    CODE:
    RETVAL = RI_PLASTIC;
    OUTPUT:
    RETVAL

RtToken
RI_POINTLIGHT()
    CODE:
    RETVAL = RI_POINTLIGHT;
    OUTPUT:
    RETVAL

RtToken
RI_PRIMITIVE()
    CODE:
    RETVAL = RI_PRIMITIVE;
    OUTPUT:
    RETVAL

RtToken
RI_PRINT()
    CODE:
    RETVAL = RI_PRINT;
    OUTPUT:
    RETVAL

RtToken
RI_PW()
    CODE:
    RETVAL = RI_PW;
    OUTPUT:
    RETVAL

RtToken
RI_PZ()
    CODE:
    RETVAL = RI_PZ;
    OUTPUT:
    RETVAL

RtToken
RI_RASTER()
    CODE:
    RETVAL = RI_RASTER;
    OUTPUT:
    RETVAL

RtToken
RI_RGB()
    CODE:
    RETVAL = RI_RGB;
    OUTPUT:
    RETVAL

RtToken
RI_RGBA()
    CODE:
    RETVAL = RI_RGBA;
    OUTPUT:
    RETVAL

RtToken
RI_RGBAZ()
    CODE:
    RETVAL = RI_RGBAZ;
    OUTPUT:
    RETVAL

RtToken
RI_RGBZ()
    CODE:
    RETVAL = RI_RGBZ;
    OUTPUT:
    RETVAL

RtToken
RI_RH()
    CODE:
    RETVAL = RI_RH;
    OUTPUT:
    RETVAL

RtToken
RI_ROUGHNESS()
    CODE:
    RETVAL = RI_ROUGHNESS;
    OUTPUT:
    RETVAL

RtToken
RI_S()
    CODE:
    RETVAL = RI_S;
    OUTPUT:
    RETVAL

RtToken
RI_SCREEN()
    CODE:
    RETVAL = RI_SCREEN;
    OUTPUT:
    RETVAL

RtToken
RI_SHINYMETAL()
    CODE:
    RETVAL = RI_SHINYMETAL;
    OUTPUT:
    RETVAL

RtToken
RI_SMOOTH()
    CODE:
    RETVAL = RI_SMOOTH;
    OUTPUT:
    RETVAL

RtToken
RI_SPECULARCOLOR()
    CODE:
    RETVAL = RI_SPECULARCOLOR;
    OUTPUT:
    RETVAL

RtToken
RI_SPOTLIGHT()
    CODE:
    RETVAL = RI_SPOTLIGHT;
    OUTPUT:
    RETVAL

RtToken
RI_ST()
    CODE:
    RETVAL = RI_ST;
    OUTPUT:
    RETVAL

RtToken
RI_STRUCTURE()
    CODE:
    RETVAL = RI_STRUCTURE;
    OUTPUT:
    RETVAL

RtToken
RI_T()
    CODE:
    RETVAL = RI_T;
    OUTPUT:
    RETVAL

RtToken
RI_TEXTURENAME()
    CODE:
    RETVAL = RI_TEXTURENAME;
    OUTPUT:
    RETVAL

RtToken
RI_TO()
    CODE:
    RETVAL = RI_TO;
    OUTPUT:
    RETVAL

RtToken
RI_UNION()
    CODE:
    RETVAL = RI_UNION;
    OUTPUT:
    RETVAL

RtToken
RI_WORLD()
    CODE:
    RETVAL = RI_WORLD;
    OUTPUT:
    RETVAL

RtToken
RI_Z()
    CODE:
    RETVAL = RI_Z;
    OUTPUT:
    RETVAL

RtToken
RI_LINEAR()
    CODE:
    RETVAL = RI_LINEAR;
    OUTPUT:
    RETVAL

RtToken
RI_CUBIC()
    CODE:
    RETVAL = RI_CUBIC;
    OUTPUT:
    RETVAL

RtToken
RI_WIDTH()
    CODE:
    RETVAL = RI_WIDTH;
    OUTPUT:
    RETVAL

RtToken
RI_CONSTANTWIDTH()
    CODE:
    RETVAL = RI_CONSTANTWIDTH;
    OUTPUT:
    RETVAL

RtToken
RI_CURRENT()
    CODE:
    RETVAL = RI_CURRENT;
    OUTPUT:
    RETVAL

# Duplicate
# RtToken
# RI_WORLD()
#     CODE:
#     RETVAL = RI_WORLD;
#     OUTPUT:
#     RETVAL

# Duplicate
# RtToken
# RI_OBJECT()
#     CODE:
#     RETVAL = RI_OBJECT;
#     OUTPUT:
#     RETVAL

RtToken
RI_SHADER()
    CODE:
    RETVAL = RI_SHADER;
    OUTPUT:
    RETVAL

# Duplicate
# RtToken
# RI_RASTER()
#     CODE:
#     RETVAL = RI_RASTER;
#     OUTPUT:
#     RETVAL

RtToken
RI_NDC()
    CODE:
    RETVAL = RI_NDC;
    OUTPUT:
    RETVAL

# Duplicate
# RtToken
# RI_SCREEN()
#     CODE:
#     RETVAL = RI_SCREEN;
#     OUTPUT:
#     RETVAL

# Duplicate
# RtToken
# RI_CAMERA()
#     CODE:
#     RETVAL = RI_CAMERA;
#     OUTPUT:
#     RETVAL

RtToken
RI_EYE()
    CODE:
    RETVAL = RI_EYE;
    OUTPUT:
    RETVAL

######################################################################

void
RiBSplineBasis()
    PPCODE:
    {
	EXTEND(sp,16);
	PUSHs(sv_2mortal(newSVnv(RiBSplineBasis[0][0])));
	PUSHs(sv_2mortal(newSVnv(RiBSplineBasis[0][1])));
	PUSHs(sv_2mortal(newSVnv(RiBSplineBasis[0][2])));
	PUSHs(sv_2mortal(newSVnv(RiBSplineBasis[0][3])));

	PUSHs(sv_2mortal(newSVnv(RiBSplineBasis[1][0])));
	PUSHs(sv_2mortal(newSVnv(RiBSplineBasis[1][1])));
	PUSHs(sv_2mortal(newSVnv(RiBSplineBasis[1][2])));
	PUSHs(sv_2mortal(newSVnv(RiBSplineBasis[1][3])));

	PUSHs(sv_2mortal(newSVnv(RiBSplineBasis[2][0])));
	PUSHs(sv_2mortal(newSVnv(RiBSplineBasis[2][1])));
	PUSHs(sv_2mortal(newSVnv(RiBSplineBasis[2][2])));
	PUSHs(sv_2mortal(newSVnv(RiBSplineBasis[2][3])));

	PUSHs(sv_2mortal(newSVnv(RiBSplineBasis[3][0])));
	PUSHs(sv_2mortal(newSVnv(RiBSplineBasis[3][1])));
	PUSHs(sv_2mortal(newSVnv(RiBSplineBasis[3][2])));
	PUSHs(sv_2mortal(newSVnv(RiBSplineBasis[3][3])));
    }

void
RiBezierBasis()
    PPCODE:
    {
	EXTEND(sp,16);
	PUSHs(sv_2mortal(newSVnv(RiBezierBasis[0][0])));
	PUSHs(sv_2mortal(newSVnv(RiBezierBasis[0][1])));
	PUSHs(sv_2mortal(newSVnv(RiBezierBasis[0][2])));
	PUSHs(sv_2mortal(newSVnv(RiBezierBasis[0][3])));

	PUSHs(sv_2mortal(newSVnv(RiBezierBasis[1][0])));
	PUSHs(sv_2mortal(newSVnv(RiBezierBasis[1][1])));
	PUSHs(sv_2mortal(newSVnv(RiBezierBasis[1][2])));
	PUSHs(sv_2mortal(newSVnv(RiBezierBasis[1][3])));

	PUSHs(sv_2mortal(newSVnv(RiBezierBasis[2][0])));
	PUSHs(sv_2mortal(newSVnv(RiBezierBasis[2][1])));
	PUSHs(sv_2mortal(newSVnv(RiBezierBasis[2][2])));
	PUSHs(sv_2mortal(newSVnv(RiBezierBasis[2][3])));

	PUSHs(sv_2mortal(newSVnv(RiBezierBasis[3][0])));
	PUSHs(sv_2mortal(newSVnv(RiBezierBasis[3][1])));
	PUSHs(sv_2mortal(newSVnv(RiBezierBasis[3][2])));
	PUSHs(sv_2mortal(newSVnv(RiBezierBasis[3][3])));
    }

void
RiCatmullRomBasis()
    PPCODE:
    {
	EXTEND(sp,16);
	PUSHs(sv_2mortal(newSVnv(RiCatmullRomBasis[0][0])));
	PUSHs(sv_2mortal(newSVnv(RiCatmullRomBasis[0][1])));
	PUSHs(sv_2mortal(newSVnv(RiCatmullRomBasis[0][2])));
	PUSHs(sv_2mortal(newSVnv(RiCatmullRomBasis[0][3])));

	PUSHs(sv_2mortal(newSVnv(RiCatmullRomBasis[1][0])));
	PUSHs(sv_2mortal(newSVnv(RiCatmullRomBasis[1][1])));
	PUSHs(sv_2mortal(newSVnv(RiCatmullRomBasis[1][2])));
	PUSHs(sv_2mortal(newSVnv(RiCatmullRomBasis[1][3])));

	PUSHs(sv_2mortal(newSVnv(RiCatmullRomBasis[2][0])));
	PUSHs(sv_2mortal(newSVnv(RiCatmullRomBasis[2][1])));
	PUSHs(sv_2mortal(newSVnv(RiCatmullRomBasis[2][2])));
	PUSHs(sv_2mortal(newSVnv(RiCatmullRomBasis[2][3])));

	PUSHs(sv_2mortal(newSVnv(RiCatmullRomBasis[3][0])));
	PUSHs(sv_2mortal(newSVnv(RiCatmullRomBasis[3][1])));
	PUSHs(sv_2mortal(newSVnv(RiCatmullRomBasis[3][2])));
	PUSHs(sv_2mortal(newSVnv(RiCatmullRomBasis[3][3])));
    }

void
RiHermiteBasis()
    PPCODE:
    {
	EXTEND(sp,16);
	PUSHs(sv_2mortal(newSVnv(RiHermiteBasis[0][0])));
	PUSHs(sv_2mortal(newSVnv(RiHermiteBasis[0][1])));
	PUSHs(sv_2mortal(newSVnv(RiHermiteBasis[0][2])));
	PUSHs(sv_2mortal(newSVnv(RiHermiteBasis[0][3])));

	PUSHs(sv_2mortal(newSVnv(RiHermiteBasis[1][0])));
	PUSHs(sv_2mortal(newSVnv(RiHermiteBasis[1][1])));
	PUSHs(sv_2mortal(newSVnv(RiHermiteBasis[1][2])));
	PUSHs(sv_2mortal(newSVnv(RiHermiteBasis[1][3])));

	PUSHs(sv_2mortal(newSVnv(RiHermiteBasis[2][0])));
	PUSHs(sv_2mortal(newSVnv(RiHermiteBasis[2][1])));
	PUSHs(sv_2mortal(newSVnv(RiHermiteBasis[2][2])));
	PUSHs(sv_2mortal(newSVnv(RiHermiteBasis[2][3])));

	PUSHs(sv_2mortal(newSVnv(RiHermiteBasis[3][0])));
	PUSHs(sv_2mortal(newSVnv(RiHermiteBasis[3][1])));
	PUSHs(sv_2mortal(newSVnv(RiHermiteBasis[3][2])));
	PUSHs(sv_2mortal(newSVnv(RiHermiteBasis[3][3])));
    }

void
RiPowerBasis()
    PPCODE:
    {
	EXTEND(sp,16);
	PUSHs(sv_2mortal(newSVnv(RiPowerBasis[0][0])));
	PUSHs(sv_2mortal(newSVnv(RiPowerBasis[0][1])));
	PUSHs(sv_2mortal(newSVnv(RiPowerBasis[0][2])));
	PUSHs(sv_2mortal(newSVnv(RiPowerBasis[0][3])));

	PUSHs(sv_2mortal(newSVnv(RiPowerBasis[1][0])));
	PUSHs(sv_2mortal(newSVnv(RiPowerBasis[1][1])));
	PUSHs(sv_2mortal(newSVnv(RiPowerBasis[1][2])));
	PUSHs(sv_2mortal(newSVnv(RiPowerBasis[1][3])));

	PUSHs(sv_2mortal(newSVnv(RiPowerBasis[2][0])));
	PUSHs(sv_2mortal(newSVnv(RiPowerBasis[2][1])));
	PUSHs(sv_2mortal(newSVnv(RiPowerBasis[2][2])));
	PUSHs(sv_2mortal(newSVnv(RiPowerBasis[2][3])));

	PUSHs(sv_2mortal(newSVnv(RiPowerBasis[3][0])));
	PUSHs(sv_2mortal(newSVnv(RiPowerBasis[3][1])));
	PUSHs(sv_2mortal(newSVnv(RiPowerBasis[3][2])));
	PUSHs(sv_2mortal(newSVnv(RiPowerBasis[3][3])));
    }

######################################################################
# Now give interfaces to the functions...
######################################################################

# RC p.242
RtToken
RiDeclare(name,declaration)
    char*	name
    char*	declaration

# RC p.48 - DONE
void
RiBegin(...)
    CODE:
    {
	char *name;
	if (items==0) { RiBegin(RI_NULL); return; }
	if (items != 1) {
	    croak("Usage: RenderMan::Begin([name])");
	    return;
	}
	name = (char*)SvPV_nolen(ST(0));
	if (!name || !name[0])
	    RiBegin(RI_NULL);
	else
	    RiBegin(name);
    }

# RC p.48 - DONE
void
RiEnd()

# RC p.51 - DONE
void
RiFrameBegin(number)
    RtInt	number

# RC p.51 - DONE
void
RiFrameEnd()

# RC p.48 - DONE
void
RiWorldBegin()

# RC p.48 - DONE
void
RiWorldEnd()

# RC p.156 - DONE
void
RiFormat(xres,yres,aspect)
    RtInt	xres
    RtInt	yres
    RtFloat	aspect

# RC p.159 - DONE
void
RiFrameAspectRatio(aspect)
    RtFloat	aspect

# RC p.150 - DONE
void
RiScreenWindow(left,right,bot,top)
    RtFloat	left
    RtFloat	right
    RtFloat	bot
    RtFloat	top

# RC p.162 - DONE
void
RiCropWindow(xmin,xmax,ymin,ymax)
    RtFloat	xmin
    RtFloat	xmax
    RtFloat	ymin
    RtFloat	ymax

# RC p.149 - DONE
void
RiProjection(name, ...)
    char*	name
    CODE:
    {
	RtInt count = 0;
	RtToken* token = 0;
	RtPointer* params = 0;

	if (items == 1) { RiProjection(name, RI_NULL); return; }
	if (!name || !name[0] || items != 2) {
	    croak("Usage: RenderMan::Projection(name, {params})");
	    return;
	}

	# Optional Parameters...
	count = build_token_params(ST(1), &token, &params, "Projection", "2 (params)");

	if (count) {
            RiProjectionV(name, count, token, params);
	} else {
	    RiProjection(name, RI_NULL);
	}
	free_token_params(count, token, params);
    }

# RC p.145 - DONE
void
RiClipping(hither,yon)
    RtFloat	hither
    RtFloat	yon

# RC p.185 - DONE
void
RiDepthOfField(fstop,focallength,focaldistance)
    RtFloat	fstop
    RtFloat	focallength
    RtFloat	focaldistance

# RC p.190 - DONE
void
RiShutter(smin,smax)
    RtFloat	smin
    RtFloat	smax

# RC p.179 - DONE
void
RiPixelVariance(variation)
    RtFloat	variation

# RC p.176 - DONE
void
RiPixelSamples(xsamples,ysamples)
    RtFloat	xsamples
    RtFloat	ysamples

# RC p.176 - Can't be fully implemented because of using -lribout
void
RiPixelFilter(function,xwidth,ywidth)
    RtFilterFunc	function
    RtFloat	xwidth
    RtFloat	ywidth

# RC p.180 - DONE
void
RiExposure(gain,gamma)
    RtFloat	gain
    RtFloat	gamma

# RC p.181 - DONE
void
RiImager(name, ...)
    char*	name
    CODE:
    {
	RtInt count = 0;
	RtToken* token = 0;
	RtPointer* params = 0;

	if (items == 1) { RiImager(name, RI_NULL); return; }
	if (!name || !name[0] || items != 2) {
	    croak("Usage: RenderMan::Imager(name, {params})");
	    return;
	}

	# Optional Parameters...
	count = build_token_params(ST(1), &token, &params, "Imager", "2 (params)");

	if (count) {
            RiImagerV(name, count, token, params);
	} else {
	    RiImager(name, RI_NULL);
	}
	free_token_params(count, token, params);
    }

# RC p.183 - DONE
void
RiQuantize(type,one,qmin,qmax,ampl)
    RtToken	type
    RtInt	one
    RtInt	qmin
    RtInt	qmax
    RtFloat	ampl

# RC p.155 - DONE
void
RiDisplay(name,type,mode, ...)
    char*	name
    RtToken	type
    RtToken	mode
    CODE:
    {
	RtInt count = 0;
	RtToken* token = 0;
	RtPointer* params = 0;

	if (items == 3) { RiDisplay(name, type, mode, RI_NULL); return; }
	if (!name || !name[0] || items != 4) {
	    croak("Usage: RenderMan::Display(name, type, mode, {params})");
	    return;
	}

	# Optional Parameters...
	count = build_token_params(ST(3), &token, &params, "Display", "4 (params)");

	if (count) {
            RiDisplayV(name, type, mode, count, token, params);
	} else {
	    RiDisplay(name, type, mode, RI_NULL);
	}
	free_token_params(count, token, params);
    }

# RC p.176 - DONE
double
RiGaussianFilter(x,y,xwidth,ywidth)
    RtFloat	x
    RtFloat	y
    RtFloat	xwidth
    RtFloat	ywidth

# RC p.176 - DONE
double
RiBoxFilter(x,y,xwidth,ywidth)
    RtFloat	x
    RtFloat	y
    RtFloat	xwidth
    RtFloat	ywidth

# RC p.176 - DONE
double
RiTriangleFilter(x,y,xwidth,ywidth)
    RtFloat	x
    RtFloat	y
    RtFloat	xwidth
    RtFloat	ywidth

# RC p.176 - DONE
double
RiCatmullRomFilter(x,y,xwidth,ywidth)
    RtFloat	x
    RtFloat	y
    RtFloat	xwidth
    RtFloat	ywidth

# RC p.176 - DONE
double
RiSincFilter(x,y,xwidth,ywidth)
    RtFloat	x
    RtFloat	y
    RtFloat	xwidth
    RtFloat	ywidth

# RC p.54 - DONE
void
RiHider(type, ...)
    RtToken	type
    CODE:
    {
	RtInt count = 0;
	RtToken* token = 0;
	RtPointer* params = 0;

	if (items == 1) { RiHider(type, RI_NULL); return; }
	if (items != 2) {
	    croak("Usage: RenderMan::Hider(type, {params})");
	    return;
	}

	# Optional Parameters...
	count = build_token_params(ST(1), &token, &params, "Hider", "2 (params)");

	if (!type || !type[0]) type = "null";
	if (count) {
            RiHiderV(type, count, token, params);
	} else {
	    RiHider(type, RI_NULL);
	}
	free_token_params(count, token, params);
    }

# RC p.43
void
RiColorSamples(N,nRGB,RGBn)
    RtInt	N
    SV*		nRGB
    SV*		RGBn
    CODE:
    {
	RtFloat* my_nRGB;
	RtFloat* my_RGBn;
	my_nRGB = get_RtFloat_array(3*N, ST(1), "ColorSamples", "2 (nRGB)");
	my_RGBn = get_RtFloat_array(3*N, ST(2), "ColorSamples", "3 (RGBn)");
	RiColorSamples(N, my_nRGB, my_RGBn);
	free(my_RGBn);
	free(my_nRGB);
    }

# RC p.196 - DONE
void
RiRelativeDetail(relativedetail)
    RtFloat	relativedetail

# RC p.46 - DONE
void
RiOption(name, ...)
    char*	name
    CODE:
    {
	RtInt count = 0;
	RtToken* token = 0;
	RtPointer* params = 0;

	if (items == 1) { RiOption(name, RI_NULL); return; }
	if (!name || !name[0] || items != 2) {
	    croak("Usage: RenderMan::Option(name, {params})");
	    return;
	}

	# Optional Parameters...
	count = build_token_params(ST(1), &token, &params, "Option", "2 (params)");

	if (count) {
            RiOptionV(name, count, token, params);
	} else {
	    RiOption(name, RI_NULL);
	}
	free_token_params(count, token, params);
    }

# RC p.50 - DONE
void
RiAttributeBegin()

# RC p.50 - DONE
void
RiAttributeEnd()

# RC p.213 - DONE
void
RiColor(...)
    CODE:
    {
	RtColor my_Cs;
	if (items == 1) {
	    get_RtColor(ST(0), &my_Cs, "Color", "1 (color)");
	} else if (items != 3) {
	    croak("Usage: RenderMan::Color(r, g, b) or ...([r, g, b])");
	} else {
	    my_Cs[0] = get_RtFloat_from_sv(ST(0), "Color", "1 (R)");
	    my_Cs[1] = get_RtFloat_from_sv(ST(1), "Color", "2 (G)");
	    my_Cs[2] = get_RtFloat_from_sv(ST(2), "Color", "3 (B)");
	}
	RiColor(my_Cs);
    }

# RC p.213 - DONE
void
RiOpacity(...)
    CODE:
    {
	RtColor my_Os;
	if (items == 1) {
	    get_RtColor(ST(0), &my_Os, "Opacity", "1 (opacity)");
	} else if (items != 3) {
	    croak("Usage: RenderMan::Opacity(r, g, b) or ...([r, g, b])");
	} else {
	    my_Os[0] = get_RtFloat_from_sv(ST(0), "Opacity", "1 (R)");
	    my_Os[1] = get_RtFloat_from_sv(ST(1), "Opacity", "2 (G)");
	    my_Os[2] = get_RtFloat_from_sv(ST(2), "Opacity", "3 (B)");
	}
	RiOpacity(my_Os);
    }

# RC p.251 - DONE
void
RiTextureCoordinates(s1,t1,s2,t2,s3,t3,s4,t4)
    RtFloat	s1
    RtFloat	t1
    RtFloat	s2
    RtFloat	t2
    RtFloat	s3
    RtFloat	t3
    RtFloat	s4
    RtFloat	t4

# RC p.216 - DONE
long
RiLightSource(name, ...)
    char*	name
    CODE:
    {
	RtInt count = 0;
	RtToken* token = 0;
	RtPointer* params = 0;
	RtLightHandle handle;

	if (items == 1) { RETVAL = (long)RiLightSource(name, RI_NULL); return; }
	if (!name || !name[0] || items != 2) {
	    croak("Usage: RenderMan::LightSource(name, {params})");
	    return;
	}

	# Optional Parameters...
	count = build_token_params(ST(1), &token, &params, "LightSource", "2 (params)");

	if (count) {
            handle = RiLightSourceV(name, count, token, params);
	} else {
	    handle = RiLightSource(name, RI_NULL);
	}
	free_token_params(count, token, params);

	RETVAL = (long)handle;
    }
    OUTPUT:
    RETVAL

# RC p.225 - DONE
long
RiAreaLightSource(name, ...)
    char*	name
    CODE:
    {
	RtInt count = 0;
	RtToken* token = 0;
	RtPointer* params = 0;
	RtLightHandle handle;

	if (items == 1) { RETVAL = (long)RiAreaLightSource(name, RI_NULL); return; }
	if (!name || !name[0] || items != 2) {
	    croak("Usage: RenderMan::AreaLightSource(name, {params})");
	    return;
	}

	# Optional Parameters...
	count = build_token_params(ST(1), &token, &params, "AreaLightSource", "2 (params)");

	if (count) {
            handle = RiAreaLightSourceV(name, count, token, params);
	} else {
	    handle = RiAreaLightSource(name, RI_NULL);
	}
	free_token_params(count, token, params);

	RETVAL = (long)handle;
    }
    OUTPUT:
    RETVAL

# RC p.217 - DONE
void
RiIlluminate(light,onoff)
    long	light
    RtBoolean	onoff
    CODE:
    {
	RtLightHandle my_handle = (RtLightHandle)light;
	RiIlluminate(my_handle, onoff);
    }

# RC p.231 - DONE
void
RiSurface(name, ...)
    char*	name
    CODE:
    {
	RtInt count = 0;
	RtToken* token = 0;
	RtPointer* params = 0;

	if (items == 1) { RiSurface(name, RI_NULL); return; }
	if (!name || !name[0] || items != 2) {
	    croak("Usage: RenderMan::Surface(name, {params})");
	    return;
	}

	# Optional Parameters...
	count = build_token_params(ST(1), &token, &params, "Surface", "2 (params)");

	if (count) {
            RiSurfaceV(name, count, token, params);
	} else {
	    RiSurface(name, RI_NULL);
	}
	free_token_params(count, token, params);
    }

# RC p.235 - DONE
void
RiAtmosphere(name, ...)
    char*	name
    CODE:
    {
	RtInt count = 0;
	RtToken* token = 0;
	RtPointer* params = 0;

	if (items == 1) { RiAtmosphere(name, RI_NULL); return; }
	if (!name || !name[0] || items != 2) {
	    croak("Usage: RenderMan::Atmosphere(name, {params})");
	    return;
	}

	# Optional Parameters...
	count = build_token_params(ST(1), &token, &params, "Atmosphere", "2 (params)");

	if (count) {
            RiAtmosphereV(name, count, token, params);
	} else {
	    RiAtmosphere(name, RI_NULL);
	}
	free_token_params(count, token, params);
    }

# RC p.235 - DONE
void
RiInterior(name, ...)
    char*	name
    CODE:
    {
	RtInt count = 0;
	RtToken* token = 0;
	RtPointer* params = 0;

	if (items == 1) { RiInterior(name, RI_NULL); return; }
	if (!name || !name[0] || items != 2) {
	    croak("Usage: RenderMan::Interior(name, {params})");
	    return;
	}

	# Optional Parameters...
	count = build_token_params(ST(1), &token, &params, "Interior", "2 (params)");

	if (count) {
            RiInteriorV(name, count, token, params);
	} else {
	    RiInterior(name, RI_NULL);
	}
	free_token_params(count, token, params);
    }

# RC p.235 - DONE
void
RiExterior(name, ...)
    char*	name
    CODE:
    {
	RtInt count = 0;
	RtToken* token = 0;
	RtPointer* params = 0;

	if (items == 1) { RiExterior(name, RI_NULL); return; }
	if (!name || !name[0] || items != 2) {
	    croak("Usage: RenderMan::Exterior(name, {params})");
	    return;
	}

	# Optional Parameters...
	count = build_token_params(ST(1), &token, &params, "Exterior", "2 (params)");

	if (count) {
            RiExteriorV(name, count, token, params);
	} else {
	    RiExterior(name, RI_NULL);
	}
	free_token_params(count, token, params);
    }

# RC p.214 - DONE
void
RiShadingRate(size)
    RtFloat	size

# RC p.215 - DONE
void
RiShadingInterpolation(type)
    RtToken	type

# RC p.216 - DONE
void
RiMatte(onoff)
    RtBoolean	onoff

# RC p.125 - DONE
void
RiBound(bound)
    SV*		bound
    CODE:
    {
	RtBound my_bound;
	get_RtBound(bound, &my_bound, "Bound", "1 (bound)");
	RiBound(my_bound);
    }

# RC p.195 - DONE
void
RiDetail(bound)
    SV*		bound
    CODE:
    {
	RtBound my_bound;
	get_RtBound(bound, &my_bound, "Detail", "1 (bound)");
	RiDetail(my_bound);
    }

# RC p.197 - DONE
void
RiDetailRange(minvis,lowtran,uptran,maxvis)
    RtFloat	minvis
    RtFloat	lowtran
    RtFloat	uptran
    RtFloat	maxvis

# RC p.172 - DONE
void
RiGeometricApproximation(type,value)
    RtToken	type
    RtFloat	value

# RC p.???
void
RiGeometricRepresentation(type)
    RtToken	type

# RC p.121 - DONE
void
RiOrientation(orientation)
    RtToken	orientation

# RC p.122 - DONE
void
RiReverseOrientation()

# RC p.119 - DONE
void
RiSides(nsides)
    RtInt	nsides

# RC p.117 - DONE
void
RiIdentity()

# RC p.117 - DONE
void
RiTransform(transform)
    SV*		transform
    CODE:
    {
	RtMatrix my_transform;
	get_RtMatrix(transform, &my_transform, "Transform", "1 (transform)");
	RiTransform(my_transform);
    }

# RC p.116 - DONE
void
RiConcatTransform(transform)
    SV*		transform
    CODE:
    {
	RtMatrix my_transform;
	get_RtMatrix(transform, &my_transform, "ConcatTransform", "1 (transform)");
	RiConcatTransform(my_transform);
    }

# RC p.114 - DONE
void
RiPerspective(fov)
    RtFloat	fov

# RC p.112 - DONE
void
RiTranslate(dx,dy,dz)
    RtFloat	dx
    RtFloat	dy
    RtFloat	dz

# RC p.112 - DONE
void
RiRotate(angle,dx,dy,dz)
    RtFloat	angle
    RtFloat	dx
    RtFloat	dy
    RtFloat	dz

# RC p.113 - DONE
void
RiScale(dx,dy,dz)
    RtFloat	dx
    RtFloat	dy
    RtFloat	dz

# RC p.113 - DONE
void
RiSkew(angle,dx1,dy1,dz1,dx2,dy2,dz2)
    RtFloat	angle
    RtFloat	dx1
    RtFloat	dy1
    RtFloat	dz1
    RtFloat	dx2
    RtFloat	dy2
    RtFloat	dz2

# RC p.117 - DONE
void
RiDeformation(name, ...)
    char*	name
    CODE:
    {
	RtInt count = 0;
	RtToken* token = 0;
	RtPointer* params = 0;

	if (items == 1) { RiDeformation(name, RI_NULL); return; }
	if (!name || !name[0] || items != 2) {
	    croak("Usage: RenderMan::Deformation(name, {params})");
	    return;
	}

	# Optional Parameters...
	count = build_token_params(ST(1), &token, &params, "Deformation", "2 (params)");

	if (count) {
            RiDeformationV(name, count, token, params);
	} else {
	    RiDeformation(name, RI_NULL);
	}
	free_token_params(count, token, params);
    }

# RC p.260 - DONE
void
RiDisplacement(name, ...)
    char*	name
    CODE:
    {
	RtInt count = 0;
	RtToken* token = 0;
	RtPointer* params = 0;

	if (items == 1) { RiDisplacement(name, RI_NULL); return; }
	if (!name || !name[0] || items != 2) {
	    croak("Usage: RenderMan::Displacement(name, {params})");
	    return;
	}

	# Optional Parameters...
	count = build_token_params(ST(1), &token, &params, "Displacement", "2 (params)");

	if (count) {
            RiDisplacementV(name, count, token, params);
	} else {
	    RiDisplacement(name, RI_NULL);
	}
	free_token_params(count, token, params);
    }

# RC p.123 - DONE
void
RiCoordinateSystem(space)
    RtToken	space

# RC p.123 - DONE
void
RiTransformPoints(fromspace,tospace,npoints,points)
    RtToken	fromspace
    RtToken	tospace
    RtInt	npoints
    SV*		points
    CODE:
    {
	RtFloat* my_points;
	long i;
	npoints *= 3;
	my_points = get_RtFloat_array(npoints, ST(3), "TransformPoints", "4 (points)");
	if (!RiTransformPoints(fromspace,tospace,npoints,(RtPoint*)my_points))
	    croak("Could not TransformPoints");
	EXTEND(sp,npoints);
	for (i=0; i<npoints; i++)
	  PUSHs(sv_2mortal(newSVnv(my_points[i])));
	free(my_points);
    }

# RC p.111 - DONE
void
RiTransformBegin()

# RC p.111 - DONE
void
RiTransformEnd()

# RC p.46 - DONE
void
RiAttribute(name, ...)
    char*	name
    CODE:
    {
	RtInt count = 0;
	RtToken* token = 0;
	RtPointer* params = 0;

	if (items == 1) { RiAttribute(name, RI_NULL); return; }
	if (!name || !name[0] || items != 2) {
	    croak("Usage: RenderMan::Attribute(name, {params})");
	    return;
	}

	# Optional Parameters...
	count = build_token_params(ST(1), &token, &params, "Attribute", "2 (params)");

	if (count) {
            RiAttributeV(name, count, token, params);
	} else {
	    RiAttribute(name, RI_NULL);
	}
	free_token_params(count, token, params);
    }

# RC p.70 - DONE
void
RiPolygon(nvertices, ...)
    RtInt	nvertices
    CODE:
    {
	RtInt count = 0;
	RtToken* token = 0;
	RtPointer* params = 0;

	if (items<1 || items>2) {
	    croak("Usage: RenderMan::Polygon(nvertices, {params})");
	    return;
	}
	if (items == 1) {
	    RiPolygon(nvertices, RI_NULL);
	    return;
	}

	# Optional Parameters...
	count = build_token_params(ST(1), &token, &params, "Polygon", "2 (params)");

	if (count) {
            RiPolygonV(nvertices, count, token, params);
	} else {
            RiPolygon(nvertices, RI_NULL);
	}
	free_token_params(count, token, params);
    }

# RC p.78 - DONE
void
RiGeneralPolygon(nloops,nverts, ...)
    RtInt	nloops
    SV*		nverts
    CODE:
    {
	RtInt count = 0;
	RtToken* token = 0;
	RtPointer* params = 0;
	RtInt *my_nverts = 0;

	if (items<2 || items>3) {
	    croak("Usage: RenderMan::GeneralPolygon(nloops, nverts, {params})");
	    return;
	}

	my_nverts = get_RtInt_array(nloops, ST(1), "GeneralPolygon", "2 (nverts)");

	if (items == 2) {
	    RiGeneralPolygon(nloops, my_nverts, RI_NULL);
	    free(my_nverts);
	    return;
	}

	# Optional Parameters...
	count = build_token_params(ST(2), &token, &params, "GeneralPolygon", "3 (params)");

	if (count) {
            RiGeneralPolygonV(nloops, my_nverts, count, token, params);
	} else {
            RiGeneralPolygon(nloops, my_nverts, RI_NULL);
	}
	free_token_params(count, token, params);
	free(my_nverts);
    }

# RC p.79 - DONE
void
RiPointsPolygons(npolys,nverts,verts, ...)
    RtInt	npolys
    SV*		nverts
    SV*		verts
    CODE:
    {
	RtInt count = 0;
	RtToken* token = 0;
	RtPointer* params = 0;
	RtInt *my_nverts = 0;
	RtInt *my_verts = 0;
	long sum = 0;

	if (items<3 || items>4) {
	    croak("Usage: RenderMan::PointsPolygons(npolys, nverts, verts, {params})");
	    return;
	}

	my_nverts = get_RtInt_array(npolys, ST(1), "PointsPolygons", "2 (nverts)");
	for (count=npolys; count--; ) sum += my_nverts[count];
	my_verts = get_RtInt_array(sum, ST(2), "PointsPolygons", "3 (verts)");

	if (items == 3) {
	    RiPointsPolygons(npolys, my_nverts, my_verts, RI_NULL);
	    free(my_verts);
	    free(my_nverts);
	    return;
	}

	# Optional Parameters...
	count = build_token_params(ST(3), &token, &params, "PointsPolygons", "4 (params)");

	if (count) {
            RiPointsPolygonsV(npolys, my_nverts, my_verts, count, token, params);
	} else {
            RiPointsPolygons(npolys, my_nverts, my_verts, RI_NULL);
	}
	free_token_params(count, token, params);
	free(my_verts);
	free(my_nverts);
    }

# RC p.82 - DONE
void
RiPointsGeneralPolygons(npolys,nloops,nverts,verts, ...)
    RtInt	npolys
    SV*		nloops
    SV*		nverts
    SV*		verts
    CODE:
    {
	RtInt count = 0;
	RtToken* token = 0;
	RtPointer* params = 0;
	RtInt *my_nloops = 0;
	RtInt *my_nverts = 0;
	RtInt *my_verts = 0;
	long sum1 = 0;
	long sum2 = 0;

	if (items<4 || items>5) {
	    croak("Usage: RenderMan::PointsGeneralPolygons(npolys, nloops, nverts, verts, {params})");
	    return;
	}

	my_nloops = get_RtInt_array(npolys, ST(1), "PointsGeneralPolygons", "2 (nloops)");
	for (count=npolys; count--; ) sum1 += my_nloops[count];
	my_nverts = get_RtInt_array(sum1, ST(2), "PointsGeneralPolygons", "3 (nverts)");
	for (count=sum1; count--; ) sum2 += my_nverts[count];
	my_verts = get_RtInt_array(sum2, ST(3), "PointsGeneralPolygons", "4 (verts)");

	if (items == 4) {
	    RiPointsGeneralPolygons(npolys, my_nloops, my_nverts, my_verts, RI_NULL);
	    free(my_verts);
	    free(my_nverts);
	    free(my_nloops);
	    return;
	}

	# Optional Parameters...
	count = build_token_params(ST(4), &token, &params, "PointsGeneralPolygons", "5 (params)");

	if (count) {
            RiPointsGeneralPolygonsV(npolys, my_nloops, my_nverts, my_verts, count, token, params);
	} else {
            RiPointsGeneralPolygons(npolys, my_nloops, my_nverts, my_verts, RI_NULL);
	}
	free_token_params(count, token, params);
	free(my_verts);
	free(my_nverts);
	free(my_nloops);
    }

# RC p.93 - DONE
void
RiBasis(ubasis,ustep,vbasis,vstep)
    SV*		ubasis
    RtInt	ustep
    SV*		vbasis
    RtInt	vstep
    CODE:
    {
	RtBasis my_ubasis;
	RtBasis my_vbasis;
	get_RtBasis(ubasis, &my_ubasis, "Basis", "1 (ubasis)");
	get_RtBasis(vbasis, &my_vbasis, "Basis", "3 (vbasis)");
	RiBasis(my_ubasis, ustep, my_vbasis, vstep);
    }

# RC p.87 - DONE
void
RiPatch(type, ...)
    RtToken	type
    CODE:
    {
	RtInt count = 0;
	RtToken* token = 0;
	RtPointer* params = 0;

	if (items == 1) { RiPatch(type, RI_NULL); return; }
	if (!type || !type[0] || items != 2) {
	    croak("Usage: RenderMan::Patch(type, {params})");
	    return;
	}

	# Optional Parameters...
	count = build_token_params(ST(1), &token, &params, "Patch", "2 (params)");

	if (count) {
            RiPatchV(type, count, token, params);
	} else {
	    RiPatch(type, RI_NULL);
	}
	free_token_params(count, token, params);
    }

# RC p.98 - DONE
void
RiPatchMesh(type,nu,uwrap,nv,vwrap, ...)
    RtToken	type
    RtInt	nu
    RtToken	uwrap
    RtInt	nv
    RtToken	vwrap
    CODE:
    {
	RtInt count = 0;
	RtToken* token = 0;
	RtPointer* params = 0;

	if (items<5 || items>6) {
	    croak("Usage: RenderMan::PatchMesh(type, nu, uwrap, nv, vwrap, {params})");
	    return;
	}
	if (items == 5) {
	    RiPatchMesh(type, nu, uwrap, nv, vwrap, RI_NULL);
	    return;
	}

	# Optional Parameters...
	count = build_token_params(ST(5), &token, &params, "PatchMesh", "6 (params)");

	if (count) {
            RiPatchMeshV(type, nu, uwrap, nv, vwrap, count, token, params);
	} else {
            RiPatchMesh(type, nu, uwrap, nv, vwrap, RI_NULL);
	}
	free_token_params(count, token, params);
    }

# RC p.104 - DONE
void
RiNuPatch(nu,uorder,uknot,umin,umax,nv,vorder,vknot,vmin,vmax, ...)
    RtInt	nu
    RtInt	uorder
    RtFloat*	uknot
    RtFloat	umin
    RtFloat	umax
    RtInt	nv
    RtInt	vorder
    RtFloat*	vknot
    RtFloat	vmin
    RtFloat	vmax
    CODE:
    {
	RtInt count = 0;
	RtToken* token = 0;
	RtPointer* params = 0;
	RtFloat* my_uknot;
	RtFloat* my_vknot;

	if (items<10 || items>11) {
	    croak("Usage: RenderMan::NuPatch(nu, uorder, uknot, umin, umax, nv, vorder, vknot, vmin, vmax, {params})");
	    return;
	}

	my_uknot = get_RtFloat_array(nu+uorder, ST(2), "NuPatch", "3 (uknot)");
	my_vknot = get_RtFloat_array(nv+vorder, ST(7), "NuPatch", "8 (vknot)");

	if (items == 10) {
	    RiNuPatch(nu, uorder, my_uknot, umin, umax, nv, vorder, my_vknot, vmin, vmax, RI_NULL);
	    free(my_vknot);
	    free(my_uknot);
	    return;
	}

	# Optional Parameters...
	count = build_token_params(ST(10), &token, &params, "NuPatch", "11 (params)");

	if (count) {
            RiNuPatchV(nu, uorder, my_uknot, umin, umax, nv, vorder, my_vknot, vmin, vmax, count, token, params);
	} else {
            RiNuPatch(nu, uorder, my_uknot, umin, umax, nv, vorder, my_vknot, vmin, vmax, RI_NULL);
	}
	free_token_params(count, token, params);
	free(my_vknot);
	free(my_uknot);
    }

# RC p.249 - DONE
void
RiTrimCurve(nloops,ncurves,order,knot,amin,amax,n,u,v,w)
    RtInt	nloops
    SV*		ncurves
    SV*		order
    SV*		knot
    SV*		amin
    SV*		amax
    SV*		n
    SV*		u
    SV*		v
    SV*		w
    CODE:
    {
	RtInt count = 0;
	RtToken* token = 0;
	RtPointer* params = 0;
	RtInt* my_ncurves;
	RtInt* my_order;
	RtInt* my_n;
	RtFloat* my_knot;
	RtFloat* my_amin;
	RtFloat* my_amax;
	RtFloat* my_u;
	RtFloat* my_v;
	RtFloat* my_w;
	long total_curves = 0;
        long control_count = 0;
	long knot_count = 0;

	my_ncurves = get_RtInt_array(nloops, ST(1), "TrimCurve", "2 (ncurves)");
	for (count=nloops; count--; ) total_curves += my_ncurves[count];
	my_order = get_RtInt_array(total_curves, ST(2), "TrimCurve", "3 (order)");
	my_amin  = get_RtFloat_array(total_curves, ST(4), "TrimCurve", "5 (amin)");
	my_amax  = get_RtFloat_array(total_curves, ST(5), "TrimCurve", "6 (amax)");
	my_n     = get_RtInt_array(total_curves, ST(6), "TrimCurve", "7 (n)");
	for (count=total_curves; count--; ) {
            control_count += my_n[count];
            knot_count += (my_order[count] + my_n[count]);
        }
	my_u     = get_RtFloat_array(control_count, ST(7), "TrimCurve", "8 (u)");
	my_v     = get_RtFloat_array(control_count, ST(8), "TrimCurve", "9 (v)");
	my_w     = get_RtFloat_array(control_count, ST(9), "TrimCurve", "10 (w)");
	my_knot  = get_RtFloat_array(knot_count, ST(3), "TrimCurve", "4 (knot)");

	RiTrimCurve(nloops, my_ncurves, my_order, my_knot, my_amin, my_amax, my_n, my_u, my_v, my_w);

	free(my_knot);
	free(my_w);
	free(my_v);
	free(my_u);
	free(my_n);
	free(my_amax);
	free(my_amin);
	free(my_order);
	free(my_ncurves);
    }

# RC p.62 - DONE
void
RiSphere(radius,zmin,zmax,thetamax, ...)
    RtFloat	radius
    RtFloat	zmin
    RtFloat	zmax
    RtFloat	thetamax
    CODE:
    {
	RtInt count = 0;
	RtToken* token = 0;
	RtPointer* params = 0;

	if (items<4 || items>5) {
	    croak("Usage: RenderMan::Sphere(radius, zmin, zmax, thetamax, {params})");
	    return;
	}
	if (items == 4) {
	    RiSphere(radius, zmin, zmax, thetamax, RI_NULL);
	    return;
	}

	# Optional Parameters...
	count = build_token_params(ST(4), &token, &params, "Sphere", "5 (params)");

	if (count) {
            RiSphereV(radius, zmin, zmax, thetamax, count, token, params);
	} else {
            RiSphere(radius, zmin, zmax, thetamax, RI_NULL);
	}
	free_token_params(count, token, params);
    }

# RC p.62 - DONE
void
RiCone(height,radius,thetamax, ...)
    RtFloat	height
    RtFloat	radius
    RtFloat	thetamax
    CODE:
    {
	RtInt count = 0;
	RtToken* token = 0;
	RtPointer* params = 0;

	if (items<3 || items>4) {
	    croak("Usage: RenderMan::Cone(height, radius, thetamax, {params})");
	    return;
	}
	if (items == 3) {
	    RiCone(height, radius, thetamax, RI_NULL);
	    return;
	}

	# Optional Parameters...
	count = build_token_params(ST(3), &token, &params, "Cone", "4 (params)");

	if (count) {
            RiConeV(height, radius, thetamax, count, token, params);
	} else {
            RiCone(height, radius, thetamax, RI_NULL);
	}
	free_token_params(count, token, params);
    }

# RC p.63 - DONE
void
RiCylinder(radius,zmin,zmax,thetamax, ...)
    RtFloat	radius
    RtFloat	zmin
    RtFloat	zmax
    RtFloat	thetamax
    CODE:
    {
	RtInt count = 0;
	RtToken* token = 0;
	RtPointer* params = 0;

	if (items<4 || items>5) {
	    croak("Usage: RenderMan::Cylinder(radius, zmin, zmax, thetamax, {params})");
	    return;
	}
	if (items == 4) {
	    RiCylinder(radius, zmin, zmax, thetamax, RI_NULL);
	    return;
	}

	# Optional Parameters...
	count = build_token_params(ST(4), &token, &params, "Cylinder", "5 (params)");

	if (count) {
            RiCylinderV(radius, zmin, zmax, thetamax, count, token, params);
	} else {
            RiCylinder(radius, zmin, zmax, thetamax, RI_NULL);
	}
	free_token_params(count, token, params);
    }

# RC p.63 - DONE
void
RiHyperboloid(point1,point2,thetamax, ...)
    SV* 	point1
    SV* 	point2
    RtFloat	thetamax
    CODE:
    {
	RtInt count = 0;
	RtToken* token = 0;
	RtPointer* params = 0;
	RtPoint p1, p2;

	if (items<3 || items>4) {
	    croak("Usage: RenderMan::Hyperboloid(point1, point2, thetamax, {params})");
	    return;
	}

	get_RtPoint(&p1, ST(0), "Hyperboloid", "1 (point1)");
	get_RtPoint(&p2, ST(1), "Hyperboloid", "2 (point2)");

	if (items == 3) {
	    RiHyperboloid(p1, p2, thetamax, RI_NULL);
	    return;
	}

	# Optional Parameters...
	count = build_token_params(ST(3), &token, &params, "Hyperboloid", "4 (params)");

	if (count) {
            RiHyperboloidV(p1, p2, thetamax, count, token, params);
	} else {
            RiHyperboloid(p1, p2, thetamax, RI_NULL);
	}
	free_token_params(count, token, params);
    }

# RC p.66 - DONE
void
RiParaboloid(rmax,zmin,zmax,thetamax, ...)
    RtFloat	rmax
    RtFloat	zmin
    RtFloat	zmax
    RtFloat	thetamax
    CODE:
    {
	RtInt count = 0;
	RtToken* token = 0;
	RtPointer* params = 0;

	if (items<4 || items>5) {
	    croak("Usage: RenderMan::Paraboloid(rmax, zmin, zmax, thetamax, {params})");
	    return;
	}
	if (items == 4) {
	    RiParaboloid(rmax, zmin, zmax, thetamax, RI_NULL);
	    return;
	}

	# Optional Parameters...
	count = build_token_params(ST(4), &token, &params, "Paraboloid", "5 (params)");

	if (count) {
            RiParaboloidV(rmax, zmin, zmax, thetamax, count, token, params);
	} else {
            RiParaboloid(rmax, zmin, zmax, thetamax, RI_NULL);
	}
	free_token_params(count, token, params);
    }

# RC p.62 - DONE
void
RiDisk(height,radius,thetamax, ...)
    RtFloat	height
    RtFloat	radius
    RtFloat	thetamax
    CODE:
    {
	RtInt count = 0;
	RtToken* token = 0;
	RtPointer* params = 0;

	if (items<3 || items>4) {
	    croak("Usage: RenderMan::Disk(height, radius, thetamax, {params})");
	    return;
	}
	if (items == 3) {
	    RiDisk(height, radius, thetamax, RI_NULL);
	    return;
	}

	# Optional Parameters...
	count = build_token_params(ST(3), &token, &params, "Disk", "4 (params)");

	if (count) {
            RiDiskV(height, radius, thetamax, count, token, params);
	} else {
            RiDisk(height, radius, thetamax, RI_NULL);
	}
	free_token_params(count, token, params);
    }

# RC p.66 - DONE
void
RiTorus(majorrad,minorrad,phimin,phimax,thetamax, ...)
    RtFloat	majorrad
    RtFloat	minorrad
    RtFloat	phimin
    RtFloat	phimax
    RtFloat	thetamax
    CODE:
    {
	RtInt count = 0;
	RtToken* token = 0;
	RtPointer* params = 0;

	if (items<5 || items>6) {
	    croak("Usage: RenderMan::Torus(majorrad, minorrad, phimin, phimax, thetamax, {params})");
	    return;
	}
	if (items == 5) {
	    RiTorus(majorrad, minorrad, phimin, phimax, thetamax, RI_NULL);
	    return;
	}

	# Optional Parameters...
	count = build_token_params(ST(5), &token, &params, "Torus", "6 (params)");

	if (count) {
            RiTorusV(majorrad, minorrad, phimin, phimax, thetamax, count, token, params);
	} else {
            RiTorus(majorrad, minorrad, phimin, phimax, thetamax, RI_NULL);
	}
	free_token_params(count, token, params);
    }

# RiProcedural - not supported (yet)

# RC p.???
void
RiGeometry(type, ...)
    RtToken	type
    CODE:
    {
	RtInt count = 0;
	RtToken* token = 0;
	RtPointer* params = 0;

	if (items<1 || items>2) {
	    croak("Usage: RenderMan::Geometry(type, {params})");
	    return;
	}
	if (items == 1) {
	    RiGeometry(type, RI_NULL);
	    return;
	}

	# Optional Parameters...
	count = build_token_params(ST(1), &token, &params, "Geometry", "2 (params)");

	if (count) {
            RiGeometryV(type, count, token, params);
	} else {
            RiGeometry(type, RI_NULL);
	}
	free_token_params(count, token, params);
    }

# RC p.??? - DONE
void
RiCurves(degree,ncurves,nverts,wrap, ...)
    RtToken     degree
    RtInt       ncurves
    SV*         nverts
    RtToken     wrap
    CODE:
    {
	RtInt count = 0;
	RtToken* token = 0;
	RtPointer* params = 0;
	RtInt *my_nverts = 0;

	if (items<4 || items>5) {
	    croak("Usage: RenderMan::Curves(degree, ncurves, nverts, wrap, {params})");
	    return;
	}

        my_nverts = get_RtInt_array(ncurves, ST(2), "Curves", "3 (nverts)");

        if (items == 4) {
            RiCurves(degree, ncurves, my_nverts, wrap, RI_NULL);
            free(my_nverts);
            return;
        }

        # Optional Parameters...
        count = build_token_params(ST(4), &token, &params, "Curves", "5 (params)");

        if (count) {
            RiCurvesV(degree, ncurves, my_nverts, wrap, count, token, params);
        } else {
            RiCurves(degree, ncurves, my_nverts, wrap, RI_NULL);
        }
        free(my_nverts);
	free_token_params(count, token, params);
    }

# RC p.??? - DONE
void
RiPoints(npts, ...)
    RtInt       npts
    CODE:
    {
	RtInt count = 0;
	RtToken* token = 0;
	RtPointer* params = 0;

	if (items<1 || items>2) {
	    croak("Usage: RenderMan::Points(npts, {params})");
	    return;
	}

        if (items == 1) {
            RiPoints(npts, RI_NULL);
            return;
        }

        # Optional Parameters...
        count = build_token_params(ST(1), &token, &params, "Points", "2 (params)");

        if (count) {
            RiPointsV(npts, count, token, params);
        } else {
            RiPoints(npts, RI_NULL);
        }
        free_token_params(count, token, params);
    }

# RC p.??? - DONE
void
RiSubdivisionMesh(scheme, nfaces, nvertices, vertices, ntags, tags, nargs, intargs, floatargs, ...)
    RtToken     scheme
    RtInt       nfaces
    SV*         nvertices
    SV*         vertices
    RtInt       ntags
    SV*         tags
    SV*         nargs
    SV*         intargs
    SV*         floatargs
    CODE:
    {
	RtInt count = 0;
	RtToken* token = 0;
	RtPointer* params = 0;
        RtInt* my_nvertices = 0;
	long sum = 0;
        RtInt* my_vertices = 0;
        RtToken* my_tags = 0;
        RtInt* my_nargs = 0;
        long intsum = 0;
        long floatsum = 0;
        RtInt* my_intargs = 0;
        RtFloat* my_floatargs = 0;

	if (items<9 || items>10) {
	    croak("Usage: RenderMan::SubdivisionMesh(scheme, nfaces, nvertices, vertices, ntags, tags, nargs, intargs, floatargs, {params})");
	    return;
	}

	my_nvertices = get_RtInt_array(nfaces, ST(2), "SubdivisionMesh", "3 (nvertices)");
	for (count=nfaces; count--; ) sum += my_nvertices[count];
	my_vertices = get_RtInt_array(sum, ST(3), "SubdivisionMesh", "4 (vertices)");
	my_tags = get_RtToken_array(ntags, ST(5), "SubdivisionMesh", "6 (tags)");
	my_nargs = get_RtInt_array(ntags*2, ST(6), "SubdivisionMesh", "7 (nargs)");
	for (count=0; count < 2*ntags; count++) {
          intsum += my_nargs[count];
          count++;
          floatsum += my_nargs[count];
        }
	my_intargs = get_RtInt_array(intsum, ST(7), "SubdivisionMesh", "8 (intargs)");
	my_floatargs = get_RtFloat_array(floatsum, ST(8), "SubdivisionMesh", "9 (floatargs)");

        if (items == 9) {
            RiSubdivisionMesh(scheme, nfaces, my_nvertices, my_vertices, ntags, my_tags, my_nargs, my_intargs, my_floatargs, RI_NULL);
            free(my_nvertices);
            free(my_vertices);
            free(my_tags);
            free(my_nargs);
            free(my_intargs);
            free(my_floatargs);
            return;
        }

        # Optional Parameters...
        count = build_token_params(ST(9), &token, &params, "SubdivisionMesh", "10 (params)");

        if (count) {
            RiSubdivisionMeshV(scheme, nfaces, my_nvertices, my_vertices, ntags, my_tags, my_nargs, my_intargs, my_floatargs, count, token, params);
        } else {
            RiSubdivisionMesh(scheme, nfaces, my_nvertices, my_vertices, ntags, my_tags, my_nargs, my_intargs, my_floatargs, RI_NULL);
        }
        free_token_params(count, token, params);
        free(my_nvertices);
        free(my_vertices);
        free(my_tags);
        free(my_nargs);
        free(my_intargs);
        free(my_floatargs);
    }


#BMRT2.5.0.8 BMRT 2.5.0.8 does not yet support Blobby
#BMRT2.5.0.8 # RC p.??? - DONE
#BMRT2.5.0.8 void
#BMRT2.5.0.8 RiBlobby(nleaf, ncode, code, nflt, flt, nstr, str, ...)
#BMRT2.5.0.8     RtInt     nleaf
#BMRT2.5.0.8     RtInt     ncode
#BMRT2.5.0.8     SV*       code
#BMRT2.5.0.8     RtInt     nflt
#BMRT2.5.0.8     SV*       flt
#BMRT2.5.0.8     RtInt     nstr
#BMRT2.5.0.8     SV*       str
#BMRT2.5.0.8     CODE:
#BMRT2.5.0.8     {
#BMRT2.5.0.8         RtInt count = 0;
#BMRT2.5.0.8         RtToken* token = 0;
#BMRT2.5.0.8         RtPointer* params = 0;
#BMRT2.5.0.8         RtInt* my_code = 0;
#BMRT2.5.0.8         RtFloat* my_flt = 0;
#BMRT2.5.0.8         RtToken* my_str = 0;
#BMRT2.5.0.8 
#BMRT2.5.0.8         if (items<7 || items>8) {
#BMRT2.5.0.8             croak("Usage: RenderMan::Blobby(nleaf, ncode, code, nflt, flt, nstr, str, {params})");
#BMRT2.5.0.8             return;
#BMRT2.5.0.8         }
#BMRT2.5.0.8 
#BMRT2.5.0.8         my_code = get_RtInt_array(ncode, ST(2), "Blobby", "3 (code)");
#BMRT2.5.0.8         my_flt = get_RtFloat_array(nflt, ST(4), "Blobby", "5 (flt)");
#BMRT2.5.0.8         my_str = get_RtToken_array(nstr, ST(6), "Blobby", "7 (str)");
#BMRT2.5.0.8 
#BMRT2.5.0.8         if (items == 7) {
#BMRT2.5.0.8             RiBlobby(nleaf, ncode, my_code, nflt, my_flt, nstr, my_str, RI_NULL);
#BMRT2.5.0.8             free(my_code);
#BMRT2.5.0.8             free(my_flt);
#BMRT2.5.0.8             free(my_str);
#BMRT2.5.0.8             return;
#BMRT2.5.0.8         }
#BMRT2.5.0.8 
#BMRT2.5.0.8         # Optional Parameters...
#BMRT2.5.0.8         count = build_token_params(ST(7), &token, &params, "Blobby", "8 (params)");
#BMRT2.5.0.8 
#BMRT2.5.0.8         if (count) {
#BMRT2.5.0.8             RiBlobbyV(nleaf, ncode, my_code, nflt, my_flt, nstr, my_str, count, token, params);
#BMRT2.5.0.8         } else {
#BMRT2.5.0.8             RiBlobby(nleaf, ncode, my_code, nflt, my_flt, nstr, my_str, RI_NULL);
#BMRT2.5.0.8         }
#BMRT2.5.0.8         free_token_params(count, token, params);
#BMRT2.5.0.8         free(my_code);
#BMRT2.5.0.8         free(my_flt);
#BMRT2.5.0.8         free(my_str);
#BMRT2.5.0.8     }

# RC p.126 - DONE
void
RiSolidBegin(type)
    RtToken	type

# RC p.126 - DONE
void
RiSolidEnd()

# RC p.133 - DONE
long
RiObjectBegin()
    CODE:
    {
	RtObjectHandle handle = RiObjectBegin();
	RETVAL = (long)handle;
    }
    OUTPUT:
    RETVAL

# RC p.133 - DONE
void
RiObjectEnd()

# RC p.134 - DONE
void
RiObjectInstance(handle)
    long	handle
    CODE:
    {
	RtObjectHandle my_handle = (RtObjectHandle)handle;
	RiObjectInstance(my_handle);
    }

# RC p.189 - DONE
void
RiMotionBegin(N, ...)
    RtInt	N
    CODE:
    {
	RtFloat* times;
	long count;
	if (items<1) {
	    croak("Usage: RenderMan::MotionBegin(N, ...)");
	    return;
	}
	if (items == 2 && N > 1) {
	    times = get_RtFloat_array(N, ST(1), "MotionBegin", "2 (times)");
	} else {
	    if (!(times = (RtFloat*)malloc(N*sizeof(RtFloat))))
		croak("Out of memory in MotionBegin");
	    for (count=0; count<N; count++)
	      times[count] = get_RtFloat_from_sv(ST(1+count), "MotionBegin", "(time)");
	}
	RiMotionBeginV(N, times);
	free(times);
    }

# RC p.189 - DONE
void
RiMotionEnd()

# RC p.256
void
RiMakeTexture(pic,tex,swrap,twrap,filterfunc,swidth,twidth, ...)
    char*	pic
    char*	tex
    RtToken	swrap
    RtToken	twrap
    RtFilterFunc	filterfunc
    RtFloat	swidth
    RtFloat	twidth
    CODE:
    {
	RtInt count = 0;
	RtToken* token = 0;
	RtPointer* params = 0;

	if (items<7 || items>8) {
	    croak("Usage: RenderMan::MakeTexture(pic,tex,swrap,twrap,filterfunc,swidth,twidth,{params})");
	    return;
	}
	if (items == 7) {
	    RiMakeTexture(pic,tex,swrap,twrap,filterfunc,swidth,twidth,RI_NULL);
	    return;
	}

	# Optional Parameters...
	count = build_token_params(ST(7), &token, &params, "MakeTexture", "8 (params)");

	if (count) {
            RiMakeTextureV(pic,tex,swrap,twrap,filterfunc,swidth,twidth,count,token,params);
	} else {
            RiMakeTexture(pic,tex,swrap,twrap,filterfunc,swidth,twidth,RI_NULL);
	}
	free_token_params(count, token, params);
    }

# RC p.259
void
RiMakeBump(pic,tex,swrap,twrap,filterfunc,swidth,twidth, ...)
    char*	pic
    char*	tex
    RtToken	swrap
    RtToken	twrap
    RtFilterFunc	filterfunc
    RtFloat	swidth
    RtFloat	twidth
    CODE:
    {
	RtInt count = 0;
	RtToken* token = 0;
	RtPointer* params = 0;

	if (items<7 || items>8) {
	    croak("Usage: RenderMan::MakeBump(pic,tex,swrap,twrap,filterfunc,swidth,twidth,{params})");
	    return;
	}
	if (items == 7) {
	    RiMakeBump(pic,tex,swrap,twrap,filterfunc,swidth,twidth,RI_NULL);
	    return;
	}

	# Optional Parameters...
	count = build_token_params(ST(7), &token, &params, "MakeBump", "8 (params)");

	if (count) {
            RiMakeBumpV(pic,tex,swrap,twrap,filterfunc,swidth,twidth,count,token,params);
	} else {
            RiMakeBump(pic,tex,swrap,twrap,filterfunc,swidth,twidth,RI_NULL);
	}
	free_token_params(count, token, params);
    }

# RC p.263 - DONE
void
RiMakeLatLongEnvironment(pic,tex,filterfunc,swidth,twidth, ...)
    char*	pic
    char*	tex
    RtFilterFunc	filterfunc
    RtFloat	swidth
    RtFloat	twidth
    CODE:
    {
	RtInt count = 0;
	RtToken* token = 0;
	RtPointer* params = 0;

	if (items<5 || items>6) {
	    croak("Usage: RenderMan::MakeLatLongEnvironment(pic,tex,filterfunc,swidth,twidth,{params})");
	    return;
	}
	if (items == 5) {
	    RiMakeLatLongEnvironment(pic,tex,filterfunc,swidth,twidth,RI_NULL);
	    return;
	}

	# Optional Parameters...
	count = build_token_params(ST(5), &token, &params, "MakeLatLongEnvironment", "6 (params)");

	if (count) {
            RiMakeLatLongEnvironmentV(pic,tex,filterfunc,swidth,twidth,count,token,params);
	} else {
            RiMakeLatLongEnvironment(pic,tex,filterfunc,swidth,twidth,RI_NULL);
	}
	free_token_params(count, token, params);
    }

# RC p.263
void
RiMakeCubeFaceEnvironment(px,nx,py,ny,pz,nz,tex,fov,filterfunc,swidth,twidth, ...)
    char*	px
    char*	nx
    char*	py
    char*	ny
    char*	pz
    char*	nz
    char*	tex
    RtFloat	fov
    RtFilterFunc	filterfunc
    RtFloat	swidth
    RtFloat	twidth
    CODE:
    {
	RtInt count = 0;
	RtToken* token = 0;
	RtPointer* params = 0;

	if (items<11 || items>12) {
	    croak("Usage: RenderMan::MakeCubeFaceEnvironment(px,nx,py,ny,pz,nz,tex,fov,filterfunc,swidth,twidth,{params})");
	    return;
	}
	if (items == 11) {
	    RiMakeCubeFaceEnvironment(px,nx,py,ny,pz,nz,tex,fov,filterfunc,swidth,twidth,RI_NULL);
	    return;
	}

	# Optional Parameters...
	count = build_token_params(ST(11), &token, &params, "MakeCubeFaceEnvironment", "12 (params)");

	if (count) {
            RiMakeCubeFaceEnvironmentV(px,nx,py,ny,pz,nz,tex,fov,filterfunc,swidth,twidth,count,token,params);
	} else {
            RiMakeCubeFaceEnvironment(px,nx,py,ny,pz,nz,tex,fov,filterfunc,swidth,twidth,RI_NULL);
	}
	free_token_params(count, token, params);
    }

# RC p.269 - DONE
void
RiMakeShadow(pic,tex, ...)
    char*	pic
    char*	tex
    CODE:
    {
	RtInt count = 0;
	RtToken* token = 0;
	RtPointer* params = 0;

	if (items<2 || items>3) {
	    croak("Usage: RenderMan::MakeShadow(pic, tex, {params})");
	    return;
	}
	if (items == 2) {
	    RiMakeShadow(pic, tex, RI_NULL);
	    return;
	}

	# Optional Parameters...
	count = build_token_params(ST(2), &token, &params, "MakeShadow", "3 (params)");

	if (count) {
            RiMakeShadowV(pic, tex, count, token, params);
	} else {
            RiMakeShadow(pic, tex, RI_NULL);
	}
	free_token_params(count, token, params);
    }

# RC p.38
void
RiErrorHandler(handler)
    RtErrorHandler	handler

# RC p.38
void
RiErrorIgnore(code,severity,message)
    RtInt	code
    RtInt	severity
    char*	message

# RC p.38
void
RiErrorPrint(code,severity,message)
    RtInt	code
    RtInt	severity
    char*	message

# RC p.38
void
RiErrorAbort(code,severity,message)
    RtInt	code
    RtInt	severity
    char*	message

# RC p.??? - DONE
void
RiArchiveRecord(type,format, ...)
    RtToken	type
    char*	format
    CODE:
    {
	RtInt count = 0;
	RtToken* token = 0;
	RtPointer* params = 0;

	if (items == 2) { RiArchiveRecord(type, format, RI_NULL); return; }
	if (!type || !type[0] || items != 3) {
	    croak("Usage: RenderMan::ArchiveRecord(type, format, {params})");
	    return;
	}

	# Optional Parameters...
	count = build_token_params(ST(2), &token, &params, "ArchiveRecord", "3 (params)");

	if (count) {
/*	    warn("RiArchiveRecordV not implemented in BMRT 2.3.4"); */
            RiArchiveRecordV(type, format, count, token, params);
	} else {
	    RiArchiveRecord(type, format, RI_NULL);
	}
	free_token_params(count, token, params);
    }

# New functions not listed in the RenderMan Interface Specification,
# but found at www.pixar.com in their PhotoRealistic RenderMan online
# User's Manual...

# RC p.??? - DONE
void
RiReadArchive(filename, ...)
    char* filename
    CODE:
    {
	RtInt count = 0;
	RtToken* token = 0;
	RtPointer* params = 0;

	if (items == 1) { RiReadArchive(filename, RI_NULL, RI_NULL); return; }
	if (items != 2) {
	    croak("Usage: RenderMan::ReadArchive(filename, {params})");
	    return;
	}

	# Optional Parameters...
	count = build_token_params(ST(1), &token, &params, "ReadArchive", "2 (params)");

	if (count) {
	    warn("RiReadArchiveV not implemented in BMRT 2.3.6b");
/*          RiReadArchiveV(filename, RI_NULL, count, token, params); */
	} else {
	    RiReadArchive(filename, RI_NULL, RI_NULL);
	}
	free_token_params(count, token, params);
    }

######################################################################
######################################################################
######################################################################
