#ifdef __CINT__

#pragma link off all globals;
#pragma link off all classes;
#pragma link off all functions;

// Somehow, this breaks everything, so TExecImpl was moved out of SOOT::
//#pragma link C++ namespace SOOT;
#pragma link C++ class TExecImpl+;

#endif
