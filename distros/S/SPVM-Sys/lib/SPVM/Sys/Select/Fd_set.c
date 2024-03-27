// Copyright (c) 2023 Yuki Kimoto
// MIT License

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
  
  int32_t error_id = 0;
  
  fd_set* type_fd_set = env->new_memory_block(env, stack, sizeof(fd_set));
  
  void* obj_fd_set = env->new_pointer_object_by_name(env, stack, "Sys::Select::Fd_set", type_fd_set, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_fd_set;
  
  return 0;
}

int32_t SPVM__Sys__Select__Fd_set__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  // File handle
  void* obj_fd_set = stack[0].oval;
  
  fd_set* type_fd_set = env->get_pointer(env, stack, obj_fd_set);
  
  assert(type_fd_set);
  
  env->free_memory_block(env, stack, type_fd_set);
  env->set_pointer(env, stack, obj_fd_set, NULL);
  
  return 0;
}

int32_t SPVM__Sys__Select__Fd_set__clone(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_fd_set = stack[0].oval;
  fd_set* type_fd_set = env->get_pointer(env, stack, obj_fd_set);
  
  fd_set* type_fd_set_clone = env->new_memory_block(env, stack, sizeof(fd_set));
  
  void* obj_fd_set_clone = env->new_pointer_object_by_name(env, stack, "Sys::Select::Fd_set", type_fd_set_clone, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  memcpy(type_fd_set_clone, type_fd_set, sizeof(fd_set));
  
  stack[0].oval = obj_fd_set_clone;
  
  return 0;
}
