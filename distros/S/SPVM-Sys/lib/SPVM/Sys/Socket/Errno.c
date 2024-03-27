// Copyright (c) 2023 Yuki Kimoto
// MIT License

// Windows 8.1+
#define _WIN32_WINNT 0x0603

#include "spvm_native.h"
#include "spvm_socket_util.h"

#include <errno.h>
#include <assert.h>

static const char* FILE_NAME = "Sys/Socket.c";

int32_t SPVM__Sys__Socket__Errno__errno(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t ret_socket_errno = spvm_socket_errno();
  
  stack[0].ival = ret_socket_errno;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Errno__strerror(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_number = stack[0].ival;
  
  int32_t length = stack[1].ival;
  
  void* obj_socket_strerror = spvm_socket_strerror_string(env, stack, error_number, length);
  
  stack[0].oval = obj_socket_strerror;
  
  return 0;
}
