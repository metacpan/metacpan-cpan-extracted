/*
 * pdfmake_custom_ops.h - Custom op infrastructure for PDF::Make XS
 *
 * Provides compile-time call checkers and runtime custom ops to replace
 * standard xsubpp method dispatch for hot paths. Reusable across the
 * Semantic ecosystem via ExtUtils::Depends.
 *
 * Three op patterns:
 *   1. CHAIN  - $obj->method() returns $obj (Canvas, Arena, Writer)
 *   2. GETTER - $obj->field reads C struct field by offset
 *   3. CONST  - Package::CONST() folds to OP_CONST at compile time
 *
 * Requires: xop_compat.h (from Object::Proto) for pre-5.14 fallback
 */

#ifndef PDFMAKE_CUSTOM_OPS_H
#define PDFMAKE_CUSTOM_OPS_H

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "xop_compat.h"

/*============================================================================
 * Pointer unwrap — skips sv_derived_from check (already validated by caller)
 *==========================================================================*/

#define PDFMAKE_UNWRAP(type, sv) \
    INT2PTR(type, SvIV(SvRV(sv)))

/*============================================================================
 * Chain op argument types
 *==========================================================================*/

#define PDFMAKE_ARG_DOUBLE  0
#define PDFMAKE_ARG_STRING  1
#define PDFMAKE_ARG_INT     2

/*============================================================================
 * Chain dispatch table entry
 *
 * Each canvas/arena method maps to an entry with:
 *   - C function pointer
 *   - argument count (0-6 beyond self)
 *   - argument type codes
 *==========================================================================*/

typedef struct {
    void *func;
    int   nargs;
    int   arg_types[6];
    int   ret_mode;     /* 0 = return self (chain), 1 = return int, 2 = void */
} pdfmake_chain_entry_t;

/*============================================================================
 * CHAIN pp function - generic chainable method dispatch
 *
 * Unwraps self, pops args from stack, calls C function via dispatch table,
 * returns self (already on stack). Used for Canvas, Arena, Writer.
 *
 * op_private holds the pointer type (which struct to unwrap to).
 * op_targ holds the dispatch table index.
 * The dispatch table pointer is stored in a package-level static.
 *==========================================================================*/

/* Forward declarations for package-specific dispatch tables */
/* These are defined in the respective XS BOOT sections */

/*
 * pp function for nullary chain ops: $obj->method() returns $obj
 * No args to pop — just unwrap, call, return self.
 * This is the simplest and most common canvas pattern.
 */
typedef int (*pdfmake_nullary_fn)(void *self);
typedef int (*pdfmake_unary_d_fn)(void *self, double a);
typedef int (*pdfmake_binary_dd_fn)(void *self, double a, double b);
typedef int (*pdfmake_ternary_ddd_fn)(void *self, double a, double b, double c);
typedef int (*pdfmake_quad_dddd_fn)(void *self, double a, double b, double c, double d);
typedef int (*pdfmake_hex_dddddd_fn)(void *self, double a, double b, double c, double d, double e, double f);
typedef int (*pdfmake_unary_s_fn)(void *self, const char *s);
typedef int (*pdfmake_sd_fn)(void *self, const char *s, double d);

/* Multiple dispatch tables — indexed by table ID (high bits of op_targ) */
#define PDFMAKE_MAX_CHAIN_TABLES 8
static pdfmake_chain_entry_t *pdfmake_chain_tables[PDFMAKE_MAX_CHAIN_TABLES];
static int pdfmake_chain_table_count = 0;

/* Encode table_id + entry_index into op_targ */
#define PDFMAKE_CHAIN_TARG(table_id, index) (((table_id) << 16) | (index))
#define PDFMAKE_CHAIN_TABLE(targ) ((targ) >> 16)
#define PDFMAKE_CHAIN_INDEX(targ) ((targ) & 0xFFFF)

