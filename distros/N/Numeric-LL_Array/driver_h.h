/* array_ind may be negative as a result of multi-dim_2_1-dim conversion. */
/* array_count is non-negative; but keep in diffptr_t just in case. */
typedef ptrdiff_t array_stride, array_ind, array_count;	/* lim is number of items */
typedef struct { array_stride stride; array_count count; } array_form1, *array_form;
typedef const array_form1 *carray_form;

#ifndef pTHX_		/* pport.h can't be included in multiple files */
#  define pTHX_
#  define aTHX_
#endif
#ifndef UVSIZE
#   define newSVuv newSViv
#endif

typedef void (*f_0arg_p)(char *to_s, int dim, carray_form to_form);
typedef void (*f_1arg_p)(const char *from_s, char *to_s, int dim, carray_form from_form, carray_form to_form);
typedef void (*f_2arg_p)(const char *from1_s, const char *from2_s, char *to_s,
 int dim, carray_form from1_form, carray_form from2_form, carray_form to_form);
typedef void (*f_1arg_2targs_p)(const char *from1_s, char *to2_s, char *to_s,
 int dim, carray_form from1_form, carray_form from2_form, carray_form to_form);
typedef void (*f_ass_p)(pTHX_ AV *av, const char *p_s, int dim, carray_form format);

typedef struct {const char* const codes_name; void *const fp; } func_descr;
typedef struct {const char* const codes_name; f_0arg_p const fp; } f_0arg_descr;
typedef struct {const char* const codes_name; f_1arg_p const fp; } f_1arg_descr;
typedef struct {const char* const codes_name; f_1arg_2targs_p const fp; } f_1arg_2targs_descr;
typedef struct {const char* const codes_name; f_2arg_p const fp; } f_2arg_descr;
typedef struct {const char* const codes_name; f_ass_p  const fp; } f_ass_descr;
extern const f_0arg_descr * const f_0arg_names_p;
extern const int f_0arg_names_c;
extern const f_1arg_descr * const f_1arg_names_p;
extern const int f_1arg_names_c;
extern const f_1arg_descr * const f_1argA_names_p;
extern const int f_1argA_names_c;
extern const f_1arg_descr * const f_1argB_names_p;
extern const int f_1argB_names_c;
extern const f_1arg_descr * const f_1argC_names_p;
extern const int f_1argC_names_c;
extern const f_1arg_2targs_descr * const f_1arg_2targs_names_p;
extern const int f_1arg_2targs_names_c;
extern const f_2arg_descr * const f_2arg_names_p;
extern const int f_2arg_names_c;
extern const f_2arg_descr * const f_2argA_names_p;
extern const int f_2argA_names_c;
extern const f_2arg_descr * const f_2argB_names_p;
extern const int f_2argB_names_c;
extern const f_2arg_descr * const f_2argC_names_p;
extern const int f_2argC_names_c;
extern const f_2arg_descr * const f_2argD_names_p;
extern const int f_2argD_names_c;
extern const f_2arg_descr * const f_2argE_names_p;
extern const int f_2argE_names_c;
extern const f_2arg_descr * const f_2argF_names_p;
extern const int f_2argF_names_c;
extern const f_ass_descr * const f_ass_names_p;
extern const int f_ass_names_c;

extern const int has_sinl;

extern const char name_by_t[];
extern const unsigned char size_by_t[];
extern const char duplicate_types_s[];

extern void croak_on_invalid_entry(void);

#ifdef MY_HAS_QUAD
extern Quad_t my_llabs (Quad_t _n);
#endif
#define my_uabs(a)	(a)

#include <signed_cmp_etc.h>
