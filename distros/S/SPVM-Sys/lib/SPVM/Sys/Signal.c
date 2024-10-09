// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <unistd.h>
#include <sys/types.h>
#include <errno.h>
#include <signal.h>
#include <stdlib.h>
#include <assert.h>
#include <stdio.h>

static const char* FILE_NAME = "Sys/Signal.c";

int32_t SPVM__Sys__Signal__kill(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "Sys::Signal#kill method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  
  int32_t pid = stack[0].ival;
  int32_t sig = stack[1].ival;
  
  int32_t status = kill(pid, sig);
  if (status == -1) {
    env->die(env, stack, "[System Error]kill() failed:%s.", env->strerror_nolen(env, stack, errno), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Signal__raise(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t sig = stack[0].ival;
  
  int32_t status = raise(sig);
  if (status != 0) {
    env->die(env, stack, "[System Error]raise() failed:%s.", env->strerror_nolen(env, stack, errno), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__Signal__alarm(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "Sys::Signal#alarm method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  
  int32_t seconds = stack[0].ival;
  
  int32_t rest_time = alarm(seconds);
  
  stack[0].ival = rest_time;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Signal__ualarm(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "Sys::Signal#ualarm method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  
  int32_t usecs = stack[0].ival;
  
  int32_t interval = stack[1].ival;
  
  int32_t rest_usecs = ualarm(usecs, interval);
  
  if (rest_usecs == -1) {
    env->die(env, stack, "[System Error]ualarm() failed:%s.", env->strerror_nolen(env, stack, errno), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = rest_usecs;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Signal__SIG_DFL(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_handler = env->new_pointer_object_by_name(env, stack, "Sys::Signal::Handler", SIG_DFL, &error_id, __func__, __FILE__, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_handler;
  
  return 0;
}

int32_t SPVM__Sys__Signal__SIG_IGN(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_handler = env->new_pointer_object_by_name(env, stack, "Sys::Signal::Handler", SIG_IGN, &error_id, __func__, __FILE__, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_handler;
  
  return 0;
}

int32_t SPVM__Sys__Signal__signal(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  int32_t signum = stack[0].ival;
  
  void* obj_handler = stack[1].oval;
  
  if (!obj_handler) {
    return env->die(env, stack, "The handler $handler must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  void* handler = env->get_pointer(env, stack, obj_handler);
  
  void* old_handler = signal(signum, handler);
  
  if (old_handler == SIG_ERR) {
    env->die(env, stack, "[System Error]signal() failed:%s.", env->strerror_nolen(env, stack, errno), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  void* obj_old_handler = env->new_pointer_object_by_name(env, stack, "Sys::Signal::Handler", old_handler, &error_id, __func__, __FILE__, __LINE__);  
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_old_handler;
  
  return 0;
}

static int32_t SIG_GO_WRITE_FD = -1;

static void signal_hander_go(int32_t signal) {
  
  int32_t write_length = write(SIG_GO_WRITE_FD, &signal, sizeof(int32_t));
}

int32_t SPVM__Sys__Signal__SET_SIG_GO_WRITE_FD(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  SIG_GO_WRITE_FD = stack[0].ival;
  
  return 0;
}

int32_t SPVM__Sys__Signal__SIG_GO(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_handler = env->new_pointer_object_by_name(env, stack, "Sys::Signal::Handler", &signal_hander_go, &error_id, __func__, __FILE__, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_handler;
  
  return 0;
}

