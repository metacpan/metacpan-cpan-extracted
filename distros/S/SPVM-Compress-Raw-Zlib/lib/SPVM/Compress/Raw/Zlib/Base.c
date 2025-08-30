// Copyright (c) 2025 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include "zlib.h"

#include <stdlib.h>

static const char* FILE_NAME = "Compress/Raw/Zlib/Base.c";

int32_t SPVM__Compress__Raw__Zlib__Base__total_out(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_z_stream = env->get_field_object_by_name(env, stack, obj_self, "z_stream", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { goto END_OF_FUNC; }
  
  z_stream* st_z_stream = env->get_pointer(env, stack, obj_z_stream);
  
  int64_t total_out = st_z_stream->total_out;
  
  stack[0].lval = total_out;
  
  END_OF_FUNC:
  
  return error_id;
}

int32_t SPVM__Compress__Raw__Zlib__Base__total_in(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_z_stream = env->get_field_object_by_name(env, stack, obj_self, "z_stream", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { goto END_OF_FUNC; }
  
  z_stream* st_z_stream = env->get_pointer(env, stack, obj_z_stream);
  
  int64_t total_in = st_z_stream->total_in;
  
  stack[0].lval = total_in;
  
  END_OF_FUNC:
  
  return error_id;
}

int32_t SPVM__Compress__Raw__Zlib__Base__adler(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_z_stream = env->get_field_object_by_name(env, stack, obj_self, "z_stream", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { goto END_OF_FUNC; }
  
  z_stream* st_z_stream = env->get_pointer(env, stack, obj_z_stream);
  
  int64_t adler = st_z_stream->adler;
  
  stack[0].lval = adler;
  
  END_OF_FUNC:
  
  return error_id;
}

