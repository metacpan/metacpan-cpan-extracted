// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <sys/time.h>
#include <assert.h>
#include <time.h>

static const char* FILE_NAME = "Sys/Time/Timespec.c";

int32_t SPVM__Sys__Time__Timespec__new(SPVM_ENV* env, SPVM_VALUE* stack) {

  int32_t error_id = 0;
  
  struct timespec* ts = env->new_memory_block(env, stack, sizeof(struct timespec));
  
  ts->tv_sec = stack[0].lval;
  
  ts->tv_nsec = stack[1].lval;
  
  void* obj_ts = env->new_pointer_object_by_name(env, stack, "Sys::Time::Timespec", ts, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_ts;
  
  return 0;
}

int32_t SPVM__Sys__Time__Timespec__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_ts = stack[0].oval;
  
  struct timespec* ts = env->get_pointer(env, stack, obj_ts);
  
  assert(ts);
  
  env->free_memory_block(env, stack, ts);
  
  return 0;
}

int32_t SPVM__Sys__Time__Timespec__tv_sec(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_ts = stack[0].oval;
  
  struct timespec* ts = env->get_pointer(env, stack, obj_ts);
  
  stack[0].lval = ts->tv_sec;
  
  return 0;
}

int32_t SPVM__Sys__Time__Timespec__set_tv_sec(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_ts = stack[0].oval;
  
  int64_t tv_sec = stack[1].lval;
  
  struct timespec* ts = env->get_pointer(env, stack, obj_ts);
  
  ts->tv_sec = tv_sec;
  
  return 0;
}

int32_t SPVM__Sys__Time__Timespec__tv_nsec(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_ts = stack[0].oval;
  
  struct timespec* ts = env->get_pointer(env, stack, obj_ts);
  
  stack[0].lval = ts->tv_nsec;
  
  return 0;
}

int32_t SPVM__Sys__Time__Timespec__set_tv_nsec(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_ts = stack[0].oval;
  
  int64_t tv_nsec = stack[1].lval;
  
  struct timespec* ts = env->get_pointer(env, stack, obj_ts);
  
  ts->tv_nsec = tv_nsec;
  
  return 0;
}
