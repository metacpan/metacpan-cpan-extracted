// Copyright (c) 2026 Yuki Kimoto
// MIT License

#include "spvm_native.h"
#include "uv.h"
#include "spvm_uv.h"

static const char* FILE_NAME = "UV/Handle/Idle.c";

void boot_UV__Handle__Idle() {}

static void UV__Handle__Idle__idle_cb(uv_idle_t* uv_handle) {
  
  int32_t error_id = 0;
  
  SPVM__UV__Handle__HANDLE_DATA* uv_handle_data = (SPVM__UV__Handle__HANDLE_DATA*)uv_handle->data;
  
  SPVM_ENV* env = uv_handle_data->env;
  SPVM_VALUE* stack = uv_handle_data->stack;
  SPVM_OBJ* obj_uv_handle = uv_handle_data->obj_uv_handle;
  SPVM_OBJ* obj_cb = env->get_field_object_by_name(env, stack, obj_uv_handle, "idle_cb", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) {
    spvm_diag("[Unexpected Error]Getting 'idle_cb' field failed.");
    abort();
  }
  
  stack[0].oval = obj_cb;
  stack[1].oval = obj_uv_handle;
  env->call_instance_method_by_name(env, stack, "", 2, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) {
    spvm_diag("[An exception is converted to a warning in UV__Handle__Idle__idle_cb]\n%s", env->get_exception_chars(env, stack));
    return;
  }
  
}

int32_t SPVM__UV__Handle__Idle__start(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  SPVM_OBJ* obj_uv_idle = stack[0].oval;
  SPVM_OBJ* obj_cb = stack[1].oval;
  
  if (!obj_cb) {
    return env->die(env, stack, "$cb must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  uv_idle_t* uv_idle = env->get_pointer(env, stack, obj_uv_idle);
  SPVM__UV__Handle__HANDLE_DATA* uv_idle_data = uv_idle->data;
  
  env->set_field_object_by_name(env, stack, obj_uv_idle, "idle_cb", obj_cb, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) return error_id;
  
  int32_t status = uv_idle_start(uv_idle, UV__Handle__Idle__idle_cb);
  
  if (!(status == 0)) {
    return env->die(env, stack, "uv_idle_start failed. status=%d.", __func__, FILE_NAME, __LINE__, status);
  }
  
  return 0;
}

int32_t SPVM__UV__Handle__Idle__stop(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  SPVM_OBJ* obj_uv_idle = stack[0].oval;
  
  uv_idle_t* uv_idle = env->get_pointer(env, stack, obj_uv_idle);
  
  int32_t status = uv_idle_stop(uv_idle);
  
  if (!(status == 0)) {
    return env->die(env, stack, "uv_idle_stop failed. status=%d.", __func__, FILE_NAME, __LINE__, status);
  }
  
  return 0;
}

int32_t SPVM__UV__Handle__Idle__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  uv_idle_t* uv_idle = env->new_memory_block(env, stack, sizeof(uv_idle_t));
  
  SPVM__UV__Handle__HANDLE_DATA* uv_handle_data = env->new_memory_block(env, stack, sizeof(SPVM__UV__Handle__HANDLE_DATA));
  uv_handle_data->env = env;
  uv_handle_data->stack = stack;
  
  uv_idle->data = uv_handle_data;
  
  SPVM_OBJ* obj_uv_idle = env->new_pointer_object_by_name(env, stack, "UV::Handle::Idle", uv_idle, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) return error_id;
  
  uv_handle_data->obj_uv_handle = obj_uv_idle;
  
  stack[0].oval = obj_uv_idle;
  
  return 0;
}
