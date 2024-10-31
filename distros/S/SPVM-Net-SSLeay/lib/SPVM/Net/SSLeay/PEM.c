// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <openssl/ssl.h>

static const char* FILE_NAME = "Net/SSLeay/PEM.c";

int32_t SPVM__Net__SSLeay__PEM__read_bio_X509(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_bp = stack[0].oval;
  
  if (!obj_bp) {
    return env->die(env, stack, "The $bp must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  BIO* bp = env->get_pointer(env, stack, obj_bp);
  
  X509* x509 = PEM_read_bio_X509(bp, NULL, 0, NULL);
  
  if (!x509) {
    return env->die(env, stack, "PEM_read_bio_X509 failed.", __func__, FILE_NAME, __LINE__);
  }
  
  void* obj_x509 = env->new_pointer_object_by_name(env, stack, "Net::SSLeay::X509", x509, &error_id, __func__, FILE_NAME, __LINE__);  if (error_id) { return error_id; }
  
  stack[0].oval = obj_x509;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__PEM__read_bio_X509_CRL(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_bp = stack[0].oval;
  
  if (!obj_bp) {
    return env->die(env, stack, "The $bp must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  BIO* bp = env->get_pointer(env, stack, obj_bp);
  
  X509_CRL* x509_crl = PEM_read_bio_X509_CRL(bp, NULL, 0, NULL);
  
  if (!x509_crl) {
    return env->die(env, stack, "PEM_read_bio_X509_CRL failed.", __func__, FILE_NAME, __LINE__);
  }
  
  void* obj_x509_crl = env->new_pointer_object_by_name(env, stack, "Net::SSLeay::X509_CRL", x509_crl, &error_id, __func__, FILE_NAME, __LINE__);  if (error_id) { return error_id; }
  
  stack[0].oval = obj_x509_crl;
  
  return 0;
}
