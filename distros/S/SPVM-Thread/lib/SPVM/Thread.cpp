// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <assert.h>

#include <iostream>
#include <thread>

extern "C" {

static const char* FILE_NAME = "Thread.cpp";

static void thread_handler (SPVM_ENV* env, void* obj_self, void* obj_task) {
  
  int32_t error_id = 0;
  
  SPVM_VALUE* stack = env->new_stack(env);
  
  stack[0].oval = obj_task;
  env->call_instance_method_by_name(env, stack, "", 1, &error_id, __func__, FILE_NAME, __LINE__);
  
  if (error_id) {
    void* obj_exception = env->get_exception(env, stack);
    const char* exception = env->get_chars(env, stack, obj_exception);
    
    fprintf(env->api->runtime->get_spvm_stderr(env->runtime), "[An exception thrown in a thread is converted to a warning]\n");
    
    env->print_stderr(env, stack, obj_exception);
    
    fprintf(env->api->runtime->get_spvm_stderr(env->runtime), "\n");
  }
  
  env->free_stack(env, stack);
  
  return;
}

int32_t SPVM__Thread__create(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_task = env->get_field_object_by_name(env, stack, obj_self, "task", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  std::thread* nt_thread = (std::thread*)env->new_memory_block(env, stack, sizeof(std::thread));
  
  *nt_thread = std::thread(thread_handler, env, obj_self, obj_task);
  
  env->set_pointer(env, stack, obj_self, nt_thread);
  
  return 0;
}

int32_t SPVM__Thread__join(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_thread = stack[0].oval;
  
  std::thread* nt_thread = (std::thread*)env->get_pointer(env, stack, obj_thread);
  
  try {
    nt_thread->join();
  }
  catch (std::exception& cpp_exception){
    env->die(env, stack, "[System Error]std::thread join failed:%s", cpp_exception.what(), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  return 0;
}

int32_t SPVM__Thread__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_thread = stack[0].oval;
  
  std::thread* nt_thread = (std::thread*)env->get_pointer(env, stack, obj_thread);
  
  if (nt_thread->joinable()) {
    nt_thread->detach();
  }
  
  env->free_memory_block(env, stack, nt_thread);
  
  return 0;
}

int32_t SPVM__Thread__get_id(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_thread = stack[0].oval;
  
  std::thread* nt_thread = (std::thread*)env->get_pointer(env, stack, obj_thread);
  
  std::thread::id* thread_id = (std::thread::id*)env->new_memory_block(env, stack, sizeof(std::thread::id));
  
  *thread_id = nt_thread->get_id();
  
  void* obj_thread_id = env->new_object_by_name(env, stack, "Thread::ID", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  env->set_pointer(env, stack, obj_thread_id, (void*)thread_id);
  
  stack[0].oval = obj_thread_id;
  
  return 0;
}

}
