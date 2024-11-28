// Copyright (c) 2024 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <openssl/ssl.h>
#include <openssl/err.h>

static const char* FILE_NAME = "Net/SSLeay/OBJ.c";

int32_t SPVM__Net__SSLeay__OBJ__txt2nid(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_s = stack[0].oval;
  
  if (!obj_s) {
    return env->die(env, stack, "The text string $s must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  const char* s = env->get_chars(env, stack, obj_s);
  
  int32_t nid = OBJ_txt2nid(s);
  
  int32_t success = nid != NID_undef;
  if (!success) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]OBJ_txt2nid failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  stack[0].ival = nid;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__OBJ__nid2obj(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  int32_t n = stack[0].ival;
  
  ASN1_OBJECT* oid = OBJ_nid2obj(n);
  
  void* obj_address_oid = env->new_pointer_object_by_name(env, stack, "Address", oid, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  stack[0].oval = obj_address_oid;
  env->call_class_method_by_name(env, stack, "Net::SSLeay::ASN1_OBJECT", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);  
  if (error_id) { return error_id; }
  void* obj_oid = stack[0].oval;
  env->set_no_free(env, stack, obj_oid, 1);
  
  stack[0].oval = obj_oid;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__OBJ__obj2nid(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  ASN1_OBJECT* o = stack[0].oval;
  
  int32_t nid = OBJ_obj2nid(o);
  
  stack[0].ival = nid;
  
  return 0;
}
