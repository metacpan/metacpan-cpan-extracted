#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "embed.h"
#include "XSUB.h"

#define NEED_load_module
#define NEED_newRV_noinc
#define NEED_vload_module
#include "ppport.h"

#define XPUSHREF(x) XPUSHs(sv_2mortal(newRV_inc(x)))
#define PUSHREF(x) PUSHs(sv_2mortal(newRV_inc(x)))

int (*Runops_Trace_old_runops ) ( pTHX );

int (*Runops_Trace_hook)(pTHX);

STATIC HV *Runops_Trace_op_counters;

STATIC int Runops_Trace_enabled;
STATIC UV Runops_Trace_threshold = 0;

STATIC SV *Runops_Trace_perl_hook;
STATIC int Runops_Trace_perl_ignore_ret = 1;

STATIC int Runops_Trace_loaded_B;
STATIC CV *Runops_Trace_B_UNOP_first;
STATIC XSUBADDR_t Runops_Trace_B_UNOP_first_xsub;

STATIC GV *Runops_Trace_B_UNOP_stash;
STATIC UNOP Runops_Trace_fakeop;
STATIC SV *Runops_Trace_fakeop_sv;

#define MAXO_PLUS ( MAXO + 100 )
#define MAXO_BIT_OCTETS ( ( MAXO_PLUS + 7 ) / 8 )
STATIC char *Runops_Trace_mask;

#define ARITY_NULL 0
#define ARITY_UNARY 1
#define ARITY_BINARY 1 << 1
#define ARITY_LIST 1 << 2
#define ARITY_LIST_BINARY (ARITY_LIST|ARITY_BINARY)
#define ARITY_LIST_UNARY (ARITY_LIST|ARITY_UNARY)
#define ARITY_UNKNOWN 1 << 3

/* this is the modified runloop */
int runops_trace(pTHX)
{
  while (PL_op) {
    if ( Runops_Trace_enabled &&
        ( !Runops_Trace_mask /* trace if no mask */
          || ( Runops_Trace_mask[PL_op->op_type >> 3] & ( 1 << (PL_op->op_type & 0x07) ) ) ) /* or this op is unmasked */
       ){

      /* the hook may have assigned PL_op itself, in which case we just go to
       * the next loop iteration */
      if (Runops_Trace_hook && CALL_FPTR( Runops_Trace_hook) (aTHX))
        continue;
    }

    /* this is pretty much the normal runops_standard */
    PL_op = CALL_FPTR(PL_op->op_ppaddr)(aTHX);

    PERL_ASYNC_CHECK(); /* FIXME is it OK that PERL_ASYNC_CHECK happens even after PL_op might be false? */
  }

  TAINT_NOT;

  return 0;
}

void
Runops_Trace_enable () {
  Runops_Trace_enabled = 1;
}

void
Runops_Trace_disable () {
  Runops_Trace_enabled = 0;
}

STATIC SV *
Runops_Trace_op_to_BOP (pTHX_ OP *op) {
  dSP;

  /* we fake B::UNOP object (fakeop_sv) that points to our static fakeop.
   * then we set first_op to the op we want to make an object out of, and
   * trampoline into B::UNOP->first so that it creates the B::OP of the
   * correct class for us.
   * B should really have a way to create an op from a pointer via some
   * external API. This sucks monkey balls on olympic levels */

  Runops_Trace_fakeop.op_first = op;

  PUSHMARK(SP);
  XPUSHs(Runops_Trace_fakeop_sv);
  PUTBACK;

  /* call_pv("B::UNOP::first", G_SCALAR); */
  assert(Runops_Trace_loaded_B);
  assert(Runops_Trace_B_UNOP_first);
  assert(Runops_Trace_B_UNOP_first_xsub != NULL);
  Runops_Trace_B_UNOP_first_xsub(aTHX_ Runops_Trace_B_UNOP_first);

  SPAGAIN;

  return POPs;
}

STATIC IV
Runops_Trace_op_arity (pTHX_ OP *o) {
  switch (o->op_type) {
    case OP_SASSIGN:
      /* wtf? */
      return ((o->op_private & OPpASSIGN_BACKWARDS) ? ARITY_UNARY : ARITY_BINARY);

    case OP_ENTERSUB:
      return ARITY_LIST_UNARY;

    case OP_REFGEN:
      return ARITY_LIST;

    case OP_LEAVELOOP: /* FIXME BASEOP_OR_UNOP */
    case OP_ENTERITER:
    case OP_ENTERLOOP:
      return ARITY_NULL;
  }

  switch (PL_opargs[o->op_type] & OA_CLASS_MASK) {
    case OA_COP:
    case OA_SVOP:
    case OA_PADOP:
    case OA_BASEOP:
    case OA_FILESTATOP:
    case OA_LOOPEXOP:
      return ARITY_NULL;

    case OA_BASEOP_OR_UNOP:
      /* FIXME gotta check gimme from context block */
      /* return (o->op_flags & OPf_KIDS ) ? ARITY_gimme : ARITY_NULL; */
      return ARITY_NULL;

    case OA_LOGOP:
    case OA_UNOP:
      return ARITY_UNARY;

    case OA_LISTOP:
      return ARITY_LIST;

    case OA_BINOP:
      if ( o->op_type == OP_AASSIGN ) {
        return ARITY_LIST_BINARY;
      } else {
        return ARITY_BINARY;
      }
    default:
      printf("%s is a %d\n", PL_op_name[o->op_type], PL_opargs[o->op_type] >> OASHIFT);
      return ARITY_UNKNOWN;
  }
}

