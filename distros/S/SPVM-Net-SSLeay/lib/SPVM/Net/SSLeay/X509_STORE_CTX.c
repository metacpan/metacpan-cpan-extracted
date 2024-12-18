// Copyright (c) 2024 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <openssl/ssl.h>
#include <openssl/err.h>

static const char* FILE_NAME = "Net/SSLeay/X509_STORE_CTX.c";

int32_t SPVM__Net__SSLeay__X509_STORE_CTX__get1_issuer(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_issuer_ref = stack[0].oval;
  
  void* obj_ctx = stack[1].oval;
  
  void* obj_x = stack[2].oval;
  
  if (!(obj_issuer_ref && env->length(env, stack, obj_issuer_ref) == 1)) {
    return env->die(env, stack, "The output array of the Net::SSLeay::X509 $issuer_ref must be a 1-length array.", __func__, FILE_NAME, __LINE__);
  }
  
  if (!obj_ctx) {
    return env->die(env, stack, "The Net::SSLeay::X509_STORE_CTX object $ctx must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  X509_STORE_CTX* ctx = env->get_pointer(env, stack, obj_ctx);
  
  if (!obj_x) {
    return env->die(env, stack, "The X509 object $x must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  X509* x = env->get_pointer(env, stack, obj_x);
  
  X509* issuer_ref_tmp[1] = {0};
  int32_t status = X509_STORE_CTX_get1_issuer(issuer_ref_tmp, ctx, x);
  
  if (!(status >= 0)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]X509_STORE_CTX_get1_issuer failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
    return error_id;
  }
  
  int32_t found = status == 1;
  
  if (found) {
    X509* issuer = issuer_ref_tmp[0];
    void* obj_address_issuer = env->new_pointer_object_by_name(env, stack, "Address", issuer, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    stack[0].oval = obj_address_issuer;
    env->call_class_method_by_name(env, stack, "Net::SSLeay::X509", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    void* obj_issuer = stack[0].oval;
    env->set_elem_object(env, stack, obj_issuer_ref, 0, obj_issuer);
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509_STORE_CTX__set_error(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  int32_t s = stack[1].ival;
  
  X509_STORE_CTX* self = env->get_pointer(env, stack, obj_self);
  
  X509_STORE_CTX_set_error(self, s);
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509_STORE_CTX__get_error(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509_STORE_CTX* self = env->get_pointer(env, stack, obj_self);
  
  int32_t error = X509_STORE_CTX_get_error(self);
  
  stack[0].ival = error;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509_STORE_CTX__get_error_depth(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509_STORE_CTX* self = env->get_pointer(env, stack, obj_self);
  
  int32_t error_depth = X509_STORE_CTX_get_error_depth(self);
  
  stack[0].ival = error_depth;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509_STORE_CTX__get_current_cert(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509_STORE_CTX* self = env->get_pointer(env, stack, obj_self);
  
  X509* x509 = X509_STORE_CTX_get_current_cert(self);
  
  void* obj_x509 = NULL;
  
  if (x509) {
    X509_up_ref(x509);
    void* obj_address_x509 = env->new_pointer_object_by_name(env, stack, "Address", x509, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    stack[0].oval = obj_address_x509;
    env->call_class_method_by_name(env, stack, "Net::SSLeay::X509", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);  
    if (error_id) { return error_id; }
    obj_x509 = stack[0].oval;
  }
  
  stack[0].oval = obj_x509;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509_STORE_CTX__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509_STORE_CTX* self = env->get_pointer(env, stack, obj_self);
  
  if (!env->no_free(env, stack, obj_self)) {
    X509_STORE_CTX_free(self);
  }
  
  return 0;
}

