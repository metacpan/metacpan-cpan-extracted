// Copyright (c) 2026 Yuki Kimoto
// MIT License

#include "spvm_native.h"
#include "uv.h"
#include "spvm_uv.h"

static const char* FILE_NAME = "UV/Handle/Poll.c";

void boot_UV__Handle__Poll() {}

static void SPVM__UV__Handle__Poll__poll_cb(uv_poll_t* uv_handle, int status, int event) {
  
  int32_t error_id = 0;
  
  SPVM__UV__Handle__HANDLE_DATA* uv_handle_data = (SPVM__UV__Handle__HANDLE_DATA*)uv_handle->data;
  
  SPVM_ENV* env = uv_handle_data->env;
  SPVM_VALUE* stack = uv_handle_data->stack;
  SPVM_OBJ* obj_uv_handle = uv_handle_data->obj_uv_handle;
  SPVM_OBJ* obj_cb = env->get_field_object_by_name(env, stack, obj_uv_handle, "poll_cb", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) {
    spvm_diag("[Unexpected Error]Getting 'poll_cb' field failed.");
    abort();
  }
  
  stack[0].oval = obj_cb;
  stack[1].oval = obj_uv_handle;
  stack[2].ival = status;
  stack[3].ival = event;
  env->call_instance_method_by_name(env, stack, "", 2, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) {
    spvm_diag("[An exception is converted to a warning in SPVM__UV__Handle__Poll__poll_cb]\n%s", env->get_exception_chars(env, stack));
    return;
  }
  
}

int32_t SPVM__UV__Handle__Poll__start(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  SPVM_OBJ* obj_uv_poll = stack[0].oval;
  SPVM_OBJ* obj_cb = stack[1].oval;
  int32_t events = stack[2].ival;
  
  if (!obj_cb) {
    return env->die(env, stack, "$cb must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  env->set_field_object_by_name(env, stack, obj_uv_poll, "poll_cb", obj_cb, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) return error_id;
  
  uv_poll_t* uv_poll = env->get_pointer(env, stack, obj_uv_poll);
  
  int32_t status = uv_poll_start(uv_poll, events, SPVM__UV__Handle__Poll__poll_cb);
  
  if (!(status == 0)) {
    return env->die(env, stack, "uv_poll_start failed. status=%d.", __func__, FILE_NAME, __LINE__, status);
  }
  
  return 0;
}

int32_t SPVM__UV__Handle__Poll__stop(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  SPVM_OBJ* obj_uv_poll = stack[0].oval;
  
  if (!obj_uv_poll) {
    return env->die(env, stack, "$uv_poll must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  uv_poll_t* uv_poll = env->get_pointer(env, stack, obj_uv_poll);
  
  // Stop polling
  int32_t status = uv_poll_stop(uv_poll);
  
  if (!(status == 0)) {
    return env->die(env, stack, "uv_poll_stop failed. status=%d.", __func__, FILE_NAME, __LINE__, status);
  }
  
  return 0;
}

int32_t SPVM__UV__Handle__Poll__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  uv_poll_t* uv_poll = env->new_memory_block(env, stack, sizeof(uv_poll_t));
  
  SPVM__UV__Handle__HANDLE_DATA* uv_handle_data = env->new_memory_block(env, stack, sizeof(SPVM__UV__Handle__HANDLE_DATA));
  uv_handle_data->env = env;
  uv_handle_data->stack = stack;
  
  uv_poll->data = uv_handle_data;
  
  SPVM_OBJ* obj_uv_poll = env->new_pointer_object_by_name(env, stack, "UV::Handle::Poll", uv_poll, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) return error_id;
  
  uv_handle_data->obj_uv_handle = obj_uv_poll;
  
  stack[0].oval = obj_uv_poll;
  
  return 0;
}
