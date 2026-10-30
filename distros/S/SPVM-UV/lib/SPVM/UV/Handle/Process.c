// Copyright (c) 2026 Yuki Kimoto
// MIT License

#include "spvm_native.h"
#include "uv.h"
#include "spvm_uv.h"

static const char* FILE_NAME = "UV/Handle/Process.c";

int32_t SPVM__UV__Handle__Process__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  uv_process_t* uv_process = env->new_memory_block(env, stack, sizeof(uv_process_t));
  
  SPVM__UV__Handle__HANDLE_DATA* uv_handle_data = env->new_memory_block(env, stack, sizeof(SPVM__UV__Handle__HANDLE_DATA));
  uv_handle_data->env = env;
  uv_handle_data->stack = stack;
  
  uv_process->data = uv_handle_data;
  
  SPVM_OBJ* obj_uv_process = env->new_pointer_object_by_name(env, stack, "UV::Handle::Process", uv_process, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) return error_id;
  
  uv_handle_data->obj_uv_handle = obj_uv_process;
  
  stack[0].oval = obj_uv_process;
  
  return 0;
}

int32_t SPVM__UV__Handle__Process__pid(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  SPVM_OBJ* obj_uv_process = stack[0].oval;
  
  uv_process_t* uv_process = env->get_pointer(env, stack, obj_uv_process);
  assert(uv_process);
  
  stack[0].ival = uv_process->pid;
  
  return 0;
}

int32_t SPVM__UV__Handle__Process__kill(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  SPVM_OBJ* obj_uv_process = stack[0].oval;
  int32_t signum = stack[1].ival;
  
  uv_process_t* uv_process = env->get_pointer(env, stack, obj_uv_process);
  assert(uv_process);
  
  int32_t status = uv_process_kill(uv_process, signum);
  
  stack[0].ival = status;
  
  return 0;
}

