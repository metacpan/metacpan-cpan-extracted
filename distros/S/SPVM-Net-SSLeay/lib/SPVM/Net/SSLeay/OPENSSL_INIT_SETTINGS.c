// Copyright (c) 2024 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <openssl/ssl.h>
#include <openssl/err.h>

static const char* FILE_NAME = "Net/SSLeay/OPENSSL_INIT_SETTINGS.c";

int32_t SPVM__Net__SSLeay__OPENSSL_INIT_SETTINGS__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  OPENSSL_INIT_SETTINGS* pointer = env->get_pointer(env, stack, obj_self);
  
  if (!env->no_free(env, stack, obj_self)) {
    OPENSSL_INIT_free(pointer);
  }
  
  return 0;
}


