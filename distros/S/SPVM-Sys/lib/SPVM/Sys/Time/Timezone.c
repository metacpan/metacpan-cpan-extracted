// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <sys/time.h>
#include <assert.h>

static const char* FILE_NAME = "Sys/Time/Timezone.c";

int32_t SPVM__Sys__Time__Timezone__new(SPVM_ENV* env, SPVM_VALUE* stack) {

  int32_t error_id = 0;
  
  struct timezone* st_tz = env->new_memory_block(env, stack, sizeof(struct timezone));
  
  void* obj_tz = env->new_pointer_object_by_name(env, stack, "Sys::Time::Timezone", st_tz, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_tz;
  
  return 0;
}

int32_t SPVM__Sys__Time__Timezone__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_tz = stack[0].oval;
  
  struct timezone* st_tz = env->get_pointer(env, stack, obj_tz);
  
  assert(st_tz);
  
  env->free_memory_block(env, stack, st_tz);
  
  return 0;
}

int32_t SPVM__Sys__Time__Timezone__tz_minuteswest(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_tz = stack[0].oval;
  
  struct timezone* st_tz = env->get_pointer(env, stack, obj_tz);
  
  stack[0].ival = st_tz->tz_minuteswest;
  
  return 0;
}

int32_t SPVM__Sys__Time__Timezone__set_tz_minuteswest(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_tz = stack[0].oval;
  
  int32_t tz_minuteswest = stack[1].ival;
  
  struct timezone* st_tz = env->get_pointer(env, stack, obj_tz);
  
  st_tz->tz_minuteswest = tz_minuteswest;
  
  return 0;
}

int32_t SPVM__Sys__Time__Timezone__tz_dsttime(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_tz = stack[0].oval;
  
  struct timezone* st_tz = env->get_pointer(env, stack, obj_tz);
  
  stack[0].ival = st_tz->tz_dsttime;
  
  return 0;
}

int32_t SPVM__Sys__Time__Timezone__set_tz_dsttime(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_tz = stack[0].oval;
  
  int32_t tz_dsttime = stack[1].ival;
  
  struct timezone* st_tz = env->get_pointer(env, stack, obj_tz);
  
  st_tz->tz_dsttime = tz_dsttime;
  
  return 0;
}
