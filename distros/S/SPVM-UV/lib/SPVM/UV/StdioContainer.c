// Copyright (c) 2026 Yuki Kimoto
// MIT License

#include "spvm_native.h"
#include "uv.h"
#include "spvm_uv.h"

static const char* FILE_NAME = "UV/StdioContainer.c";

int32_t SPVM__UV__StdioContainer__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  uv_stdio_container_t* uv_stdio_container = env->new_memory_block(env, stack, sizeof(uv_stdio_container_t));
  
  SPVM_OBJ* obj_uv_stdio_container = env->new_pointer_object_by_name(env, stack, "UV::StdioContainer", uv_stdio_container, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) return error_id;
  
  stack[0].oval = obj_uv_stdio_container;
  
  return 0;
}

int32_t SPVM__UV__StdioContainer__flags(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  SPVM_OBJ* obj_uv_stdio_container = stack[0].oval;
  
  uv_stdio_container_t* uv_stdio_container = env->get_pointer(env, stack, obj_uv_stdio_container);
  assert(uv_stdio_container);
  
  stack[0].ival = uv_stdio_container->flags;
  
  return 0;
}

int32_t SPVM__UV__StdioContainer__set_flags(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  SPVM_OBJ* obj_uv_stdio_container = stack[0].oval;
  int32_t flags = stack[1].ival;
  
  uv_stdio_container_t* uv_stdio_container = env->get_pointer(env, stack, obj_uv_stdio_container);
  assert(uv_stdio_container);
  
  uv_stdio_container->flags = flags;
  
  return 0;
}

int32_t SPVM__UV__StdioContainer__stream(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  SPVM_OBJ* obj_uv_stdio_container = stack[0].oval;
  
  uv_stdio_container_t* uv_stdio_container = env->get_pointer(env, stack, obj_uv_stdio_container);
  assert(uv_stdio_container);
  
  if (!(uv_stdio_container->flags & (UV_CREATE_PIPE | UV_INHERIT_STREAM))) {
    return env->die(env, stack, "Flags must be UV_CREATE_PIPE or UV_INHERIT_STREAM to get stream.", __func__, FILE_NAME, __LINE__);
  }
  
  SPVM_OBJ* obj_stream = env->get_field_object_by_name(env, stack, obj_uv_stdio_container, "stream", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) return error_id;
  
  stack[0].oval = obj_stream;
  
  return 0;
}

int32_t SPVM__UV__StdioContainer__set_stream(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  SPVM_OBJ* obj_uv_stdio_container = stack[0].oval;
  SPVM_OBJ* obj_uv_stream = stack[1].oval;
  
  uv_stdio_container_t* uv_stdio_container = env->get_pointer(env, stack, obj_uv_stdio_container);
  assert(uv_stdio_container);
  
  if (!(uv_stdio_container->flags & (UV_CREATE_PIPE | UV_INHERIT_STREAM))) {
    return env->die(env, stack, "Flags must be UV_CREATE_PIPE or UV_INHERIT_STREAM to set stream.", __func__, FILE_NAME, __LINE__);
  }
  
  uv_stream_t* uv_stream = NULL;
  if (obj_uv_stream) {
    uv_stream = env->get_pointer(env, stack, obj_uv_stream);
    assert(uv_stream);
  }
  
  uv_stdio_container->data.stream = uv_stream;
  
  env->set_field_object_by_name(env, stack, obj_uv_stdio_container, "stream", obj_uv_stream, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) return error_id;
  
  return 0;
}

int32_t SPVM__UV__StdioContainer__fd(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  SPVM_OBJ* obj_uv_stdio_container = stack[0].oval;
  
  uv_stdio_container_t* uv_stdio_container = env->get_pointer(env, stack, obj_uv_stdio_container);
  assert(uv_stdio_container);
  
  if (!(uv_stdio_container->flags & UV_INHERIT_FD)) {
    return env->die(env, stack, "Flags must be UV_INHERIT_FD to get fd.", __func__, FILE_NAME, __LINE__);
  }
  
  stack[0].ival = uv_stdio_container->data.fd;
  
  return 0;
}

int32_t SPVM__UV__StdioContainer__set_fd(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  SPVM_OBJ* obj_uv_stdio_container = stack[0].oval;
  int32_t fd = stack[1].ival;
  
  uv_stdio_container_t* uv_stdio_container = env->get_pointer(env, stack, obj_uv_stdio_container);
  assert(uv_stdio_container);
  
  if (!(uv_stdio_container->flags & UV_INHERIT_FD)) {
    return env->die(env, stack, "Flags must be UV_INHERIT_FD to set fd.", __func__, FILE_NAME, __LINE__);
  }
  
  uv_stdio_container->data.fd = fd;
  uv_stdio_container->data.stream = NULL;
  
  env->set_field_object_by_name(env, stack, obj_uv_stdio_container, "stream", NULL, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) return error_id;
  
  return 0;
}

int32_t SPVM__UV__StdioContainer__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  SPVM_OBJ* obj_uv_stdio_container = stack[0].oval;
  
  uv_stdio_container_t* uv_stdio_container = env->get_pointer(env, stack, obj_uv_stdio_container);
  
  int32_t no_free = env->no_free(env, stack, obj_uv_stdio_container);
  if (!no_free) {
    env->free_memory_block(env, stack, uv_stdio_container);
  }
  
  return 0;
}
