#include <TROOT.h>
#include <TClassTable.h>
#include <TH1D.h>
#include <TPRegexp.h>
#include <TEnv.h>
#include <Rtypes.h>
#include <TClass.h>
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

#include <string>
#include <vector>
#include <iostream>
#include <iomanip>

using namespace std;

int main (int /*argc*/, char** /*argv*/) {
  TH1D* hist = new TH1D("hist", "hist", 2, 0., 1.);

  // Now try to call GetXaxis...
  TClass* histClass = TClass::GetClass("TH1D");
  if (histClass == NULL) {
    cout << "Couldn't get TClass" << endl;
    return 1;
  }

  const char* cproto = ""; // ->GetXaxis(void)!

  TObject* callee = (TObject*)hist;
  G__ClassInfo theClass("TH1D");
  long offset;
  G__MethodInfo  mInfo = theClass.GetMethod("GetXaxis", cproto, &offset);
  if (!mInfo.InterfaceMethod()) {
    cout << "Invalid mInfo" << endl;
    return 1;
  }

  const char* retType = mInfo.Type()->TrueName();
  cout << "Return type: " << retType << endl;

  delete hist;
  return 0;
}

