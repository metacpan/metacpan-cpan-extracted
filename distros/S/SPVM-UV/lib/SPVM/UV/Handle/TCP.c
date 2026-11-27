// Copyright (c) 2026 Yuki Kimoto
// MIT License

#include "spvm_native.h"
#include "uv.h"
#include "spvm_uv.h"

static const char* FILE_NAME = "UV/Handle/TCP.c";

int32_t SPVM__UV__Handle__TCP__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  uv_tcp_t* uv_tcp = env->new_memory_block(env, stack, sizeof(uv_tcp_t));
  
  SPVM__UV__Handle__HANDLE_DATA* uv_handle_data = env->new_memory_block(env, stack, sizeof(SPVM__UV__Handle__HANDLE_DATA));
  uv_handle_data->env = env;
  uv_handle_data->stack = stack;
  
  uv_tcp->data = uv_handle_data;
  
  SPVM_OBJ* obj_uv_tcp = env->new_pointer_object_by_name(env, stack, "UV::Handle::TCP", uv_tcp, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) return error_id;
  
  uv_handle_data->obj_uv_handle = obj_uv_tcp;
  
  stack[0].oval = obj_uv_tcp;
  
  return 0;
}

int32_t SPVM__UV__Handle__TCP__open(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  SPVM_OBJ* obj_uv_tcp = stack[0].oval;
  int32_t fd = stack[1].ival;
  
  if (!obj_uv_tcp) {
    return env->die(env, stack, "$uv_tcp must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  uv_tcp_t* uv_tcp = env->get_pointer(env, stack, obj_uv_tcp);
  
  #if defined(_WIN32)
    // Convert fd to socket handle on Windows
    int32_t status = uv_tcp_open(uv_tcp, (uv_os_sock_t)_get_osfhandle(fd));
  #else
    int32_t status = uv_tcp_open(uv_tcp, fd);
  #endif
  
  if (!(status == 0)) {
    return env->die(env, stack, "uv_tcp_open failed. status=%d.", __func__, FILE_NAME, __LINE__, status);
  }
  
  return 0;
}