STATIC AV *
av_make_with_refs(pTHX_ SV**from, SV**to) {
  SV **i;
  AV *av = newAV();

  /* Bug #64830 */
  if (to > from) {
    av_extend(av, (to - from) / sizeof(SV **));

    for (i = from; i <= to; i++) {
      av_push(av, newRV_inc(*i));
    }
  }

  return av;
}

/* this is a hook that calls to a perl code ref */
int
Runops_Trace_perl (pTHX) {
  dSP;

  SV **orig_sp = SP;
  SV **list_mark;

  SV *sv_ret;
  SV *PL_op_object;
  int ret;
  IV arity;

  /* if the threshold is enabled, only trace if the op has exceeded the threshold */
  if (Runops_Trace_threshold != 0) {
    SV **count;
    UV c;

    /* having a threshold means that only ops that are hit enough
     * times get hooked, the idea is that this can be used for
     * trace caching */

    /* in the future this might change to a dynamically decayed bloom filter */

    if ( !Runops_Trace_op_counters )
      Runops_Trace_op_counters = newHV();

    /* unfortunately we need to keep the counters in a hash */
    count = hv_fetch(Runops_Trace_op_counters, (char *)PL_op, sizeof(PL_op), 1);
    if ( SvTRUE(*count) ) {
      SvUVX(*count)++;
    } else {
      *count = newSVuv(1);
    }

    /* if we haven't reached the threshold yet, then return */
    if (c < Runops_Trace_threshold)
      return 0;
  }

  /* don't want to hook the hook */
  Runops_Trace_disable();

  /* make the environment as normal as possible for callbacks */
  PL_runops = Runops_Trace_old_runops;

  ENTER;
  SAVETMPS;

  PL_op_object = Runops_Trace_op_to_BOP(aTHX_ PL_op);
  arity = Runops_Trace_op_arity(aTHX_ PL_op);

  /* arguments for the sub start at this mark */
  PUSHMARK(SP);

  EXTEND(SP, 4); /* op obj, arity flag, unary and binary ops. ARITY_LIST will call extend for nary args */

  PUSHs(PL_op_object);
  PUSHs(sv_2mortal(newSViv(arity)));

  switch (arity) {

    case ARITY_LIST_UNARY:
      /* ENTERSUB's unary arg (the cv) is the last thing on the stack, but it has args too */
      PUSHREF(*orig_sp--);
      /* fall through */
    case ARITY_LIST:
      list_mark = PL_stack_base + *(PL_markstack_ptr-1) + 1;
      /* repeat stack from the op's mark to SP just before we started pushing */
      EXTEND(SP, orig_sp - list_mark);
      while ( list_mark <= orig_sp ) {
        XPUSHREF(*list_mark++);
      }

      break;

    case ARITY_BINARY:
      XPUSHREF(*(orig_sp-1));
    case ARITY_UNARY:
      XPUSHREF(*orig_sp);
      break;

    case ARITY_LIST_BINARY:
      {
        SV **mark = SP; dORIGMARK;

        SV **lastlelem = orig_sp;
        SV **lastrelem = PL_stack_base + *(PL_markstack_ptr-1);
        SV **firstrelem = PL_stack_base + *(PL_markstack_ptr-2) + 1;
        SV **firstlelem = lastrelem + 1;

        SV *lav = (SV *)av_make_with_refs(aTHX_ firstlelem, lastlelem);
        SV *rav = (SV *)av_make_with_refs(aTHX_ firstrelem, lastrelem);

        SP = ORIGMARK;

        XPUSHREF(lav);
        XPUSHREF(rav);
      }
      break;

    case ARITY_NULL:
      break;


    default:
      /* warn("Unknown arity for %s (%p)", PL_op_name[PL_op->op_type], PL_op); */
      break;
  }

  PUTBACK;

  call_sv(Runops_Trace_perl_hook, (Runops_Trace_perl_ignore_ret ? G_DISCARD : G_SCALAR));

  SPAGAIN;

  /* we coerce it here so that SvTRUE is evaluated without hooking, and
   * Runops_Trace_enable() is the last thing in this hook */

  if (!Runops_Trace_perl_ignore_ret) {
    sv_ret = POPs;
    ret = SvTRUE(sv_ret);
  } else {
    ret = 0;
  }

  PUTBACK;
  FREETMPS;
  LEAVE;

  /* set up debugging again */
  PL_runops = runops_trace;

  Runops_Trace_enable();

  return ret;
}

