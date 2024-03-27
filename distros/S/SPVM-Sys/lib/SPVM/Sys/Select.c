// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include "spvm_socket_util.h"

// The maximum number of sockets that a Windows Sockets application can use is not affected by the manifest constant FD_SETSIZE
// See https://learn.microsoft.com/en-us/windows/win32/winsock/maximum-number-of-sockets-supported-2
#if defined(_WIN32)
  #undef FD_SETSIZE
  #define FD_SETSIZE 1024
#endif

#if defined(_WIN32)
  #include <winsock2.h>
  #include <winerror.h>
#else
  #include <sys/select.h>
#endif

#include <errno.h>

static const char* FILE_NAME = "Sys/Select.c";

int32_t SPVM__Sys__Select__FD_ZERO(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_set = stack[0].oval;
  
  if (!obj_set) {
    return env->die(env, stack, "$set must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  fd_set* set = env->get_pointer(env, stack, obj_set);
  
  FD_ZERO(set);
  
  return 0;
}

int32_t SPVM__Sys__Select__FD_SET(SPVM_ENV* env, SPVM_VALUE* stack) {
 
  int32_t fd = stack[0].ival;
  
  if (!(fd >= 0)) {
    return env->die(env, stack, "$fd must be greater than or equal to 0.", __func__, FILE_NAME, __LINE__);
  }
  
  if (!(fd <= FD_SETSIZE)) {
    return env->die(env, stack, "$fd must be less than FD_SETSIZE.", __func__, FILE_NAME, __LINE__);
  }
  
  void* obj_set = stack[1].oval;
  
  if (!obj_set) {
    return env->die(env, stack, "$set must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  fd_set* set = env->get_pointer(env, stack, obj_set);
  
  FD_SET(fd, set);
  
  return 0;
}

int32_t SPVM__Sys__Select__FD_CLR(SPVM_ENV* env, SPVM_VALUE* stack) {

  int32_t fd = stack[0].ival;
  
  if (!(fd >= 0)) {
    return env->die(env, stack, "$fd must be greater than or equal to 0.", __func__, FILE_NAME, __LINE__);
  }
  
  if (!(fd <= FD_SETSIZE)) {
    return env->die(env, stack, "$fd must be less than FD_SETSIZE.", __func__, FILE_NAME, __LINE__);
  }
  
  void* obj_set = stack[1].oval;
  
  if (!obj_set) {
    return env->die(env, stack, "$set must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  fd_set* set = env->get_pointer(env, stack, obj_set);
  
  FD_CLR(fd, set);
  
  return 0;
}

int32_t SPVM__Sys__Select__FD_ISSET(SPVM_ENV* env, SPVM_VALUE* stack) {

  int32_t fd = stack[0].ival;
  
  if (!(fd >= 0)) {
    return env->die(env, stack, "$fd must be greater than or equal to 0.", __func__, FILE_NAME, __LINE__);
  }
  
  if (!(fd <= FD_SETSIZE)) {
    return env->die(env, stack, "$fd must be less than FD_SETSIZE.", __func__, FILE_NAME, __LINE__);
  }
  
  void* obj_set = stack[1].oval;
  
  if (!obj_set) {
    return env->die(env, stack, "$set must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  fd_set* set = env->get_pointer(env, stack, obj_set);
  
  int32_t isset = FD_ISSET(fd, set);
  
  stack[0].ival = isset;
  
  return 0;
}

int32_t SPVM__Sys__Select__select(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t fd = stack[0].ival;
  if (!(fd >= 0)) {
    return env->die(env, stack, "$fd must be greater than or equal to 0.", __func__, FILE_NAME, __LINE__);
  }
  if (!(fd <= FD_SETSIZE)) {
    return env->die(env, stack, "$fd must be less than FD_SETSIZE.", __func__, FILE_NAME, __LINE__);
  }
  
  void* obj_readfds = stack[1].oval;
  fd_set* readfds = NULL;
  if (obj_readfds) {
    readfds = env->get_pointer(env, stack, obj_readfds);
  }
  
  void* obj_writefds = stack[2].oval;
  fd_set* writefds = NULL;
  if (obj_writefds) {
    writefds = env->get_pointer(env, stack, obj_writefds);
  }
  
  void* obj_exceptfds = stack[3].oval;
  fd_set* exceptfds = NULL;
  if (obj_exceptfds) {
    exceptfds = env->get_pointer(env, stack, obj_exceptfds);
  }
  
  void* obj_timeout = stack[4].oval;
  struct timeval* timeout = NULL;
  if (obj_timeout) {
    timeout = env->get_pointer(env, stack, obj_timeout);
  }
  
  int32_t updated_fds_count = select(fd, readfds, writefds, exceptfds, timeout);
  
  if (updated_fds_count == -1) {
    env->die(env, stack, "[System Error]select failed: %s", spvm_socket_strerror(env, stack, spvm_socket_errno(), 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = updated_fds_count;
  
  return 0;
}
