#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "driver_h.h"

void
croak_on_invalid_entry(void)
{
  croak("An invalid entry in dispatch table reached; a naked INTERFACE XSUB exposed?");
}

#ifdef MY_HAS_QUAD
Quad_t
my_llabs (Quad_t _n) {
  return (_n < 0 ? -_n : _n);
}
#endif

#ifdef MY_NEED_UQUAD_TO_DOUBLE
double uquad2double(Uquad_t u) {
  Uquad_t U1 = u >> 32, U2 = u & 0xFFFFFFFF;
  unsigned int u1 = (unsigned int)U1, u2 = (unsigned int)U2;

  return ((double)u1)*(((double)0x10000)*((double)0x10000)) + (double)u2;
}
#endif

carray_form
sv_2_carray_form(int dim, SV *sv)
{
    if (!dim)
	return NULL;
    if (SvPOK(sv)) {
	if (SvCUR(sv) < dim * sizeof(array_form1))
	    croak("String given as carray_form is too short: expect len=%d, got %d",
		  dim * sizeof(array_form1), SvCUR(sv));
	return (carray_form)SvPV_nolen(sv);
    }
    if (SvROK(sv)) {
	int d;
	array_form format;
	SV **svp;
	AV *av = (AV*)SvRV(sv);

	if (SvTYPE(av) != SVt_PVAV)
	    croak("Reference given as carray_form is not an ARRAY reference");
	d = av_len(av);			/* Last index */
	if (d < 2*dim - 1)
	    croak("Array given as carray_form is too short: expect len=%d, got %d",
		  2*dim, d);
	New(917, format, dim, array_form1);
	save_freepv((char*)format);	/* Why undocumented?  Savefree() later */
	svp = AvARRAY(av);

	for (d = 0; d < dim; d++) {
	    format[d].stride = SvIV(svp[2*d]);
	    format[d].count = SvIV(svp[2*d + 1]);
	}
	return (carray_form)format;
    }
    croak("format argument must be an array reference or a string");
    return 0;
}

array_ind
mInd2ind(int dim, const array_ind *ind, carray_form format)
{
  array_ind ret = 0;

  while (--dim >= 0) {
    ret += format[dim].stride * ind[dim];
  }
  return ret;
}

int			/* lim is in bytes, start_i in len bytes */
checkfit(IV lim, int len, int dim, const IV start_i, carray_form format_for_strides, carray_form format_for_sizes)
{
  IV min = start_i, max = start_i, diff, omax, omin;
  int m = 0;

  while (m < dim) {			/* XXXX We do not check overflow... */
    if (format_for_sizes[m].count == 0)
      return 1;
    else if (format_for_sizes[m].count == 1)
      goto do_incr;
    else if (format_for_sizes[m].count < 0)
      return 0;
    diff = (format_for_sizes[m].count - 1) * format_for_strides[m].stride;
    if (diff <= 0 && format_for_strides[m].stride > 0
	|| diff >= 0 && format_for_strides[m].stride < 0)	/* Overflow */
      return 0;
    if (format_for_strides[m].stride > 0) {		/* diff > 0 */
      omax = max;
      max += diff;	/* We assume count[m] >= 1 */
      if (max < omax)	/* Overflow */
	return 0;
    } else if (min >= -diff) {		/* diff <= 0 here */
      omin = min;
      min += diff;
      if (min > omin)	/* Overflow */
	return 0;
    } else
      return 0;
   do_incr:
    m++;
  }
  if (max * (double)len < lim)
    return 1;
  return 0;
}

int
checkfit_v(IV lim, int len, int dim, const array_ind *start, carray_form format)
{
  IV start_i = mInd2ind(dim, start, format);

  return checkfit(lim, len, dim, start_i, format, format);
}

double
d_extract_1(char *s, int off)
{
    double *arr = (double *)s;
    return arr[off];
}

SV *
d_extract_as_ref(char *s, int start, int count, int stride)
{
    double *arr = (double *)s;
    AV *av = newAV();
    SV **sv_arr;

    av_fill(av, count-1);
    sv_arr = AvARRAY(av);

    arr += start;

    while (count--) {
	*sv_arr++ = newSVnv(*arr);
	arr += stride;
    }
    return newRV_noinc((SV*)av);
}

/* Can't make const without pointers, are defined in other compilation unit */
typedef struct { const func_descr * const * f; const int *cnt; } func_descr_str;
typedef struct { const f_ass_descr * const * f; const int *cnt; } f_ass_descr_str;
typedef struct { const f_0arg_descr * const * f; const int *cnt; } f_0arg_descr_str;
typedef struct { const f_1arg_descr * const * f; const int *cnt; } f_1arg_descr_str;
typedef struct { const f_2arg_descr * const * f; const int *cnt; } f_2arg_descr_str;

