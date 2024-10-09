// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <sys/time.h>
#include <assert.h>

static const char* FILE_NAME = "Sys/Time/Itimerval.c";

int32_t SPVM__Sys__Time__Itimerval__new(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "Sys::Time::Itimerval#new method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  int32_t error_id = 0;
  
  struct itimerval* it = env->new_memory_block(env, stack, sizeof(struct itimerval));
  
  void* obj_it = env->new_pointer_object_by_name(env, stack, "Sys::Time::Itimerval", it, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }

  stack[0].oval = obj_it;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Time__Itimerval__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "Sys::Time::Itimerval#DESTROY method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  void* obj_it = stack[0].oval;
  
  struct itimerval* it = env->get_pointer(env, stack, obj_it);
  
  assert(it);
  
  env->free_memory_block(env, stack, it);
  
  return 0;
#endif
}

int32_t SPVM__Sys__Time__Itimerval__it_interval(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "Sys::Time::Itimerval#it_interval method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  int32_t error_id = 0;
  
  void* obj_it = stack[0].oval;
  
  struct itimerval* it = env->get_pointer(env, stack, obj_it);
  
  struct timeval* it_it_interval = env->new_memory_block(env, stack, sizeof(struct timeval));
  memcpy(it_it_interval, &it->it_interval, sizeof(struct timeval));

  void* obj_tv = env->new_pointer_object_by_name(env, stack, "Sys::Time::Timeval", it_it_interval, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }

  stack[0].oval = obj_tv;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Time__Itimerval__set_it_interval(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "Sys::Time::Itimerval#set_it_interval method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  void* obj_it = stack[0].oval;
  struct itimerval* it = env->get_pointer(env, stack, obj_it);
  
  void* obj_it_interval = stack[1].oval;
  
  struct timeval* it_interval;
  if (obj_it_interval) {
    it_interval = env->get_pointer(env, stack, obj_it_interval);
  }
  else {
    return env->die(env, stack, "Sys::Time::Itimerval#it_interval must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  memcpy(&it->it_interval, it_interval, sizeof(struct timeval));
  
  return 0;
#endif
}

int32_t SPVM__Sys__Time__Itimerval__it_value(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "Sys::Time::Itimerval#it_value method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  int32_t error_id = 0;
  
  void* obj_it = stack[0].oval;
  
  struct itimerval* it = env->get_pointer(env, stack, obj_it);
  
  struct timeval* it_it_value = env->new_memory_block(env, stack, sizeof(struct timeval));
  memcpy(it_it_value, &it->it_value, sizeof(struct timeval));

  void* obj_tv = env->new_pointer_object_by_name(env, stack, "Sys::Time::Timeval", it_it_value, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }

  stack[0].oval = obj_tv;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Time__Itimerval__set_it_value(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "Sys::Time::Itimerval#set_it_value method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  void* obj_it = stack[0].oval;
  struct itimerval* it = env->get_pointer(env, stack, obj_it);
  
  void* obj_it_value = stack[1].oval;
  
  struct timeval* it_value;
  if (obj_it_value) {
    it_value = env->get_pointer(env, stack, obj_it_value);
  }
  else {
    return env->die(env, stack, "Sys::Time::Itimerval#it_value must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  memcpy(&it->it_value, it_value, sizeof(struct timeval));
  
  return 0;
#endif
}
