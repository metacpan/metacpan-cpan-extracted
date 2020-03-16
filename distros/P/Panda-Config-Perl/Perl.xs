#include <xs.h>
#include <xs/merge.h>

using xs::Sv;
using xs::merge;

typedef OP* (*opcheck_t) (pTHX_ OP* op);
static opcheck_t orig_opcheck = NULL;

static OP* pp_sassign (pTHX) {
    dSP;
    Sv left  = *SP;
    Sv right = *(SP-1);

    if (PL_op->op_private & OPpASSIGN_BACKWARDS) swap(left, right);
    
    if (left.is_hash_ref() && right.is_hash_ref()) {
        xs::merge(left, right);
        POPs; SETs(left);
        return NORMAL;
    }
    
    return PL_ppaddr[PL_op->op_type](aTHX);
}

static OP* opcheck (pTHX_ OP* op) {
    OP* ret = orig_opcheck ? orig_opcheck(aTHX_ op) : op;
    const char* packname = SvPVX(PL_curstname);
    STRLEN packlen = SvCUR(PL_curstname);
    if (packlen < 2 || packname[0] != 'N' || packname[1] != 'S') return ret;
    if (packlen > 2 && (packname[2] != ':' || packname[3] != ':')) return ret;
    ret->op_ppaddr = pp_sassign;
    return ret;
}

static void enable_op_tracking (pTHX) {
    if (PL_check[OP_SASSIGN] == opcheck) return;
    orig_opcheck = PL_check[OP_SASSIGN];
    PL_check[OP_SASSIGN] = opcheck;
}

static void disable_op_tracking (pTHX) {
    if (PL_check[OP_SASSIGN] != opcheck) return;
    PL_check[OP_SASSIGN] = orig_opcheck;
    orig_opcheck = NULL;
}

MODULE = Panda::Config::Perl                PACKAGE = Panda::Config::Perl
PROTOTYPES: DISABLE

void enable_op_tracking () {
    enable_op_tracking(aTHX);
}

void disable_op_tracking () {
    disable_op_tracking(aTHX);
}
