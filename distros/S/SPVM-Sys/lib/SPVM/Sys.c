// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <stdlib.h>
#include <errno.h>

static const char* FILE_NAME = "Sys.c";

int32_t SPVM__Sys__is_windows(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t defined = 0;
  
#   ifdef _WIN32
  defined = 1;
#   endif
  
  stack[0].ival = defined;
  
  return 0;
}

int32_t SPVM__Sys__defined(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t items = env->get_args_stack_length(env, stack);
  
  void* obj_macro_name = stack[0].oval;
  if (!obj_macro_name) {
    return env->die(env, stack, "The $macro_name must be defined", __func__, FILE_NAME, __LINE__);
  }
  
  const char* macro_name = env->get_chars(env, stack, obj_macro_name);
  
  int32_t defined = 0;
  int32_t ival = 0;
  int64_t lval = 0;
  double dval = 0;
  
  if (strcmp(macro_name, "__GNUC__") == 0) {
#   ifdef __GNUC__
      defined = 1;
      ival = (int32_t)__GNUC__;
      lval = (int64_t)__GNUC__;
      dval = (double)__GNUC__;
#   endif
  }
  else if (strcmp(macro_name, "__clang__") == 0) {
#   ifdef __clang__
      defined = 1;
      ival = (int32_t)__clang__;
      lval = (int64_t)__clang__;
      dval = (double)__clang__;
#   endif
  }
  else if (strcmp(macro_name, "__BORLANDC__") == 0) {
#   ifdef __BORLANDC__
      defined = 1;
      ival = (int32_t)__BORLANDC__;
      lval = (int64_t)__BORLANDC__;
      dval = (double)__BORLANDC__;
#   endif
  }
  else if (strcmp(macro_name, "__INTEL_COMPILER") == 0) {
#   ifdef __INTEL_COMPILER
      defined = 1;
      ival = (int32_t)__INTEL_COMPILER;
      lval = (int64_t)__INTEL_COMPILER;
      dval = (double)__INTEL_COMPILER;
#   endif
  }
  else if (strcmp(macro_name, "__unix") == 0) {
#   ifdef __unix
      defined = 1;
      ival = (int32_t)__unix;
      lval = (int64_t)__unix;
      dval = (double)__unix;
#   endif
  }
  else if (strcmp(macro_name, "__unix__") == 0) {
#   ifdef __unix__
      defined = 1;
      ival = (int32_t)__unix__;
      lval = (int64_t)__unix__;
      dval = (double)__unix__;
#   endif
  }
  else if (strcmp(macro_name, "__linux") == 0) {
#   ifdef __linux
      defined = 1;
      ival = (int32_t)__linux;
      lval = (int64_t)__linux;
      dval = (double)__linux;
#   endif
  }
  else if (strcmp(macro_name, "__linux__") == 0) {
#   ifdef __linux__
      defined = 1;
      ival = (int32_t)__linux__;
      lval = (int64_t)__linux__;
      dval = (double)__linux__;
#   endif
  }
  else if (strcmp(macro_name, "__FreeBSD__") == 0) {
#   ifdef __FreeBSD__
      defined = 1;
      ival = (int32_t)__FreeBSD__;
      lval = (int64_t)__FreeBSD__;
      dval = (double)__FreeBSD__;
#   endif
  }
  else if (strcmp(macro_name, "__NetBSD__") == 0) {
#   ifdef __NetBSD__
      defined = 1;
      ival = (int32_t)__NetBSD__;
      lval = (int64_t)__NetBSD__;
      dval = (double)__NetBSD__;
#   endif
  }
  else if (strcmp(macro_name, "__OpenBSD__") == 0) {
#   ifdef __OpenBSD__
      defined = 1;
      ival = (int32_t)__OpenBSD__;
      lval = (int64_t)__OpenBSD__;
      dval = (double)__OpenBSD__;
#   endif
  }
  else if (strcmp(macro_name, "_WIN32") == 0) {
#   ifdef _WIN32
      defined = 1;
      ival = (int32_t)_WIN32;
      lval = (int64_t)_WIN32;
      dval = (double)_WIN32;
#   endif
  }
  else if (strcmp(macro_name, "_WIN64") == 0) {
#   ifdef _WIN64
      defined = 1;
      ival = (int32_t)_WIN64;
      lval = (int64_t)_WIN64;
      dval = (double)_WIN64;
#   endif
  }
  else if (strcmp(macro_name, "_WINDOWS") == 0) {
#   ifdef _WINDOWS
      defined = 1;
      ival = (int32_t)_WINDOWS;
      lval = (int64_t)_WINDOWS;
      dval = (double)_WINDOWS;
#   endif
  }
  else if (strcmp(macro_name, "_CONSOLE") == 0) {
#   ifdef _CONSOLE
      defined = 1;
      ival = (int32_t)_CONSOLE;
      lval = (int64_t)_CONSOLE;
      dval = (double)_CONSOLE;
#   endif
  }
  else if (strcmp(macro_name, "_WIN32_WINDOWS") == 0) {
#   ifdef _WIN32_WINDOWS
      defined = 1;
      ival = (int32_t)_WIN32_WINDOWS;
      lval = (int64_t)_WIN32_WINDOWS;
      dval = (double)_WIN32_WINDOWS;
#   endif
  }
  else if (strcmp(macro_name, "_WIN32_WINNT") == 0) {
#   ifdef _WIN32_WINNT
      defined = 1;
      ival = (int32_t)_WIN32_WINNT;
      lval = (int64_t)_WIN32_WINNT;
      dval = (double)_WIN32_WINNT;
#   endif
  }
  else if (strcmp(macro_name, "__CYGWIN__") == 0) {
#   ifdef __CYGWIN__
      defined = 1;
      ival = (int32_t)__CYGWIN__;
      lval = (int64_t)__CYGWIN__;
      dval = (double)__CYGWIN__;
#   endif
  }
  else if (strcmp(macro_name, "__CYGWIN32__") == 0) {
#   ifdef __CYGWIN32__
      defined = 1;
      ival = (int32_t)__CYGWIN32__;
      lval = (int64_t)__CYGWIN32__;
      dval = (double)__CYGWIN32__;
#   endif
  }
  else if (strcmp(macro_name, "__MINGW32__") == 0) {
#   ifdef __MINGW32__
      defined = 1;
      ival = (int32_t)__MINGW32__;
      lval = (int64_t)__MINGW32__;
      dval = (double)__MINGW32__;
#   endif
  }
  else if (strcmp(macro_name, "__MINGW64__") == 0) {
#   ifdef __MINGW64__
      defined = 1;
      ival = (int32_t)__MINGW64__;
      lval = (int64_t)__MINGW64__;
      dval = (double)__MINGW64__;
#   endif
  }
  else if (strcmp(macro_name, "__APPLE__") == 0) {
#   ifdef __APPLE__
      defined = 1;
      ival = (int32_t)__APPLE__;
      lval = (int64_t)__APPLE__;
      dval = (double)__APPLE__;
#   endif
  }
  else if (strcmp(macro_name, "__MACH__") == 0) {
#   ifdef __MACH__
      defined = 1;
      ival = (int32_t)__MACH__;
      lval = (int64_t)__MACH__;
      dval = (double)__MACH__;
#   endif
  }
  else if (strcmp(macro_name, "__solaris") == 0) {
#   ifdef __solaris
      defined = 1;
      ival = (int32_t)__solaris;
      lval = (int64_t)__solaris;
      dval = (double)__solaris;
#   endif
  }
  else if (strcmp(macro_name, "__sun") == 0) {
#   ifdef __sun
      defined = 1;
      ival = (int32_t)__sun;
      lval = (int64_t)__sun;
      dval = (double)__sun;
#   endif
  }
  else {
    return env->die(env, stack, "The macro name \"%s\" is not supported yet", macro_name, __func__, FILE_NAME, __LINE__);
  }

  if (items > 1) {
    void* obj_value = stack[1].oval;
    
    int32_t e = 0;
    
    // Int
    if (env->is_type(env, stack, obj_value, SPVM_NATIVE_C_BASIC_TYPE_ID_INT_CLASS, 0)) {
      env->set_field_int_by_name(env, stack, obj_value, "value", ival, &e, __func__, FILE_NAME, __LINE__);
      if (e) { return e; }
    }
    else if (env->is_type(env, stack, obj_value, SPVM_NATIVE_C_BASIC_TYPE_ID_LONG_CLASS, 0)) {
      env->set_field_long_by_name(env, stack, obj_value, "value", lval, &e, __func__, FILE_NAME, __LINE__);
      if (e) { return e; }
    }
    else if (env->is_type(env, stack, obj_value, SPVM_NATIVE_C_BASIC_TYPE_ID_DOUBLE_CLASS, 0)) {
      env->set_field_double_by_name(env, stack, obj_value, "value", dval, &e, __func__, FILE_NAME, __LINE__);
      if (e) { return e; }
    }
    else {
      return env->die(env, stack, "The $value must be the Int, Long, or Double class", macro_name, __func__, FILE_NAME, __LINE__);
    }
  }
  
  stack[0].ival = defined;
  
  return 0;
}

