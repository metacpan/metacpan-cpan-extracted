#include "spvm_native.h"

#include "utf8proc.h"

int32_t SPVM__TestCase__Resource__Utf8proc__test(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  const char* string = "あいう";
  
  utf8proc_uint8_t* string_ret_tmp = NULL;
  
  int32_t string_ret_length = utf8proc_map(string, 0, &string_ret_tmp, UTF8PROC_NULLTERM | UTF8PROC_STABLE |
  UTF8PROC_COMPOSE);
  
  stack[0].ival = 1;
  
  return 0;
}


