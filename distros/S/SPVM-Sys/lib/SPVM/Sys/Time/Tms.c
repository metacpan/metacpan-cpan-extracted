// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <assert.h>

#ifndef _WIN32
  #include <sys/times.h>
#endif

static const char* FILE_NAME = "Sys/Time/Tms.c";

int32_t SPVM__Sys__Time__Tms__new(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "The new method in the Sys::Time::Tms is not supported on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  
  int32_t e = 0;
  
  struct tms* st_tms = env->new_memory_stack(env, stack, sizeof(struct tms));

  void* obj_st_tms = env->new_pointer_object_by_name(env, stack, "Sys::Time::Tms", st_tms, &e, __func__, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  stack[0].oval = obj_st_tms;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Time__Tms__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "The DESTROY method in the Sys::Time::Tms is not supported on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  
  void* obj_self = stack[0].oval;
  
  struct tms* st_tms = env->get_pointer(env, stack, obj_self);
  
  if (st_tms) {
    env->free_memory_stack(env, stack, st_tms);
    env->set_pointer(env, stack, obj_self, NULL);
  }
  
  return 0;
#endif
}

int32_t SPVM__Sys__Time__Tms__tms_utime(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "The tms_utime method in the Sys::Time::Tms is not supported on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  
  void* obj_self = stack[0].oval;
  
  struct tms* st_tms = env->get_pointer(env, stack, obj_self);
  
  if (st_tms) {
    stack[0].lval = st_tms->tms_utime;
  }
  else {
    assert(0);
  }
  
  return 0;
#endif
}

int32_t SPVM__Sys__Time__Tms__set_tms_utime(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "The set_tms_utime method in the Sys::Time::Tms is not supported on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  void* obj_self = stack[0].oval;
  
  struct tms* st_tms = env->get_pointer(env, stack, obj_self);
  
  if (st_tms) {
    int64_t tms_utime = stack[1].lval;
    st_tms->tms_utime = tms_utime;
  }
  else {
    assert(0);
  }
  
  return 0;
#endif
}

int32_t SPVM__Sys__Time__Tms__tms_stime(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "The tms_stime method in the Sys::Time::Tms is not supported on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  
  void* obj_self = stack[0].oval;
  
  struct tms* st_tms = env->get_pointer(env, stack, obj_self);
  
  if (st_tms) {
    stack[0].lval = st_tms->tms_stime;
  }
  else {
    assert(0);
  }
  
  return 0;
#endif
}

int32_t SPVM__Sys__Time__Tms__set_tms_stime(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "The set_tms_stime method in the Sys::Time::Tms is not supported on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  void* obj_self = stack[0].oval;
  
  struct tms* st_tms = env->get_pointer(env, stack, obj_self);
  
  if (st_tms) {
    int64_t tms_stime = stack[1].lval;
    st_tms->tms_stime = tms_stime;
  }
  else {
    assert(0);
  }
  
  return 0;
#endif
}

int32_t SPVM__Sys__Time__Tms__tms_cutime(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "The tms_cutime method in the Sys::Time::Tms is not supported on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  
  void* obj_self = stack[0].oval;
  
  struct tms* st_tms = env->get_pointer(env, stack, obj_self);
  
  if (st_tms) {
    stack[0].lval = st_tms->tms_cutime;
  }
  else {
    assert(0);
  }
  
  return 0;
#endif
}

int32_t SPVM__Sys__Time__Tms__set_tms_cutime(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "The set_tms_cutime method in the Sys::Time::Tms is not supported on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  void* obj_self = stack[0].oval;
  
  struct tms* st_tms = env->get_pointer(env, stack, obj_self);
  
  if (st_tms) {
    int64_t tms_cutime = stack[1].lval;
    st_tms->tms_cutime = tms_cutime;
  }
  else {
    assert(0);
  }
  
  return 0;
#endif
}

int32_t SPVM__Sys__Time__Tms__tms_cstime(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "The tms_cstime method in the Sys::Time::Tms is not supported on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  
  void* obj_self = stack[0].oval;
  
  struct tms* st_tms = env->get_pointer(env, stack, obj_self);
  
  if (st_tms) {
    stack[0].lval = st_tms->tms_cstime;
  }
  else {
    assert(0);
  }
  
  return 0;
#endif
}

int32_t SPVM__Sys__Time__Tms__set_tms_cstime(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "The set_tms_cstime method in the Sys::Time::Tms is not supported on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  void* obj_self = stack[0].oval;
  
  struct tms* st_tms = env->get_pointer(env, stack, obj_self);
  
  if (st_tms) {
    int64_t tms_cstime = stack[1].lval;
    st_tms->tms_cstime = tms_cstime;
  }
  else {
    assert(0);
  }
  
  return 0;
#endif
}
