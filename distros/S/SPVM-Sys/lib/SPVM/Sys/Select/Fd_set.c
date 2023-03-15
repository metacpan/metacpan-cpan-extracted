#include "spvm_native.h"

// The maximum number of sockets that a Windows Sockets application can use is not affected by the manifest constant FD_SETSIZE
// See https://learn.microsoft.com/en-us/windows/win32/winsock/maximum-number-of-sockets-supported-2
#if defined(_WIN32)
  #undef FD_SETSIZE
  #define FD_SETSIZE 1024
#endif

#if defined(_WIN32)
  #include <winsock2.h>
#else
  #include <sys/select.h>
#endif

#include <assert.h>

static const char* FILE_NAME = "Sys/Select/Fd_set.c";

int32_t SPVM__Sys__Select__Fd_set__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)env;
  (void)stack;

  int32_t e;

  fd_set* type_fd_set = env->new_memory_stack(env, stack, sizeof(fd_set));
  
  void* obj_fd_set = env->new_pointer_by_name(env, stack, "Sys::Select::Fd_set", type_fd_set, &e, __func__, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  stack[0].oval = obj_fd_set;
  
  return 0;
}

int32_t SPVM__Sys__Select__Fd_set__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)env;
  (void)stack;
  
  // File handle
  void* obj_fd_set = stack[0].oval;
  
  fd_set* type_fd_set = env->get_pointer(env, stack, obj_fd_set);
  
  assert(type_fd_set);
  
  env->free_memory_stack(env, stack, type_fd_set);
  env->set_pointer(env, stack, obj_fd_set, NULL);
  
  return 0;
}

int32_t SPVM__Sys__Select__Fd_set__set(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)env;
  (void)stack;
  
  void* obj_fd_set = stack[0].oval;
  fd_set* type_fd_set = env->get_pointer(env, stack, obj_fd_set);
  
  void* obj_fd_set_arg = stack[1].oval;
  if (!obj_fd_set_arg) {
    return env->die(env, stack, "The $set must be defined", __func__, FILE_NAME, __LINE__);
  }
  fd_set* type_fd_set_arg = env->get_pointer(env, stack, obj_fd_set_arg);
  
  assert(type_fd_set);
  
  memcpy(type_fd_set, type_fd_set_arg, sizeof(fd_set));
  
  return 0;
}
