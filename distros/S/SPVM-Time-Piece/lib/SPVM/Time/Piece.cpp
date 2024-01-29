// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <time.h>
#include <sstream>
#include <iomanip>
#include <errno.h>

extern "C" {

static const char* FILE_NAME = "Time/Piece.cpp";

int32_t SPVM__Time__Piece__foo(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  return 0;
}

int32_t SPVM__Time__Piece__strftime(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_format = stack[1].oval;
  
  if (!obj_format) {
    const char* format = "%a, %d %b %Y %H:%M:%S %Z";
    obj_format = env->new_string(env, stack, format, strlen(format));
  }
  
  int32_t format_length = env->length(env, stack, obj_format);
  
  if (format_length == 0) {
    return env->die(env, stack, "The length of $format must be greater than 1.", __func__, FILE_NAME, __LINE__);
  }
  
  const char* format = env->get_chars(env, stack, obj_format);
  
  void* obj_tm = env->get_field_object_by_name(env, stack, obj_self, "tm", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  struct tm* st_tm = (struct tm*)env->get_pointer(env, stack, obj_tm);
  
  int32_t max_length = format_length + 160;
  
  void* obj_ret = NULL;
  
  while (1) {
    
    obj_ret = env->new_string(env, stack, NULL, max_length);
    
    char* ret = (char*)env->get_chars(env, stack, obj_ret);
    
    errno = 0;
    int32_t write_length = strftime(ret, max_length, format, st_tm);
    
    if (!(errno == 0)) {
      env->die(env, stack, "[System Error]strftime failed:%s. $format is \"%s\"", env->strerror(env, stack, errno, 0), format, __func__, FILE_NAME, __LINE__);
      return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
    }
    
    if (write_length == 0) {
      if (max_length > 100 * format_length) {
        return env->die(env, stack, "Too many memory is allocated.", __func__, FILE_NAME, __LINE__);
      }
      
      max_length *= 2;
    }
    else {
      env->shorten(env, stack, obj_ret, write_length);
      break;
    }
  }
  
  stack[0].oval = obj_ret;
  
  return 0;
}

int32_t SPVM__Time__Piece__strptime_tm(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_string = stack[0].oval;
  
  if (!obj_string) {
    return env->die(env, stack, "$string must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  const char* string = env->get_chars(env, stack, obj_string);
  
  void* obj_format = stack[1].oval;
  
  if (!obj_format) {
    return env->die(env, stack, "$format must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  const char* format = env->get_chars(env, stack, obj_format);
  
  struct tm* st_tm = (struct tm*)env->new_memory_block(env, stack, sizeof(struct tm));
  
  
  std::istringstream string_stream(string);
  
  string_stream >> std::get_time(st_tm, format);
  
  if (string_stream.fail()) {
    return env->die(env, stack, "std::get_time failed.", __func__, FILE_NAME, __LINE__);
  }
  
  void* obj_tm = env->new_pointer_object_by_name(env, stack, "Sys::Time::Tm", st_tm, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_tm;
  
  return 0;
}

}
