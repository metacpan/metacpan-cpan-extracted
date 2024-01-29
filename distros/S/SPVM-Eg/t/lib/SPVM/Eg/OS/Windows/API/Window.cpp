#include <spvm_native.h>

#include <windows.h>
#include <d2d1.h>
#include <dwrite.h>
#include <assert.h>
#include <d3d11.h>
#include <d3dcompiler.h>
#include<memory>

static const char* FILE_NAME = "Eg/OS/Windows/API/Window.cpp";

extern "C" {

int32_t SPVM__Eg__OS__Windows__API__Window__inner_width(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  stack[0].oval = obj_self;
  stack[1].oval = env->new_string_nolen(env, stack, "window_handle");
  env->call_instance_method_by_name(env, stack, "get_data", 2, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  void* obj_window_handle = stack[0].oval;
  
  HWND window_handle = (HWND)env->get_pointer(env, stack, obj_window_handle);
  
  RECT rect;
  GetClientRect(window_handle, &rect);
  
  stack[0].ival = rect.right + 1;
  
  return 0;
}


int32_t SPVM__Eg__OS__Windows__API__Window__inner_height(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  stack[0].oval = obj_self;
  stack[1].oval = env->new_string_nolen(env, stack, "window_handle");
  env->call_instance_method_by_name(env, stack, "get_data", 2, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  void* obj_window_handle = stack[0].oval;
  
  HWND window_handle = (HWND)env->get_pointer(env, stack, obj_window_handle);
  
  RECT rect;
  GetClientRect(window_handle, &rect);
  
  stack[0].ival = rect.bottom + 1;
  
  return 0;
}

int32_t SPVM__Eg__OS__Windows__API__Window__outer_width(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  stack[0].oval = obj_self;
  stack[1].oval = env->new_string_nolen(env, stack, "window_handle");
  env->call_instance_method_by_name(env, stack, "get_data", 2, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  void* obj_window_handle = stack[0].oval;
  
  HWND window_handle = (HWND)env->get_pointer(env, stack, obj_window_handle);
  
  RECT rect;
  GetWindowRect(window_handle, &rect);
  
  stack[0].ival = rect.right + 1;
  
  return 0;
}


int32_t SPVM__Eg__OS__Windows__API__Window__outer_height(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  stack[0].oval = obj_self;
  stack[1].oval = env->new_string_nolen(env, stack, "window_handle");
  env->call_instance_method_by_name(env, stack, "get_data", 2, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  void* obj_window_handle = stack[0].oval;
  
  HWND window_handle = (HWND)env->get_pointer(env, stack, obj_window_handle);
  
  RECT rect;
  GetWindowRect(window_handle, &rect);
  
  stack[0].ival = rect.bottom + 1;
  
  return 0;
}

}
