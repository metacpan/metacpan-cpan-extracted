// Copyright (c) 2024 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <openssl/ssl.h>
#include <openssl/err.h>

static const char* FILE_NAME = "Net/SSLeay/Util.c";

int32_t SPVM__Net__SSLeay__Util__convert_to_wire_format(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_protocols = stack[0].oval;
  
  if (!obj_protocols) {
    return env->die(env, stack, "The protocols $protocols must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  int32_t wire_format_index = 0;
  int32_t protocols_length = env->length(env, stack, obj_protocols);
  for(int32_t i = 0; i < protocols_length; i++) {
    
    void* obj_protocol = env->get_elem_string(env, stack, obj_protocols, i);
    
    if (!obj_protocol) {
      return env->die(env, stack, "The element of the protocols $protocols at index $i must be defined.", __func__, FILE_NAME, __LINE__);
    }
    
    if (!obj_protocol) {
      return env->die(env, stack, "The element of the protocols $protocols at index $i must be defined.", __func__, FILE_NAME, __LINE__);
    }
    
    const char *protocol = env->get_chars(env, stack, obj_protocol);
    
    int32_t protocol_length = env->length(env, stack, obj_protocol);
    
    if (!(protocol_length > 0)) {
      return env->die(env, stack, "The element of the protocols $protocols at index $i must be a non-empty string.", __func__, FILE_NAME, __LINE__);
    }
    
    if (!(protocol_length <= 255)) {
      return env->die(env, stack, "The string lenght of the element of the protocols $protocols at index $i must be less than or equal to 255.", __func__, FILE_NAME, __LINE__);
    }
    
    wire_format_index += 1 + protocol_length;
  }
  
  int32_t wire_format_length = wire_format_index;
  
  void* obj_wire_format = env->new_byte_array(env, stack, wire_format_length);
  
  unsigned char* wire_format = (unsigned char*)env->get_elems_byte(env, stack, obj_wire_format);
  
  wire_format_index = 0;
  for(int32_t i = 0; i < protocols_length; i++) {
    
    void* obj_protocol = env->get_elem_string(env, stack, obj_protocols, i);
    
    const char *protocol = env->get_chars(env, stack, obj_protocol);
    
    int32_t protocol_length = env->length(env, stack, obj_protocol);
    
    wire_format[wire_format_index] = (unsigned char)protocol_length;
    strncpy((char*)wire_format + 1 + wire_format_index, protocol, protocol_length);
    
    wire_format_index += 1 + protocol_length;
  }
  
  stack[0].oval = obj_wire_format;
  
  return 0;
}
