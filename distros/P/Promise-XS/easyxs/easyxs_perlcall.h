#ifndef EASYXS_PERLCALL_H
#define EASYXS_PERLCALL_H 1

#include "init.h"

static inline void _EASYXS_SET_ARGS (pTHX_ SV* object, SV** args) {
    dSP;

    unsigned argscount = 0;

    if (args) {
        while (args[argscount] != NULL) argscount++;
    }

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);

    if (object || argscount) {
        EXTEND(SP, (object ? 1 : 0) + argscount);

        if (object) PUSHs( sv_mortalcopy(object) );

        unsigned a=0;
        while (a < argscount) mPUSHs( args[a++] );

        PUTBACK;
    }
}

#define exs_call_sv_void(sv, args) STMT_START { \
    _EASYXS_SET_ARGS(aTHX_ NULL, args);         \
    call_sv(sv, G_DISCARD | G_VOID);            \
    FREETMPS;                                   \
    LEAVE;                                      \
} STMT_END

#define exs_call_method_void(object, methname, args) STMT_START { \
    _EASYXS_SET_ARGS(aTHX_ object, args);                 \
                                                    \
    call_method( methname, G_DISCARD | G_VOID );    \
                                                    \
    FREETMPS;                                       \
    LEAVE;                                          \
} STMT_END

static inline SV* _easyxs_fetch_scalar_return (pTHX_ int count) {
    dSP;

    SPAGAIN;

    SV* ret;

    if (count == 0) {
        ret = &PL_sv_undef;
    }
    else {
        ret = SvREFCNT_inc(POPs);

        while (count-- > 1) PERL_UNUSED_VAR(POPs);
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    return ret;
}

static inline SV** _easyxs_fetch_list_return (pTHX_ int count) {
    dSP;

    SPAGAIN;

    SV** ret;

    Newx(ret, 1 + count, SV*);
    ret[count] = NULL;

    while (count-- > 0) {
        ret[count] = SvREFCNT_inc(POPs);
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    SAVEFREEPV(ret);

    return ret;
}

static inline SV* _easyxs_call_method_scalar (pTHX_ SV* object, const char* methname, SV** args) {
    _EASYXS_SET_ARGS(aTHX_ object, args);

    int count = call_method(methname, G_SCALAR);

    return _easyxs_fetch_scalar_return(aTHX_ count);
}

#define exs_call_method_scalar(object, methname, args) \
    _easyxs_call_method_scalar(aTHX_ object, methname, args)

static inline SV* _easyxs_call_sv_scalar (pTHX_ SV* cb, SV** args) {
    _EASYXS_SET_ARGS(aTHX_ NULL, args);

    int count = call_sv(cb, G_SCALAR);

    return _easyxs_fetch_scalar_return(aTHX_ count);
}

#define exs_call_sv_scalar(sv, args) \
    _easyxs_call_sv_scalar(aTHX_ sv, args)

static inline SV** _easyxs_call_sv_list (pTHX_ SV* cb, SV** args) {
    _EASYXS_SET_ARGS(aTHX_ NULL, args);

    int count = call_sv(cb, G_ARRAY);

    return _easyxs_fetch_list_return(aTHX_ count);
}

#define exs_call_sv_list(sv, args) \
    _easyxs_call_sv_list(aTHX_ sv, args)

#define _handle_trapped_error(count, err_p) STMT_START { \
    dSP;                                        \
    SV* err_tmp = ERRSV;                        \
    if (SvTRUE(err_tmp)) {                      \
        while (count--) PERL_UNUSED_VAR(POPs);  \
                                                \
        *err_p = newSVsv(err_tmp);              \
                                                \
        PUTBACK;                                \
        FREETMPS;                               \
        LEAVE;                                  \
    }                                           \
} STMT_END

static inline void _easyxs_call_sv_void_trapped (pTHX_ SV* cb, SV** args, SV** error) {
    _EASYXS_SET_ARGS(aTHX_ NULL, args);

    int count = call_sv(cb, G_VOID | G_EVAL);

    _handle_trapped_error(count, error);
}

#define exs_call_sv_void_trapped(sv, args, err_p) \
    _easyxs_call_sv_void_trapped(aTHX_ sv, args, err_p)

static inline SV* _easyxs_call_sv_scalar_trapped (pTHX_ SV* cb, SV** args, SV** error) {
    _EASYXS_SET_ARGS(aTHX_ NULL, args);

    int count = call_sv(cb, G_SCALAR | G_EVAL);

    _handle_trapped_error(count, error);

    if (SvTRUE(ERRSV)) return NULL;

    return _easyxs_fetch_scalar_return(aTHX_ count);
}

#define exs_call_sv_scalar_trapped(sv, args, err_p) \
    _easyxs_call_sv_scalar_trapped(aTHX_ sv, args, err_p)

static inline SV** _easyxs_call_sv_list_trapped (pTHX_ SV* cb, SV** args, SV** error) {
    _EASYXS_SET_ARGS(aTHX_ NULL, args);

    int count = call_sv(cb, G_ARRAY | G_EVAL);

    _handle_trapped_error(count, error);

    if (SvTRUE(ERRSV)) return NULL;

    return _easyxs_fetch_list_return(aTHX_ count);
}

#define exs_call_sv_list_trapped(sv, args, err_p) \
    _easyxs_call_sv_list_trapped(aTHX_ sv, args, err_p)

#endif
