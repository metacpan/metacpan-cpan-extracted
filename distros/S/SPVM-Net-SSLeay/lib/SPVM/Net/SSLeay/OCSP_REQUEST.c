// Copyright (c) 2024 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <openssl/ssl.h>
#include <openssl/err.h>

#include <openssl/ocsp.h>

static const char* FILE_NAME = "Net/SSLeay/OCSP_REQUEST.c";

int32_t SPVM__Net__SSLeay__OCSP_REQUEST__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  OCSP_REQUEST* pointer = OCSP_REQUEST_new();
  
  if (!pointer) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]OCSP_REQUEST_new failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  void* obj_address_pointer = env->new_pointer_object_by_name(env, stack, "Address", pointer, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  stack[0].oval = obj_address_pointer;
  env->call_class_method_by_name(env, stack, "Net::SSLeay::OCSP_REQUEST", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  void* obj_self = stack[0].oval;
  
  stack[0].oval = obj_self;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__OCSP_REQUEST__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  OCSP_REQUEST* pointer = env->get_pointer(env, stack, obj_self);
  
  if (!env->no_free(env, stack, obj_self)) {
    OCSP_REQUEST_free(pointer);
  }
  
  return 0;
}