void
Runops_Trace_clear_hook () {
  Runops_Trace_hook = NULL;
}

void
Runops_Trace_set_hook (int (*hook)(pTHX)) {
  Runops_Trace_hook = hook;
}

void
Runops_Trace_clear_perl_hook(pTHX) {
  SvSetSV(Runops_Trace_perl_hook, &PL_sv_undef );
}

STATIC void
Runops_Trace_load_B (pTHX) {
  if (!Runops_Trace_loaded_B) {
    load_module( PERL_LOADMOD_NOIMPORT, newSVpv("B", 0), (SV *)NULL );

    Runops_Trace_B_UNOP_first = get_cv("B::UNOP::first", TRUE);
    Runops_Trace_B_UNOP_first_xsub = CvXSUB(Runops_Trace_B_UNOP_first);

    Runops_Trace_fakeop_sv = sv_bless(newRV_noinc(newSVuv((UV)&Runops_Trace_fakeop)), gv_stashpv("B::UNOP", 0));

    Runops_Trace_loaded_B = 1;
  }
}

void
Runops_Trace_set_perl_hook (pTHX_ SV *tracer_rv) {
  /* Validate tracer_rv */
  if ( ! SvROK( tracer_rv ) ||  ! SVt_PVCV == SvTYPE( SvRV( tracer_rv ) ) ) {
    croak("the hook must be a code reference");
  }

  Runops_Trace_load_B(aTHX);

  Runops_Trace_clear_perl_hook(aTHX);

  /* Initialize/set the tracing function */
  SvSetSV( Runops_Trace_perl_hook, tracer_rv );

  Runops_Trace_set_hook(Runops_Trace_perl);
}

STATIC UV
Runops_Trace_get_threshold () {
  return Runops_Trace_threshold;
}

STATIC void
Runops_Trace_set_threshold (UV t) {
  Runops_Trace_threshold = t;
}

STATIC void
Runops_Trace_mask_set (bool t) {
  if ( Runops_Trace_mask ) {
    char *byte = Runops_Trace_mask;
    while ( byte < Runops_Trace_mask + MAXO_BIT_OCTETS ) {
      *byte++ = t ? 0xff : 0;
    }
  }
}

STATIC void
Runops_Trace_mask_autocreate () {
  if (!Runops_Trace_mask) {
    I32 len = MAXO_BIT_OCTETS;

    Newx(Runops_Trace_mask, MAXO_BIT_OCTETS, char);
    Runops_Trace_mask_set(1);
  }
}

STATIC void
Runops_Trace_mask_all () {
  if (!Runops_Trace_mask) {
    Newxz(Runops_Trace_mask, MAXO_BIT_OCTETS, char);
  } else {
    Runops_Trace_mask_set(0);
  }
}

STATIC void
Runops_Trace_mask_none () {
  if (!Runops_Trace_mask) {
    Runops_Trace_mask_autocreate();
  } else {
    Runops_Trace_mask_set(1);
  }
}

STATIC void
Runops_Trace_mask_set_op_type (I32 op_type, bool bit) {
  if ( !Runops_Trace_mask )
      Runops_Trace_mask_autocreate();
  if ( op_type < MAXO_PLUS && op_type >= 0 ) {
    const int offset = op_type >> 3;
    const int bit    = op_type & 0x07;

    if (bit)
      Runops_Trace_mask[offset] |=   1 << bit;
    else
      Runops_Trace_mask[offset] &= ~(1 << bit);
  } else {
    croak("Invalid op_type %d", op_type);
  }
}

STATIC void
Runops_Trace_unmask_op_type (unsigned op_type) {
  Runops_Trace_mask_set_op_type(op_type, 1);
}

STATIC void
Runops_Trace_mask_op_type (unsigned op_type) {
  Runops_Trace_mask_set_op_type(op_type, 0);
}

STATIC void
Runops_Trace_clear_op_mask () {
  Safefree(Runops_Trace_mask);
  Runops_Trace_mask = NULL;
}

MODULE = Runops::Trace PACKAGE = Runops::Trace

PROTOTYPES: ENABLE

BOOT:
  Runops_Trace_clear_hook();
  Runops_Trace_old_runops = PL_runops;
  PL_runops = runops_trace;
  Runops_Trace_perl_hook = newSVsv( &PL_sv_undef );

