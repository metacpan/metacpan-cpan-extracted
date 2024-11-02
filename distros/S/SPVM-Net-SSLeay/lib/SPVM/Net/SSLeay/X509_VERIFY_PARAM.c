// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <openssl/ssl.h>

static const char* FILE_NAME = "Net/SSLeay/X509_VERIFY_PARAM.c";

int32_t SPVM__Net__SSLeay__X509_VERIFY_PARAM__set_hostflags(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  int32_t flags = stack[1].ival;
  
  X509_VERIFY_PARAM* x509_verify_param = env->get_pointer(env, stack, obj_self);
  
  X509_VERIFY_PARAM_set_hostflags(x509_verify_param, flags);
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509_VERIFY_PARAM__set1_host(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_name = stack[1].oval;
  
  if (!obj_name) {
    return env->die(env, stack, "The $name must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  int32_t namelen = stack[2].ival;
  
  int32_t name_length = env->length(env, stack, obj_name);
    
  if (namelen == 0) {
    namelen = name_length;
  }
  
  if (!(namelen <= name_length)) {
    return env->die(env, stack, "The $namelen must be greater than or equal to the length of the $name.", __func__, FILE_NAME, __LINE__);
  }
  
  const char* name = env->get_chars(env, stack, obj_name);
  
  X509_VERIFY_PARAM* x509_verify_param = env->get_pointer(env, stack, obj_self);
  
  X509_VERIFY_PARAM_set1_host(x509_verify_param, name, namelen);
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509_VERIFY_PARAM__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509_VERIFY_PARAM* x509_verify_param = env->get_pointer(env, stack, obj_self);
  
  if (!env->no_free(env, stack, obj_self)) {
    X509_VERIFY_PARAM_free(x509_verify_param);
  }
  
  return 0;
}
