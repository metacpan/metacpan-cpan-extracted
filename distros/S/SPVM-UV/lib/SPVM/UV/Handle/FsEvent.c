// Copyright (c) 2026 Yuki Kimoto
// MIT License

#include "spvm_native.h"
#include "uv.h"
#include "spvm_uv.h"

static const char* FILE_NAME = "UV/Handle/FsEvent.c";

void boot_UV__Handle__FsEvent() {}

static void UV__Handle__FsEvent__fs_event_cb(uv_fs_event_t* uv_handle, const char* filename, int events, int status) {
  
  int32_t error_id = 0;
  
  SPVM__UV__Handle__HANDLE_DATA* uv_handle_data = (SPVM__UV__Handle__HANDLE_DATA*)uv_handle->data;
  
  SPVM_ENV* env = uv_handle_data->env;
  SPVM_VALUE* stack = uv_handle_data->stack;
  SPVM_OBJ* obj_uv_handle = uv_handle_data->obj_uv_handle;
  SPVM_OBJ* obj_cb = env->get_field_object_by_name(env, stack, obj_uv_handle, "fs_event_cb", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) {
    spvm_diag("[Unexpected Error]Getting 'fs_event_cb' field failed.");
    abort();
  }
  
  SPVM_OBJ* obj_filename = NULL;
  if (filename) {
    obj_filename = env->new_string(env, stack, filename, strlen(filename));
  }
  
  stack[0].oval = obj_cb;
  stack[1].oval = obj_uv_handle;
  stack[2].oval = obj_filename;
  stack[3].ival = (int32_t)events;
  stack[4].ival = (int32_t)status;
  env->call_instance_method_by_name(env, stack, "", 5, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) {
    spvm_diag("[An exception is converted to a warning in UV__Handle__FsEvent__fs_event_cb]\n%s", env->get_exception_chars(env, stack));
    return;
  }
}

int32_t SPVM__UV__Handle__FsEvent__start(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  SPVM_OBJ* obj_uv_fs_event = stack[0].oval;
  SPVM_OBJ* obj_cb = stack[1].oval;
  SPVM_OBJ* obj_path = stack[2].oval;
  int32_t flags = stack[3].ival;
  
  if (!obj_cb) {
    return env->die(env, stack, "$cb must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  if (!obj_path) {
    return env->die(env, stack, "$path must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  const char* path = env->get_chars(env, stack, obj_path);
  
  uv_fs_event_t* uv_fs_event = env->get_pointer(env, stack, obj_uv_fs_event);
  
  env->set_field_object_by_name(env, stack, obj_uv_fs_event, "fs_event_cb", obj_cb, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) return error_id;
  
  int32_t status = uv_fs_event_start(uv_fs_event, UV__Handle__FsEvent__fs_event_cb, path, (unsigned int)flags);
  
  if (!(status == 0)) {
    return env->die(env, stack, "uv_fs_event_start failed. status=%d.", __func__, FILE_NAME, __LINE__, status);
  }
  
  return 0;
}

int32_t SPVM__UV__Handle__FsEvent__stop(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  SPVM_OBJ* obj_uv_fs_event = stack[0].oval;
  
  uv_fs_event_t* uv_fs_event = env->get_pointer(env, stack, obj_uv_fs_event);
  
  int32_t status = uv_fs_event_stop(uv_fs_event);
  
  if (!(status == 0)) {
    return env->die(env, stack, "uv_fs_event_stop failed. status=%d.", __func__, FILE_NAME, __LINE__, status);
  }
  
  return 0;
}

int32_t SPVM__UV__Handle__FsEvent__getpath(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  SPVM_OBJ* obj_uv_fs_event = stack[0].oval;
  
  uv_fs_event_t* uv_fs_event = env->get_pointer(env, stack, obj_uv_fs_event);
  
  char buffer[1024];
  size_t size = sizeof(buffer);
  
  int32_t status = uv_fs_event_getpath(uv_fs_event, buffer, &size);
  
  if (!(status == 0)) {
    return env->die(env, stack, "uv_fs_event_getpath failed. status=%d.", __func__, FILE_NAME, __LINE__, status);
  }
  
  SPVM_OBJ* obj_path = env->new_string(env, stack, buffer, size);
  
  stack[0].oval = obj_path;
  
  return 0;
}

int32_t SPVM__UV__Handle__FsEvent__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  uv_fs_event_t* uv_fs_event = env->new_memory_block(env, stack, sizeof(uv_fs_event_t));
  
  SPVM__UV__Handle__HANDLE_DATA* uv_handle_data = env->new_memory_block(env, stack, sizeof(SPVM__UV__Handle__HANDLE_DATA));
  uv_handle_data->env = env;
  uv_handle_data->stack = stack;
  
  uv_fs_event->data = uv_handle_data;
  
  SPVM_OBJ* obj_uv_fs_event = env->new_pointer_object_by_name(env, stack, "UV::Handle::FsEvent", uv_fs_event, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) return error_id;
  
  uv_handle_data->obj_uv_handle = obj_uv_fs_event;
  
  stack[0].oval = obj_uv_fs_event;
  
  return 0;
}
