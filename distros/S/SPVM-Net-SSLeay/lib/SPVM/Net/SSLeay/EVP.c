// Copyright (c) 2024 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <assert.h>

#include <openssl/ssl.h>
#include <openssl/err.h>

static const char* FILE_NAME = "Net/SSLeay/EVP.c";

int32_t SPVM__Net__SSLeay__EVP__get_digestbyname(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_name = stack[0].oval;
  
  if (!obj_name) {
    return env->die(env, stack, "The name $name must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  const char* name = (char*)env->get_chars(env, stack, obj_name);
  
  const EVP_MD* evp_md = EVP_get_digestbyname(name);
  
  void* obj_evp_md = NULL;
  
  if (evp_md) {
    obj_evp_md = env->new_pointer_object_by_name(env, stack, "Net::SSLeay::EVP_MD", (void*)evp_md, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    
    env->set_no_free(env, stack, obj_evp_md, 1);
  }
  
  stack[0].oval = obj_evp_md;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__EVP__sha1(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  const EVP_MD* evp_md = EVP_sha1();
  
  assert(evp_md);
  
  void* obj_evp_md = env->new_pointer_object_by_name(env, stack, "Net::SSLeay::EVP_MD", (void*)evp_md, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  env->set_no_free(env, stack, obj_evp_md, 1);
  
  stack[0].oval = obj_evp_md;
  
  return 0;
}

