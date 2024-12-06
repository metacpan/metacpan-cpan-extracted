// Copyright (c) 2024 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <assert.h>

#include <openssl/ssl.h>
#include <openssl/err.h>

static const char* FILE_NAME = "Net/SSLeay/X509_CRL.c";

int32_t SPVM__Net__SSLeay__X509_CRL__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  X509_CRL* self = X509_CRL_new();
  
  if (!self) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]X509_CRL_new failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
    return error_id;
  }
  
  void* obj_self = env->new_pointer_object_by_name(env, stack, "Net::SSLeay::X509_CRL", self, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_self;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509_CRL__get_REVOKED(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509_CRL* self = env->get_pointer(env, stack, obj_self);
  
  STACK_OF(X509_REVOKED)* stack_of_x509_revokeds = X509_CRL_get_REVOKED(self);
  
  assert(stack_of_x509_revokeds);
  
  int32_t length = sk_X509_REVOKED_num(stack_of_x509_revokeds);
  
  void* obj_x509_revokeds = env->new_object_array_by_name(env, stack, "Net::SSLeay::X509_REVOKED", length, &error_id, __func__, FILE_NAME, __LINE__);
  
  for (int32_t i = 0; i < length; i++) {
    X509_REVOKED* x509_revoked_tmp = sk_X509_REVOKED_value(stack_of_x509_revokeds, i);
    
    X509_REVOKED* x509_revoked = X509_REVOKED_dup(x509_revoked_tmp);
    
    void* obj_address_x509_revoked = env->new_pointer_object_by_name(env, stack, "Address", x509_revoked, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    stack[0].oval = obj_address_x509_revoked;
    env->call_class_method_by_name(env, stack, "Net::SSLeay::X509_REVOKED", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    void* obj_x509_revoked = stack[0].oval;
    
    env->set_elem_object(env, stack, obj_x509_revokeds, i, obj_x509_revoked);
  }
  
  stack[0].oval = obj_x509_revokeds;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509_CRL__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509_CRL* self = env->get_pointer(env, stack, obj_self);
  
  if (!env->no_free(env, stack, obj_self)) {
    X509_CRL_free(self);
  }
  
  return 0;
}

