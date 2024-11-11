// Copyright (c) 2024 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <openssl/ssl.h>
#include <openssl/err.h>

static const char* FILE_NAME = "Net/SSLeay/OPENSSL.c";

int32_t SPVM__Net__SSLeay__OPENSSL_add_ssl_algorithms(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  int32_t status = OpenSSL_add_ssl_algorithms();
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__OPENSSL_add_all_algorithms(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  OpenSSL_add_all_algorithms();
  
  return 0;
}

