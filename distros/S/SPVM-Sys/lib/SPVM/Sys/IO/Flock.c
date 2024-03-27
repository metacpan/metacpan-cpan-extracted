// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <assert.h>
#include <fcntl.h>

static const char* FILE_NAME = "Sys/IO/Flock";

int32_t SPVM__Sys__IO__Flock__new(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "The \"new\" method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  
  int32_t error_id = 0;
  
  struct flock* st_flock = env->new_memory_block(env, stack, sizeof(struct flock));

  void* obj_st_flock = env->new_pointer_object_by_name(env, stack, "Sys::IO::Flock", st_flock, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_st_flock;
  
  return 0;
#endif
}

int32_t SPVM__Sys__IO__Flock__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "The \"DESTROY\" method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  
  void* obj_st_flock = stack[0].oval;
  
  struct flock* st_flock = env->get_pointer(env, stack, obj_st_flock);
  
  assert(st_flock);
  
  env->free_memory_block(env, stack, st_flock);
  env->set_pointer(env, stack, obj_st_flock, NULL);
  
  return 0;
#endif
}

int32_t SPVM__Sys__IO__Flock__l_type(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "The \"l_type\" method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  struct flock* st_flock = env->get_pointer(env, stack, obj_self);
  
  int16_t l_type = st_flock->l_type;
  
  stack[0].ival = l_type;
  
  return 0;
#endif
}

int32_t SPVM__Sys__IO__Flock__set_l_type(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "The \"set_l_type\" method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  
  void* obj_self = stack[0].oval;
  
  struct flock* st_flock = env->get_pointer(env, stack, obj_self);
  
  int16_t l_type = stack[1].ival;
  st_flock->l_type = l_type;
  
  return 0;
#endif
}

int32_t SPVM__Sys__IO__Flock__l_whence(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "The \"l_whence\" method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  struct flock* st_flock = env->get_pointer(env, stack, obj_self);
  
  int16_t l_whence = st_flock->l_whence;
  
  stack[0].ival = l_whence;
  
  return 0;
#endif
}

int32_t SPVM__Sys__IO__Flock__set_l_whence(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "The \"set_l_whence\" method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  
  void* obj_self = stack[0].oval;
  
  struct flock* st_flock = env->get_pointer(env, stack, obj_self);
  
  int16_t l_whence = stack[1].ival;
  st_flock->l_whence = l_whence;
  
  return 0;
#endif
}

int32_t SPVM__Sys__IO__Flock__l_start(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "The \"l_start\" method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  struct flock* st_flock = env->get_pointer(env, stack, obj_self);
  
  int64_t l_start = st_flock->l_start;
  
  stack[0].lval = l_start;
  
  return 0;
#endif
}

int32_t SPVM__Sys__IO__Flock__set_l_start(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "The \"set_l_start\" method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  
  void* obj_self = stack[0].oval;
  
  struct flock* st_flock = env->get_pointer(env, stack, obj_self);
  
  int64_t l_start = stack[1].lval;
  st_flock->l_start = l_start;
  
  return 0;
#endif
}

int32_t SPVM__Sys__IO__Flock__l_len(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "The \"l_len\" method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  struct flock* st_flock = env->get_pointer(env, stack, obj_self);
  
  int64_t l_len = st_flock->l_len;
  
  stack[0].lval = l_len;
  
  return 0;
#endif
}

int32_t SPVM__Sys__IO__Flock__set_l_len(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "The \"set_l_len\" method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  
  void* obj_self = stack[0].oval;
  
  struct flock* st_flock = env->get_pointer(env, stack, obj_self);
  
  int64_t l_len = stack[1].lval;
  st_flock->l_len = l_len;
  
  return 0;
#endif
}

int32_t SPVM__Sys__IO__Flock__l_pid(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "The \"new\" method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  struct flock* st_flock = env->get_pointer(env, stack, obj_self);
  
  int32_t l_pid = st_flock->l_pid;
  
  stack[0].ival = l_pid;
  
  return 0;
#endif
}

int32_t SPVM__Sys__IO__Flock__set_l_pid(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "The \"new\" method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  
  void* obj_self = stack[0].oval;
  
  struct flock* st_flock = env->get_pointer(env, stack, obj_self);
  
  int32_t l_pid = stack[1].ival;
  st_flock->l_pid = l_pid;
  
  return 0;
#endif
}
