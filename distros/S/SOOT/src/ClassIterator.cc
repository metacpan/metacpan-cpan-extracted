
#include "ClassIterator.h"
#include "SOOTDebug.h"

namespace SOOT {
  static TPRegexp gBadClassRegexp("T(?:Btree|List|Map|ObjArray|OrdCollection|RefArray)Iter"); // FIXME "Warning in <TClass::TClass>: no dictionary for class iterator<bidirectional_iterator_tag,TObject*,long,const TObject**,const TObject*&> is available"
  ClassIterator::ClassIterator()
    : fClassNo(0)
  {}

  const char*
  ClassIterator::next()
  {
    if ((int)fClassNo < gClassTable->Classes()) {
      const char* name = gClassTable->At(fClassNo++);
      TString cn(name);
      if (cn.Contains("<") || cn.Contains("::") || gBadClassRegexp.MatchB(cn)) // FIXME optimize
        return next();
      return name;
    }
    return NULL;
  }

} // end namespace SOOT

