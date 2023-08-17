// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <assert.h>
#include <stdio.h>
#include <errno.h>

const char* FILE_NAME = "Sys/IO/FileStream.c";

int32_t SPVM__Sys__IO__FileStream__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {

  int32_t e = 0;
  
  // File handle
  void* obj_self = stack[0].oval;
  
  int32_t closed = env->get_field_byte_by_name(env, stack, obj_self, "closed", &e, __func__, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  FILE* fh = (FILE*)env->get_pointer(env, stack, obj_self);
  
  assert(fh);

  int32_t no_need_free = env->get_field_byte_by_name(env, stack, obj_self, "no_need_free", &e, __func__, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  if (!no_need_free) {
    if (!closed) {
      int32_t status = fclose(fh);
      if (status == EOF) {
        env->die(env, stack, "[System Error]fclose failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
        return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
      }
      env->set_pointer(env, stack, obj_self, NULL);
    }
  }
  
  return 0;
}
