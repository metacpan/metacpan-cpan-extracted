#include "spvm_native.h"

#include "spvm_native.h"
#include "coro.h"

int32_t SPVM__TestCase__Resource__Coro__test(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  coro_context ctx;
  
  stack[0].ival = 1;
  
  return 0;
}