static OP* pp_pdfmake_chain(pTHX) {
    dSP;
    UV targ = PL_op->op_targ;
    int table_id = PDFMAKE_CHAIN_TABLE(targ);
    int idx = PDFMAKE_CHAIN_INDEX(targ);
    pdfmake_chain_entry_t *e = &pdfmake_chain_tables[table_id][idx];
    int nargs = e->nargs;

    /* Self is below the args on the stack */
    SV *self_sv = *(SP - nargs);
    void *self = PDFMAKE_UNWRAP(void*, self_sv);
    int err = 0;

    switch (nargs) {
    case 0:
        err = ((pdfmake_nullary_fn)e->func)(self);
        break;
    case 1:
        if (e->arg_types[0] == PDFMAKE_ARG_STRING) {
            const char *a = SvPV_nolen(TOPs);
            SP--;
            err = ((pdfmake_unary_s_fn)e->func)(self, a);
        } else {
            double a = SvNV(TOPs);
            SP--;
            err = ((pdfmake_unary_d_fn)e->func)(self, a);
        }
        break;
    case 2:
        if (e->arg_types[0] == PDFMAKE_ARG_STRING) {
            /* string, double — e.g. Tf(font, size) */
            double b = SvNV(TOPs); SP--;
            const char *a = SvPV_nolen(TOPs); SP--;
            err = ((pdfmake_sd_fn)e->func)(self, a, b);
        } else {
            double b = SvNV(TOPs); SP--;
            double a = SvNV(TOPs); SP--;
            err = ((pdfmake_binary_dd_fn)e->func)(self, a, b);
        }
        break;
    case 3: {
        double c = SvNV(TOPs); SP--;
        double b = SvNV(TOPs); SP--;
        double a = SvNV(TOPs); SP--;
        err = ((pdfmake_ternary_ddd_fn)e->func)(self, a, b, c);
        break;
    }
    case 4: {
        double d = SvNV(TOPs); SP--;
        double c = SvNV(TOPs); SP--;
        double b = SvNV(TOPs); SP--;
        double a = SvNV(TOPs); SP--;
        err = ((pdfmake_quad_dddd_fn)e->func)(self, a, b, c, d);
        break;
    }
    case 6: {
        double f = SvNV(TOPs); SP--;
        double e_val = SvNV(TOPs); SP--;
        double d = SvNV(TOPs); SP--;
        double c = SvNV(TOPs); SP--;
        double b = SvNV(TOPs); SP--;
        double a = SvNV(TOPs); SP--;
        err = ((pdfmake_hex_dddddd_fn)e->func)(self, a, b, c, d, e_val, f);
        break;
    }
    }

    switch (e->ret_mode) {
    case 1:
        /* Return int result */
        if (err < 0) croak("PDF::Make custom op failed (index %d)", idx);
        SETs(sv_2mortal(newSViv(err)));
        PUTBACK;
        RETURN;
    case 2:
        /* Void — just pop args, leave nothing */
        SP = SP - nargs;
        PUTBACK;
        RETURN;
    default:
        /* Chain — return self */
        if (err != 0) croak("PDF::Make custom op failed (index %d)", idx);
        PUTBACK;
        RETURN;
    }
}

/*============================================================================
 * Chain call checker
 *
 * At compile time, replaces entersub with our custom op.
 * For nullary ops, creates a UNOP(self).
 * For ops with args, we DON'T rewrite the op tree — instead we just
 * replace the pp_addr of the entersub to avoid complex tree surgery.
 * This is simpler and still eliminates typemap/method-cache overhead.
 *==========================================================================*/

static OP* pdfmake_chain_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    IV idx = SvIV(ckobj);
    PERL_UNUSED_ARG(namegv);

    /* Simple approach: replace entersub's pp_addr directly.
     * The args remain on the stack in standard order.
     * This avoids complex op tree surgery for multi-arg methods. */
    entersubop->op_ppaddr = pp_pdfmake_chain;
    cUNOPx(entersubop)->op_first->op_targ = idx;  /* Store index */

    /* Actually, op_targ on entersub is used for pad allocation.
     * Store in op_private + a side table instead. */

    /* For safety, just use op_targ on the entersubop itself */
    entersubop->op_targ = idx;

    return entersubop;
}