const f_ass_descr_str  f_ass_names_arr[]  = {{&f_ass_names_p,  &f_ass_names_c}};
const f_0arg_descr_str f_0arg_names_arr[] = {{&f_0arg_names_p, &f_0arg_names_c}};
const f_1arg_descr_str f_1arg_names_arr[] = {
  {&f_1arg_names_p, &f_1arg_names_c},
  {&f_1argA_names_p, &f_1argA_names_c},
  {&f_1argB_names_p, &f_1argB_names_c},
  {&f_1argC_names_p, &f_1argC_names_c}};
    /* One cast below saves as a lot of duplication of Perl-->C interfaces */
const f_2arg_descr_str f_2arg_names_arr[] = {
  {&f_2arg_names_p, &f_2arg_names_c},
  {&f_2argA_names_p, &f_2argA_names_c},
  {&f_2argB_names_p, &f_2argB_names_c},
  {&f_2argC_names_p, &f_2argC_names_c},
  {&f_2argD_names_p, &f_2argD_names_c},
  {&f_2argE_names_p, &f_2argE_names_c},
  {&f_2argF_names_p, &f_2argF_names_c},
  {(const f_2arg_descr * const *)&f_1arg_2targs_names_p, &f_1arg_2targs_names_c},
};

const func_descr_str *names_arr[] =
 {(const func_descr_str *)f_2arg_names_arr,	/* inverted 2-arg */
  (const func_descr_str *)f_ass_names_arr,	/* accessors */
  (const func_descr_str *)f_0arg_names_arr,
  (const func_descr_str *)f_1arg_names_arr,
  (const func_descr_str *)f_2arg_names_arr};

		    /* n = 2  a  0  1  2  (n-args flavors of func) */
const int names_arr_c[] = {8, 1, 1, 4, 8};	/* How many parts of array */

#define NAMES_IND_SHIFT	3	/* 2^int >= max(names_arr_c) */
#define NAMES_IND_MASK	((1<<NAMES_IND_SHIFT)-1)

#define Fa_get(ix)	(*(f_ass_names_arr [(ix) & NAMES_IND_MASK].f)  + ((ix)>>NAMES_IND_SHIFT))
#define F0_get(ix)	(*(f_0arg_names_arr[(ix) & NAMES_IND_MASK].f) + ((ix)>>NAMES_IND_SHIFT))
#define F1_get(ix)	(*(f_1arg_names_arr[(ix) & NAMES_IND_MASK].f) + ((ix)>>NAMES_IND_SHIFT))
#define F2_get(ix)	(*(f_2arg_names_arr[(ix) & NAMES_IND_MASK].f) + ((ix)>>NAMES_IND_SHIFT))

static int
find_in_ftable(char *s, const func_descr *table, int tcount)
{
  int n;

  for (n = 1; n < tcount; n++) {
    if (0 == strcmp(table[n].codes_name, s))
      return n;
  }
  return 0;
}

static int
find_in_ftable_arr(char *s, const func_descr_str *tables, int tcount)
{
  int n, res;

  for (n = 0; n < tcount; n++) {
    res = find_in_ftable(s, *(tables[n].f), *(tables[n].cnt));
    if (res)
      return n + (res<<NAMES_IND_SHIFT);
  }
  return 0;
}

static int
find_in_ftables(char *s, int arity)
{
  switch (arity) {/* Arity, Accessor=-1, inv-2arg=-2 */
    case -2: case -1:  case 0: case 1: case 2:
	return find_in_ftable_arr(s, names_arr[arity+2],  names_arr_c[arity+2]);
    default:
	croak("Unknown table arity for find: %d; expect -1,0,1,2,-2", arity);
  }
  return 0;
}

XS(XS_Numeric__LL_Array___a_accessor__INTERFACE); /* prototype to pass -Wmissing-prototypes */
XS(XS_Numeric__LL_Array__0arg__INTERFACE); /* prototype to pass -Wmissing-prototypes */
XS(XS_Numeric__LL_Array__1arg__INTERFACE); /* prototype to pass -Wmissing-prototypes */
XS(XS_Numeric__LL_Array__2arg__INTERFACE); /* prototype to pass -Wmissing-prototypes */
XS(XS_Numeric__LL_Array__2arg__INTERFACE_inverted); /* prototype to pass -Wmissing-prototypes */

