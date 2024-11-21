// Copyright (c) 2024 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <openssl/bio.h>
#include <openssl/err.h>

#include <openssl/hmac.h>

static const char* FILE_NAME = "Net/SSLeay/HMAC_CTX.c";

int32_t SPVM__Net__SSLeay__HMAC_CTX__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  HMAC_CTX* pointer = env->get_pointer(env, stack, obj_self);
  
  if (!env->no_free(env, stack, obj_self)) {
    HMAC_CTX_free(pointer);
  }
  
  return 0;
}