/*============================================================================
 * GETTER ops — read C struct field by offset + type
 *
 * op_targ encodes: (byte_offset << 4) | field_type
 *==========================================================================*/

#define PDFMAKE_FIELD_DOUBLE  0
#define PDFMAKE_FIELD_INT     1
#define PDFMAKE_FIELD_UV      2
#define PDFMAKE_FIELD_STRING  3

#define PDFMAKE_GETTER_TARG(offset, type) (((UV)(offset) << 4) | (type))

static OP* pp_pdfmake_getter(pTHX) {
    dSP;
    SV *obj = TOPs;
    char *ptr = PDFMAKE_UNWRAP(char*, obj);
    UV encoded = PL_op->op_targ;
    int field_type = encoded & 0xF;
    size_t offset = encoded >> 4;

    switch (field_type) {
    case PDFMAKE_FIELD_DOUBLE:
        SETs(sv_2mortal(newSVnv(*(double*)(ptr + offset))));
        break;
    case PDFMAKE_FIELD_INT:
        SETs(sv_2mortal(newSViv(*(int*)(ptr + offset))));
        break;
    case PDFMAKE_FIELD_UV:
        SETs(sv_2mortal(newSVuv(*(UV*)(ptr + offset))));
        break;
    case PDFMAKE_FIELD_STRING: {
        const char *val = *(const char**)(ptr + offset);
        SETs(val ? sv_2mortal(newSVpv(val, 0)) : &PL_sv_undef);
        break;
    }
    }
    RETURN;
}

static OP* pdfmake_getter_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    UV targ = SvUV(ckobj);
    OP *pushop, *selfop, *cvop;
    PERL_UNUSED_ARG(namegv);

    pushop = cUNOPx(entersubop)->op_first;
    if (!OpHAS_SIBLING(pushop))
        pushop = cUNOPx(pushop)->op_first;

    selfop = OpSIBLING(pushop);
    cvop = selfop;
    while (OpHAS_SIBLING(cvop))
        cvop = OpSIBLING(cvop);

    /* Detach self from chain, free the rest */
    OpMORESIB_set(pushop, cvop);
    OpLASTSIB_set(selfop, NULL);

    OP *newop = newUNOP(OP_NULL, 0, selfop);
    newop->op_type = OP_CUSTOM;
    newop->op_ppaddr = pp_pdfmake_getter;
    newop->op_targ = targ;

    op_free(entersubop);
    return newop;
}

/*============================================================================
 * INDIRECT GETTER — read field through one pointer chase
 *
 * For wrapper structs: self->ptr_offset is a pointer, then read field
 * at field_offset from that pointer.
 *
 * op_targ encodes: (ptr_offset << 20) | (field_offset << 4) | field_type
 *==========================================================================*/

#define PDFMAKE_INDIRECT_TARG(ptr_off, field_off, type) \
    (((UV)(ptr_off) << 20) | ((UV)(field_off) << 4) | (type))

static OP* pp_pdfmake_indirect_getter(pTHX) {
    dSP;
    SV *obj = TOPs;
    char *wrapper = PDFMAKE_UNWRAP(char*, obj);
    UV encoded = PL_op->op_targ;
    int field_type = encoded & 0xF;
    size_t field_off = (encoded >> 4) & 0xFFFF;
    size_t ptr_off = encoded >> 20;

    /* Follow the pointer: wrapper + ptr_off is a pointer to the inner struct */
    char *inner = *(char**)(wrapper + ptr_off);
    if (!inner) {
        SETs(&PL_sv_undef);
        RETURN;
    }

    switch (field_type) {
    case PDFMAKE_FIELD_DOUBLE:
        SETs(sv_2mortal(newSVnv(*(double*)(inner + field_off))));
        break;
    case PDFMAKE_FIELD_INT:
        SETs(sv_2mortal(newSViv(*(int*)(inner + field_off))));
        break;
    case PDFMAKE_FIELD_UV:
        SETs(sv_2mortal(newSVuv(*(UV*)(inner + field_off))));
        break;
    case PDFMAKE_FIELD_STRING: {
        const char *val = *(const char**)(inner + field_off);
        SETs(val ? sv_2mortal(newSVpv(val, 0)) : &PL_sv_undef);
        break;
    }
    }
    RETURN;
}

