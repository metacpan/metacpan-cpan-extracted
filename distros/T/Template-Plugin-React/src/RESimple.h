#ifndef RESIMPLE_H_
#define RESIMPLE_H_

#include <string>
#include "jsapi.h"

class RESimple {
 public:
  RESimple(unsigned int);
  ~RESimple();
  int exec(const char *name);
  const char *output();

 private:
  JSRuntime   *rt;
  JSContext   *cx;
  JSObject    *global;
};

#endif
