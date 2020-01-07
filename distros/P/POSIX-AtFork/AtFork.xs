#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <pthread.h>

#define MY_CXT_KEY "POSIX::AtFork::_guts" XS_VERSION
typedef struct {
    AV* prepare_list;
    AV* parent_list;
    AV* child_list;
} my_cxt_t;
START_MY_CXT

typedef struct {
    PERL_SI *curstackinfo;
    AV *curstack;
    AV *mainstack;
    SV **stack_base;
    SV **stack_sp;
    SV **stack_max;
} stack_backup_t;

static void
paf_save_stacks(pTHX_ stack_backup_t* bk) {
    bk->curstackinfo = PL_curstackinfo;
    bk->curstack = PL_curstack;
    bk->mainstack = PL_mainstack;

    bk->stack_base = PL_stack_base;
    bk->stack_sp = PL_stack_sp;
    bk->stack_max = PL_stack_max;
}

static void
paf_restore_stacks(pTHX_ stack_backup_t* bk) {
    PL_curstackinfo = bk->curstackinfo;
    PL_curstack = bk->curstack;
    PL_mainstack = bk->mainstack;

    PL_stack_base = bk->stack_base;
    PL_stack_sp = bk->stack_sp;
    PL_stack_max = bk->stack_max;
}

static void
paf_init_stacks(pTHX) {
    PL_curstackinfo = new_stackinfo(32, 4);
    PL_curstackinfo->si_type = PERLSI_MAIN;
    PL_curstack = PL_curstackinfo->si_stack;
    PL_mainstack = PL_curstack;

    PL_stack_base = AvARRAY(PL_curstack);
    PL_stack_sp = PL_stack_base;
    PL_stack_max = PL_stack_base + AvMAX(PL_curstack);
}

static void
paf_destruct_stacks(pTHX) {
    while (PL_curstackinfo->si_next)
        PL_curstackinfo = PL_curstackinfo->si_next;

    while (PL_curstackinfo) {
        PERL_SI *p = PL_curstackinfo->si_prev;

        if (!PL_dirty)
            SvREFCNT_dec (PL_curstackinfo->si_stack);

        Safefree (PL_curstackinfo->si_cxstack);
        Safefree (PL_curstackinfo);
        PL_curstackinfo = p;
    }
}

static void
paf_call_list(pTHX_ AV* const av) {
    const char* const opname = PL_op ? OP_NAME(PL_op) : "(unknown)";
    SV* opnamesv;
    I32 const len = av_len(av) + 1;
    I32 i;

    stack_backup_t bk;
    paf_save_stacks(aTHX_ &bk);
    paf_init_stacks(aTHX);
    ENTER;
    SAVETMPS;
    opnamesv = sv_2mortal(newSVpv(opname, 0));
    for(i = 0; i < len; i++) {
        dSP;
        PUSHMARK(SP);
        XPUSHs(opnamesv);
        PUTBACK;
        call_sv(*av_fetch(av, i, TRUE), G_VOID | G_EVAL);
        if(SvTRUEx(ERRSV)) {
            warn("Callback for pthread_atfork() died (ignored): %"SVf,
                ERRSV);
        }
    }
    FREETMPS;
    LEAVE;
    paf_destruct_stacks(aTHX);
    paf_restore_stacks(aTHX_ &bk);
}

static void
paf_prepare(void) {
    dTHX;
    dMY_CXT;
    paf_call_list(aTHX_ MY_CXT.prepare_list);
}

static void
paf_parent(void) {
    dTHX;
    dMY_CXT;
    paf_call_list(aTHX_ MY_CXT.parent_list);
}

static void
paf_child(void) {
    dTHX;
    dMY_CXT;
    SV* pidsv;

    /* fix up pid */
    pidsv = get_sv("$", GV_ADD);
    SvREADONLY_off(pidsv);
    sv_setiv(pidsv, (IV)PerlProc_getpid());
    SvREADONLY_on(pidsv);

    paf_call_list(aTHX_ MY_CXT.child_list);
}

static void
paf_register_cb(pTHX_ AV* const list, SV* const cb) {
    SvGETMAGIC(cb);
    if(SvOK(cb)) {
        if(SvROK(cb) && SvTYPE(SvRV(cb)) == SVt_PVCV) {
            av_push(list, newSVsv(cb));
        }
        else {
            croak("Callback for atfork must be a CODE reference");
        }
    }
}

static void
paf_delete(pTHX_ AV* const av, SV* const cb) {
    I32 len = av_len(av) + 1;
    I32 i;

    if(!(SvROK(cb) && SvTYPE(SvRV(cb)) == SVt_PVCV)) {
        croak("Not a CODE reference to delete callbacks");
    }

    for(i = 0; i < len; i++) {
        SV* const sv = *av_fetch(av, i, TRUE);
        if(!SvROK(sv)){ sv_dump(sv); }
        assert(SvROK(sv));

        if(SvRV(sv) == SvRV(cb)) {
            size_t const tail = len - i - 1;
            Move(AvARRAY(av) + i + 1, AvARRAY(av) + i, tail, SV*);
            AvFILLp(av)--;
            len--;
            SvREFCNT_dec(sv);
        }
    }
}

static void
paf_initialize(pTHX_ pMY_CXT_ bool const cloning PERL_UNUSED_DECL) {
    pthread_atfork(paf_prepare, paf_parent, paf_child);

    MY_CXT.prepare_list = newAV();
    MY_CXT.parent_list  = newAV();
    MY_CXT.child_list   = newAV();
}

MODULE = POSIX::AtFork		PACKAGE = POSIX::AtFork

PROTOTYPES: DISABLE

BOOT:
{
    MY_CXT_INIT;
    paf_initialize(aTHX_ aMY_CXT_ FALSE);
}

#ifdef USE_ITHREADS

void
CLONE(...)
CODE:
{
    MY_CXT_CLONE;
    paf_initialize(aTHX_ aMY_CXT_ TRUE);
    PERL_UNUSED_VAR(items);
}

#endif

void
pthread_atfork(SV* prepare, SV* parent, SV* child)
CODE:
{
   dMY_CXT;
   paf_register_cb(aTHX_ MY_CXT.prepare_list, prepare);
   paf_register_cb(aTHX_ MY_CXT.parent_list,  parent);
   paf_register_cb(aTHX_ MY_CXT.child_list,   child);
}


void
add_to_prepare(klass, SV* cb)
CODE:
{
   dMY_CXT;
   paf_register_cb(aTHX_ MY_CXT.prepare_list, cb);
}


void
add_to_parent(klass, SV* cb)
CODE:
{
   dMY_CXT;
   paf_register_cb(aTHX_ MY_CXT.parent_list, cb);
}


void
add_to_child(klass, SV* cb)
CODE:
{
   dMY_CXT;
   paf_register_cb(aTHX_ MY_CXT.child_list, cb);
}

void
delete_from_prepare(klass, SV* cb)
CODE:
{
    dMY_CXT;
    paf_delete(aTHX_ MY_CXT.prepare_list, cb);
}

void
delete_from_parent(klass, SV* cb)
CODE:
{
    dMY_CXT;
    paf_delete(aTHX_ MY_CXT.parent_list, cb);
}

void
delete_from_child(klass, SV* cb)
CODE:
{
    dMY_CXT;
    paf_delete(aTHX_ MY_CXT.child_list, cb);
}

