// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <openssl/ssl.h>

static const char* FILE_NAME = "Net/SSLeay/SSL_CTX.c";

int32_t SPVM__Net__SSLeay__SSL_CTX__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_ssl_method = stack[0].oval;
  
  SSL_METHOD* ssl_method = env->get_pointer(env, stack, obj_ssl_method);
  
  SSL_CTX* ssl_ctx = SSL_CTX_new(ssl_method);
  
  // OpenSSL 1.1+ default
  SSL_CTX_set_mode(ssl_ctx, SSL_MODE_AUTO_RETRY);
  
  void* obj_ssl_ctx = env->new_pointer_object_by_name(env, stack, "Net::SSLeay::SSL_CTX", ssl_ctx, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_ssl_ctx;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__set_mode(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  int64_t mode = stack[1].lval;
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  int64_t new_mode = SSL_CTX_set_mode(ssl_ctx, mode);
  
  stack[0].lval = new_mode;
  
  return 0;
}

int verify_callback(int preverified, X509_STORE_CTX *ctx)
{
	X509* cert;
	char subject[1024];

	cert = X509_STORE_CTX_get_current_cert(ctx);
	if (cert == NULL) {
		return 0;
	}
	X509_NAME_oneline(X509_get_subject_name(cert), &subject[0], sizeof(subject));
	printf("%d %s\n", preverified, subject);

	return preverified;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__set_verify(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  int32_t mode = stack[1].ival;
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  SSL_CTX_set_verify(ssl_ctx, mode, NULL);
  
  return 0;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  SSL_CTX_free(ssl_ctx);
  
  return 0;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__get0_param(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  X509_VERIFY_PARAM* x509_verify_param = SSL_CTX_get0_param(ssl_ctx);
  
  void* obj_x509_verify_param = env->new_pointer_object_by_name(env, stack, "Net::SSLeay::X509_VERIFY_PARAM", x509_verify_param, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_x509_verify_param;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__set_default_verify_paths(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  int32_t status = SSL_CTX_set_default_verify_paths(ssl_ctx);
  
  if (!(status == 1)) {
    env->die(env, stack, "[System Error]SSL_CTX_set_default_verify_paths failed.", __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__use_certificate_file(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_file = stack[1].oval;
  
  if (!obj_file) {
    return env->die(env, stack, "The $file must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  char* file = (char*)env->get_chars(env, stack, obj_file);
  int32_t file_length = env->length(env, stack, obj_file);
  
  int32_t type = stack[2].ival;
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  int32_t status = SSL_CTX_use_certificate_file(ssl_ctx, file, type);
  
  if (!(status == 1)) {
    env->die(env, stack, "[System Error]SSL_CTX_use_certificate_file failed.", __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__use_certificate_chain_file(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_file = stack[1].oval;
  
  if (!obj_file) {
    return env->die(env, stack, "The $file must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  char* file = (char*)env->get_chars(env, stack, obj_file);
  int32_t file_length = env->length(env, stack, obj_file);
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  int32_t status = SSL_CTX_use_certificate_chain_file(ssl_ctx, file);
  
  if (!(status == 1)) {
    env->die(env, stack, "[System Error]SSL_CTX_use_certificate_chain_file failed.", __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__use_PrivateKey_file(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_file = stack[1].oval;
  
  if (!obj_file) {
    return env->die(env, stack, "The $file must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  char* file = (char*)env->get_chars(env, stack, obj_file);
  int32_t file_length = env->length(env, stack, obj_file);
  
  int32_t type = stack[2].ival;
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  int32_t status = SSL_CTX_use_PrivateKey_file(ssl_ctx, file, type);
  
  if (!(status == 1)) {
    env->die(env, stack, "[System Error]SSL_CTX_use_PrivateKey_file failed.", __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__set_cipher_list(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_str = stack[1].oval;
  
  if (!obj_str) {
    return env->die(env, stack, "The $str must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  char* str = (char*)env->get_chars(env, stack, obj_str);
  int32_t str_length = env->length(env, stack, obj_str);
  
  int32_t type = stack[2].ival;
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  int32_t status = SSL_CTX_set_cipher_list(ssl_ctx, str);
  
  if (!(status == 1)) {
    env->die(env, stack, "[System Error]SSL_CTX_set_cipher_list failed.", __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__set_ciphersuites(SPVM_ENV* env, SPVM_VALUE* stack) {
#if !(OPENSSL_VERSION_NUMBER >= 0x10100000)
  env->die(env, stack, "The set_ciphersuites method in the Net::SSLeay::SSL_CTX class is not supported in this system(!(OPENSSL_VERSION_NUMBER >= 0x10100000))", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_str = stack[1].oval;
  
  if (!obj_str) {
    return env->die(env, stack, "The $str must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  char* str = (char*)env->get_chars(env, stack, obj_str);
  int32_t str_length = env->length(env, stack, obj_str);
  
  int32_t type = stack[2].ival;
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  int32_t status = SSL_CTX_set_ciphersuites(ssl_ctx, str);
  
  if (!(status == 1)) {
    env->die(env, stack, "[System Error]SSL_CTX_set_ciphersuites failed.", __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
#endif
}

int32_t SPVM__Net__SSLeay__SSL_CTX__load_verify_locations(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  void* obj_file = stack[1].oval;
  char* file = (char*)env->get_chars(env, stack, obj_file);
  
  void* obj_path = stack[2].oval;
  char* path = (char*)env->get_chars(env, stack, obj_path);
  
  int32_t status = SSL_CTX_load_verify_locations(ssl_ctx, file, path);
  
  if (!(status == 1)) {
    return env->die(env, stack, "SSL_CTX_load_verify_locations failed.", __func__, FILE_NAME, __LINE__);
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__get_cert_store(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  X509_STORE* x509_store = SSL_CTX_get_cert_store(ssl_ctx);
  
  void* obj_x509_store = env->new_pointer_object_by_name(env, stack, "Net::SSLeay::X509_STORE", x509_store, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_x509_store;
  
  return 0;
}
