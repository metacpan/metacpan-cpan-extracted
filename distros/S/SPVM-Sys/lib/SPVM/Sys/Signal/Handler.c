// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <unistd.h>
#include <sys/types.h>
#include <errno.h>
#include <signal.h>
#include <stdlib.h>
#include <assert.h>

static const char* FILE_NAME = "Sys/Signal/Handler.c";

int32_t SPVM__Sys__Signal__Handler__eq(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_handler1 = stack[0].oval;
  
  if (!obj_handler1) {
    return env->die(env, stack, "$handler1 must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  void* obj_handler2 = stack[1].oval;
  
  if (!obj_handler2) {
    return env->die(env, stack, "$handler2 must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  void* handler1 = env->get_pointer(env, stack, obj_handler1);
  
  void* handler2 = env->get_pointer(env, stack, obj_handler2);
  
  int32_t equals = 0;
  if (handler1 == handler2) {
    equals = 1;
  }
  
  stack[0].ival = equals;
  
  return 0;
}

