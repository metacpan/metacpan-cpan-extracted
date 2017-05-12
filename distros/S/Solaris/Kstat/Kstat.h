/******************************************************************************/
/******************************************************************************/
/**                                                                          **/
/** Code for saving the contents of KSTAT_RAW strucrures                     **/
/**                                                                          **/
/******************************************************************************/
/******************************************************************************/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef __SunOS_5_5_1
typedef unsigned int uint32_t;
typedef unsigned long long uint64_t;
#include <2.6/nfs_kstat.h>
#else
#include <nfs/nfs.h>
#include <nfs/nfs_clnt.h>
#endif

#ifdef NDEBUG
#define PERL_ASSERT(EX) ((void)0)
#else
#define PERL_ASSERT(EX) ((void)((EX) || (croak(#EX), 0), 0))
#endif

#ifndef PL_na
#define PL_na na
#endif

#ifndef PL_sv_undef
#define PL_sv_undef sv_undef
#endif

#define NEW_UIV(V) \
   (V <= IV_MAX ? newSViv(V) : newSVnv((double)V))
#define NEW_HRTIME(V) \
   newSVnv((double)(V / 1000000000.0))

#define SAVE_FNP(H, F, K) \
   hv_store(H, K, sizeof(K) - 1, newSViv((long)&F), 0)
#define SAVE_STRING(H, S, K) \
   hv_store(H, #K, sizeof(#K) - 1, newSVpv(S->K, 0), 0)
#define SAVE_INT32(H, S, K) \
   hv_store(H, #K, sizeof(#K) - 1, newSViv(S->K), 0)
#define SAVE_UINT32(H, S, K) \
   hv_store(H, #K, sizeof(#K) - 1, NEW_UIV(S->K), 0) 
#define SAVE_INT64(H, S, K) \
   hv_store(H, #K, sizeof(#K) - 1, NEW_UIV(S->K), 0)
#define SAVE_UINT64(H, S, K) \
   hv_store(H, #K, sizeof(#K) - 1, NEW_UIV(S->K), 0)
#define SAVE_HRTIME(H, S, K) \
   hv_store(H, #K, sizeof(#K) - 1, NEW_HRTIME(S->K), 0)

/******************************************************************************/
