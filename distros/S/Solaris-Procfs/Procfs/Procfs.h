/******************************************************************************/
/******************************************************************************/
/**                                                                          **/
/** Code for saving the contents of various strucrures                       **/
/** Originally written by Alan Burlison                                      **/
/** Several additions by John Nolan                                          **/
/**                                                                          **/
/******************************************************************************/
/******************************************************************************/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* #undef SP */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <procfs.h>
#include <dirent.h>
#include <assert.h>
#include <string.h>
#include <fcntl.h>
#include <sys/time.h>
#include <sys/auxv.h>
#include <vm/as.h>

#define HEXVAL_AS_STRING 17

#define NEW_UIV(V) \
   (V <= IV_MAX ? newSViv(V) : newSVnv((double)V))

#define NEW_HRTIME(V) \
   newSVnv((double)(V / 1000000000.0))

#define SAVE_FNP(H, F, K) \
   hv_store(H, K, sizeof(K) - 1, newSViv((long)&F), 0)
#define SAVE_STRING(H, S, K) \
   hv_store(H, #K, sizeof(#K) - 1, newSVpv(S->K, 0), 0)

#define SAVE_HEXVAL(H, S, K, B) \
   sprintf(B, "0x%08X", S->K); hv_store(H, #K, sizeof(#K) - 1, newSVpv(B, 0), 0);   
#define SAVE_HEXVAL_TO_LIST(L, K, B) \
   sprintf(B, "0x%08X", K); av_push(L, newSVpv(B, 0));       

#define SAVE_INT32(H, S, K) \
   hv_store(H, #K, sizeof(#K) - 1, newSViv(S->K), 0)
#define SAVE_UINT32(H, S, K) \
   hv_store(H, #K, sizeof(#K) - 1, NEW_UIV(S->K), 0)
#define SAVE_INT64(H, S, K) \
   hv_store(H, #K, sizeof(#K) - 1, NEW_UIV(S->K), 0)
#define SAVE_UINT64(H, S, K) \
   hv_store(H, #K, sizeof(#K) - 1, NEW_UIV(S->K), 0)

#define SAVE_INT(H, S, K) \
   hv_store(H, #K, sizeof(#K) - 1, NEW_UIV(S->K), 0)

#define SAVE_HRTIME(H, S, K) \
   hv_store(H, #K, sizeof(#K) - 1, NEW_HRTIME(S->K), 0)    

#define SAVE_STRUCT(H, S, K, F) \
   hv_store(H, #K, sizeof(#K) - 1, F( & S->K ), 0); 
#define SAVE_REF(H, K) \
   hv_store(H, #K, sizeof(#K) - 1, newRV_noinc( (SV*) K), 0 );

#define FORGET_STRUCT(H, K, N) \
	hv_store(H, #K, sizeof(#K) - 1, newSVsv(perl_get_sv( #N, 0)), 0); \
	SvREFCNT_dec(K);


/* hv_store(hash, "pr_argv", sizeof("pr_argv") - 1, */
/* newSVsv(perl_get_sv( "Solaris::Procfs::read_failed", 0)), 0); */
/* SvREFCNT_dec(pr_argv); */


/******************************************************************************/
