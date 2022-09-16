#include "spvm_native.h"

#include <assert.h>
#include <stdio.h>
#include <errno.h>
#include <dirent.h>

const char* FILE_NAME = "Sys/IO/DirStream.c";

static const int DIR_STREAM_CLOSED_INDEX = 0;

int32_t SPVM__Sys__IO__DirStream__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {

  // File handle
  void* obj_self = stack[0].oval;
  
  int32_t dir_stream_is_closed = env->get_pointer_field_int(env, stack, obj_self, DIR_STREAM_CLOSED_INDEX);
  
  DIR* dir_stream = (DIR*)env->get_pointer(env, stack, obj_self);
  
  assert(dir_stream);
  
  if (!dir_stream_is_closed) {
    int32_t status = closedir(dir_stream);
    if (status == -1) {
      env->die(env, stack, "[System Error]closedir failed:%s.", env->strerror(env, stack, errno, 0), FILE_NAME, __LINE__);
      return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
    }
    env->set_pointer(env, stack, obj_self, NULL);
  }
  
  return 0;
}
