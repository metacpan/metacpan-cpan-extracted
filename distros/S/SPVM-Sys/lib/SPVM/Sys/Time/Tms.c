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
  env->die(env, stack, "The new method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  
  int32_t error_id = 0;
  
  struct tms* st_tms = env->new_memory_block(env, stack, sizeof(struct tms));
  
  void* obj_st_tms = env->new_pointer_object_by_name(env, stack, "Sys::Time::Tms", st_tms, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_st_tms;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Time__Tms__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "The DESTROY method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  
  void* obj_self = stack[0].oval;
  
  struct tms* st_tms = env->get_pointer(env, stack, obj_self);
  
  env->free_memory_block(env, stack, st_tms);
  env->set_pointer(env, stack, obj_self, NULL);
  
  return 0;
#endif
}

int32_t SPVM__Sys__Time__Tms__tms_utime(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "The tms_utime method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  
  void* obj_self = stack[0].oval;
  
  struct tms* st_tms = env->get_pointer(env, stack, obj_self);
  
  stack[0].lval = st_tms->tms_utime;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Time__Tms__set_tms_utime(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "The set_tms_utime method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  void* obj_self = stack[0].oval;
  
  struct tms* st_tms = env->get_pointer(env, stack, obj_self);
  
  int64_t tms_utime = stack[1].lval;
  st_tms->tms_utime = tms_utime;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Time__Tms__tms_stime(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "The tms_stime method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  
  void* obj_self = stack[0].oval;
  
  struct tms* st_tms = env->get_pointer(env, stack, obj_self);
  
  stack[0].lval = st_tms->tms_stime;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Time__Tms__set_tms_stime(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "The set_tms_stime method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  void* obj_self = stack[0].oval;
  
  struct tms* st_tms = env->get_pointer(env, stack, obj_self);
  
  int64_t tms_stime = stack[1].lval;
  st_tms->tms_stime = tms_stime;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Time__Tms__tms_cutime(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "The tms_cutime method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  
  void* obj_self = stack[0].oval;
  
  struct tms* st_tms = env->get_pointer(env, stack, obj_self);
  
  stack[0].lval = st_tms->tms_cutime;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Time__Tms__set_tms_cutime(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "The set_tms_cutime method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  void* obj_self = stack[0].oval;
  
  struct tms* st_tms = env->get_pointer(env, stack, obj_self);
  
  int64_t tms_cutime = stack[1].lval;
  st_tms->tms_cutime = tms_cutime;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Time__Tms__tms_cstime(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "The tms_cstime method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  
  void* obj_self = stack[0].oval;
  
  struct tms* st_tms = env->get_pointer(env, stack, obj_self);
  
  stack[0].lval = st_tms->tms_cstime;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Time__Tms__set_tms_cstime(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "The set_tms_cstime method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  void* obj_self = stack[0].oval;
  
  struct tms* st_tms = env->get_pointer(env, stack, obj_self);
  
  int64_t tms_cstime = stack[1].lval;
  st_tms->tms_cstime = tms_cstime;
  
  return 0;
#endif
}
