// Copyright (c) 2023 Yuki Kimoto
// MIT License

// Windows 8.1+
#define _WIN32_WINNT 0x0603

#include "spvm_native.h"

#if defined(_WIN32)
  #include <winsock2.h>
  #include <winerror.h>
#else
  #include <poll.h>
#endif

#include <errno.h>

const char* FILE_NAME = "Sys/Poll.c";

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

int32_t SPVM__Sys__Poll__poll(SPVM_ENV* env, SPVM_VALUE* stack) {
  void* obj_fds = stack[0].oval;
  
  struct pollfd* fds = env->get_pointer(env, stack, obj_fds);
  
  int32_t nfds = stack[1].ival;
  
  int32_t timeout = stack[2].ival;
  
#if defined(_WIN32)
  int32_t ready_count = WSAPoll(fds, nfds, timeout);
#else
  int32_t ready_count = poll(fds, nfds, timeout);
#endif

  if (ready_count == -1) {
    env->die(env, stack, "[System Error]poll failed: %s", socket_strerror(env, stack, socket_errno(), 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  stack[0].ival = ready_count;
  
  return 0;
}
