// Copyright (c) 2026 Yuki Kimoto
// MIT License

#include "spvm_native.h"
#include "uv.h"
#include "spvm_uv.h"

static const char* FILE_NAME = "UV/Handle/Async.c";

void boot_UV__Handle__Async() {}

int32_t SPVM__UV__Handle__Async__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  uv_async_t* uv_async = env->new_memory_block(env, stack, sizeof(uv_async_t));
  
  SPVM__UV__Handle__HANDLE_DATA* uv_handle_data = env->new_memory_block(env, stack, sizeof(SPVM__UV__Handle__HANDLE_DATA));
  uv_handle_data->env = env;
  uv_handle_data->stack = stack;
  
  uv_async->data = uv_handle_data;
  
  SPVM_OBJ* obj_uv_async = env->new_pointer_object_by_name(env, stack, "UV::Handle::Async", uv_async, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) return error_id;
  
  uv_handle_data->obj_uv_handle = obj_uv_async;
  
  stack[0].oval = obj_uv_async;
  
  return 0;
}

int32_t SPVM__UV__Handle__Async__send(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  SPVM_OBJ* obj_uv_async = stack[0].oval;
  
  uv_async_t* uv_async = (uv_async_t*)env->get_pointer(env, stack, obj_uv_async);
  
  uv_async_send(uv_async);
  
  return 0;
}
