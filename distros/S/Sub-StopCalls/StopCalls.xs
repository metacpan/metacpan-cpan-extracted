#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_sv_2pv_flags
#define NEED_vnewSVpvf
#define NEED_warner
#define NEED_dopoptosub_at
#define NEED_caller_cx
#include "ppport.h"

typedef struct {
    U16 length;
    U16 max;
    OP* ops[];
} oplist;

#define new_oplist(l) \
    l = (oplist*) malloc(sizeof(U16)*2 + 16*sizeof(OP*)); \
    l->length = 0; l->max = 16;

static void
pushop(oplist** list, OP* op)
{
    if (!op) return;
    if ((*list)->length >= (*list)->max) {
        (*list) = realloc((*list), sizeof(U16)*2 + sizeof(OP*)*(*list)->max*2);
        (*list)->max *= 2;
    }
    (*list)->ops[ (*list)->length++ ] = op;
}

static int
is_in_oplist(oplist* list, OP* op) {
    U16 i;
    if (list->length == 0)
        return 0;

    for ( i = 0; i < list->length; i++ ) {
        if ( op == list->ops[i] )
            return 1;
    }
    return 0;
}

typedef struct {
    const PERL_CONTEXT* cx;
    OP* enter;
    OP* sibling;
    OP* parent;
    oplist* targets;
    oplist* prev;
} call_info;

static OP*
find_entry(pTHX_ OP* start_at, OP* retop, OP** sibling, OP** parent )
{
    OP *o, *p = NULL, *res;
    for (o = start_at; o; p = o, o = o->op_sibling) {
        /* o->op_next on entersub is a retop */
        if (o->op_type == OP_ENTERSUB && o->op_next == retop) {
            if (sibling && p) *sibling = p;
            return o;
        }

        if (o->op_flags & OPf_KIDS) {
            res = find_entry(aTHX_ cUNOPo->op_first, retop, sibling, parent);
            if (res) {
                if ( sibling && !*sibling && parent && !*parent )
                    *parent = o;
                return res;
            }
        }
    }
    return NULL;
}

static void
_tree2oplist(pTHX_ oplist** dst, OP* start_at)
{
    OP *o;
    pushop(dst, start_at);
    if (!(start_at->op_flags & OPf_KIDS)) return;

    for (o = cUNOPx(start_at)->op_first; o; o = o->op_sibling) {
        _tree2oplist(aTHX_ dst, o);
    }
}

static oplist*
tree2oplist(pTHX_ OP* start_at)
{
    oplist *res;
    new_oplist(res);
    _tree2oplist(aTHX_ &res, start_at);
    return res;
}


static void
_find_prev_ops(pTHX_ oplist** res, OP* start_at, oplist* into, OP* stop_at )
{
    OP *o; U16 i;

    for (o = start_at; o; o = o->op_sibling) {
        if ( o == stop_at )
            return;

        if ( is_in_oplist( into, o ) )
            continue;

        if ( is_in_oplist( into, o->op_next ) )
            pushop(res, o);

        if (o->op_flags & OPf_KIDS) {
            _find_prev_ops(aTHX_ res, cUNOPo->op_first, into, stop_at);
        }
    }
}

static oplist*
find_prev_ops(pTHX_ OP* start_at, oplist* into, OP* stop_at )
{
    oplist *res;

    new_oplist(res);
    _find_prev_ops(aTHX_ &res, start_at, into, stop_at);
    if ( res->length ) return res;

    free(res);
    return NULL;
}

#if PERL_REVISION>5 || ((PERL_REVISION == 5 && PERL_VERSION > 9) || (PERL_VERSION == 9 && PERL_SUBVERSION > 1) )
#define RETOP cx->blk_sub.retop
#else
#define RETOP PL_retstack[cx->blk_oldretsp-1]
#endif

static call_info
caller_info(pTHX)
{
    call_info res;
    const PERL_CONTEXT *cx = res.cx = caller_cx(0, NULL);
    if (!cx) {
        warn("Couldn't find caller");
        return res;
    }
    res.sibling = NULL;
    res.parent = NULL;
    res.enter = find_entry( aTHX_ (OP*)cx->blk_oldcop, RETOP, &res.sibling, &res.parent );
    if (!res.enter) {
        warn("Couldn't find sub entry");
        res.cx = NULL;
        return res;
    }
    res.targets = tree2oplist(aTHX_ res.enter);
    res.prev = find_prev_ops(
        aTHX_ (OP*)cx->blk_oldcop, res.targets, cx->blk_oldcop->op_sibling->op_sibling
    );
    if ( !res.prev ) {
        warn( "Couldn't find prev ops" );
        res.cx = NULL;
        free(res.targets);
        return res;
    }

    return res;
}

void
void_case(pTHX_ call_info* info) {
    int i;
    if ( info->sibling ) {
        info->sibling->op_sibling = info->enter->op_sibling;
    }
    else {
        cUNOPx(info->parent)->op_first = info->enter->op_sibling;
    }

    for( i = 0; i < info->prev->length; i++ ) {
        info->prev->ops[i]->op_next = info->enter->op_next;
    }
}

void
scalar_case(pTHX_ call_info* info, SV** stack, I32 items) {
    int i;
    SV* s;
    OP *rop;

    if ( items > 1 ) {
        s = newSViv(items);
    }
    else {
        s = newSVsv(*(stack+1));
    }
    rop = newSVOP(OP_CONST, 0, s);

    rop->op_next = info->enter->op_next;
    rop->op_sibling = info->enter->op_sibling;

    if ( info->sibling ) {
        info->sibling->op_sibling = rop;
    } else {
        cUNOPx(info->parent)->op_first = rop;
    }
    for( i = 0; i < info->prev->length; i++ ) {
        info->prev->ops[i]->op_next = rop;
    }
}

void
array_case(pTHX_ call_info* info, SV** stack, I32 items) {
    int i;
    OP *fop = NULL, *pop = NULL, *op = NULL;

    if ( items == 0 )
        return void_case(aTHX_ info);

    for( i = 0; i < items; i++ ) {
        pop = op;
        op = newSVOP( OP_CONST, 0, newSVsv(*(stack+i+1)) );
        if (!fop) fop = op;
        if (pop)
            pop->op_sibling = pop->op_next = op;
    }

    op->op_next = info->enter->op_next;
    op->op_sibling = info->enter->op_sibling;

    if ( info->sibling ) {
        info->sibling->op_sibling = fop;
    }
    else {
        cUNOPx(info->parent)->op_first = fop;
    }

    for( i = 0; i < info->prev->length; i++ ) {
        info->prev->ops[i]->op_next = fop;
    }
}

static void
stop(pTHX_ SV** stack, I32 items)
{
    call_info info = caller_info(aTHX);
    if (!info.cx) return;

    switch( info.cx->blk_gimme ) {
        case G_ARRAY:
            array_case( aTHX_ &info, stack, items );
            break;
        case G_SCALAR:
            scalar_case( aTHX_ &info, stack, items );
            break;
        case G_VOID:
            void_case( aTHX_ &info );
    }
    free(info.targets);
    free(info.prev);
}

MODULE = Sub::StopCalls   PACKAGE = Sub::StopCalls

PROTOTYPES: DISABLE

void
stop(...)
    PPCODE:
        stop(aTHX_ SP, items);
        if ( GIMME_V == G_SCALAR && items > 1 )
            mPUSHi(items);
        else
            SP += items;

