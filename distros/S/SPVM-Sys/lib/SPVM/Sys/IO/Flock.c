#include "spvm_native.h"

#include <assert.h>
#include <fcntl.h>

const char* FILE_NAME = "Sys/IO/Flock";

int32_t SPVM__Sys__IO__Flock__new(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifdef _WIN32
  env->die(env, stack, "The \"new\" method in the class \"Sys::IO::Flock\" is not supported on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  
  int32_t e = 0;
  
  struct flock* st_flock = env->new_memory_stack(env, stack, sizeof(struct flock));

  void* obj_st_flock = env->new_pointer_by_name(env, stack, "Sys::IO::Flock", st_flock, &e, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  stack[0].oval = obj_st_flock;
  
  return 0;
#endif
}

int32_t SPVM__Sys__IO__Flock__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifdef _WIN32
  env->die(env, stack, "The \"new\" method in the class \"Sys::IO::Flock\" is not supported on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  
  void* obj_st_flock = stack[0].oval;
  
  struct flock* st_flock = env->get_pointer(env, stack, obj_st_flock);
  
  assert(st_flock);
  
  env->free_memory_stack(env, stack, st_flock);
  env->set_pointer(env, stack, obj_st_flock, NULL);
  
  return 0;
#endif
}

int32_t SPVM__Sys__IO__Flock__l_type(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifdef _WIN32
  env->die(env, stack, "The \"l_type\" method in the class \"Sys::IO::Flock\" is not supported on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  
  int32_t e = 0;
  
  void* obj_self = stack[0].oval;
  
  struct flock* st_flock = env->get_pointer(env, stack, obj_self);
  
  int16_t l_type = st_flock->l_type;
  
  stack[0].sval = l_type;
  
  return 0;
#endif
}

int32_t SPVM__Sys__IO__Flock__set_l_type(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifdef _WIN32
  env->die(env, stack, "The \"set_l_type\" method in the class \"Sys::IO::Flock\" is not supported on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  
  void* obj_self = stack[0].oval;
  
  struct flock* st_flock = env->get_pointer(env, stack, obj_self);
  
  int16_t l_type = stack[1].sval;
  st_flock->l_type = l_type;
  
  return 0;
#endif
}

int32_t SPVM__Sys__IO__Flock__l_whence(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifdef _WIN32
  env->die(env, stack, "The \"l_whence\" method in the class \"Sys::IO::Flock\" is not supported on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  
  int32_t e = 0;
  
  void* obj_self = stack[0].oval;
  
  struct flock* st_flock = env->get_pointer(env, stack, obj_self);
  
  int16_t l_whence = st_flock->l_whence;
  
  stack[0].sval = l_whence;
  
  return 0;
#endif
}

int32_t SPVM__Sys__IO__Flock__set_l_whence(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifdef _WIN32
  env->die(env, stack, "The \"set_l_whence\" method in the class \"Sys::IO::Flock\" is not supported on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  
  void* obj_self = stack[0].oval;
  
  struct flock* st_flock = env->get_pointer(env, stack, obj_self);
  
  int16_t l_whence = stack[1].sval;
  st_flock->l_whence = l_whence;
  
  return 0;
#endif
}

int32_t SPVM__Sys__IO__Flock__l_start(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifdef _WIN32
  env->die(env, stack, "The \"l_start\" method in the class \"Sys::IO::Flock\" is not supported on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  
  int32_t e = 0;
  
  void* obj_self = stack[0].oval;
  
  struct flock* st_flock = env->get_pointer(env, stack, obj_self);
  
  int64_t l_start = st_flock->l_start;
  
  stack[0].lval = l_start;
  
  return 0;
#endif
}

int32_t SPVM__Sys__IO__Flock__set_l_start(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifdef _WIN32
  env->die(env, stack, "The \"set_l_start\" method in the class \"Sys::IO::Flock\" is not supported on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  
  void* obj_self = stack[0].oval;
  
  struct flock* st_flock = env->get_pointer(env, stack, obj_self);
  
  int64_t l_start = stack[1].lval;
  st_flock->l_start = l_start;
  
  return 0;
#endif
}

int32_t SPVM__Sys__IO__Flock__l_len(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifdef _WIN32
  env->die(env, stack, "The \"l_len\" method in the class \"Sys::IO::Flock\" is not supported on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  
  int32_t e = 0;
  
  void* obj_self = stack[0].oval;
  
  struct flock* st_flock = env->get_pointer(env, stack, obj_self);
  
  int64_t l_len = st_flock->l_len;
  
  stack[0].lval = l_len;
  
  return 0;
#endif
}

int32_t SPVM__Sys__IO__Flock__set_l_len(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifdef _WIN32
  env->die(env, stack, "The \"set_l_len\" method in the class \"Sys::IO::Flock\" is not supported on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  
  void* obj_self = stack[0].oval;
  
  struct flock* st_flock = env->get_pointer(env, stack, obj_self);
  
  int64_t l_len = stack[1].lval;
  st_flock->l_len = l_len;
  
  return 0;
#endif
}

int32_t SPVM__Sys__IO__Flock__l_pid(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifdef _WIN32
  env->die(env, stack, "The \"new\" method in the class \"Sys::IO::Flock\" is not supported on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  
  int32_t e = 0;
  
  void* obj_self = stack[0].oval;
  
  struct flock* st_flock = env->get_pointer(env, stack, obj_self);
  
  int32_t l_pid = st_flock->l_pid;
  
  stack[0].ival = l_pid;
  
  return 0;
#endif
}

int32_t SPVM__Sys__IO__Flock__set_l_pid(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifdef _WIN32
  env->die(env, stack, "The \"new\" method in the class \"Sys::IO::Flock\" is not supported on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  
  void* obj_self = stack[0].oval;
  
  struct flock* st_flock = env->get_pointer(env, stack, obj_self);
  
  int32_t l_pid = stack[1].ival;
  st_flock->l_pid = l_pid;
  
  return 0;
#endif
}
