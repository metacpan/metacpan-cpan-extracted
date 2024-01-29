// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include "eg_css_box.h"

static const char* FILE_NAME = "Eg/CSS/Box.cpp";

int32_t SPVM__Eg__CSS__Box__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  struct tm* st_box = env->new_memory_block(env, stack, sizeof(struct eg_css_box));
  
  void* obj_box = env->new_pointer_object_by_name(env, stack, "Eg::CSS::Box", st_box, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_box;
  
  return 0;
}

int32_t SPVM__Eg__CSS__Box__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_box = stack[0].oval;
  
  struct eg_css_box* st_box = env->get_pointer(env, stack, obj_box);
  env->free_memory_block(env, stack, st_box);
  
  return 0;
}

