// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <assert.h>
#include <signal.h>

#include <iostream>
#include <thread>

extern "C" {

static const char* FILE_NAME = "Thread.cpp";

static void thread_handler(SPVM_ENV* env, SPVM_OBJ* obj_self, SPVM_OBJ* obj_task, const char* caller_func_name, const char* caller_file, int32_t caller_line) {
  
  int32_t error_id = 0;
  
  SPVM_VALUE* stack = env->new_stack(env);
  
  stack[0].oval = obj_task;
  env->call_instance_method_by_name(env, stack, "", 1, &error_id, caller_func_name, caller_file, caller_line);
  
  if (error_id) {
    // Reconstruct the full exception message including stack trace.
    // The level 0 means the trace starts from the origin of the exception.
    int32_t scope_id = env->enter_scope(env, stack);
    
    SPVM_OBJ* obj_full_exception_message = env->build_exception_message(env, stack, 0);
    
    fprintf(env->api->runtime->get_spvm_stderr(env->runtime), "[An exception thrown in a thread is converted to a warning]\n");
    
    // Print the full exception message with stack trace.
    env->print_stderr(env, stack, obj_full_exception_message);
    
    env->leave_scope(env, stack, scope_id);
    
    fprintf(env->api->runtime->get_spvm_stderr(env->runtime), "\n");
  }
  
  env->free_stack(env, stack);
  
  return;
}

int32_t SPVM__Thread__create(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  SPVM_OBJ* obj_self = stack[0].oval;
  
  SPVM_OBJ* obj_task = env->get_field_object_by_name(env, stack, obj_self, "task", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  std::thread* nt_thread = (std::thread*)env->new_memory_block(env, stack, sizeof(std::thread));
  
  SPVM_OBJ* obj_caller_info = env->get_field_object_by_name(env, stack, obj_self, "caller_info", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) return error_id;
  
  SPVM_OBJ* obj_caller_method_abs_name = env->get_field_object_by_name(env, stack, obj_caller_info, "method_abs_name", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) return error_id;
  const char* caller_method_abs_name = env->get_chars(env, stack, obj_caller_method_abs_name);
  
  SPVM_OBJ* obj_caller_file = env->get_field_object_by_name(env, stack, obj_caller_info, "file", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) return error_id;
  const char* caller_file = env->get_chars(env, stack, obj_caller_file);
  
  int32_t caller_line = env->get_field_int_by_name(env, stack, obj_caller_info, "line", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) return error_id;
  
  #ifndef _WIN32
  // Block all maskable signals before spawning thread
  sigset_t block_set;
  sigset_t old_set;
  sigfillset(&block_set);
  int mask_rc = pthread_sigmask(SIG_BLOCK, &block_set, &old_set);
#endif
  
  try {
    // Spawn native thread with inherited signal mask
    *nt_thread = std::thread(thread_handler, env, obj_self, obj_task, caller_method_abs_name, caller_file, caller_line);
  }
  catch (const std::exception& e) {
    return env->die(env, stack, "Failed to create thread: %s", __func__, FILE_NAME, __LINE__, e.what());
  }
  
#ifndef _WIN32
  // Restore original signal mask after thread creation
  if (mask_rc == 0) {
    pthread_sigmask(SIG_SETMASK, &old_set, nullptr);
  }
#endif
  
  env->set_pointer(env, stack, obj_self, nt_thread);
  
  return 0;
}

int32_t SPVM__Thread__join(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  SPVM_OBJ* obj_thread = stack[0].oval;
  
  std::thread* nt_thread = (std::thread*)env->get_pointer(env, stack, obj_thread);
  
  try {
    nt_thread->join();
  }
  catch (std::exception& cpp_exception){
    env->die(env, stack, "[System Error]std::thread join failed:%s", __func__, FILE_NAME, __LINE__, cpp_exception.what());
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  return 0;
}

int32_t SPVM__Thread__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  SPVM_OBJ* obj_thread = stack[0].oval;
  
  std::thread* nt_thread = (std::thread*)env->get_pointer(env, stack, obj_thread);
  
  if (nt_thread->joinable()) {
    nt_thread->detach();
  }
  
  env->free_memory_block(env, stack, nt_thread);
  
  return 0;
}

int32_t SPVM__Thread__get_id(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  SPVM_OBJ* obj_thread = stack[0].oval;
  
  std::thread* nt_thread = (std::thread*)env->get_pointer(env, stack, obj_thread);
  
  std::thread::id* thread_id = (std::thread::id*)env->new_memory_block(env, stack, sizeof(std::thread::id));
  
  *thread_id = nt_thread->get_id();
  
  SPVM_OBJ* obj_thread_id = env->new_object_by_name(env, stack, "Thread::ID", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  env->set_pointer(env, stack, obj_thread_id, (void*)thread_id);
  
  stack[0].oval = obj_thread_id;
  
  return 0;
}

}