static OP* pdfmake_indirect_getter_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    UV targ = SvUV(ckobj);
    OP *pushop, *selfop, *cvop;
    PERL_UNUSED_ARG(namegv);

    pushop = cUNOPx(entersubop)->op_first;
    if (!OpHAS_SIBLING(pushop))
        pushop = cUNOPx(pushop)->op_first;
    selfop = OpSIBLING(pushop);
    cvop = selfop;
    while (OpHAS_SIBLING(cvop))
        cvop = OpSIBLING(cvop);

    OpMORESIB_set(pushop, cvop);
    OpLASTSIB_set(selfop, NULL);

    OP *newop = newUNOP(OP_NULL, 0, selfop);
    newop->op_type = OP_CUSTOM;
    newop->op_ppaddr = pp_pdfmake_indirect_getter;
    newop->op_targ = targ;

    op_free(entersubop);
    return newop;
}

#define PDFMAKE_REGISTER_INDIRECT_GETTER(stash, method, wrap_type, ptr_field, inner_type, field, ftype) \
    do { \
        GV *_gv = gv_fetchmeth_pvn(stash, method, strlen(method), 0, 0); \
        if (_gv && GvCV(_gv)) { \
            SV *_ck = newSVuv(PDFMAKE_INDIRECT_TARG( \
                offsetof(wrap_type, ptr_field), \
                offsetof(inner_type, field), ftype)); \
            cv_set_call_checker(GvCV(_gv), pdfmake_indirect_getter_call_checker, _ck); \
        } \
    } while(0)

/*============================================================================
 * TYPE-TEST ops — compare struct field to constant, return bool
 *
 * op_targ encodes: (ptr_offset << 20) | (field_offset << 8) | expected_value
 * Used for: is_null, is_int, is_array, etc. on Obj wrapper
 *==========================================================================*/

#define PDFMAKE_TYPETEST_TARG(ptr_off, field_off, expected) \
    (((UV)(ptr_off) << 20) | ((UV)(field_off) << 8) | ((expected) & 0xFF))

static OP* pp_pdfmake_typetest(pTHX) {
    dSP;
    SV *obj = TOPs;
    char *wrapper = PDFMAKE_UNWRAP(char*, obj);
    UV encoded = PL_op->op_targ;
    int expected = encoded & 0xFF;
    size_t field_off = (encoded >> 8) & 0xFFF;
    size_t ptr_off = encoded >> 20;

    char *inner = *(char**)(wrapper + ptr_off);
    int actual = inner ? *(int*)(inner + field_off) : -1;

    SETs(boolSV(actual == expected));
    RETURN;
}

static OP* pdfmake_typetest_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    UV targ = SvUV(ckobj);
    OP *pushop, *selfop, *cvop;
    PERL_UNUSED_ARG(namegv);

    pushop = cUNOPx(entersubop)->op_first;
    if (!OpHAS_SIBLING(pushop))
        pushop = cUNOPx(pushop)->op_first;
    selfop = OpSIBLING(pushop);
    cvop = selfop;
    while (OpHAS_SIBLING(cvop))
        cvop = OpSIBLING(cvop);

    OpMORESIB_set(pushop, cvop);
    OpLASTSIB_set(selfop, NULL);

    OP *newop = newUNOP(OP_NULL, 0, selfop);
    newop->op_type = OP_CUSTOM;
    newop->op_ppaddr = pp_pdfmake_typetest;
    newop->op_targ = targ;

    op_free(entersubop);
    return newop;
}