static void
init_interface(char *perl_name, int arity, char *code, char *perl_file)
{
  CV *mycv;
  int n = find_in_ftables(code, arity);

  if (!n)
    croak("C function with load code `%s', arity=%d not found", code, arity);
  switch (arity) {
    case -1:	/* Accessor */
	mycv = newXS(perl_name, XS_Numeric__LL_Array___a_accessor__INTERFACE, perl_file);
	break;
    case 0:
	mycv = newXS(perl_name, XS_Numeric__LL_Array__0arg__INTERFACE, perl_file);
	break;
    case 1:
	mycv = newXS(perl_name, XS_Numeric__LL_Array__1arg__INTERFACE, perl_file);
	break;
    case 2:
	mycv = newXS(perl_name, XS_Numeric__LL_Array__2arg__INTERFACE, perl_file);
	break;
    case -2:
	mycv = newXS(perl_name, XS_Numeric__LL_Array__2arg__INTERFACE_inverted, perl_file);
	break;
    default:
	croak("Unknown table arity for create: %d; expect -1,0,1,2,-2", arity);
  }
  CvXSUBANY(mycv).any_i32 = n;
}

#define typeNames()		name_by_t
#define typeSizes()		((char*)size_by_t)	/* unsigned char* */
#define duplicateTypes()	duplicate_types_s
#define ptrdiff_t_size()	sizeof(ptrdiff_t)

#define elementary_D_missing()	(!has_sinl)

MODULE = Numeric::LL_Array		PACKAGE = Numeric::LL_Array

double
d_extract_1(s, off)
    char *s
    int off

void
d_extract(s, start, count, stride = 1)
    char *s
    int start
    int count
    int stride
  PPCODE:
  {
    double *arr = (double *)s;

    EXTEND(SP, count);
    arr += start;

    while (count--) {
	PUSHs(sv_2mortal(newSVnv(*arr)));
	arr += stride;
    }
  }

SV *
d_extract_as_ref(s, start, count, stride = 1)
    char *s
    int start
    int count
    int stride

int
find_in_ftables(s, arity)
    char *s
    int arity

void
init_interface(perl_name, arity, code, perl_file)
    char *perl_name
    int arity
    char *code
    char *perl_file

void
__a_accessor__INTERFACE(p, offset = 0, dim = 0, format = Nullsv, sv = Nullsv, keep = FALSE)
	SV *p
	I32 offset
	int dim
	SV* format
	SV *sv
	bool keep
    PPCODE:
   {
       AV *av;
       const char *p_s;
       STRLEN sz;
       dXSI32;		/* ix */
       const f_ass_descr *desc = Fa_get(ix);
       int sizeof_elt = desc->codes_name[0];

       if (!sv || !SvOK(sv))
	   av = 0;
       else if (!SvROK(sv) && SvTRUE(sv)) {
	   if (dim) {
	       av = newAV();
	       PUSHs(sv_2mortal(newRV_noinc((SV*)av)));
	   } else
	       av = 0;
       } else if (SvROK(sv) && SvTYPE(SvRV(sv))==SVt_PVAV) {
	   av = (AV*)SvRV(sv);
	   if (!keep)
	       av_clear(av);
	   PUSHs(sv);
       } else
	   croak("av is not an array reference");
       if (dim && !format)
	   croak("format should be present if dim > 0");
       p_s = SvPV(p, sz);
       PUTBACK;
       {
         carray_form f = sv_2_carray_form(dim, format);

         if (!checkfit(sz, sizeof_elt, dim, offset, f, f))
             croak("Array of negative size, or not fitting into a playground: "
		   "sz=%ld, sizeof(elt)=%ld, arity=%ld, offset=%ld",
		   (long)sz, (long)sizeof_elt, (long)dim, (long)offset);
         (desc->fp)(aTHX_ av, p_s + sizeof_elt*offset, dim, f);
       }
       SPAGAIN;    
   }

void
_0arg__INTERFACE(p, offset = 0, dim = 0, format = Nullsv)
	SV *p
	I32 offset
	int dim
	SV* format
    PPCODE:
   {
       char *p_s;
       STRLEN sz;
       dXSI32;		/* ix */
       const f_0arg_descr *desc = F0_get(ix);
       int sizeof_elt = desc->codes_name[0];

       if (dim && !format)
	   croak("format should be present if dim > 0");
       p_s = SvPV(p, sz);
       {
         carray_form f = sv_2_carray_form(dim, format);

         if (!checkfit(sz, sizeof_elt, dim, offset, f, f))
             croak("Array of negative size, or not fitting into a playground");
         (desc->fp)(p_s + sizeof_elt*offset, dim, f);
       }
       XSRETURN_YES;
   }

