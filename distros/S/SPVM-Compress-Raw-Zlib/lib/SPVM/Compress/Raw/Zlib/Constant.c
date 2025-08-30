// Copyright (c) 2025 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include "zlib.h"

static const char* FILE_NAME = "Compress/Raw/Zlib/Constant.c";

int32_t SPVM__Compress__Raw__Zlib__Constant__DEF_WBITS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef DEF_WBITS
  stack[0].ival = DEF_WBITS;
  return 0;
#else
  env->die(env, stack, "DEF_WBITS is not defined on the system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Compress__Raw__Zlib__Constant__MAX_MEM_LEVEL(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef MAX_MEM_LEVEL
  stack[0].ival = MAX_MEM_LEVEL;
  return 0;
#else
  env->die(env, stack, "MAX_MEM_LEVEL is not defined on the system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Compress__Raw__Zlib__Constant__MAX_WBITS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef MAX_WBITS
  stack[0].ival = MAX_WBITS;
  return 0;
#else
  env->die(env, stack, "MAX_WBITS is not defined on the system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Compress__Raw__Zlib__Constant__OS_CODE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OS_CODE
  stack[0].ival = OS_CODE;
  return 0;
#else
  env->die(env, stack, "OS_CODE is not defined on the system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Compress__Raw__Zlib__Constant__Z_ASCII(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef Z_ASCII
  stack[0].ival = Z_ASCII;
  return 0;
#else
  env->die(env, stack, "Z_ASCII is not defined on the system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Compress__Raw__Zlib__Constant__Z_BEST_COMPRESSION(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef Z_BEST_COMPRESSION
  stack[0].ival = Z_BEST_COMPRESSION;
  return 0;
#else
  env->die(env, stack, "Z_BEST_COMPRESSION is not defined on the system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Compress__Raw__Zlib__Constant__Z_BEST_SPEED(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef Z_BEST_SPEED
  stack[0].ival = Z_BEST_SPEED;
  return 0;
#else
  env->die(env, stack, "Z_BEST_SPEED is not defined on the system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Compress__Raw__Zlib__Constant__Z_BINARY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef Z_BINARY
  stack[0].ival = Z_BINARY;
  return 0;
#else
  env->die(env, stack, "Z_BINARY is not defined on the system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Compress__Raw__Zlib__Constant__Z_BLOCK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef Z_BLOCK
  stack[0].ival = Z_BLOCK;
  return 0;
#else
  env->die(env, stack, "Z_BLOCK is not defined on the system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Compress__Raw__Zlib__Constant__Z_BUF_ERROR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef Z_BUF_ERROR
  stack[0].ival = Z_BUF_ERROR;
  return 0;
#else
  env->die(env, stack, "Z_BUF_ERROR is not defined on the system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Compress__Raw__Zlib__Constant__Z_DATA_ERROR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef Z_DATA_ERROR
  stack[0].ival = Z_DATA_ERROR;
  return 0;
#else
  env->die(env, stack, "Z_DATA_ERROR is not defined on the system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Compress__Raw__Zlib__Constant__Z_DEFAULT_COMPRESSION(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef Z_DEFAULT_COMPRESSION
  stack[0].ival = Z_DEFAULT_COMPRESSION;
  return 0;
#else
  env->die(env, stack, "Z_DEFAULT_COMPRESSION is not defined on the system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Compress__Raw__Zlib__Constant__Z_DEFAULT_STRATEGY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef Z_DEFAULT_STRATEGY
  stack[0].ival = Z_DEFAULT_STRATEGY;
  return 0;
#else
  env->die(env, stack, "Z_DEFAULT_STRATEGY is not defined on the system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Compress__Raw__Zlib__Constant__Z_DEFLATED(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef Z_DEFLATED
  stack[0].ival = Z_DEFLATED;
  return 0;
#else
  env->die(env, stack, "Z_DEFLATED is not defined on the system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Compress__Raw__Zlib__Constant__Z_ERRNO(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef Z_ERRNO
  stack[0].ival = Z_ERRNO;
  return 0;
#else
  env->die(env, stack, "Z_ERRNO is not defined on the system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Compress__Raw__Zlib__Constant__Z_FILTERED(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef Z_FILTERED
  stack[0].ival = Z_FILTERED;
  return 0;
#else
  env->die(env, stack, "Z_FILTERED is not defined on the system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Compress__Raw__Zlib__Constant__Z_FINISH(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef Z_FINISH
  stack[0].ival = Z_FINISH;
  return 0;
#else
  env->die(env, stack, "Z_FINISH is not defined on the system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Compress__Raw__Zlib__Constant__Z_FIXED(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef Z_FIXED
  stack[0].ival = Z_FIXED;
  return 0;
#else
  env->die(env, stack, "Z_FIXED is not defined on the system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Compress__Raw__Zlib__Constant__Z_FULL_FLUSH(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef Z_FULL_FLUSH
  stack[0].ival = Z_FULL_FLUSH;
  return 0;
#else
  env->die(env, stack, "Z_FULL_FLUSH is not defined on the system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Compress__Raw__Zlib__Constant__Z_HUFFMAN_ONLY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef Z_HUFFMAN_ONLY
  stack[0].ival = Z_HUFFMAN_ONLY;
  return 0;
#else
  env->die(env, stack, "Z_HUFFMAN_ONLY is not defined on the system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Compress__Raw__Zlib__Constant__Z_MEM_ERROR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef Z_MEM_ERROR
  stack[0].ival = Z_MEM_ERROR;
  return 0;
#else
  env->die(env, stack, "Z_MEM_ERROR is not defined on the system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Compress__Raw__Zlib__Constant__Z_NEED_DICT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef Z_NEED_DICT
  stack[0].ival = Z_NEED_DICT;
  return 0;
#else
  env->die(env, stack, "Z_NEED_DICT is not defined on the system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Compress__Raw__Zlib__Constant__Z_NO_COMPRESSION(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef Z_NO_COMPRESSION
  stack[0].ival = Z_NO_COMPRESSION;
  return 0;
#else
  env->die(env, stack, "Z_NO_COMPRESSION is not defined on the system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Compress__Raw__Zlib__Constant__Z_NO_FLUSH(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef Z_NO_FLUSH
  stack[0].ival = Z_NO_FLUSH;
  return 0;
#else
  env->die(env, stack, "Z_NO_FLUSH is not defined on the system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Compress__Raw__Zlib__Constant__Z_OK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef Z_OK
  stack[0].ival = Z_OK;
  return 0;
#else
  env->die(env, stack, "Z_OK is not defined on the system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Compress__Raw__Zlib__Constant__Z_PARTIAL_FLUSH(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef Z_PARTIAL_FLUSH
  stack[0].ival = Z_PARTIAL_FLUSH;
  return 0;
#else
  env->die(env, stack, "Z_PARTIAL_FLUSH is not defined on the system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Compress__Raw__Zlib__Constant__Z_RLE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef Z_RLE
  stack[0].ival = Z_RLE;
  return 0;
#else
  env->die(env, stack, "Z_RLE is not defined on the system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Compress__Raw__Zlib__Constant__Z_STREAM_END(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef Z_STREAM_END
  stack[0].ival = Z_STREAM_END;
  return 0;
#else
  env->die(env, stack, "Z_STREAM_END is not defined on the system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Compress__Raw__Zlib__Constant__Z_STREAM_ERROR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef Z_STREAM_ERROR
  stack[0].ival = Z_STREAM_ERROR;
  return 0;
#else
  env->die(env, stack, "Z_STREAM_ERROR is not defined on the system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Compress__Raw__Zlib__Constant__Z_SYNC_FLUSH(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef Z_SYNC_FLUSH
  stack[0].ival = Z_SYNC_FLUSH;
  return 0;
#else
  env->die(env, stack, "Z_SYNC_FLUSH is not defined on the system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Compress__Raw__Zlib__Constant__Z_UNKNOWN(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef Z_UNKNOWN
  stack[0].ival = Z_UNKNOWN;
  return 0;
#else
  env->die(env, stack, "Z_UNKNOWN is not defined on the system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Compress__Raw__Zlib__Constant__Z_VERSION_ERROR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef Z_VERSION_ERROR
  stack[0].ival = Z_VERSION_ERROR;
  return 0;
#else
  env->die(env, stack, "Z_VERSION_ERROR is not defined on the system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

