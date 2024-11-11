// Copyright (c) 2024 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <openssl/ssl.h>

static const char* FILE_NAME = "Net/SSLeay/X509_STORE_CTX.c";

// Instance Methods
int32_t SPVM__Net__SSLeay__X509_STORE_CTX__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509_STORE_CTX* x509_store_ctx = env->get_pointer(env, stack, obj_self);
  
  if (!env->no_free(env, stack, obj_self)) {
    X509_STORE_CTX_free(x509_store_ctx);
  }
  
  return 0;
}
