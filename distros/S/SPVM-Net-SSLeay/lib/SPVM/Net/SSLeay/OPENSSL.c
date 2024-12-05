// Copyright (c) 2024 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <openssl/ssl.h>
#include <openssl/err.h>

static const char* FILE_NAME = "Net/SSLeay/OPENSSL.c";

int32_t SPVM__Net__SSLeay__OPENSSL__add_ssl_algorithms(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  int32_t status = OpenSSL_add_ssl_algorithms();
  
  if (!(status == 1)) {
    env->die(env, stack, "[OpenSSL Error]OpenSSL_add_ssl_algorithms failed.", __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
    return error_id;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__OPENSSL__add_all_algorithms(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  OpenSSL_add_all_algorithms();
  
  return 0;
}

int32_t SPVM__Net__SSLeay__OPENSSL__init_crypto(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  int64_t opts = stack[0].lval;
  
  void* obj_settings = stack[1].oval;
  
  OPENSSL_INIT_SETTINGS* settings = NULL;
  if (obj_settings) {
    settings = env->get_pointer(env, stack, obj_settings);
  }
  
  int32_t status = OPENSSL_init_crypto(opts, settings);
  
  if (!(status == 1)) {
    env->die(env, stack, "[OpenSSL Error]OPENSSL_init_crypto failed.", __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
    return error_id;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__OPENSSL__init_ssl(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  int64_t opts = stack[0].lval;
  
  void* obj_settings = stack[1].oval;
  
  OPENSSL_INIT_SETTINGS* settings = NULL;
  if (obj_settings) {
    settings = env->get_pointer(env, stack, obj_settings);
  }
  
  int32_t status = OPENSSL_init_ssl(opts, settings);
  
  if (!(status == 1)) {
    env->die(env, stack, "[OpenSSL Error]OPENSSL_init_ssl failed.", __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
    return error_id;
  }
  
  stack[0].ival = status;
  
  return 0;
}

