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
  #include <winerror.h>
#else
  #include <sys/select.h>
#endif

#include <errno.h>

const char* FILE_NAME = "Sys/Select.c";

// static functions are copied from Sys/Socket.c
static int32_t socket_errno (void) {
#if defined(_WIN32)
  return WSAGetLastError();
#else
  return errno;
#endif
}

#if defined(_WIN32)
static void* socket_strerror_string_win (SPVM_ENV* env, SPVM_VALUE* stack, int32_t error_number, int32_t length) {
  char* error_message = NULL;
  FormatMessageA(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS, 
                 NULL, error_number,
                 MAKELANGID(LANG_ENGLISH, SUBLANG_ENGLISH_US),
                 (LPSTR)&error_message, length, NULL);
  
  void* obj_error_message = env->new_string(env, stack, error_message, strlen(error_message));
  
  LocalFree(error_message);
  
  return obj_error_message;
}
#endif

static void* socket_strerror_string (SPVM_ENV* env, SPVM_VALUE* stack, int32_t error_number, int32_t length) {
  void*
#if defined(_WIN32)
  obj_strerror_value = socket_strerror_string_win(env, stack, error_number, length);
#else
  obj_strerror_value = env->strerror_string(env, stack, error_number, length);
#endif
  return obj_strerror_value;
}


static const char* socket_strerror(SPVM_ENV* env, SPVM_VALUE* stack, int32_t error_number, int32_t length) {
  void* obj_socket_strerror = socket_strerror_string(env, stack, error_number, length);
  
  const char* ret_socket_strerror = NULL;
  if (obj_socket_strerror) {
    ret_socket_strerror = env->get_chars(env, stack, obj_socket_strerror);
  }
  
  return ret_socket_strerror;
}

int32_t SPVM__Sys__Select__FD_ZERO(SPVM_ENV* env, SPVM_VALUE* stack) {

  void* obj_set = stack[0].oval;

  fd_set* set = env->get_pointer(env, stack, obj_set);

  FD_ZERO(set);

  return 0;
}

int32_t SPVM__Sys__Select__FD_SET(SPVM_ENV* env, SPVM_VALUE* stack) {

  int32_t fd = stack[0].ival;

  if (!(fd >= 0)) {
    return env->die(env, stack, "The $fd must be greater than or equal to 0", __func__, FILE_NAME, __LINE__);
  }

  if (!(fd < FD_SETSIZE)) {
    return env->die(env, stack, "The $fd must be less than FD_SETSIZE", __func__, FILE_NAME, __LINE__);
  }

  void* obj_set = stack[1].oval;

  if (!obj_set) {
    return env->die(env, stack, "The $set must be defined", __func__, FILE_NAME, __LINE__);
  }

  fd_set* set = env->get_pointer(env, stack, obj_set);

  FD_SET(fd, set);

  return 0;
}

int32_t SPVM__Sys__Select__FD_CLR(SPVM_ENV* env, SPVM_VALUE* stack) {

  int32_t fd = stack[0].ival;

  if (!(fd >= 0)) {
    return env->die(env, stack, "The $fd must be greater than or equal to 0", __func__, FILE_NAME, __LINE__);
  }

  if (!(fd < FD_SETSIZE)) {
    return env->die(env, stack, "The $fd must be less than FD_SETSIZE", __func__, FILE_NAME, __LINE__);
  }

  void* obj_set = stack[1].oval;

  if (!obj_set) {
    return env->die(env, stack, "The $set must be defined", __func__, FILE_NAME, __LINE__);
  }

  fd_set* set = env->get_pointer(env, stack, obj_set);

  FD_CLR(fd, set);

  return 0;
}

int32_t SPVM__Sys__Select__FD_ISSET(SPVM_ENV* env, SPVM_VALUE* stack) {

  int32_t fd = stack[0].ival;

  if (!(fd >= 0)) {
    return env->die(env, stack, "The $fd must be greater than or equal to 0", __func__, FILE_NAME, __LINE__);
  }

  if (!(fd < FD_SETSIZE)) {
    return env->die(env, stack, "The $fd must be less than FD_SETSIZE", __func__, FILE_NAME, __LINE__);
  }

  void* obj_set = stack[1].oval;

  if (!obj_set) {
    return env->die(env, stack, "The $set must be defined", __func__, FILE_NAME, __LINE__);
  }

  fd_set* set = env->get_pointer(env, stack, obj_set);

  int32_t isset = FD_ISSET(fd, set);

  stack[0].ival = isset;

  return 0;
}

int32_t SPVM__Sys__Select__select(SPVM_ENV* env, SPVM_VALUE* stack) {

  int32_t fd = stack[0].ival;
  if (!(fd >= 0)) {
    return env->die(env, stack, "The $fd must be greater than or equal to 0", __func__, FILE_NAME, __LINE__);
  }
  if (!(fd < FD_SETSIZE)) {
    return env->die(env, stack, "The $fd must be less than FD_SETSIZE", __func__, FILE_NAME, __LINE__);
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
    env->die(env, stack, "[System Error]select failed: %s", socket_strerror(env, stack, socket_errno(), 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }

  stack[0].ival = updated_fds_count;
  
  return 0;
}
