// Copyright (c) 2023 Yuki Kimoto
// MIT License

// Windows 8.1+
#define _WIN32_WINNT 0x0603

#include "spvm_native.h"

#if defined(_WIN32)
  #include <winsock2.h>
#else
  #include <poll.h>
#endif

static const char* FILE_NAME = "Sys/Poll/Constant.c";

int32_t SPVM__Sys__Poll__Constant__POLLERR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef POLLERR
  stack[0].ival = POLLERR;
  return 0;
#else
  env->die(env, stack, "POLLERR is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Sys__Poll__Constant__POLLHUP(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef POLLHUP
  stack[0].ival = POLLHUP;
  return 0;
#else
  env->die(env, stack, "POLLHUP is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Sys__Poll__Constant__POLLIN(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef POLLIN
  stack[0].ival = POLLIN;
  return 0;
#else
  env->die(env, stack, "POLLIN is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Sys__Poll__Constant__POLLNORM(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef POLLNORM
  stack[0].ival = POLLNORM;
  return 0;
#else
  env->die(env, stack, "POLLNORM is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Sys__Poll__Constant__POLLNVAL(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef POLLNVAL
  stack[0].ival = POLLNVAL;
  return 0;
#else
  env->die(env, stack, "POLLNVAL is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Sys__Poll__Constant__POLLOUT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef POLLOUT
  stack[0].ival = POLLOUT;
  return 0;
#else
  env->die(env, stack, "POLLOUT is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Sys__Poll__Constant__POLLPRI(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef POLLPRI
  stack[0].ival = POLLPRI;
  return 0;
#else
  env->die(env, stack, "POLLPRI is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Sys__Poll__Constant__POLLRDBAND(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef POLLRDBAND
  stack[0].ival = POLLRDBAND;
  return 0;
#else
  env->die(env, stack, "POLLRDBAND is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Sys__Poll__Constant__POLLRDNORM(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef POLLRDNORM
  stack[0].ival = POLLRDNORM;
  return 0;
#else
  env->die(env, stack, "POLLRDNORM is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Sys__Poll__Constant__POLLWRBAND(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef POLLWRBAND
  stack[0].ival = POLLWRBAND;
  return 0;
#else
  env->die(env, stack, "POLLWRBAND is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Sys__Poll__Constant__POLLWRNORM(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef POLLWRNORM
  stack[0].ival = POLLWRNORM;
  return 0;
#else
  env->die(env, stack, "POLLWRNORM is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

