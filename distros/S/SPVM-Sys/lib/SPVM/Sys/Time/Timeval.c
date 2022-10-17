#include "spvm_native.h"

#include <sys/time.h>
#include <assert.h>

static const char* FILE_NAME = "Sys/Time/Timeval.c";

int32_t SPVM__Sys__Time__Timeval__new(SPVM_ENV* env, SPVM_VALUE* stack) {

  int32_t e;
  
  struct timeval* st_tv = env->new_memory_stack(env, stack, sizeof(struct timeval));
  
  void* obj_tv = env->new_pointer_by_name(env, stack, "Sys::Time::Timeval", st_tv, &e, FILE_NAME, __LINE__);
  if (e) { return e; }

  stack[0].oval = obj_tv;
  
  return 0;
}

int32_t SPVM__Sys__Time__Timeval__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_tv = stack[0].oval;
  
  struct timeval* st_tv = env->get_pointer(env, stack, obj_tv);
  
  assert(st_tv);
  
  env->free_memory_stack(env, stack, st_tv);
  
  return 0;
}

int32_t SPVM__Sys__Time__Timeval__tv_sec(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_tv = stack[0].oval;
  
  struct timeval* st_tv = env->get_pointer(env, stack, obj_tv);
  
  stack[0].lval = st_tv->tv_sec;
  
  return 0;
}

int32_t SPVM__Sys__Time__Timeval__set_tv_sec(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_tv = stack[0].oval;
  
  int64_t tv_sec = stack[1].lval;
  
  struct timeval* st_tv = env->get_pointer(env, stack, obj_tv);
  
  st_tv->tv_sec = tv_sec;
  
  return 0;
}

int32_t SPVM__Sys__Time__Timeval__tv_usec(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_tv = stack[0].oval;
  
  struct timeval* st_tv = env->get_pointer(env, stack, obj_tv);
  
  stack[0].lval = st_tv->tv_usec;
  
  return 0;
}

int32_t SPVM__Sys__Time__Timeval__set_tv_usec(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_tv = stack[0].oval;
  
  int64_t tv_usec = stack[1].lval;
  
  struct timeval* st_tv = env->get_pointer(env, stack, obj_tv);
  
  st_tv->tv_usec = tv_usec;
  
  return 0;
}
