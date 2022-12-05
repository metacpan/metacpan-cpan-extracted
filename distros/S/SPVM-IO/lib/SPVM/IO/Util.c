#include "spvm_native.h"

#include <errno.h>
#include <assert.h>

#include "SPVM__IO__Util.h"

static const char* FILE_NAME = "IO/Util.c";

int32_t SPVM__IO__Util__sockatmark(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifdef _WIN32
    env->die(env, stack, "[Not Supported]sockatmark is not supported on this system(_WIN32)", FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  
  int32_t sockfd = stack[0].ival;
  
  int32_t status = sockatmark(sockfd);
  
  if (status == -1) {
    env->die(env, stack, "[System Error]shutdown failed: %s", spvm_socket_strerror(env, stack, spvm_socket_errno(), 0), FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  stack[0].ival = status;
  
  return 0;
#endif
}

int32_t SPVM__IO__Util__sendto(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t sockfd = stack[0].ival;

  void* obj_buf = stack[1].oval;
  
  if (!obj_buf) {
    return env->die(env, stack, "The $buf must be defined", FILE_NAME, __LINE__);
  }
  
  const char* buf = env->get_chars(env, stack, obj_buf);
  
  int32_t len = stack[2].ival;
  
  int32_t flags = stack[3].ival;

  void* obj_addr = stack[4].oval;
  
  if (!obj_addr) {
    return env->die(env, stack, "The $addr must be defined", FILE_NAME, __LINE__);
  }
  
  const struct sockaddr* addr = env->get_pointer(env, stack, obj_addr);
  
  int32_t addrlen = stack[5].ival;

  int32_t bytes_length = sendto(sockfd, buf, len, flags, addr, addrlen);
  
  if (bytes_length == -1) {
    env->die(env, stack, "[System Error]sendto failed: %s", spvm_socket_strerror(env, stack, spvm_socket_errno(), 0), FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  stack[0].ival = bytes_length;
  
  return 0;
}

int32_t SPVM__IO__Util__SO_BROADCAST(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_BROADCAST
  stack[0].ival = SO_BROADCAST;
  return 0;
#else
  env->die(env, stack, "SO_BROADCAST is not defined on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__IO__Util__IPPROTO_ICMP(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IPPROTO_ICMP
  stack[0].ival = IPPROTO_ICMP;
  return 0;
#else
  env->die(env, stack, "IPPROTO_ICMP is not defined on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}
