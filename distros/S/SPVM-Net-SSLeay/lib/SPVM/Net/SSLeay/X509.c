// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <assert.h>

#include <openssl/ssl.h>
#include <openssl/err.h>

#include <openssl/x509v3.h>

static const char* FILE_NAME = "Net/SSLeay/X509.c";

int32_t SPVM__Net__SSLeay__X509__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  X509* self = X509_new();
  
  if (!self) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]X509_new failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
    return error_id;
  }
  
  void* obj_self = env->new_pointer_object_by_name(env, stack, "Net::SSLeay::X509", self, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_self;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509__check_issued(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_issuer = stack[0].oval;
  
  void* obj_subject = stack[1].oval;
  
  if (!obj_issuer) {
    return env->die(env, stack, "The X509 object $issuer must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  X509* issuer = env->get_pointer(env, stack, obj_issuer);
  
  if (!obj_subject) {
    return env->die(env, stack, "The X509 object $subject must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  X509* subject = env->get_pointer(env, stack, obj_subject);
  
  int32_t status = X509_check_issued(issuer, subject);
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509__get_serialNumber(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509* self = env->get_pointer(env, stack, obj_self);
  
  ASN1_INTEGER* serialNumber_tmp = X509_get_serialNumber(self);
  
  assert(serialNumber_tmp);
  
  ASN1_INTEGER* serialNumber = ASN1_INTEGER_dup(serialNumber_tmp);
  
  void* obj_address_serialNumber = env->new_pointer_object_by_name(env, stack, "Address", serialNumber, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  stack[0].oval = obj_address_serialNumber;
  env->call_class_method_by_name(env, stack, "Net::SSLeay::ASN1_INTEGER", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  void* obj_serialNumber = stack[0].oval;
  
  stack[0].oval = obj_serialNumber;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509__get_issuer_name(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509* self = env->get_pointer(env, stack, obj_self);
  
  X509_NAME* x509_name_tmp = X509_get_issuer_name(self);
  
  assert(x509_name_tmp);
  
  X509_NAME* x509_name = X509_NAME_dup(x509_name_tmp);
  
  void* obj_address_x509_name = env->new_pointer_object_by_name(env, stack, "Address", x509_name, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  stack[0].oval = obj_address_x509_name;
  env->call_class_method_by_name(env, stack, "Net::SSLeay::X509_NAME", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  void* obj_x509_name = stack[0].oval;
  
  stack[0].oval = obj_x509_name;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509__get_subject_name(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509* self = env->get_pointer(env, stack, obj_self);
  
  X509_NAME* x509_name_tmp = X509_get_subject_name(self);
  
  assert(x509_name_tmp);
  
  X509_NAME* x509_name = X509_NAME_dup(x509_name_tmp);
  
  void* obj_address_x509_name = env->new_pointer_object_by_name(env, stack, "Address", x509_name, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  stack[0].oval = obj_address_x509_name;
  env->call_class_method_by_name(env, stack, "Net::SSLeay::X509_NAME", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  void* obj_x509_name = stack[0].oval;
  
  stack[0].oval = obj_x509_name;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509__get_pubkey(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509* self = env->get_pointer(env, stack, obj_self);
  
  // The reference count is incremented
  EVP_PKEY* pubkey = X509_get_pubkey(self);
  
  if (!pubkey) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]X509_get_pubkey failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
    return error_id;
  }
  
  void* obj_address_pubkey = env->new_pointer_object_by_name(env, stack, "Address", pubkey, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  stack[0].oval = obj_address_pubkey;
  env->call_class_method_by_name(env, stack, "Net::SSLeay::EVP_PKEY", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  void* obj_pubkey = stack[0].oval;
  
  stack[0].oval = obj_pubkey;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509__pubkey_digest(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_type = stack[1].oval;
  
  void* obj_md = stack[2].oval;
  
  int32_t* len_ref = stack[3].iref;
  
  X509* self = env->get_pointer(env, stack, obj_self);
  
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
  int32_t status = X509_pubkey_digest(self, type, md, &len_tmp);
  
  if (!(status == 1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]X509_pubkey_digest failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
    return error_id;
  }
  
  *len_ref = len_tmp;
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509__get_ext_by_NID(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  int32_t nid = stack[1].ival;
  
  int32_t lastpos = stack[2].ival;
  
  X509* self = env->get_pointer(env, stack, obj_self);
  
  int32_t index = X509_get_ext_by_NID(self, nid, lastpos);
  
  int32_t success = index != -1;
  if (!success) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]X509_get_ext_by_NID failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
    return error_id;
  }
  
  stack[0].ival = index;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509__get_ext_count(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509* self = env->get_pointer(env, stack, obj_self);
  
  int32_t ext_count = X509_get_ext_count(self);
  
  stack[0].ival = ext_count;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509__get_ext(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  int32_t loc = stack[1].ival;
  
  X509* self = env->get_pointer(env, stack, obj_self);
  
  X509_EXTENSION* x509_ext_tmp = X509_get_ext(self, loc);
  
  if (!x509_ext_tmp) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]X509_get_ext failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
    return error_id;
  }
  
  X509_EXTENSION* x509_ext = X509_EXTENSION_dup(x509_ext_tmp);
  
  void* obj_address_x509_ext = env->new_pointer_object_by_name(env, stack, "Address", x509_ext, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  stack[0].oval = obj_address_x509_ext;
  env->call_class_method_by_name(env, stack, "Net::SSLeay::X509_EXTENSION", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  void* obj_x509_ext = stack[0].oval;
  
  stack[0].oval = obj_x509_ext;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509__get_subjectAltNames(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509* self = env->get_pointer(env, stack, obj_self);
  
  int32_t ext_loc = X509_get_ext_by_NID(self, NID_subject_alt_name, -1);
  STACK_OF(GENERAL_NAME)* sans_stack = NULL;
  if (ext_loc >= 0) {
    X509_EXTENSION* ext = X509_get_ext(self, ext_loc);
    assert(ext);
    sans_stack = (STACK_OF(GENERAL_NAME)*)X509V3_EXT_d2i(ext);
  }
  
  int32_t length = sans_stack ? sk_GENERAL_NAME_num(sans_stack) : 0;
  void* obj_sans = env->new_object_array_by_name(env, stack, "Net::SSLeay::GENERAL_NAME", length, &error_id, __func__, FILE_NAME, __LINE__);
  for (int32_t i = 0; i < length; i++) {
    GENERAL_NAME* san_tmp = sk_GENERAL_NAME_value(sans_stack, i);
    GENERAL_NAME* san = GENERAL_NAME_dup(san_tmp);
    
    void* obj_address_san = env->new_pointer_object_by_name(env, stack, "Address", san, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    stack[0].oval = obj_address_san;
    env->call_class_method_by_name(env, stack, "Net::SSLeay::GENERAL_NAME", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    void* obj_san = stack[0].oval;
    
    env->set_elem_object(env, stack, obj_sans, i, obj_san);
  }
  
  stack[0].oval = obj_sans;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509__digest(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_type = stack[1].oval;
  
  void* obj_md = stack[2].oval;
  
  int32_t* len_ref = stack[3].iref;
  
  X509* self = env->get_pointer(env, stack, obj_self);
  
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
  int32_t status = X509_digest(self, type, md, &len_tmp);
  
  if (!(status == 1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]X509_digest failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
    return error_id;
  }
  
  *len_ref = len_tmp;
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509__dup(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509* self = env->get_pointer(env, stack, obj_self);
  
  X509* x509_dup = X509_dup(self);
  
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

int32_t SPVM__Net__SSLeay__X509__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509* self = env->get_pointer(env, stack, obj_self);
  
  if (!env->no_free(env, stack, obj_self)) {
    X509_free(self);
  }
  
  return 0;
}

