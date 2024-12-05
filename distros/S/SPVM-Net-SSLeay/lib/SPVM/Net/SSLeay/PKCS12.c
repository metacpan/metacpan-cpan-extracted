// Copyright (c) 2024 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <openssl/ssl.h>
#include <openssl/err.h>

#include <openssl/pkcs12.h>

static const char* FILE_NAME = "Net/SSLeay/PKCS12.c";

int32_t SPVM__Net__SSLeay__PKCS12__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  PKCS12* self = PKCS12_new();
  
  if (!self) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]PKCS12_new failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
    return error_id;
  }
  
  void* obj_self = env->new_pointer_object_by_name(env, stack, "Net::SSLeay::PKCS12", self, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_self;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__PKCS12__parse(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_pass = stack[1].oval;
  
  void* obj_pkey_ref = stack[2].oval;
  
  void* obj_cert_ref = stack[3].oval;
  
  void* obj_cas_ref = stack[4].oval;
  
  PKCS12* self = env->get_pointer(env, stack, obj_self);
  
  const char* pass = NULL;
  if (obj_pass) {
    pass = env->get_chars(env, stack, obj_pass);
  }
  
  if (!(obj_pkey_ref && env->length(env, stack, obj_pkey_ref) == 1)) {
    return env->die(env, stack, "The 1-length array $pkey_ref for output for a private key must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  if (!(obj_cert_ref && env->length(env, stack, obj_cert_ref) == 1)) {
    return env->die(env, stack, "The 1-length array $cert_ref for output for a certificate must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  if (obj_cas_ref) {
    if (!env->length(env, stack, obj_cas_ref) == 1) {
      return env->die(env, stack, "The 1-length array $cas_ref for output for intermediate certificate must be defined if defined.", __func__, FILE_NAME, __LINE__);
    }
  }
  
  EVP_PKEY* pkey_tmp = NULL;
  X509* cert_tmp = NULL;
  STACK_OF(X509)* stack_of_cas_tmp = NULL;
  
  int32_t status = PKCS12_parse(self, pass, &pkey_tmp, &cert_tmp, &stack_of_cas_tmp);
  
  if (!(status == 1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL ErrorPKCS12_parse failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
    return error_id;
  }
  
  void* obj_pkey = NULL;
  if (pkey_tmp) {
    EVP_PKEY_up_ref(pkey_tmp);
    
    void* obj_address_pkey = env->new_pointer_object_by_name(env, stack, "Address", pkey_tmp, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    stack[0].oval = obj_address_pkey;
    env->call_class_method_by_name(env, stack, "Net::SSLeay::EVP_PKEY", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    obj_pkey = stack[0].oval;
  }
  env->set_elem_object(env, stack, obj_pkey_ref, 0, obj_pkey);
  
  void* obj_cert = NULL;
  if (cert_tmp) {
    X509_up_ref(cert_tmp);
    
    void* obj_address_cert = env->new_pointer_object_by_name(env, stack, "Address", cert_tmp, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    stack[0].oval = obj_address_cert;
    env->call_class_method_by_name(env, stack, "Net::SSLeay::X509", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    obj_cert = stack[0].oval;
  }
  env->set_elem_object(env, stack, obj_cert_ref, 0, obj_cert);
  
  void* obj_cas = NULL;
  if (obj_cas_ref) {
    if (stack_of_cas_tmp) {
      int32_t length = sk_X509_num(stack_of_cas_tmp);
      obj_cas = env->new_object_array_by_name(env, stack, "Net::SSLeay::X509", length, &error_id, __func__, FILE_NAME, __LINE__);
      
      for (int32_t i = 0; i < length; i++) {
        X509* ca = sk_X509_value(stack_of_cas_tmp, i);
        X509_up_ref(ca);
        
        void* obj_address_ca = env->new_pointer_object_by_name(env, stack, "Address", ca, &error_id, __func__, FILE_NAME, __LINE__);
        if (error_id) { return error_id; }
        stack[0].oval = obj_address_ca;
        env->call_class_method_by_name(env, stack, "Net::SSLeay::X509", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);
        if (error_id) { return error_id; }
        void* obj_ca = stack[0].oval;
        
        env->set_elem_object(env, stack, obj_cas, i, obj_ca);
      }
    }
    else {
      obj_cas = env->new_object_array_by_name(env, stack, "Net::SSLeay::X509", 0, &error_id, __func__, FILE_NAME, __LINE__);
    }
    
    env->set_elem_object(env, stack, obj_cas_ref, 0, obj_cas);
  }
  
  return 0;
}

int32_t SPVM__Net__SSLeay__PKCS12__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  PKCS12* self = env->get_pointer(env, stack, obj_self);
  
  if (!env->no_free(env, stack, obj_self)) {
    PKCS12_free(self);
  }
  
  return 0;
}
