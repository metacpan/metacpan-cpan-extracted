
#ifndef __PerlCallback_h_
#define __PerlCallback_h_

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#undef do_open
#undef do_close
#ifdef __cplusplus
}
#endif

namespace SOOT {

  /* This stuff is used for implementing TExec wrapping */

  /* Run the given callback using call_sv in void context without args */
  void ExecPerlCallback(pTHX_ SV* callback);

  /* Store the given callback using the given id (usually abusing a pointer) in the global storage of callbacks */
  void StorePerlCallback(pTHX_ long unsigned int id, SV* callback);

  /* Run the callback identified by the given id. Returns != 0 if the callback was run. */
  int ExecStoredPerlCallback(pTHX_ long unsigned int id);

  /* Remove the callback identified by the given id */
  void ClearStoredPerlCallback(pTHX_ long unsigned int id);

} // end namespace SOOT

#endif