HV *
get_op_counters()
  PROTOTYPE:
  CODE:
{
  if ( !Runops_Trace_op_counters )
    Runops_Trace_op_counters = newHV();

  RETVAL = Runops_Trace_op_counters;
}
  OUTPUT:
    RETVAL

int
tracing_enabled()
  PROTOTYPE:
  CODE:
{
  RETVAL = Runops_Trace_enabled;
}
  OUTPUT:
    RETVAL

void
enable_tracing()
  PROTOTYPE:
  CODE:
{
  Runops_Trace_enable();
}

void
disable_tracing()
  PROTOTYPE:
  CODE:
{
  Runops_Trace_disable();
}

UV
get_trace_threshold()
  PROTOTYPE:
  CODE:
{
  RETVAL = Runops_Trace_get_threshold();
}
  OUTPUT:
    RETVAL

void
set_trace_threshold(SV *a)
  PROTOTYPE: $
  CODE:
{
     Runops_Trace_set_threshold(SvUV(a));
}

void
set_tracer(SV *hook)
  PROTOTYPE: $
  CODE:
{
  Runops_Trace_set_perl_hook(aTHX_ hook);
}

SV *
get_tracer()
  PROTOTYPE:
  CODE:
{
  RETVAL = Runops_Trace_perl_hook;
}
  OUTPUT:
    RETVAL

void
clear_tracer()
  PROTOTYPE:
  CODE:
{
  Runops_Trace_clear_perl_hook(aTHX);
  Runops_Trace_clear_hook();
}

void
ignore_hook_ret()
  PROTOTYPE:
  CODE:
{
  Runops_Trace_perl_ignore_ret = 1;
}

void
unignore_hook_ret()
  PROTOTYPE:
  CODE:
{
  Runops_Trace_perl_ignore_ret = 0;
}

void
_trace_function( tracer_rv, to_trace_rv)
    SV * tracer_rv
    SV * to_trace_rv
  PROTOTYPE: $$
  CODE:
    Runops_Trace_set_perl_hook( aTHX_ tracer_rv );

    /* Call the function to trace */
    Runops_Trace_enable();
    call_sv( to_trace_rv, G_VOID | G_DISCARD | G_EVAL | G_KEEPERR );
    Runops_Trace_disable();

void
enable_global_tracing(tracer_rv)
    SV * tracer_rv
  PROTOTYPE: $
  CODE:
    Runops_Trace_set_perl_hook( aTHX_ tracer_rv );
    Runops_Trace_enable();

void
disable_global_tracing()
  PROTOTYPE:
  CODE:
    Runops_Trace_disable();

void
mask_op_type (unsigned op_type)
  PROTOTYPE: $
  CODE:
{
  Runops_Trace_mask_op_type(op_type);
}

void
unmask_op_type (unsigned op_type)
  PROTOTYPE: $
  CODE:
{
  Runops_Trace_unmask_op_type(op_type);
}

void
mask_all ()
  PROTOTYPE:
  CODE:
{
  Runops_Trace_mask_all();
}

void
unmask_all ()
  PROTOTYPE:
  CODE:
{
  Runops_Trace_mask_none();
}

void
mask_none ()
  PROTOTYPE:
  CODE:
{
  Runops_Trace_mask_none();
}


void
clear_mask()
  PROTOTYPE:
  CODE:
{
  Runops_Trace_clear_op_mask();
}

int
ARITY_NULL ()
  PROTOTYPE:
  CODE:
{
  RETVAL = ARITY_NULL;
}
  OUTPUT:
    RETVAL

int
ARITY_UNARY ()
  PROTOTYPE:
  CODE:
{
  RETVAL = ARITY_UNARY;
}
  OUTPUT:
    RETVAL

int
ARITY_BINARY ()
  PROTOTYPE:
  CODE:
{
  RETVAL = ARITY_BINARY;
}
  OUTPUT:
    RETVAL


int
ARITY_LIST ()
  PROTOTYPE:
  CODE:
{
  RETVAL = ARITY_LIST;
}
  OUTPUT:
    RETVAL


int
ARITY_LIST_BINARY ()
  PROTOTYPE:
  CODE:
{
  RETVAL = ARITY_LIST_BINARY;
}
  OUTPUT:
    RETVAL


int
ARITY_LIST_UNARY ()
  PROTOTYPE:
  CODE:
{
  RETVAL = ARITY_LIST_UNARY;
}
  OUTPUT:
    RETVAL


int
ARITY_UNKNOWN ()
  PROTOTYPE:
  CODE:
{
  RETVAL = ARITY_UNKNOWN;
}
  OUTPUT:
    RETVAL


