
MODULE = SOOT PACKAGE = SOOT
BOOT:
  //cout << "BOOTING SOOT" << endl;
  static TTObjectEncapsulator e;
  gROOT->GetListOfCleanups()->Add( &e );
  gSystem->Load("libMathCore");
  gSystem->Load("libPhysics");
  SOOT::gSOOTObjects = new SOOT::PtrTable(aTHX_ (UV)1024, &SOOT::ClearAnnotation);
  SOOT::GenerateClassStubs(aTHX);
  SOOT::InitializePerlGlobals(aTHX);

void
Init(int eval_macros = 0)
  INIT:
    static bool initialized = false;
    static bool initialized_macros = false;
  PPCODE:
    if (!initialized) {
      gROOT->ProcessLine("#include <iostream>");
      gROOT->ProcessLine("#include <iomanip>");
      gROOT->ProcessLine("#include <sstream>");
      gROOT->ProcessLine("#include <vector>");
      gROOT->ProcessLine("#include <map>");
      gROOT->ProcessLine("#include <string>");
      gROOT->ProcessLine("using namespace std;");
      initialized = true;
    }
    if (eval_macros && !initialized_macros) {
      initialized_macros = true;
      const char *logon;
      logon = gEnv->GetValue("Rint.Load", (char*)0);
      if (logon) {
        char *mac = gSystem->Which(TROOT::GetMacroPath(), logon, kReadPermission);
        if (mac)
          gROOT->ProcessLine(Form(".L %s", logon));
        delete [] mac;
      }
      TString name = ".rootlogon.C";
      TString sname = "system";
      sname += name;
#ifdef ROOTETCDIR
      char *s = gSystem->ConcatFileName(ROOTETCDIR, sname);
#else
      TString etc = gRootDir;
#ifdef WIN32
      etc += "\\etc";
#else
      etc += "/etc";
#endif
      char *s = gSystem->ConcatFileName(etc, sname);
#endif
      if (!gSystem->AccessPathName(s, kReadPermission))
        gROOT->ProcessLine(Form(".x %s", s));
      delete [] s;
      s = gSystem->ConcatFileName(gSystem->HomeDirectory(), name);
      if (!gSystem->AccessPathName(s, kReadPermission)) 
        gROOT->ProcessLine(Form(".x %s", s));
      delete [] s;
      // avoid executing ~/.rootlogon.C twice
      if (strcmp(gSystem->HomeDirectory(), gSystem->WorkingDirectory())) {
        if (!gSystem->AccessPathName(name, kReadPermission))
          gROOT->ProcessLine(Form(".x %s", name.Data()));
      }
      // execute also the logon macro specified by "Rint.Logon"
      logon = gEnv->GetValue("Rint.Logon", (char*)0);
      if (logon) {
        char *mac = gSystem->Which(TROOT::GetMacroPath(), logon, kReadPermission);
        if (mac)
          gROOT->ProcessLine(Form(".x %s", logon));
        delete [] mac;
      }
    }
    XSRETURN(0);

