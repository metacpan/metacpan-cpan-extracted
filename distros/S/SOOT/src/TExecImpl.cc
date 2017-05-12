
#include "TExecImpl.h"
#include "SOOTDictionary.h"
#include "LinkDef.h"

#include "ROOTIncludes.h"

#if !defined(__CINT__)
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
#endif

#include "SOOTDebug.h"
#include <string>
#include <iostream>

#include "PerlCallback.h"

using namespace std;

void
TExecImpl::TestAlive() {
  cout << "# Test: Alive" << endl;
}

void
TExecImpl::RunPerlCallback(const unsigned long id)
{
  dTHX;
  SOOT::ExecStoredPerlCallback(aTHX_ id);
}


