// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <assert.h>

#include <iostream>
#include <thread>

extern "C" {

static const char* FILE_NAME = "Thread/ID.cpp";

int32_t SPVM__Thread__ID__eq(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_thread_id1 = stack[0].oval;
  
  if (!obj_thread_id1) {
    return env->die(env, stack, "$thread_id1 must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  void* obj_thread_id2 = stack[1].oval;
  
  if (!obj_thread_id2) {
    return env->die(env, stack, "$thread_id2 must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  std::thread::id* thread_id1 = (std::thread::id*)env->get_pointer(env, stack, obj_thread_id1);
  
  std::thread::id* thread_id2 = (std::thread::id*)env->get_pointer(env, stack, obj_thread_id2);
  
  int32_t ok = *thread_id1 == *thread_id2;
  
  stack[0].ival = ok;
  
  return 0;
}

int32_t SPVM__Thread__ID__ne(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_thread_id1 = stack[0].oval;
  
  if (!obj_thread_id1) {
    return env->die(env, stack, "$thread_id1 must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  void* obj_thread_id2 = stack[1].oval;
  
  if (!obj_thread_id2) {
    return env->die(env, stack, "$thread_id2 must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  std::thread::id* thread_id1 = (std::thread::id*)env->get_pointer(env, stack, obj_thread_id1);
  
  std::thread::id* thread_id2 = (std::thread::id*)env->get_pointer(env, stack, obj_thread_id2);
  
  int32_t ok = *thread_id1 != *thread_id2;
  
  stack[0].ival = ok;
  
  return 0;
}

int32_t SPVM__Thread__ID__gt(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_thread_id1 = stack[0].oval;
  
  if (!obj_thread_id1) {
    return env->die(env, stack, "$thread_id1 must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  void* obj_thread_id2 = stack[1].oval;
  
  if (!obj_thread_id2) {
    return env->die(env, stack, "$thread_id2 must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  std::thread::id* thread_id1 = (std::thread::id*)env->get_pointer(env, stack, obj_thread_id1);
  
  std::thread::id* thread_id2 = (std::thread::id*)env->get_pointer(env, stack, obj_thread_id2);
  
  int32_t ok = *thread_id1 > *thread_id2;
  
  stack[0].ival = ok;
  
  return 0;
}

int32_t SPVM__Thread__ID__ge(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_thread_id1 = stack[0].oval;
  
  if (!obj_thread_id1) {
    return env->die(env, stack, "$thread_id1 must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  void* obj_thread_id2 = stack[1].oval;
  
  if (!obj_thread_id2) {
    return env->die(env, stack, "$thread_id2 must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  std::thread::id* thread_id1 = (std::thread::id*)env->get_pointer(env, stack, obj_thread_id1);
  
  std::thread::id* thread_id2 = (std::thread::id*)env->get_pointer(env, stack, obj_thread_id2);
  
  int32_t ok = *thread_id1 >= *thread_id2;
  
  stack[0].ival = ok;
  
  return 0;
}

int32_t SPVM__Thread__ID__lt(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_thread_id1 = stack[0].oval;
  
  if (!obj_thread_id1) {
    return env->die(env, stack, "$thread_id1 must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  void* obj_thread_id2 = stack[1].oval;
  
  if (!obj_thread_id2) {
    return env->die(env, stack, "$thread_id2 must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  std::thread::id* thread_id1 = (std::thread::id*)env->get_pointer(env, stack, obj_thread_id1);
  
  std::thread::id* thread_id2 = (std::thread::id*)env->get_pointer(env, stack, obj_thread_id2);
  
  int32_t ok = *thread_id1 < *thread_id2;
  
  stack[0].ival = ok;
  
  return 0;
}

int32_t SPVM__Thread__ID__le(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_thread_id1 = stack[0].oval;
  
  if (!obj_thread_id1) {
    return env->die(env, stack, "$thread_id1 must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  void* obj_thread_id2 = stack[1].oval;
  
  if (!obj_thread_id2) {
    return env->die(env, stack, "$thread_id2 must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  std::thread::id* thread_id1 = (std::thread::id*)env->get_pointer(env, stack, obj_thread_id1);
  
  std::thread::id* thread_id2 = (std::thread::id*)env->get_pointer(env, stack, obj_thread_id2);
  
  int32_t ok = *thread_id1 <= *thread_id2;
  
  stack[0].ival = ok;
  
  return 0;
}

int32_t SPVM__Thread__ID__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_self = stack[0].oval;
  
  std::thread::id* thread_id = (std::thread::id*)env->get_pointer(env, stack, obj_self);
  
  env->free_memory_block(env, stack, thread_id);
  
  return 0;
}

}
