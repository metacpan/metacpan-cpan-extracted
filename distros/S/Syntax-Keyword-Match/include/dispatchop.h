#ifndef __DISPATCHOP_H__
#define __DISPATCHOP_H__

struct dispatchop {
  /* Looks like a LOGOP */
  BASEOP
  OP *op_first; /* Probably not used */
  OP *op_other;

  /* Extra fields */
  size_t n_cases;
  SV **values;
  OP **dispatch;
};
typedef struct dispatchop DISPATCHOP;

#define cDISPATCHOP      ((DISPATCHOP *)PL_op)
#define cDISPATCHOPx(o)  ((DISPATCHOP *)o)

#define alloc_DISPATCHOP()  MY_alloc_DISPATCHOP(aTHX)
static DISPATCHOP *MY_alloc_DISPATCHOP(pTHX)
{
  OP *o;
  NewOpSz(1101, o, sizeof(DISPATCHOP));
  return (DISPATCHOP *)o;
}

/* A convenient macro for the start of pp_dispatch_* functions */
#define dDISPATCH \
  size_t n_cases = cDISPATCHOP->n_cases; \
  SV **values    = cDISPATCHOP->values;  \
  OP **dispatch  = cDISPATCHOP->dispatch;

#endif
