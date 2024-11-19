// Copyright (c) 2024 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <openssl/ssl.h>
#include <openssl/err.h>

#include <openssl/ocsp.h>

static const char* FILE_NAME = "Net/SSLeay/OCSP_ONEREQ.c";

int32_t SPVM__Net__SSLeay__OCSP_ONEREQ__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  OCSP_ONEREQ* pointer = env->get_pointer(env, stack, obj_self);
  
  if (!env->no_free(env, stack, obj_self)) {
    OCSP_ONEREQ_free(pointer);
  }
  
  return 0;
}

