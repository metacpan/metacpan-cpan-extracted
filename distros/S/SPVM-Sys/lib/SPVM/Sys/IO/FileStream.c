#include "spvm_native.h"

#include <assert.h>
#include <stdio.h>
#include <errno.h>

const char* FILE_NAME = "Sys/IO/FileStream.c";

static const int FILE_STREAM_CLOSED_INDEX = 0;

int32_t SPVM__Sys__IO__FileStream__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {

  // File handle
  void* obj_self = stack[0].oval;
  
  int32_t file_stream_is_closed = env->get_pointer_field_int(env, stack, obj_self, FILE_STREAM_CLOSED_INDEX);
  
  FILE* fh = (FILE*)env->get_pointer(env, stack, obj_self);
  
  assert(fh);
  
  if (!env->get_pointer_no_need_free(env, stack, obj_self)) {
    if (!file_stream_is_closed) {
      int32_t status = fclose(fh);
      if (status == EOF) {
        env->die(env, stack, "[System Error]fclose failed:%s.", env->strerror(env, stack, errno, 0), FILE_NAME, __LINE__);
        return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
      }
      env->set_pointer(env, stack, obj_self, NULL);
    }
  }
  
  return 0;
}
