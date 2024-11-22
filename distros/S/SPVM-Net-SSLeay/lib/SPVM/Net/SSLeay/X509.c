// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <assert.h>

#include <openssl/ssl.h>
#include <openssl/err.h>

#include <openssl/x509v3.h>

static const char* FILE_NAME = "Net/SSLeay/X509.c";

int32_t SPVM__Net__SSLeay__X509__get_issuer_name(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509* x509 = env->get_pointer(env, stack, obj_self);
  
  X509_NAME* x509_name = X509_get_issuer_name(x509);
  
  assert(x509_name);
  
  void* obj_address_x509_name = env->new_pointer_object_by_name(env, stack, "Address", x509_name, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  stack[0].oval = obj_address_x509_name;
  env->call_class_method_by_name(env, stack, "Net::SSLeay::X509_NAME", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  void* obj_x509_name = stack[0].oval;
  
  env->set_no_free(env, stack, obj_x509_name, 1);
  
  stack[0].oval = obj_x509_name;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509__get_subject_name(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509* x509 = env->get_pointer(env, stack, obj_self);
  
  X509_NAME* x509_name = X509_get_subject_name(x509);
  
  assert(x509_name);
  
  void* obj_address_x509_name = env->new_pointer_object_by_name(env, stack, "Address", x509_name, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  stack[0].oval = obj_address_x509_name;
  env->call_class_method_by_name(env, stack, "Net::SSLeay::X509_NAME", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  void* obj_x509_name = stack[0].oval;
  
  env->set_no_free(env, stack, obj_x509_name, 1);
  
  stack[0].oval = obj_x509_name;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509__digest(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_type = stack[1].oval;
  
  void* obj_md = stack[2].oval;
  
  int32_t* len_ref = stack[3].iref;
  
  X509* x509 = env->get_pointer(env, stack, obj_self);
  
  if (!obj_type) {
    return env->die(env, stack, "The digest type $type must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  EVP_MD* type = env->get_pointer(env, stack, obj_type);
  
  if (!obj_md) {
    return env->die(env, stack, "The output buffer $md must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  int32_t md_length = env->length(env, stack, obj_md);
  if (!(md_length >= EVP_MAX_MD_SIZE)) {
    return env->die(env, stack, "The length of output buffer $md must be greater than or equal to EVP_MAX_MD_SIZE.", __func__, FILE_NAME, __LINE__);
  }
  
  char* md = (char*)env->get_chars(env, stack, obj_md);
  
  unsigned int len_tmp = 0;
  int32_t status = X509_digest(x509, type, md, &len_tmp);
  
  if (!(status == 1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]X509_digest failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  *len_ref = len_tmp;
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509__pubkey_digest(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_type = stack[1].oval;
  
  void* obj_md = stack[2].oval;
  
  int32_t* len_ref = stack[3].iref;
  
  X509* x509 = env->get_pointer(env, stack, obj_self);
  
  if (!obj_type) {
    return env->die(env, stack, "The digest type $type must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  EVP_MD* type = env->get_pointer(env, stack, obj_type);
  
  if (!obj_md) {
    return env->die(env, stack, "The output buffer $md must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  int32_t md_length = env->length(env, stack, obj_md);
  if (!(md_length >= EVP_MAX_MD_SIZE)) {
    return env->die(env, stack, "The length of output buffer $md must be greater than or equal to EVP_MAX_MD_SIZE.", __func__, FILE_NAME, __LINE__);
  }
  
  char* md = (char*)env->get_chars(env, stack, obj_md);
  
  unsigned int len_tmp = 0;
  int32_t status = X509_pubkey_digest(x509, type, md, &len_tmp);
  
  if (!(status == 1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]X509_pubkey_digest failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  *len_ref = len_tmp;
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509__dup(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509* x509 = env->get_pointer(env, stack, obj_self);
  
  X509* x509_dup = X509_dup(x509);
  
  assert(x509_dup);
  
  void* obj_address_x509_dup = env->new_pointer_object_by_name(env, stack, "Address", x509_dup, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  stack[0].oval = obj_address_x509_dup;
  env->call_class_method_by_name(env, stack, "Net::SSLeay::X509", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  void* obj_x509_dup = stack[0].oval;
  
  stack[0].oval = obj_x509_dup;
  
  return 0;
}


int32_t SPVM__Net__SSLeay__X509__check_issued(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_subject = stack[1].oval;
  
  X509* x509 = env->get_pointer(env, stack, obj_self);
  
  if (!obj_subject) {
    return env->die(env, stack, "The X509 object $subject must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  X509* subject = env->get_pointer(env, stack, obj_subject);
  
  int32_t status = X509_check_issued(x509, subject);
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509__P_get_ocsp_uri(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509* x509 = env->get_pointer(env, stack, obj_self);
  
  AUTHORITY_INFO_ACCESS* info = X509_get_ext_d2i(x509, NID_info_access, NULL, NULL);
  
  void* obj_ocsp_uri = NULL;
  
  if (info) {
    for (int32_t i = 0; i < sk_ACCESS_DESCRIPTION_num(info); i++) {
      ACCESS_DESCRIPTION *ad = sk_ACCESS_DESCRIPTION_value(info, i);
      
      if (OBJ_obj2nid(ad->method) == NID_ad_OCSP && ad->location->type == GEN_URI) {
        
        const char* ocsp_uri = (const char*)ASN1_STRING_get0_data(ad->location->d.uniformResourceIdentifier);
        int32_t ocsp_uri_length = ASN1_STRING_length(ad->location->d.uniformResourceIdentifier);
        
        obj_ocsp_uri = env->new_string(env, stack, ocsp_uri, ocsp_uri_length);
        
        break;
      }
    }
  }
  
  stack[0].oval = obj_ocsp_uri;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509* pointer = env->get_pointer(env, stack, obj_self);
  
  if (!env->no_free(env, stack, obj_self)) {
    X509_free(pointer);
  }
  
  return 0;
}

