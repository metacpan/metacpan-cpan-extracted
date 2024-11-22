// Copyright (c) 2024 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <openssl/bio.h>
#include <openssl/err.h>

#include <openssl/evp.h>

static const char* FILE_NAME = "Net/SSLeay/EVP_CIPHER_CTX.c";

int32_t SPVM__Net__SSLeay__EVP_CIPHER_CTX__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  EVP_CIPHER_CTX* pointer = env->get_pointer(env, stack, obj_self);
  
  if (!env->no_free(env, stack, obj_self)) {
    EVP_CIPHER_CTX_free(pointer);
  }
  
  return 0;
}


