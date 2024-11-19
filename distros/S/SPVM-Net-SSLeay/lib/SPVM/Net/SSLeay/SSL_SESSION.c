// Copyright (c) 2024 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <openssl/ssl.h>
#include <openssl/err.h>

static const char* FILE_NAME = "Net/SSLeay/SSL_SESSION.c";

// Instance Methods
int32_t SPVM__Net__SSLeay__SSL_SESSION__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  SSL_SESSION* pointer = env->get_pointer(env, stack, obj_self);
  
  if (!env->no_free(env, stack, obj_self)) {
    SSL_SESSION_free(pointer);
  }
  
  return 0;
}

