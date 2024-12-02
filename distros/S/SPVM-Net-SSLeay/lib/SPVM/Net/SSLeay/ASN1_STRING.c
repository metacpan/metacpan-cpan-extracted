// Copyright (c) 2024 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <openssl/ssl.h>
#include <openssl/err.h>

static const char* FILE_NAME = "Net/SSLeay/ASN1_STRING.c";

int32_t SPVM__Net__SSLeay__ASN1_STRING__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  ASN1_STRING* self = ASN1_STRING_new();
  
  if (!self) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]ASN1_STRING_new failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
    return error_id;
  }
  
  void* obj_self = env->new_pointer_object_by_name(env, stack, "Net::SSLeay::ASN1_STRING", self, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_self;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__ASN1_STRING__length(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  ASN1_STRING* self = env->get_pointer(env, stack, obj_self);
  
  int32_t length = ASN1_STRING_length(self);
  
  stack[0].ival = length;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__ASN1_STRING__get0_data(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  ASN1_STRING* self = env->get_pointer(env, stack, obj_self);
  
  const unsigned char* string = ASN1_STRING_get0_data(self);
  
  int32_t length = ASN1_STRING_length(self);
  
  void* obj_string = env->new_string(env, stack, string, length);
  
  stack[0].oval = obj_string;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__ASN1_STRING__set(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_data = stack[1].oval;
  
  int32_t len = stack[2].ival;
  
  if (!obj_data) {
    return env->die(env, stack, "The data $data must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  const void* data = (const void*)env->get_chars(env, stack, obj_data);
  
  ASN1_STRING* self = env->get_pointer(env, stack, obj_self);
  
  int32_t status = ASN1_STRING_set(self, data, len);
  
  if (!(status == 1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]ASN1_STRING_set failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
    return error_id;
  }
  
  return 0;
}

int32_t SPVM__Net__SSLeay__ASN1_STRING__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  ASN1_STRING* self = env->get_pointer(env, stack, obj_self);
  
  if (!env->no_free(env, stack, obj_self)) {
    ASN1_STRING_free(self);
  }
  
  return 0;
}

