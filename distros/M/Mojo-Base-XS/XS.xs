#define NEED_sv_2pv_flags_GLOBAL
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "cxsa_memory.h"
#include "CXSAccessor.h"

#include "ppport.h"

#define CXAH(name) XS_Mojo__Base__XS_ ## name

/* From Class-XSAccessor:
 * For versions of ExtUtils::ParseXS > 3.04_02, we need to
 * explicitly enforce exporting of XSUBs since we want to
 * refer to them using XS(). This isn't strictly necessary,
 * but it's by far the simplest way to be backwards-compatible.
 */
#define PERL_EUPXS_ALWAYS_EXPORT

#if (PERL_BCDVERSION >= 0x5010000)
#define CXA_ENABLE_ENTERSUB_OPTIMIZATION
#endif

//#ifdef CXA_ENABLE_ENTERSUB_OPTIMIZATION

#define CXA_OPTIMIZATION_OK(op) ((op->op_spare & 1) != 1)
#define CXA_DISABLE_OPTIMIZATION(op) (op->op_spare |= 1)

#ifdef hv_common_key_len
#define CXSA_HASH_FETCH(hv, key, len, hash)                                  \
    hv_common_key_len((hv), (key), (len), HV_FETCH_JUST_SV, NULL, (hash))
#else
#define CXSA_HASH_FETCH(hv, key, len, hash) hv_fetch((hv), (key), (len), 0)
#endif

