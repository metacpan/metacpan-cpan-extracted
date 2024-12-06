// Copyright (c) 2024 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <openssl/ssl.h>
#include <openssl/err.h>

static const char* FILE_NAME = "Net/SSLeay/X509_REVOKED.c";

int32_t SPVM__Net__SSLeay__X509_REVOKED__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  X509_REVOKED* self = X509_REVOKED_new();
  
  if (!self) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]X509_REVOKED_new failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
    return error_id;
  }
  
  void* obj_self = env->new_pointer_object_by_name(env, stack, "Net::SSLeay::X509_REVOKED", self, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_self;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509_REVOKED__get0_serialNumber(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509_REVOKED* self = env->get_pointer(env, stack, obj_self);
  
  const ASN1_INTEGER* ret_tmp = X509_REVOKED_get0_serialNumber(self);
  
  ASN1_INTEGER* ret = ASN1_INTEGER_dup(ret_tmp);
  
  void* obj_address_ret = env->new_pointer_object_by_name(env, stack, "Address", ret, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  stack[0].oval = obj_address_ret;
  env->call_class_method_by_name(env, stack, "Net::SSLeay::ASN1_INTEGER", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  void* obj_ret = stack[0].oval;
  
  stack[0].oval = obj_ret;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509_REVOKED__get0_revocationDate(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509_REVOKED* self = env->get_pointer(env, stack, obj_self);
  
  const ASN1_TIME* ret_tmp = X509_REVOKED_get0_revocationDate(self);
  
  ASN1_TIME* ret = ASN1_STRING_dup(ret_tmp);
  
  void* obj_address_ret = env->new_pointer_object_by_name(env, stack, "Address", ret, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  stack[0].oval = obj_address_ret;
  env->call_class_method_by_name(env, stack, "Net::SSLeay::ASN1_TIME", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  void* obj_ret = stack[0].oval;
  
  stack[0].oval = obj_ret;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509_REVOKED__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509_REVOKED* self = env->get_pointer(env, stack, obj_self);
  
  if (!env->no_free(env, stack, obj_self)) {
    X509_REVOKED_free(self);
  }
  
  return 0;
}

