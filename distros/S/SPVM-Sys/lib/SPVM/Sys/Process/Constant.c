#include "spvm_native.h"

#include <stdlib.h>

static const char* FILE_NAME = "Sys/Process/Constant.c";

int32_t SPVM__Sys__Process__Constant__EXIT_FAILURE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef EXIT_FAILURE
  stack[0].ival = EXIT_FAILURE;
  return 0;
#else
  env->die(env, stack, "EXIT_FAILURE is not defined on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Process__Constant__EXIT_SUCCESS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef EXIT_SUCCESS
  stack[0].ival = EXIT_SUCCESS;
  return 0;
#else
  env->die(env, stack, "EXIT_SUCCESS is not defined on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Process__Constant__WNOHANG(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef WNOHANG
  stack[0].ival = WNOHANG;
  return 0;
#else
  env->die(env, stack, "WNOHANG is not defined on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Process__Constant__WUNTRACED(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef WUNTRACED
  stack[0].ival = WUNTRACED;
  return 0;
#else
  env->die(env, stack, "WUNTRACED is not defined on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Process__Constant__WCONTINUED(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef WCONTINUED
  stack[0].ival = WCONTINUED;
  return 0;
#else
  env->die(env, stack, "WCONTINUED is not defined on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}
