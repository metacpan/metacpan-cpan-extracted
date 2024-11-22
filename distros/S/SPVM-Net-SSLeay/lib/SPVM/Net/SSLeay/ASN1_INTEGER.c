// Copyright (c) 2024 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <openssl/bio.h>
#include <openssl/err.h>

#include <openssl/asn1.h>

static const char* FILE_NAME = "Net/SSLeay/ASN1_INTEGER.c";

int32_t SPVM__Net__SSLeay__ASN1_INTEGER__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  ASN1_INTEGER* pointer = env->get_pointer(env, stack, obj_self);
  
  if (!env->no_free(env, stack, obj_self)) {
    ASN1_INTEGER_free(pointer);
  }
  
  return 0;
}