#define PDFMAKE_REGISTER_TYPETEST(stash, method, wrap_type, ptr_field, inner_type, field, expected_val) \
    do { \
        GV *_gv = gv_fetchmeth_pvn(stash, method, strlen(method), 0, 0); \
        if (_gv && GvCV(_gv)) { \
            SV *_ck = newSVuv(PDFMAKE_TYPETEST_TARG( \
                offsetof(wrap_type, ptr_field), \
                offsetof(inner_type, field), expected_val)); \
            cv_set_call_checker(GvCV(_gv), pdfmake_typetest_call_checker, _ck); \
        } \
    } while(0)

/*============================================================================
 * ARENA CONSTRUCTOR ops — create PDF objects from arena
 *
 * All arena constructors follow the same pattern:
 *   Newxz wrapper → set arena backref → arena_alloc → C_init(args) → bless
 *
 * op_targ indexes a dispatch table of init function + arg type.
 *==========================================================================*/

#define PDFMAKE_ARENA_ARG_NONE   0  /* null, array, dict, stream */
#define PDFMAKE_ARENA_ARG_INT    1  /* bool(int), int(IV) */
#define PDFMAKE_ARENA_ARG_DOUBLE 2  /* real(NV) */
#define PDFMAKE_ARENA_ARG_STRING 3  /* name(str,len), str(str,len), hexstr(str,len) */
#define PDFMAKE_ARENA_ARG_REF    4  /* ref(num, gen) */

typedef struct {
    int arg_type;
    /* The init function signature varies, stored as void* */
    void *init_fn;
} pdfmake_arena_ctor_entry_t;

#define PDFMAKE_MAX_ARENA_CTORS 16
static pdfmake_arena_ctor_entry_t pdfmake_arena_ctors[PDFMAKE_MAX_ARENA_CTORS];
static int pdfmake_arena_ctor_count = 0;

/* Forward declare the types we need */
typedef struct pdfmake_obj pdfmake_obj_t_fwd;

static OP* pp_pdfmake_arena_ctor(pTHX) {
    dSP; dMARK; dAX;
    UV idx = PL_op->op_targ;
    pdfmake_arena_ctor_entry_t *e = &pdfmake_arena_ctors[idx];

    /* Self (arena wrapper) is ST(0) */
    SV *arena_sv = ST(0);
    /* Unwrap to arena_xs_t — we know the struct layout:
     * { pdfmake_arena_t *arena } at offset 0 */
    char *arena_xs = PDFMAKE_UNWRAP(char*, arena_sv);
    void *arena_ptr = *(void**)arena_xs;  /* first field is arena pointer */

    /* Allocate wrapper + obj */
    /* We inline the Newxz/alloc pattern here */
    typedef struct {
        void *arena_xs_ptr;
        SV   *arena_sv_ref;
        void *obj_ptr;
    } obj_wrap_t;

    obj_wrap_t *wrap;
    Newxz(wrap, 1, obj_wrap_t);
    wrap->arena_xs_ptr = arena_xs;
    wrap->arena_sv_ref = SvREFCNT_inc(arena_sv);

    /* Arena alloc for the obj (pdfmake_arena_alloc declared in pdfmake_arena.h) */
    wrap->obj_ptr = pdfmake_arena_alloc(arena_ptr, 32); /* sizeof(pdfmake_obj_t) */
    if (!wrap->obj_ptr) {
        SvREFCNT_dec(wrap->arena_sv_ref);
        Safefree(wrap);
        croak("Arena allocation failed");
    }

    /* Call the init function based on arg type */
    typedef struct { int kind; } simple_obj_t; /* just need to write to *obj */

    switch (e->arg_type) {
    case PDFMAKE_ARENA_ARG_NONE: {
        typedef simple_obj_t (*fn0)(void);
        simple_obj_t result = ((fn0)e->init_fn)();
        *(simple_obj_t*)wrap->obj_ptr = result;
        SP = MARK;
        break;
    }
    case PDFMAKE_ARENA_ARG_INT: {
        typedef simple_obj_t (*fn_iv)(int64_t);
        int64_t val = SvIV(ST(1));
        simple_obj_t result = ((fn_iv)e->init_fn)(val);
        *(simple_obj_t*)wrap->obj_ptr = result;
        SP = MARK;
        break;
    }
    case PDFMAKE_ARENA_ARG_DOUBLE: {
        typedef simple_obj_t (*fn_nv)(double);
        double val = SvNV(ST(1));
        simple_obj_t result = ((fn_nv)e->init_fn)(val);
        *(simple_obj_t*)wrap->obj_ptr = result;
        SP = MARK;
        break;
    }
    case PDFMAKE_ARENA_ARG_STRING: {
        typedef simple_obj_t (*fn_str)(void*, const char*, size_t);
        STRLEN len;
        const char *str = SvPV(ST(1), len);
        simple_obj_t result = ((fn_str)e->init_fn)(arena_ptr, str, len);
        *(simple_obj_t*)wrap->obj_ptr = result;
        SP = MARK;
        break;
    }
    case PDFMAKE_ARENA_ARG_REF: {
        typedef simple_obj_t (*fn_ref)(uint32_t, uint16_t);
        uint32_t num = SvUV(ST(1));
        uint16_t gen = (uint16_t)SvUV(ST(2));
        simple_obj_t result = ((fn_ref)e->init_fn)(num, gen);
        *(simple_obj_t*)wrap->obj_ptr = result;
        SP = MARK;
        break;
    }
    }

    /* Bless and return */
    SV *rv = newRV_noinc(newSViv(PTR2IV(wrap)));
    sv_bless(rv, gv_stashpv("PDF::Make::Obj", GV_ADD));
    XPUSHs(sv_2mortal(rv));
    PUTBACK;
    return NORMAL;
}