void
_1arg__INTERFACE(s_p, p, s_offset, offset, dim, sformat, format)
	SV *s_p
	SV *p
	I32 s_offset
	I32 offset
	int dim
	SV* sformat
	SV* format
    PPCODE:
   {
       char *p_s;
       const char *sp_s;
       STRLEN sz, ssz;
       dXSI32;		/* ix */
       const f_1arg_descr *desc = F1_get(ix);
       int sizeof_elt   = desc->codes_name[0];
       int s_sizeof_elt = desc->codes_name[1];

       if (dim && !(format && sformat))
	   croak("format should be present if dim > 0");
       p_s = SvPV(p, sz);
       sp_s = SvPV(s_p, ssz);
       {
         carray_form f = sv_2_carray_form(dim, format);
         carray_form s_f = sv_2_carray_form(dim, sformat);

         if (!checkfit(sz, sizeof_elt, dim, offset, f, f))
             croak("Target array of negative size, or not fitting into a playground");
         if (!checkfit(ssz, s_sizeof_elt, dim, s_offset, s_f, f))
             croak("Source array not fitting into a playground");
         (desc->fp)(sp_s + s_sizeof_elt * s_offset, p_s + sizeof_elt*offset, dim, s_f, f);
       }
       XSRETURN_YES;
   }

void
_2arg__INTERFACE(s1_p, s2_p, p, s1_offset, s2_offset, offset, dim, s1format, s2format, format)
	SV *s1_p
	SV *s2_p
	SV *p
	I32 s1_offset
	I32 s2_offset
	I32 offset
	int dim
	SV* s1format
	SV* s2format
	SV* format
    PPCODE:
   {			/* Not implemented yet */
       char *p_s;
       const char *s1p_s, *s2p_s;
       STRLEN sz, s1sz, s2sz;
       dXSI32;		/* ix */
       const f_2arg_descr *desc = F2_get(ix);
       int sizeof_elt    = desc->codes_name[0];
       int s1_sizeof_elt = desc->codes_name[1];
       int s2_sizeof_elt = desc->codes_name[2];

       if (dim && !(format && s1format && s2format))
	   croak("format should be present if dim > 0");
       p_s = SvPV(p, sz);
       s1p_s = SvPV(s1_p, s1sz);
       s2p_s = SvPV(s2_p, s2sz);
       {
         carray_form f = sv_2_carray_form(dim, format);
         carray_form s1_f = sv_2_carray_form(dim, s1format);
         carray_form s2_f = sv_2_carray_form(dim, s2format);

         if (!checkfit(sz, sizeof_elt, dim, offset, f, f))
             croak("Target array of negative size, or not fitting into a playground");
         if (!checkfit(s1sz, s1_sizeof_elt, dim, s1_offset, s1_f, f))
             croak("Source1 array not fitting into a playground");
         if (!checkfit(s2sz, s2_sizeof_elt, dim, s2_offset, s2_f, f))
             croak("Source2 array not fitting into a playground");
         (desc->fp)(s1p_s + s1_sizeof_elt * s1_offset,
				 s2p_s + s2_sizeof_elt * s2_offset,
				 p_s + sizeof_elt*offset, dim, s1_f, s2_f, f);
       }
       XSRETURN_YES;
   }

void
_2arg__INTERFACE_inverted(s2_p, s1_p, p, s2_offset, s1_offset, offset, dim, s2format, s1format, format)
	SV *s2_p
	SV *s1_p
	SV *p
	I32 s2_offset
	I32 s1_offset
	I32 offset
	int dim
	SV* s2format
	SV* s1format
	SV* format
    PPCODE:
   {			/* Not implemented yet */
       char *p_s;
       const char *s1p_s, *s2p_s;
       STRLEN sz, s1sz, s2sz;
       dXSI32;		/* ix */
       const f_2arg_descr *desc = F2_get(ix);
       int sizeof_elt    = desc->codes_name[0];
       int s1_sizeof_elt = desc->codes_name[1];
       int s2_sizeof_elt = desc->codes_name[2];

       if (dim && !(format && s1format && s2format))
	   croak("format should be present if dim > 0");
       p_s = SvPV(p, sz);
       s1p_s = SvPV(s1_p, s1sz);
       s2p_s = SvPV(s2_p, s2sz);
       {
         carray_form f = sv_2_carray_form(dim, format);
         carray_form s1_f = sv_2_carray_form(dim, s1format);
         carray_form s2_f = sv_2_carray_form(dim, s2format);

         if (!checkfit(sz, sizeof_elt, dim, offset, f, f))
             croak("Target array of negative size, or not fitting into a playground");
         if (!checkfit(s1sz, s1_sizeof_elt, dim, s1_offset, s1_f, f))
             croak("Source1 array not fitting into a playground");
         if (!checkfit(s2sz, s2_sizeof_elt, dim, s2_offset, s2_f, f))
             croak("Source2 array not fitting into a playground");
         (desc->fp)(s1p_s + s1_sizeof_elt * s1_offset,
				 s2p_s + s2_sizeof_elt * s2_offset,
				 p_s + sizeof_elt*offset, dim, s1_f, s2_f, f);
       }
       XSRETURN_YES;
   }

const char*
typeNames()

const char*
typeSizes()

const char*
duplicateTypes()

int
ptrdiff_t_size()

int
elementary_D_missing()

int
have_uquad2double()
