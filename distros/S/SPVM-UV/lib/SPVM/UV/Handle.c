// Copyright (c) 2026 Yuki Kimoto
// MIT License

#include "spvm_native.h"
#include "uv.h"
#include "spvm_uv.h"

static const char* FILE_NAME = "UV/Handle.c";

void boot_UV__Handle() {}

static void SPVM__UV__Handle__close_cb(uv_handle_t* uv_handle) {
  
  int32_t error_id = 0;
  
  SPVM__UV__Handle__HANDLE_DATA* uv_handle_data = (SPVM__UV__Handle__HANDLE_DATA*)uv_handle->data;
  
  SPVM_ENV* env = uv_handle_data->env;
  SPVM_VALUE* stack = uv_handle_data->stack;
  SPVM_OBJ* obj_uv_handle = uv_handle_data->obj_uv_handle;
  SPVM_OBJ* obj_cb = env->get_field_object_by_name(env, stack, obj_uv_handle, "close_cb", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) {
    spvm_diag("[Unexpected Error]Getting 'close_cb' field failed.");
    abort();
  }
  
  if (obj_cb) {
    stack[0].oval = obj_cb;
    stack[1].oval = obj_uv_handle;
    env->call_instance_method_by_name(env, stack, "", 2, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) {
      spvm_diag("[An exception is converted to a warning in SPVM__UV__Handle__close_cb]\n%s", env->get_exception_chars(env, stack));
      return;
    }
  }
  
  SPVM_OBJ* obj_uv_loop = env->get_field_object_by_name(env, stack, obj_uv_handle, "loop", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) {
    spvm_diag("[Unexpected Error]Getting 'loop' field failed.");
    abort();
  }
  
  stack[0].oval = obj_uv_loop;
  stack[1].oval = obj_uv_handle;
  env->call_instance_method_by_name(env, stack, "delete_uv_handle", 2, &error_id, __func__, FILE_NAME, __LINE__);
  
  if (error_id) {
    spvm_diag("[Unexpected Error]Calling 'delete_uv_handle' failed.");
    abort();
  }
}

int32_t SPVM__UV__Handle__close_safe(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  SPVM_OBJ* obj_uv_handle = stack[0].oval;
  SPVM_OBJ* obj_cb = stack[1].oval;
  
  env->set_field_object_by_name(env, stack, obj_uv_handle, "close_cb", obj_cb, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) return error_id;
  
  uv_handle_t* uv_handle = env->get_pointer(env, stack, obj_uv_handle);
  
  if (!uv_is_closing(uv_handle)) {
    uv_close(uv_handle, SPVM__UV__Handle__close_cb);
  }
  
  return 0;
}

int32_t SPVM__UV__Handle__get_type(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  SPVM_OBJ* obj_uv_handle = stack[0].oval;
  
  uv_handle_t* uv_handle = env->get_pointer(env, stack, obj_uv_handle);
  
  int32_t uv_handle_type = uv_handle_get_type(uv_handle);
  
  stack[0].ival = uv_handle_type;
  
  return 0;
}

int32_t SPVM__UV__Handle__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  SPVM_OBJ* obj_uv_handle = stack[0].oval;
  
  int32_t no_free = env->no_free(env, stack, obj_uv_handle);
  
  if (!no_free) {
    uv_handle_t* uv_handle = env->get_pointer(env, stack, obj_uv_handle);
    
    SPVM__UV__Handle__HANDLE_DATA* uv_handle_data = (SPVM__UV__Handle__HANDLE_DATA*)uv_handle->data;
    
    env->free_memory_block(env, stack, uv_handle_data);
    uv_handle->data = NULL;
    env->free_memory_block(env, stack, uv_handle);
    env->set_no_free(env, stack, obj_uv_handle, 1);
  }
  
  return 0;
}