int32_t SPVM__Sys__getenv(SPVM_ENV* env, SPVM_VALUE* stack) {

  void* obj_name = stack[0].oval;
  
  if (!obj_name) {
    return env->die(env, stack, "The name must be defined", __func__, FILE_NAME, __LINE__);
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
#if defined(_WIN32)
  env->die(env, stack, "setenv is not supported on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  void* obj_name = stack[0].oval;
  if (!obj_name) {
    return env->die(env, stack, "The name must be defined", __func__, FILE_NAME, __LINE__);
  }
  const char* name = env->get_chars(env, stack, obj_name);

  void* obj_value = stack[1].oval;
  if (!obj_value) {
    return env->die(env, stack, "The value must be defined", __func__, FILE_NAME, __LINE__);
  }
  const char* value = env->get_chars(env, stack, obj_value);
  
  int32_t overwrite = stack[2].ival;
  
  int32_t status = setenv(name, value, overwrite);

  if (status == -1) {
    env->die(env, stack, "[System Error]setenv failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  stack[0].ival = status;
  
  return 0;
#endif
}

int32_t SPVM__Sys__unsetenv(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "unsetenv is not supported on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  void* obj_name = stack[0].oval;
  if (!obj_name) {
    return env->die(env, stack, "The name must be defined", __func__, FILE_NAME, __LINE__);
  }
  const char* name = env->get_chars(env, stack, obj_name);

  int32_t status = unsetenv(name);

  if (status == -1) {
    env->die(env, stack, "[System Error]unsetenv failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  stack[0].ival = status;
  
  return 0;
#endif
}
