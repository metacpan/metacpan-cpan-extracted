// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <openssl/ssl.h>
#include <openssl/err.h>

static const char* FILE_NAME = "Net/SSLeay/PEM.c";

int32_t SPVM__Net__SSLeay__PEM__read_bio_X509(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_bp = stack[0].oval;
  
  if (!obj_bp) {
    return env->die(env, stack, "The BIO $bp must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  BIO* bp = env->get_pointer(env, stack, obj_bp);
  
  X509* x509 = PEM_read_bio_X509(bp, NULL, 0, NULL);
  
  if (!x509) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]PEM_read_bio_X509 failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  void* obj_address_x509 = env->new_pointer_object_by_name(env, stack, "Address", x509, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  stack[0].oval = obj_address_x509;
  env->call_class_method_by_name(env, stack, "Net::SSLeay::X509", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);  
  if (error_id) { return error_id; }
  void* obj_x509 = stack[0].oval;
  
  stack[0].oval = obj_x509;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__PEM__read_bio_X509_CRL(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_bp = stack[0].oval;
  
  if (!obj_bp) {
    return env->die(env, stack, "The BIO $bp must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  BIO* bp = env->get_pointer(env, stack, obj_bp);
  
  X509_CRL* x509_crl = PEM_read_bio_X509_CRL(bp, NULL, 0, NULL);
  
  if (!x509_crl) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]PEM_read_bio_X509_CRL failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  void* obj_address_x509_crl = env->new_pointer_object_by_name(env, stack, "Address", x509_crl, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  stack[0].oval = obj_address_x509_crl;
  env->call_class_method_by_name(env, stack, "Net::SSLeay::X509_CRL", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  void* obj_x509_crl = stack[0].oval;
  
  stack[0].oval = obj_x509_crl;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__PEM__read_bio_DHparams(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_bp = stack[0].oval;
  
  if (!obj_bp) {
    return env->die(env, stack, "The BIO $bp must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  BIO* bp = env->get_pointer(env, stack, obj_bp);
  
  DH* dh = PEM_read_bio_DHparams(bp, NULL, NULL, NULL);
  
  if (!dh) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]PEM_read_bio_DHparams failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  void* obj_address_dh = env->new_pointer_object_by_name(env, stack, "Address", dh, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  stack[0].oval = obj_address_dh;
  env->call_class_method_by_name(env, stack, "Net::SSLeay::DH", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  void* obj_dh = stack[0].oval;
  
  stack[0].oval = obj_dh;
  
  return 0;
}
