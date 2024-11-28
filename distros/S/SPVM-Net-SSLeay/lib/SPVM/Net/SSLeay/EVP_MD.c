// Copyright (c) 2024 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <openssl/ssl.h>
#include <openssl/err.h>

#include <openssl/evp.h>

static const char* FILE_NAME = "Net/SSLeay/EVP_MD.c";

int32_t SPVM__Net__SSLeay__EVP_MD__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  EVP_MD* self = env->get_pointer(env, stack, obj_self);
  
  if (!env->no_free(env, stack, obj_self)) {
#if !(OPENSSL_VERSION_NUMBER >= 0x30000000L)
    env->die(env, stack, "Native EVP_MD_free function is not supported in this system(!(OPENSSL_VERSION_NUMBER >= 0x30000000L))", __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
    EVP_MD_free(self);
#endif

  }
  
  return 0;
}