static OP* pdfmake_arena_ctor_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    IV idx = SvIV(ckobj);
    PERL_UNUSED_ARG(namegv);
    entersubop->op_ppaddr = pp_pdfmake_arena_ctor;
    entersubop->op_targ = idx;
    return entersubop;
}

#define PDFMAKE_REGISTER_ARENA_CTOR(stash, method_name, arg_type_val, init_func) \
    do { \
        int _idx = pdfmake_arena_ctor_count++; \
        pdfmake_arena_ctors[_idx].arg_type = (arg_type_val); \
        pdfmake_arena_ctors[_idx].init_fn = (void*)(init_func); \
        GV *_gv = gv_fetchmeth_pvn(stash, method_name, \
                                    strlen(method_name), 0, 0); \
        if (_gv && GvCV(_gv)) { \
            SV *_ck = newSViv((IV)_idx); \
            cv_set_call_checker(GvCV(_gv), pdfmake_arena_ctor_call_checker, _ck); \
        } \
    } while(0)

/*============================================================================
 * META ops — getter/setter for string metadata fields
 *
 * op_targ indexes into a dispatch table of get/set function pairs.
 * At runtime: if 1 arg (just self) → call getter, return string.
 *             if 2 args (self + value) → call setter, return value.
 *
 * Uses pp_addr replacement on entersub (not op tree rewrite) so args
 * stay on the stack and items count is preserved.
 *==========================================================================*/

typedef const char* (*pdfmake_meta_get_fn)(void *self);
typedef int         (*pdfmake_meta_set_fn)(void *self, const char *val);

typedef struct {
    pdfmake_meta_get_fn getter;
    pdfmake_meta_set_fn setter;
} pdfmake_meta_entry_t;

#define PDFMAKE_MAX_META_ENTRIES 16
static pdfmake_meta_entry_t pdfmake_meta_table[PDFMAKE_MAX_META_ENTRIES];
static int pdfmake_meta_table_count = 0;

