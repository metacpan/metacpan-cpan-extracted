// Copyright (c) 2026 Yuki Kimoto
// MIT License

#include "spvm_native.h"
#include "uv.h"
#include "spvm_uv.h"

static const char* FILE_NAME = "UV/Handle/Signal.c";

void boot_UV__Handle__Signal() {}

static void UV__Handle__Signal__signal_cb(uv_signal_t* uv_handle, int signum) {
  
  int32_t error_id = 0;
  
  SPVM__UV__Handle__HANDLE_DATA* uv_handle_data = (SPVM__UV__Handle__HANDLE_DATA*)uv_handle->data;
  
  SPVM_ENV* env = uv_handle_data->env;
  SPVM_VALUE* stack = uv_handle_data->stack;
  SPVM_OBJ* obj_uv_handle = uv_handle_data->obj_uv_handle;
  SPVM_OBJ* obj_cb = env->get_field_object_by_name(env, stack, obj_uv_handle, "signal_cb", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) {
    spvm_diag("[Unexpected Error]Getting 'signal_cb' field failed.");
    abort();
  }
  
  stack[0].oval = obj_cb;
  stack[1].oval = obj_uv_handle;
  stack[2].ival = signum;
  env->call_instance_method_by_name(env, stack, "", 3, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) {
    spvm_diag("[An exception is converted to a warning in UV__Handle__Signal__signal_cb]\n%s", env->get_exception_chars(env, stack));
    return;
  }
  
}

int32_t SPVM__UV__Handle__Signal__start(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  SPVM_OBJ* obj_uv_signal = stack[0].oval;
  SPVM_OBJ* obj_cb = stack[1].oval;
  int32_t signum = stack[2].ival;
  
  if (!obj_cb) {
    return env->die(env, stack, "$cb must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  uv_signal_t* uv_signal = env->get_pointer(env, stack, obj_uv_signal);
  
  env->set_field_object_by_name(env, stack, obj_uv_signal, "signal_cb", obj_cb, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) return error_id;
  
  int32_t status = uv_signal_start(uv_signal, UV__Handle__Signal__signal_cb, signum);
  
  if (!(status == 0)) {
    return env->die(env, stack, "uv_signal_start failed. status=%d.", __func__, FILE_NAME, __LINE__, status);
  }
  
  return 0;
}

int32_t SPVM__UV__Handle__Signal__stop(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  SPVM_OBJ* obj_uv_signal = stack[0].oval;
  
  uv_signal_t* uv_signal = env->get_pointer(env, stack, obj_uv_signal);
  
  int32_t status = uv_signal_stop(uv_signal);
  
  if (!(status == 0)) {
    return env->die(env, stack, "uv_signal_stop failed. status=%d.", __func__, FILE_NAME, __LINE__, status);
  }
  
  return 0;
}

int32_t SPVM__UV__Handle__Signal__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  uv_signal_t* uv_signal = env->new_memory_block(env, stack, sizeof(uv_signal_t));
  
  SPVM__UV__Handle__HANDLE_DATA* uv_handle_data = env->new_memory_block(env, stack, sizeof(SPVM__UV__Handle__HANDLE_DATA));
  uv_handle_data->env = env;
  uv_handle_data->stack = stack;
  
  uv_signal->data = uv_handle_data;
  
  SPVM_OBJ* obj_uv_signal = env->new_pointer_object_by_name(env, stack, "UV::Handle::Signal", uv_signal, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) return error_id;
  
  uv_handle_data->obj_uv_handle = obj_uv_signal;
  
  stack[0].oval = obj_uv_signal;
  
  return 0;
}
