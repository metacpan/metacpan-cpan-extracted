
#ifndef __ClassIterator_h_
#define __ClassIterator_h_

#include "ROOTIncludes.h"

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

  /// A simple iterator class for accessing the set of wrapped ROOT classes
  class ClassIterator {
  public:
    /// Setup new iterator
    ClassIterator();

    /// Return next class name or NULL when none left
    const char* next();
  private:
    unsigned int fClassNo;
  };

} // end namespace SOOT

#endif