static OP* pp_pdfmake_meta(pTHX) {
    dSP; dMARK; dAX;
    int count = SP - MARK;
    UV idx = PL_op->op_targ;
    pdfmake_meta_entry_t *e = &pdfmake_meta_table[idx];

    SV *self_sv = ST(0);
    void *self = PDFMAKE_UNWRAP(void*, self_sv);

    if (count > 1) {
        /* Setter */
        const char *val = SvPV_nolen(ST(1));
        e->setter(self, val);
        SP = MARK;
        XPUSHs(ST(1));
    } else {
        /* Getter */
        const char *val = e->getter(self);
        SP = MARK;
        if (val)
            XPUSHs(sv_2mortal(newSVpv(val, 0)));
        else
            XPUSHs(&PL_sv_undef);
    }
    PUTBACK;
    return NORMAL;
}

static OP* pdfmake_meta_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    IV idx = SvIV(ckobj);
    PERL_UNUSED_ARG(namegv);
    entersubop->op_ppaddr = pp_pdfmake_meta;
    entersubop->op_targ = idx;
    return entersubop;
}

#define PDFMAKE_REGISTER_META(stash, method_name, get_fn, set_fn) \
    do { \
        int _idx = pdfmake_meta_table_count++; \
        pdfmake_meta_table[_idx].getter = (pdfmake_meta_get_fn)(get_fn); \
        pdfmake_meta_table[_idx].setter = (pdfmake_meta_set_fn)(set_fn); \
        GV *_gv = gv_fetchmeth_pvn(stash, method_name, \
                                    strlen(method_name), 0, 0); \
        if (_gv && GvCV(_gv)) { \
            SV *_ck = newSViv((IV)_idx); \
            cv_set_call_checker(GvCV(_gv), pdfmake_meta_call_checker, _ck); \
        } \
    } while(0)

/*============================================================================
 * CONST ops — fold to OP_CONST at compile time
 *==========================================================================*/

static OP* pdfmake_const_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    PERL_UNUSED_ARG(namegv);
    op_free(entersubop);
    return newSVOP(OP_CONST, 0, SvREFCNT_inc(ckobj));
}

/*============================================================================
 * Registration macros
 *==========================================================================*/

/* Register a chainable method's CV with the chain call checker */
#define PDFMAKE_REGISTER_CHAIN(stash, method_name, table_id, index) \
    do { \
        GV *_gv = gv_fetchmeth_pvn(stash, method_name, \
                                    strlen(method_name), 0, 0); \
        if (_gv && GvCV(_gv)) { \
            SV *_ck = newSViv((IV)PDFMAKE_CHAIN_TARG(table_id, index)); \
            cv_set_call_checker(GvCV(_gv), pdfmake_chain_call_checker, _ck); \
        } \
    } while(0)

/* Register a struct field getter */
#define PDFMAKE_REGISTER_GETTER(stash, method_name, struct_type, field, ftype) \
    do { \
        GV *_gv = gv_fetchmeth_pvn(stash, method_name, \
                                    strlen(method_name), 0, 0); \
        if (_gv && GvCV(_gv)) { \
            SV *_ck = newSVuv(PDFMAKE_GETTER_TARG( \
                offsetof(struct_type, field), ftype)); \
            cv_set_call_checker(GvCV(_gv), pdfmake_getter_call_checker, _ck); \
        } \
    } while(0)

/* Register a constant (folds to OP_CONST at compile time) */
#define PDFMAKE_REGISTER_CONST(stash, name, value) \
    do { \
        GV *_gv = gv_fetchmeth_pvn(stash, name, strlen(name), 0, 0); \
        if (_gv && GvCV(_gv)) { \
            SV *_ck = newSViv((IV)(value)); \
            cv_set_call_checker(GvCV(_gv), pdfmake_const_call_checker, _ck); \
        } \
    } while(0)

/*============================================================================
 * XOP registration helper — call once per pp function in BOOT
 *==========================================================================*/

#define PDFMAKE_REGISTER_XOP(xop_var, pp_func, op_name, op_desc) \
    do { \
        XopENTRY_set(&(xop_var), xop_name, op_name); \
        XopENTRY_set(&(xop_var), xop_desc, op_desc); \
        Perl_custom_op_register(aTHX_ pp_func, &(xop_var)); \
    } while(0)

#endif /* PDFMAKE_CUSTOM_OPS_H */
