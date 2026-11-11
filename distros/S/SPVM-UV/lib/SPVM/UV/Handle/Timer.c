// Copyright (c) 2026 Yuki Kimoto
// MIT License

#include "spvm_native.h"
#include "uv.h"
#include "spvm_uv.h"

static const char* FILE_NAME = "UV/Handle/Timer.c";

void boot_UV__Handle__Timer() {}

static void SPVM__UV__Handle__Timer__timer_cb(uv_timer_t* uv_handle) {
  
  int32_t error_id = 0;
  
  SPVM__UV__Handle__HANDLE_DATA* uv_handle_data = (SPVM__UV__Handle__HANDLE_DATA*)uv_handle->data;
  
  SPVM_ENV* env = uv_handle_data->env;
  SPVM_VALUE* stack = uv_handle_data->stack;
  SPVM_OBJ* obj_uv_handle = uv_handle_data->obj_uv_handle;
  SPVM_OBJ* obj_cb = env->get_field_object_by_name(env, stack, obj_uv_handle, "timer_cb", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) {
    spvm_diag("[Unexpected Error]Getting 'timer_cb' field failed.");
    abort();
  }
  
  stack[0].oval = obj_cb;
  stack[1].oval = obj_uv_handle;
  env->call_instance_method_by_name(env, stack, "", 2, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) {
    spvm_diag("[An exception is converted to a warning in SPVM__UV__Handle__Timer__timer_cb]\n%s", env->get_exception_chars(env, stack));
    return;
  }
  
}

int32_t SPVM__UV__Handle__Timer__start(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  SPVM_OBJ* obj_uv_timer = stack[0].oval;
  SPVM_OBJ* obj_cb = stack[1].oval;
  int64_t timeout_msec = stack[2].lval;
  int64_t interval_msec = stack[3].lval;
  
  if (!obj_cb) {
    return env->die(env, stack, "$cb must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  env->set_field_object_by_name(env, stack, obj_uv_timer, "timer_cb", obj_cb, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) return error_id;
  
  uv_timer_t* uv_timer = env->get_pointer(env, stack, obj_uv_timer);
  
  int32_t status = uv_timer_start(uv_timer, SPVM__UV__Handle__Timer__timer_cb, (uint64_t)timeout_msec, (uint64_t)interval_msec);
  
  if (!(status == 0)) {
    return env->die(env, stack, "uv_timer_start failed. status=%d.", __func__, FILE_NAME, __LINE__, status);
  }
  
  return 0;
}

int32_t SPVM__UV__Handle__Timer__stop(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  SPVM_OBJ* obj_uv_timer = stack[0].oval;
  
  uv_timer_t* uv_timer = env->get_pointer(env, stack, obj_uv_timer);
  
  int32_t status = uv_timer_stop(uv_timer);
  
  if (!(status == 0)) {
    return env->die(env, stack, "uv_timer_stop failed. status=%d.", __func__, FILE_NAME, __LINE__, status);
  }
  
  return 0;
}

int32_t SPVM__UV__Handle__Timer__again(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  SPVM_OBJ* obj_uv_timer = stack[0].oval;
  
  uv_timer_t* uv_timer = env->get_pointer(env, stack, obj_uv_timer);
  
  int32_t status = uv_timer_again(uv_timer);
  
  if (!(status == 0)) {
    return env->die(env, stack, "uv_timer_again failed. status=%d.", __func__, FILE_NAME, __LINE__, status);
  }
  
  return 0;
}

int32_t SPVM__UV__Handle__Timer__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  uv_timer_t* uv_timer = env->new_memory_block(env, stack, sizeof(uv_timer_t));
  
  SPVM__UV__Handle__HANDLE_DATA* uv_handle_data = env->new_memory_block(env, stack, sizeof(SPVM__UV__Handle__HANDLE_DATA));
  uv_handle_data->env = env;
  uv_handle_data->stack = stack;
  
  uv_timer->data = uv_handle_data;
  
  SPVM_OBJ* obj_uv_timer = env->new_pointer_object_by_name(env, stack, "UV::Handle::Timer", uv_timer, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) return error_id;
  
  uv_handle_data->obj_uv_handle = obj_uv_timer;
  
  stack[0].oval = obj_uv_timer;
  
  return 0;
}
