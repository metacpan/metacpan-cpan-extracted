#include "spvm_native.h"

#include <png.h>

int32_t SPVM__MyLibpng__test(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)env;
  
  png_colorp palette;
  
  stack[0].ival = 1;
  
  return 0;
}
