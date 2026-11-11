// Copyright (c) 2026 Yuki Kimoto
// MIT License

#include "spvm_native.h"
#include "uv.h"
#include "spvm_uv.h"

static const char* FILE_NAME = "UV/Handle/Stream.c";

void SPVM__UV__Handle__Stream__alloc_cb(uv_handle_t* uv_handle, size_t suggested_size, uv_buf_t* uv_buf) {
  
  int32_t error_id = 0;
  
  SPVM__UV__Handle__HANDLE_DATA* uv_handle_buffer = (SPVM__UV__Handle__HANDLE_DATA*)uv_handle->data;
  
  SPVM_ENV* env = uv_handle_buffer->env;
  SPVM_VALUE* stack = uv_handle_buffer->stack;
  SPVM_OBJ* obj_uv_handle = uv_handle_buffer->obj_uv_handle;
  
  SPVM_OBJ* obj_buffer = env->get_field_object_by_name(env, stack, obj_uv_handle, "read_buffer", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) {
    spvm_diag("[Unexpected Error]%s", env->get_exception_chars(env, stack));
    abort();
  }
  const char* buffer = env->get_chars(env, stack, obj_buffer);
  
  int32_t buffer_length = env->get_field_int_by_name(env, stack, obj_uv_handle, "read_buffer_length", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) {
    spvm_diag("[Unexpected Error]%s", env->get_exception_chars(env, stack));
    abort();
  }
  
  int32_t buffer_offset = env->get_field_int_by_name(env, stack,obj_uv_handle, "read_buffer_offset", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) {
    spvm_diag("[Unexpected Error]%s", env->get_exception_chars(env, stack));
    abort();
  }
  
  uv_buf->base = (char*)buffer + buffer_offset;
  uv_buf->len = buffer_length;
}

void SPVM__UV__Handle__Stream__read_cb(uv_stream_t* uv_handle, ssize_t nread, const uv_buf_t* buf) {
  
  int32_t error_id = 0;
  
  SPVM__UV__Handle__HANDLE_DATA* uv_handle_data = (SPVM__UV__Handle__HANDLE_DATA*)uv_handle->data;
  
  SPVM_ENV* env = uv_handle_data->env;
  SPVM_VALUE* stack = uv_handle_data->stack;
  SPVM_OBJ* obj_uv_handle = uv_handle_data->obj_uv_handle;
  SPVM_OBJ* obj_cb = env->get_field_object_by_name(env, stack, obj_uv_handle, "read_cb", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) {
    spvm_diag("[Unexpected Error]Getting 'read_cb' field failed.");
    abort();
  }
  
  SPVM_OBJ* obj_read_buffer = env->get_field_object_by_name(env, stack, obj_uv_handle, "read_buffer", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) {
    spvm_diag("[Unexpected Error]Getting 'read_buffer' field failed.");
    abort();
  }
  
  assert(obj_cb);
  stack[0].oval = obj_cb;
  stack[1].oval = obj_uv_handle;
  stack[2].ival = nread;
  stack[3].oval = obj_read_buffer;
  env->call_instance_method_by_name(env, stack, "", 4, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) {
    spvm_diag("[An exception is converted to a warning in SPVM__UV__Handle__Stream__read_cb]\n%s", env->get_exception_chars(env, stack));
    return;
  }
  
}

int32_t SPVM__UV__Handle__Stream__read_start(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  SPVM_OBJ* obj_uv_stream = stack[0].oval;
  SPVM_OBJ* obj_buffer = stack[1].oval;
  int32_t buffer_length = stack[2].ival;
  SPVM_OBJ* obj_cb = stack[3].oval;
  int32_t buffer_offset = stack[4].ival;
  
  if (!obj_uv_stream) {
    return env->die(env, stack, "$uv_stream must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  if (!obj_buffer) {
    return env->die(env, stack, "$buffer must be defined.", __func__, FILE_NAME, __LINE__);
  }
  int32_t max_buffer_length = env->length(env, stack, obj_buffer);
  
  if (!(buffer_length >= 0)) {
    return env->die(env, stack, "$buffer_length must be a non-negative number.", __func__, FILE_NAME, __LINE__);
  }
  
  if (!(buffer_offset + buffer_length <= max_buffer_length)) {
    return env->die(env, stack, "$buffer_offset + $buffer_length must be less than or equal to the length of $buffer.", __func__, FILE_NAME, __LINE__);
  }
  
  if (!obj_cb) {
    return env->die(env, stack, "$cb must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  env->set_field_object_by_name(env, stack, obj_uv_stream, "read_cb", obj_cb, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) return error_id;
  
  env->set_field_object_by_name(env, stack, obj_uv_stream, "read_buffer", obj_buffer, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) return error_id;
  
  env->set_field_int_by_name(env, stack, obj_uv_stream, "read_buffer_length", buffer_length, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) return error_id;
  
  env->set_field_int_by_name(env, stack, obj_uv_stream, "read_buffer_offset", buffer_offset, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) return error_id;
  
  uv_stream_t* uv_stream = env->get_pointer(env, stack, obj_uv_stream);
  
  int32_t status = uv_read_start(uv_stream, SPVM__UV__Handle__Stream__alloc_cb, SPVM__UV__Handle__Stream__read_cb);
  
  if (!(status == 0)) {
    return env->die(env, stack, "uv_read_start failed. status=%d.", __func__, FILE_NAME, __LINE__, status);
  }
  
  return 0;
}

int32_t SPVM__UV__Handle__Stream__read_stop(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  SPVM_OBJ* obj_uv_stream = stack[0].oval;
  
  if (!obj_uv_stream) {
    return env->die(env, stack, "$uv_stream must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  uv_stream_t* uv_stream = env->get_pointer(env, stack, obj_uv_stream);
  
  // Stop reading data from the stream
  int32_t status = uv_read_stop(uv_stream);
  
  if (!(status == 0)) {
    return env->die(env, stack, "uv_read_stop failed. status=%d.", __func__, FILE_NAME, __LINE__, status);
  }
  
  return 0;
}
