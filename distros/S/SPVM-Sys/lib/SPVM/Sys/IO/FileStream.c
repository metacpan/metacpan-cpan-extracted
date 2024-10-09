// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <assert.h>
#include <stdio.h>
#include <errno.h>

static const char* FILE_NAME = "Sys/IO/FileStream.c";

int32_t SPVM__Sys__IO__FileStream__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  int32_t no_destroy = env->get_field_byte_by_name(env, stack, obj_self, "no_destroy", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  if (!no_destroy) {
    int32_t closed = env->get_field_byte_by_name(env, stack, obj_self, "closed", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    
    FILE* fh = (FILE*)env->get_pointer(env, stack, obj_self);
    
    assert(fh);
    
    if (!closed) {
      int32_t is_pipe = env->get_field_byte_by_name(env, stack, obj_self, "is_pipe", &error_id, __func__, FILE_NAME, __LINE__);
      if (error_id) { return error_id; }
      
      if (is_pipe) {
        int32_t status = pclose(fh);
        if (status == -1) {
          env->die(env, stack, "[System Error]pclose() failed:%s.", env->strerror_nolen(env, stack, errno), __func__, FILE_NAME, __LINE__);
          return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
        }
      }
      else {
        int32_t status = fclose(fh);
        if (status == EOF) {
          env->die(env, stack, "[System Error]fclose() failed:%s.", env->strerror_nolen(env, stack, errno), __func__, FILE_NAME, __LINE__);
          return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
        }
      }
      
      env->set_pointer(env, stack, obj_self, NULL);
    }
  }
  
  return 0;
}