#define CXAH_GENERATE_ENTERSUB(name)                                         \
OP * cxah_entersub_ ## name(pTHX) {                                          \
    dVAR; dSP; dTOPss;                                                       \
    if (sv                                                                   \
        && (SvTYPE(sv) == SVt_PVCV)                                          \
        && (CvXSUB((CV *)sv) == CXAH(name ## _init))                         \
    ) {                                                                      \
        (void)POPs;                                                          \
        PUTBACK;                                                             \
        (void)CXAH(name)(aTHX_ (CV *)sv);                                    \
        return NORMAL;                                                       \
    } else { /* not static: disable optimization */                          \
        CXA_DISABLE_OPTIMIZATION(PL_op); /* make sure it's not reinstated */ \
        PL_op->op_ppaddr = CXA_DEFAULT_ENTERSUB;                             \
        return CXA_DEFAULT_ENTERSUB(aTHX);                                   \
    }                                                                        \
}

#define CXAH_OPTIMIZE_ENTERSUB(name)                                         \
STMT_START {                                                                 \
    if (CXA_OPTIMIZATION_OK(PL_op)) {                                        \
        if (PL_op->op_ppaddr == CXA_DEFAULT_ENTERSUB) {                      \
            PL_op->op_ppaddr = cxah_entersub_ ## name;                       \
        } else {                                                             \
            CXA_DISABLE_OPTIMIZATION(PL_op);                                 \
        }                                                                    \
    }                                                                        \
} STMT_END
/*
#else

#define CXAH_GENERATE_ENTERSUB(name)

#endif
*/

#define INSTALL_NEW_CV(name, xsub)                                           \
STMT_START {                                                                 \
  if (newXS(name, xsub, (char*)__FILE__) == NULL)                            \
    croak("ARG! Something went really wrong while installing a new XSUB!");  \
} STMT_END

/* Install a new XSUB under 'name' and set the function index attribute
 * Requires a previous declaration of a CV* cv!
 **/
#define INSTALL_NEW_CV_WITH_INDEX(subname, xsub, function_index)             \
STMT_START {                                                                 \
  cv = newXS(subname, xsub, (const char*)__FILE__);                          \
  if (cv == NULL)                                                            \
    croak("ARG! Something went really wrong while installing a new XSUB!");  \
  XSANY.any_i32 = function_index;                                            \
} STMT_END

/* Install a new XSUB under 'name' and set the function index attribute
 * for hash-based objects. Requires a previous declaration of a CV* cv!
 **/
#define INSTALL_NEW_CV_HASH_OBJ(package, xsub, name, default_value)          \
STMT_START {                                                                 \
  const U32 key_len = strlen(name);                                          \
  if (default_value != NULL && SvROK(default_value) &&                       \
        SvTYPE(SvRV(default_value)) != SVt_PVCV)  {                          \
        croak("Default has to be a code reference or constant value");       \
  }                                                                          \
  if (!isALPHA(name[0]) || !name[0] == '_') {                                \
    croak("Attribute \"%s\" invalid", name);                                 \
  }                                                                          \
  int i;                                                                     \
  for (i = 1; i < key_len; i++)                                              \
    if (!isWORDCHAR(name[i]))                                                \
        croak("Attribute \"%s\" invalid", name);                             \
  autoxs_hashkey hashkey;                                                    \
  const U32 package_len = strlen(package);                                   \
  const U32 subname_len = key_len + package_len + 2;                         \
  hashkey.key = (char*)cxa_malloc((subname_len+1));                          \
  cxa_memcpy(hashkey.key, (void*)package, package_len);                      \
  cxa_memcpy(&hashkey.key[package_len], "::", 2);                            \
  cxa_memcpy(&hashkey.key[package_len+2], name, key_len );                   \
  hashkey.key[subname_len] = 0;                                              \
  hashkey.len = subname_len;                                                 \
  const U32 function_index =                                                 \
    get_hashkey_index(aTHX_ hashkey.key, hashkey.len);                       \
  INSTALL_NEW_CV_WITH_INDEX(hashkey.key, xsub, function_index);              \
  hashkey.default_value = default_value;                                     \
  hashkey.accessor_name = (char*)cxa_malloc((key_len+1));                    \
  hashkey.accessor_len = key_len;                                            \
  cxa_memcpy(hashkey.accessor_name, name, key_len);                          \
  hashkey.accessor_name[key_len] = 0;                                        \
  PERL_HASH(hashkey.hash, hashkey.accessor_name, key_len);                   \
  if (default_value != NULL) {                                               \
      SvREFCNT_inc(default_value);                                           \
      hashkey.default_coderef = SvROK(hashkey.default_value) &&              \
        SvTYPE(SvRV(hashkey.default_value)) == SVt_PVCV;                     \
  } else { hashkey.default_coderef = 0; }                                    \
  CXSAccessor_hashkeys[function_index] = hashkey;                            \
} STMT_END


static Perl_ppaddr_t CXA_DEFAULT_ENTERSUB = NULL;

XS(CXAH(accessor));
XS(CXAH(accessor_init));
CXAH_GENERATE_ENTERSUB(accessor);

XS(CXAH(constructor));
XS(CXAH(constructor_init));
CXAH_GENERATE_ENTERSUB(constructor);

MODULE = Mojo::Base::XS    PACKAGE = Mojo::Base::XS
PROTOTYPES: DISABLE

BOOT:
#ifdef CXA_ENABLE_ENTERSUB_OPTIMIZATION
CXA_DEFAULT_ENTERSUB = PL_ppaddr[OP_ENTERSUB];
#endif

void
__entersub_optimized__()
    PROTOTYPE:
    CODE:
#ifdef CXA_ENABLE_ENTERSUB_OPTIMIZATION
        XSRETURN(1);
#else
        XSRETURN(0);
#endif


#define ACCESSOR_BODY                                                        \
    if (!SvROK(self))                                                        \
        croak(                                                               \
            "Accessor '%s' should be called on an object, "                  \
            "but called on the '%s' clasname",                               \
            readfrom.accessor_name,                                          \
            SvPV_nolen(self)                                                 \
        );                                                                   \
    HV *object = (HV*)SvRV(self);                                            \
    if (items > 1) {                                                         \
      SV* newvalue = newSVsv(ST(1));                                         \
      if (NULL == hv_common_key_len(                                         \
        object, readfrom.accessor_name, readfrom.accessor_len,               \
        HV_FETCH_ISSTORE, newvalue, readfrom.hash))                          \
          croak("Failed to write new value to hash.");                       \
                                                                             \
      PUSHs(self);                                                           \
      XSRETURN(1);                                                           \
    }                                                                        \
                                                                             \
    if ((svp = CXSA_HASH_FETCH(                                              \
            object, readfrom.accessor_name, readfrom.accessor_len,           \
            readfrom.hash)))                                                 \
    {                                                                        \
        PUSHs(*svp);                                                         \
        XSRETURN(1);                                                         \
    }                                                                        \
                                                                             \
    if (readfrom.default_value != NULL)                                      \
    {                                                                        \
        SV **retval;                                                         \
        if (readfrom.default_coderef) {                                      \
            /* Coderef to generate defautl value */                          \
          {                                                                  \
            ENTER;                                                           \
            SAVETMPS;                                                        \
            PUSHMARK(SP);                                                    \
            XPUSHs(self);                                                    \
            PUTBACK;                                                         \
            int number =                                                     \
                call_sv(SvRV(readfrom.default_value),                        \
                  G_SCALAR|G_EVAL|G_KEEPERR);                                \
            SPAGAIN;                                                         \
            if (number == 1) {                                               \
                retval = &POPs;                                              \
            } else {                                                         \
                XSRETURN_UNDEF;                                              \
            }                                                                \
            retval = hv_store(                                               \
                    object, readfrom.accessor_name, readfrom.accessor_len,   \
                    newSVsv(*retval), readfrom.hash);                        \
            if (!retval) {                                                   \
                warn("hv_store failed\n\n\n\n");                             \
                XSRETURN_UNDEF;                                              \
            }                                                                \
            PUTBACK;                                                         \
            FREETMPS;                                                        \
            LEAVE;                                                           \
          }                                                                  \
        } else {                                                             \
            retval = hv_store(                                               \
                object, readfrom.accessor_name, readfrom.accessor_len,       \
                newSVsv(readfrom.default_value), readfrom.hash);             \
        }                                                                    \
        PUSHs(*retval);                                                      \
        XSRETURN(1);                                                         \
    }                                                                        \
    XSRETURN_UNDEF;                                                          \

void
accessor_init(self, ...)
    SV *self;
ALIAS:
INIT:
    /* Get the const hash key struct from the global storage */
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    const autoxs_hashkey readfrom = CXSAccessor_hashkeys[ix];
    SV** svp;
PPCODE:
    CXAH_OPTIMIZE_ENTERSUB(accessor);
    ACCESSOR_BODY

void
accessor(self, ...)
    SV* self;
ALIAS:
INIT:
    /* Get the const hash key struct from the global storage */
    /* ix is the magic integer variable that is set by the perl guts for us.
    * We uses it to identify the currently running alias of the accessor. Gollum! */
    const autoxs_hashkey readfrom = CXSAccessor_hashkeys[ix];
    SV** svp;
PPCODE:
    ACCESSOR_BODY


void
attr(caller_obj, name, ...)
    SV *caller_obj;
    SV *name;
PREINIT:
    char *cstname = SvPV_nolen(PL_curstname);
    SV *default_value = items > 2 ? ST(2) : NULL;
    const char *caller = SvROK(caller_obj) ?
        sv_reftype(SvRV(caller_obj), TRUE) :
        SvPV_nolen(caller_obj);
CODE:
    if (items > 3) {
        croak("Attribute generator called with too many arguments");
        return;
    }

    if (SvROK(name) && SvTYPE(SvRV(name)) == SVt_PVAV) {
        int i;
        for (i = av_len((AV*)SvRV(name)); i >= 0; i--) {
            CV* cv;
            SV **elem = av_fetch((AV*)SvRV(name), i, 0);
            INSTALL_NEW_CV_HASH_OBJ(
                caller, CXAH(accessor_init),
                SvPV_nolen(*elem), default_value);
        }
    } else {
        CV* cv;
        INSTALL_NEW_CV_HASH_OBJ(
            caller, CXAH(accessor_init), SvPV_nolen(name), default_value);
    }
    PUSHs(caller_obj);

#define CONSTRUCTOR_BODY                                                         \
    classname = SvROK(class)       ?                                             \
        sv_reftype(SvRV(class), 1) :                                             \
        SvPV_nolen_const(class);                                                 \
    hash = newHV();                                                              \
    if (items > 2) {                                                             \
        for (iStack = 1; iStack < items; iStack += 2) {                          \
            /* we could check for the hv_store_ent return value,          */     \
            /* but perl doesn't in this situation (see pp_anonhash)       */     \
            (void)hv_store_ent(                                                  \
                hash, ST(iStack),                                                \
                newSVsv(iStack > items ? &PL_sv_undef : ST(iStack+1)), 0);       \
        }                                                                        \
    } else if (items > 1) {                                                      \
        HV *hv_hashopt;                                                          \
        SV *optref = ST(1);                                                      \
        if (SvROK(optref) &&                                                     \
            SvTYPE((hv_hashopt = (HV*)SvRV(optref))) == SVt_PVHV) {              \
            I32 key_len;                                                         \
            char *key;                                                           \
            SV *val;                                                             \
            hv_iterinit(hv_hashopt);                                             \
            while ((val = hv_iternextsv(hv_hashopt, &key, &key_len))) {          \
                (void)hv_common_key_len(                                         \
                    hash, key, key_len,  HV_FETCH_ISSTORE, newSVsv(val), 0);     \
            }                                                                    \
        } else {                                                                 \
            croak("Not a hash reference");                                       \
        }                                                                        \
    }                                                                            \
    obj = sv_bless(newRV_noinc((SV *)hash), gv_stashpv(classname, 1));           \
    PUSHs(sv_2mortal(obj));                                                      \

void
constructor_init(class, ...)
    SV* class;
  PREINIT:
    int iStack;
    HV* hash;
    SV* obj;
    const char* classname;
  PPCODE:
    CXAH_OPTIMIZE_ENTERSUB(constructor);
    CONSTRUCTOR_BODY


void
constructor(class, ...)
    SV* class;
  PREINIT:
    int iStack;
    HV* hash;
    SV* obj;
    const char* classname;
  PPCODE:
    CONSTRUCTOR_BODY

void
newxs_constructor(name)
  char* name;
  PPCODE:
    INSTALL_NEW_CV(name, CXAH(constructor_init));

void
newxs_attr(name)
  char* name;
  PPCODE:
    INSTALL_NEW_CV(name, CXAH(attr));
