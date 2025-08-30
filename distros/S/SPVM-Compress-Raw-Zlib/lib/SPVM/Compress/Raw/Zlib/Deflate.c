// Copyright (c) 2025 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include "zlib.h"

#include <stdlib.h>

static const char* FILE_NAME = "Compress/Raw/Zlib/Deflate.c";

int32_t SPVM__Compress__Raw__Zlib__Deflate___deflateInit(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  int32_t level = env->get_field_int_by_name(env, stack, obj_self, "Level", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { goto END_OF_FUNC; }
  
  int32_t method = env->get_field_int_by_name(env, stack, obj_self, "Method", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { goto END_OF_FUNC; }
  
  int32_t windowBits = env->get_field_int_by_name(env, stack, obj_self, "WindowBits", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { goto END_OF_FUNC; }
  
  int32_t memLevel = env->get_field_int_by_name(env, stack, obj_self, "MemLevel", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { goto END_OF_FUNC; }
  
  int32_t strategy = env->get_field_int_by_name(env, stack, obj_self, "Strategy", &error_id, __func__, FILE_NAME, __LINE__);
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
  int32_t status = deflateInit2(st_z_stream, level, method, windowBits, memLevel, strategy);
  
  if (!(status == Z_OK)) {
    error_id = env->die(env, stack, "[zlib Error]deflateInit2() failed(status:%d).", status, __func__, FILE_NAME, __LINE__);
    goto END_OF_FUNC;
  }
  
  if (dictionary && dictonary_length) {
    status = deflateSetDictionary(st_z_stream, (const Bytef*) dictionary, dictonary_length);
  }
  
  if (!(status == Z_OK)) {
    error_id = env->die(env, stack, "[zlib Error]deflateSetDictionary() failed(status:%d).", status, __func__, FILE_NAME, __LINE__);
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

int32_t SPVM__Compress__Raw__Zlib__Deflate___deflateParams(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  int32_t level = env->get_field_int_by_name(env, stack, obj_self, "Level", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { goto END_OF_FUNC; }
  
  int32_t strategy = env->get_field_int_by_name(env, stack, obj_self, "Strategy", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { goto END_OF_FUNC; }
  
  z_stream* st_z_stream = NULL;
  int32_t status = deflateParams(st_z_stream, level, strategy);
  
  if (!(status == Z_OK)) {
    error_id = env->die(env, stack, "[zlib Error]deflateParams() failed(status:%d).", status, __func__, FILE_NAME, __LINE__);
    goto END_OF_FUNC;
  }
  
  END_OF_FUNC:
  
  return error_id;
}

int32_t SPVM__Compress__Raw__Zlib__Deflate__deflateReset(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_z_stream = env->get_field_object_by_name(env, stack, obj_self, "z_stream", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { goto END_OF_FUNC; }
  
  z_stream* st_z_stream = env->get_pointer(env, stack, obj_z_stream);
  
  int32_t status = deflateReset(st_z_stream);
  
  if (!(status == Z_OK)) {
    error_id = env->die(env, stack, "[zlib Error]deflateReset() failed(status:%d).", status, __func__, FILE_NAME, __LINE__);
    goto END_OF_FUNC;
  }
  
  END_OF_FUNC:
  
  return error_id;
}

int32_t SPVM__Compress__Raw__Zlib__Deflate__deflateTune(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  int good_length = stack[0].ival;
  int max_lazy = stack[1].ival;
  int nice_length = stack[2].ival;
  int max_chain = stack[3].ival;
  
  void* obj_self = stack[0].oval;
  
  void* obj_z_stream = env->get_field_object_by_name(env, stack, obj_self, "z_stream", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { goto END_OF_FUNC; }
  
  z_stream* st_z_stream = env->get_pointer(env, stack, obj_z_stream);
  
  int32_t status = deflateTune(st_z_stream, good_length, max_lazy, nice_length, max_chain);
  
  if (!(status == Z_OK)) {
    error_id = env->die(env, stack, "[zlib Error]deflateTune() failed(status:%d).", status, __func__, FILE_NAME, __LINE__);
    goto END_OF_FUNC;
  }
  
  END_OF_FUNC:
  
  return error_id;
}

int32_t SPVM__Compress__Raw__Zlib__Deflate__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_z_stream = env->get_field_object_by_name(env, stack, obj_self, "z_stream", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { goto END_OF_FUNC; }
  
  z_stream* st_z_stream = env->get_pointer(env, stack, obj_z_stream);
  
  deflateEnd(st_z_stream);
  
  END_OF_FUNC:
  
  return error_id;
}

int32_t SPVM__Compress__Raw__Zlib__Deflate__deflate(SPVM_ENV* env, SPVM_VALUE* stack) {
  
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
  
  char* input = (char*)env->get_chars(env, stack, obj_input);
  int32_t input_length = env->length(env, stack, obj_input);
  
  st_z_stream->next_in = input;
  st_z_stream->avail_in = input_length;
  
  int64_t Bufsize = env->get_field_long_by_name(env, stack, obj_self, "Bufsize", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { goto END_OF_FUNC; }
  
  int32_t output_length = Bufsize;
  char* output = env->new_memory_block(env, stack, output_length);
  
  st_z_stream->next_out = output;
  st_z_stream->avail_out = Bufsize;
  
  while (1) {
    
    if (st_z_stream->avail_in == 0) {
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
    
    int32_t status = deflate(st_z_stream, Z_NO_FLUSH);
    
    if (status < 0 && status != Z_BUF_ERROR) {
      error_id = env->die(env, stack, "[zlib Error]deflate() failed(status:%d).", status, __func__, FILE_NAME, __LINE__);
      goto END_OF_FUNC;
    }
    
  }
  
  output_length -= st_z_stream->avail_out;
  
  void* obj_output = env->new_string(env, stack, output, output_length);
  
  env->set_elem_object(env, stack, obj_output_ref, 0, obj_output);
  
  END_OF_FUNC:
  
  if (output) {
    env->free_memory_block(env, stack, output);
  }
  
  return error_id;
}

int32_t SPVM__Compress__Raw__Zlib__Deflate__flush(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_output_ref = stack[1].oval;
  
  int32_t flush_type = stack[2].ival;
  
  if (!(obj_output_ref && env->length(env, stack, obj_output_ref) == 1)) {
    error_id = env->die(env, stack, "The output reference $output_ref must be 1-length string array.", __func__, FILE_NAME, __LINE__);
    goto END_OF_FUNC;
  }
  
  void* obj_z_stream = env->get_field_object_by_name(env, stack, obj_self, "z_stream", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { goto END_OF_FUNC; }
  
  z_stream* st_z_stream = env->get_pointer(env, stack, obj_z_stream);
  
  int64_t Bufsize = env->get_field_long_by_name(env, stack, obj_self, "Bufsize", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { goto END_OF_FUNC; }
  
  int32_t output_length = Bufsize;
  char* output = env->new_memory_block(env, stack, output_length);
  
  st_z_stream->next_out = output;
  st_z_stream->avail_out = Bufsize;
  
  if (!(flush_type > -1)) {
    flush_type = Z_FINISH;
  }
  
  while (1){
    
    if (st_z_stream->avail_out == 0) {
      int32_t new_output_length = output_length + Bufsize;
      
      char* new_output = env->new_memory_block(env, stack, new_output_length);
      memcpy(new_output, output, output_length);
      env->free_memory_block(env, stack, output);
      output = new_output;
      
      st_z_stream->next_out = new_output + output_length;
      st_z_stream->avail_out = Bufsize;
    }
    
    int32_t avail_out =  st_z_stream->avail_out;
    
    int32_t status = deflate(st_z_stream, flush_type);
    
    if (status < 0 && status != Z_BUF_ERROR) {
      error_id = env->die(env, stack, "[zlib Error]deflate() failed(status:%d).", status, __func__, FILE_NAME, __LINE__);
      goto END_OF_FUNC;
    }
    
    /* deflate has finished flushing only when it hasn't used up
     * all the available space in the output buffer:
     */
    if (st_z_stream->avail_out != 0) {
      break;
    }
  }
  
  output_length -= st_z_stream->avail_out;
  
  void* obj_output = env->new_string(env, stack, output, output_length);
  
  env->set_elem_object(env, stack, obj_output_ref, 0, obj_output);
  
  END_OF_FUNC:
  
  if (output) {
    env->free_memory_block(env, stack, output);
  }
  
  return error_id;
}

