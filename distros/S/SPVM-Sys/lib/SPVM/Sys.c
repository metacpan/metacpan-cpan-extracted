#include "spvm_native.h"

#include <stdlib.h>
#include <errno.h>

static const char* FILE_NAME = "Sys.c";

int32_t SPVM__Sys__is_D_WIN32(SPVM_ENV* env, SPVM_VALUE* stack) {

  int32_t ok;
  
#ifdef _WIN32
  ok = 1;
#else
  ok = 0;
#endif
  
  stack[0].ival = ok;
  
  return 0;
}


int32_t SPVM__Sys__getenv(SPVM_ENV* env, SPVM_VALUE* stack) {

  void* obj_name = stack[0].oval;
  
  if (!obj_name) {
    return env->die(env, stack, "The name must be defined", FILE_NAME, __LINE__);
  }
  
  const char* name = env->get_chars(env, stack, obj_name);
  
  char* value = getenv(name);
  
  void* obj_value;
  if (value) {
    obj_value = env->new_string(env, stack, value, strlen(value));
  }
  else {
    obj_value = NULL;
  }
  
  stack[0].oval = obj_value;
  
  return 0;
}

int32_t SPVM__Sys__setenv(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifdef _WIN32
  env->die(env, stack, "setenv is not supported on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  void* obj_name = stack[0].oval;
  if (!obj_name) {
    return env->die(env, stack, "The name must be defined", FILE_NAME, __LINE__);
  }
  const char* name = env->get_chars(env, stack, obj_name);

  void* obj_value = stack[1].oval;
  if (!obj_value) {
    return env->die(env, stack, "The value must be defined", FILE_NAME, __LINE__);
  }
  const char* value = env->get_chars(env, stack, obj_value);
  
  int32_t overwrite = stack[2].ival;
  
  int32_t status = setenv(name, value, overwrite);

  if (status == -1) {
    env->die(env, stack, "[System Error]setenv failed:%s.", env->strerror(env, stack, errno, 0), FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  stack[0].ival = status;
  
  return 0;
#endif
}

int32_t SPVM__Sys__unsetenv(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifdef _WIN32
  env->die(env, stack, "unsetenv is not supported on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  void* obj_name = stack[0].oval;
  if (!obj_name) {
    return env->die(env, stack, "The name must be defined", FILE_NAME, __LINE__);
  }
  const char* name = env->get_chars(env, stack, obj_name);

  int32_t status = unsetenv(name);

  if (status == -1) {
    env->die(env, stack, "[System Error]unsetenv failed:%s.", env->strerror(env, stack, errno, 0), FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  stack[0].ival = status;
  
  return 0;
#endif
}
