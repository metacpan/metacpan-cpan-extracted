// Copyright (c) 2024 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <openssl/ssl.h>
#include <openssl/err.h>

#include <openssl/x509v3.h>

static const char* FILE_NAME = "Net/SSLeay/GENERAL_NAME.c";

int32_t SPVM__Net__SSLeay__GENERAL_NAME__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  GENERAL_NAME* self = GENERAL_NAME_new();
  
  if (!self) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]GENERAL_NAME_new failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
    return error_id;
  }
  
  void* obj_self = env->new_pointer_object_by_name(env, stack, "Net::SSLeay::GENERAL_NAME", self, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_self;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__GENERAL_NAME__get_type(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  GENERAL_NAME* self = env->get_pointer(env, stack, obj_self);
  
  int32_t type = self->type;
  
  stack[0].ival = type;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__GENERAL_NAME__get_data_as_string(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  GENERAL_NAME* self = env->get_pointer(env, stack, obj_self);
  
  void* obj_data_as_string = NULL;
  switch (self->type) {
    case GEN_OTHERNAME: {
      ASN1_STRING* data_asn1_string = self->d.otherName->value->value.utf8string;
      
      const char* data = ASN1_STRING_get0_data(data_asn1_string);
      int32_t data_length = ASN1_STRING_length(data_asn1_string);
      
      obj_data_as_string = env->new_string(env, stack, data, data_length);
      break;
    }
    case GEN_EMAIL:
    case GEN_DNS:
    case GEN_URI:
    {
      ASN1_STRING* data_asn1_string = self->d.ia5;
      
      const char* data = ASN1_STRING_get0_data(data_asn1_string);
      int32_t data_length = ASN1_STRING_length(data_asn1_string);
      
      obj_data_as_string = env->new_string(env, stack, data, data_length);
      break;
    }
    case GEN_DIRNAME: {
      char * buf = X509_NAME_oneline(self->d.dirn, NULL, 0);
      obj_data_as_string = env->new_string(env, stack, buf, strlen(buf));
      OPENSSL_free(buf);
      break;
    }
    case GEN_RID: {
      char buf[2501] = {0};
      int len = OBJ_obj2txt(buf, sizeof(buf), self->d.rid, 1);
      if (len < 0 || len > (int)((sizeof(buf) - 1))) {
        return env->die(env, stack, "The length of d.rid is invalid.", __func__, FILE_NAME, __LINE__);
      }
      
      obj_data_as_string = env->new_string_nolen(env, stack, buf);
      break;
    }
    case GEN_IPADD: {
      const char* data = self->d.ip->data;
      int32_t data_length = self->d.ip->length;
      
      obj_data_as_string = env->new_string(env, stack, data, data_length);
      break;
    }
    default : {
      return env->die(env, stack, "The value of type member variable: %d.", self->type, __func__, FILE_NAME, __LINE__);
    }
  }
  
  stack[0].oval = obj_data_as_string;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__GENERAL_NAME__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  GENERAL_NAME* self = env->get_pointer(env, stack, obj_self);
  
  if (!env->no_free(env, stack, obj_self)) {
    GENERAL_NAME_free(self);
  }
  
  return 0;
}

