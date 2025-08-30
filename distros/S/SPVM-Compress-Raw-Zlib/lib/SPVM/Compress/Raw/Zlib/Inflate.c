// Copyright (c) 2025 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include "zlib.h"

#include <stdlib.h>

static const char* FILE_NAME = "Compress/Raw/Zlib/Inflate.c";

int32_t SPVM__Compress__Raw__Zlib__Inflate___inflateInit(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  int32_t windowBits = env->get_field_int_by_name(env, stack, obj_self, "WindowBits", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { goto END_OF_FUNC; }
  
  void* obj_dictionary = env->get_field_string_by_name(env, stack, obj_self, "Dictionary", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { goto END_OF_FUNC; }
  const char* dictionary = NULL;
  int32_t dictonary_length = 0;
  if (obj_dictionary) {
    dictionary = env->get_chars(env, stack, obj_dictionary);
    dictonary_length = env->length(env, stack, obj_dictionary);
  }
  
  z_stream* st_z_stream = NULL;
  int32_t status = inflateInit2(st_z_stream, windowBits);
  
  if (!(status == Z_OK)) {
    error_id = env->die(env, stack, "[zlib Error]inflateInit2() failed(status:%d).", status, __func__, FILE_NAME, __LINE__);
    goto END_OF_FUNC;
  }
  
  if (dictionary && dictonary_length) {
    status = inflateSetDictionary(st_z_stream, (const Bytef*) dictionary, dictonary_length);
  }
  
  if (!(status == Z_OK)) {
    error_id = env->die(env, stack, "[zlib Error]inflateSetDictionary() failed(status:%d).", status, __func__, FILE_NAME, __LINE__);
    goto END_OF_FUNC;
  }
  
  void* obj_z_stream = env->new_pointer_object_by_name(env, stack, "Compress::Raw::Zlib::Z_stream", st_z_stream, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { goto END_OF_FUNC; }
  
  env->set_field_object_by_name(env, stack, obj_self, "z_stream", obj_z_stream, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { goto END_OF_FUNC; }
  
  END_OF_FUNC:
  
  if (error_id) {
    if (st_z_stream) {
      free(st_z_stream);
      st_z_stream = NULL;
    }
  }
  
  return error_id;
}

int32_t SPVM__Compress__Raw__Zlib__Inflate__inflateReset(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_z_stream = env->get_field_object_by_name(env, stack, obj_self, "z_stream", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { goto END_OF_FUNC; }
  
  z_stream* st_z_stream = env->get_pointer(env, stack, obj_z_stream);
  
  int32_t status = inflateReset(st_z_stream);
  
  if (!(status == Z_OK)) {
    error_id = env->die(env, stack, "[zlib Error]inflateReset() failed(status:%d).", status, __func__, FILE_NAME, __LINE__);
    goto END_OF_FUNC;
  }
  
  END_OF_FUNC:
  
  return error_id;
}

int32_t SPVM__Compress__Raw__Zlib__Inflate__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_z_stream = env->get_field_object_by_name(env, stack, obj_self, "z_stream", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { goto END_OF_FUNC; }
  
  z_stream* st_z_stream = env->get_pointer(env, stack, obj_z_stream);
  
  inflateEnd(st_z_stream);
  
  END_OF_FUNC:
  
  return error_id;
}

int32_t SPVM__Compress__Raw__Zlib__Inflate__inflate(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_input = stack[1].oval;
  
  void* obj_output_ref = stack[2].oval;
  
  if (!obj_input) {
    error_id = env->die(env, stack, "The input $input must be define.", __func__, FILE_NAME, __LINE__);
    goto END_OF_FUNC;
  }
  
  if (!(obj_output_ref && env->length(env, stack, obj_output_ref) == 1)) {
    error_id = env->die(env, stack, "The output reference $output_ref must be 1-length string array.", __func__, FILE_NAME, __LINE__);
    goto END_OF_FUNC;
  }
  
  void* obj_z_stream = env->get_field_object_by_name(env, stack, obj_self, "z_stream", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { goto END_OF_FUNC; }
  
  z_stream* st_z_stream = env->get_pointer(env, stack, obj_z_stream);
  
  int64_t Bufsize = env->get_field_long_by_name(env, stack, obj_self, "Bufsize", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { goto END_OF_FUNC; }
  
  int32_t LimitOutput = env->get_field_byte_by_name(env, stack, obj_self, "LimitOutput", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { goto END_OF_FUNC; }
  
  char* input = (char*)env->get_chars(env, stack, obj_input);
  int32_t input_length = env->length(env, stack, obj_input);
  
  st_z_stream->next_in = input;
  st_z_stream->avail_in = input_length;
  
  int32_t output_length = Bufsize;
  char* output = env->new_memory_block(env, stack, output_length);
  
  st_z_stream->next_out = output;
  st_z_stream->avail_out = Bufsize;
  
  st_z_stream->avail_out = 0;
  int32_t status = Z_OK;
  while (1) {
    
    if (status == Z_BUF_ERROR && st_z_stream->avail_in == 0) {
      break;
    }
    
    if (LimitOutput && st_z_stream->avail_out == 0) {
      break;
    }
    
    if (st_z_stream->avail_out == 0) {
      int32_t new_output_length = output_length + Bufsize;
      
      char* new_output = env->new_memory_block(env, stack, new_output_length);
      memcpy(new_output, output, output_length);
      env->free_memory_block(env, stack, output);
      output = new_output;
      
      st_z_stream->next_out = new_output + output_length;
      st_z_stream->avail_out = Bufsize;
    }
    
    status = inflate(st_z_stream, Z_SYNC_FLUSH);
    
    int32_t fatal_error = 0;
    if (status == Z_NEED_DICT) {
      fatal_error = 1;
    }
    else if (status < 0 && status != Z_BUF_ERROR) {
      fatal_error = 1;
    }
    
    if (fatal_error) {
      error_id = env->die(env, stack, "[zlib Error]inflate() failed(status:%d).", status, __func__, FILE_NAME, __LINE__);
      goto END_OF_FUNC;
    }
    
  }
  
  output_length -= st_z_stream->avail_out;
  
  void* obj_output = env->new_string(env, stack, output, output_length);
  
  env->set_elem_object(env, stack, obj_output_ref, 0, obj_output);
  
  int32_t used_input_length = input_length - st_z_stream->avail_in;
  int32_t last_input_length = st_z_stream->avail_in;
  
  memmove(input, input + used_input_length, last_input_length);
  
  env->shorten(env, stack, obj_input, last_input_length);
  
  END_OF_FUNC:
  
  if (output) {
    env->free_memory_block(env, stack, output);
  }
  
  return error_id;
}
