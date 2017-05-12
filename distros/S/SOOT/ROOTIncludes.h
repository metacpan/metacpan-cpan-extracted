#ifndef __ROOTIncludes_h_
#define __ROOTIncludes_h_

/* must load ROOT stuff veeery early due to pollution */
#undef Copy
#undef Move
#undef New
#undef STATIC
#undef Stat_t

#include <TROOT.h>
#include <TClassTable.h>
#include <TPRegexp.h>
#include <TEnv.h>
#include <Rtypes.h>
#include <TClass.h>
#include <TDataMember.h>
#include <TDataType.h>
#include <TMethod.h>
#include <Reflex/Scope.h>
#include <CallFunc.h>
#include <Class.h>
#include <TBaseClass.h>
#include <TList.h>
#include <TSystem.h>
#include <TApplication.h>
#include <TRandom.h>
#include <TBenchmark.h>
#include <TPad.h>
#include <TStyle.h>
#include <TDirectory.h>
#include <TCanvas.h>
#include <TVirtualPad.h>
#include <TPad.h>
#include <TAttImage.h>
#include <TFitResultPtr.h>

#undef Copy
#undef Move
#undef New

#endif
