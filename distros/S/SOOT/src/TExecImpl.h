
#ifndef __TExecImpl_h_
#define __TExecImpl_h_

#include <TObject.h>

class TExecImpl {
private:
  TExecImpl() {}
public:
  static void TestAlive();
  static void RunPerlCallback(const unsigned long id);
  ClassDef(TExecImpl, 1);
};

#endif

