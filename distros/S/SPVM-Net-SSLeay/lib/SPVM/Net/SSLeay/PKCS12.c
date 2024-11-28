// Copyright (c) 2024 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <openssl/ssl.h>
#include <openssl/err.h>

#include <openssl/pkcs12.h>

static const char* FILE_NAME = "Net/SSLeay/PKCS12.c";

int32_t SPVM__Net__SSLeay__PKCS12__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  PKCS12* self = env->get_pointer(env, stack, obj_self);
  
  if (!env->no_free(env, stack, obj_self)) {
    PKCS12_free(self);
  }
  
  return 0;
}
