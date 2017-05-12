#ifndef RN_LEND_H
#define RN_LEND_H

#ifdef RE_FIELDS_REXC
# define  pREXC     RExC_state_t *pRExC_state
# define  aREXC     pRExC_state
# define  pREXC_    pREXC,
# define  aREXC_    aREXC,

# ifdef PERL_IMPLICIT_CONTEXT
#   define _pREXC  ,pREXC
#   define _aREXC  ,aREXC
#   define pTHX_pREXC pTHX, pREXC
#   define aTHX_aREXC aTHX, aREXC
# else
#   define _pREXC   pREXC
#   define _aREXC   aREXC
#   define pTHX_pREXC pREXC
#   define aTHX_aREXC aREXC
# endif

# if (PERL_REVISION == 5) && (PERL_VERSION == 7) && (PERL_SUBVERSION == 1)
#   undef  RExC_npar
#   define RExC_npar    PL_regnpar
# endif

#else
# define  pREXC
# define  aREXC
# define  pREXC_
# define  aREXC_
# define _pREXC
# define _aREXC

# ifdef PERL_IMPLICIT_CONTEXT
#   define pTHX_pREXC pTHX
#   define aTHX_aREXC aTHX
# else
#   define pTHX_pREXC 
#   define aTHX_aREXC 
# endif

# define  RExC_parse     PL_regcomp_parse
# define  RExC_rx        PL_regcomp_rx
# define  RExC_npar      PL_regnpar
# define  RExC_seen      PL_regseen

# ifndef vFAIL
#   define  vFAIL(p)       Perl_croak(aTHX_ p " in regular expression")
# endif
# ifndef vFAIL3
#   define  vFAIL3(p,x,y)  Perl_croak(aTHX_ p " in regular expression", x, y)
# endif
#endif

#ifndef PM_SETRE
# define  PM_SETRE(o,x)  (o->op_pmregexp = x)
#endif
#ifndef PM_GETRE
# define  PM_GETRE(o)    (o->op_pmregexp)
#endif

#ifdef PERL_IN_REGCOMP_C
  EXT void rx_regcomp_start(pTHX_pREXC);
  EXT int  rx_regcomp_parse(pTHX_ pREXC_ char*, I32);
  EXT void rx_regfree(pTHX_ REGEXP*);
#endif
#ifdef PERL_IN_REGEXEC_C
  EXT void rx_regexec_start(pTHX_ REGEXP*, I32 flags);
  EXT void rx_regexec_match(pTHX_ REGEXP*, I32 flags);
  EXT void rx_regexec_fail(pTHX_ REGEXP*,  I32 flags);
#endif

#endif
