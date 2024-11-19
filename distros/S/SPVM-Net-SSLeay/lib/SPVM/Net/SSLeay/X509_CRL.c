// Copyright (c) 2024 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <openssl/ssl.h>

static const char* FILE_NAME = "Net/SSLeay/X509_CRL.c";

int32_t SPVM__Net__SSLeay__X509_CRL__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509_CRL* pointer = env->get_pointer(env, stack, obj_self);
  
  if (!env->no_free(env, stack, obj_self)) {
    X509_CRL_free(pointer);
  }
  
  return 0;
}

