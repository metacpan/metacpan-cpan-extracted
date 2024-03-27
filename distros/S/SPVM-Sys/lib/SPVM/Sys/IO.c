// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

// File IO
#include <stdio.h>

// Files and directories
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/file.h>
#include <dirent.h>
#include <fcntl.h>
#if defined(_WIN32)
  #include <direct.h>
#endif

// Utilities
#include <errno.h>
#include <stdlib.h>

static const char* FILE_NAME = "Sys/IO.c";

int32_t SPVM__Sys__IO__fopen(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_path = stack[0].oval;
  if (!obj_path) {
    return env->die(env, stack, "$path must be defined.", __func__, FILE_NAME, __LINE__);
  }
  const char* path = env->get_chars(env, stack, obj_path);
  
  void* obj_mode = stack[1].oval;
  if (!obj_mode) {
    return env->die(env, stack, "$mode must be defined.", __func__, FILE_NAME, __LINE__);
  }
  const char* mode = env->get_chars(env, stack, obj_mode);
  
  FILE* stream = fopen(path, mode);
  
  if (!stream) {
    env->die(env, stack, "[System Error]fopen failed:%s. $path is \"%s\". $mode is \"%s\"", env->strerror(env, stack, errno, 0), path, mode, __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  void* obj_stream = env->new_pointer_object_by_name(env, stack, "Sys::IO::FileStream", stream, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_stream;
  
  return 0;
}

int32_t SPVM__Sys__IO__fdopen(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  int32_t fd = stack[0].ival;
  
  if (!(fd >= 0)) {
    return env->die(env, stack, "$fd must be greater than or equal to 0.", __func__, FILE_NAME, __LINE__);
  }
  
  void* obj_mode = stack[1].oval;
  
  if (!obj_mode) {
    return env->die(env, stack, "$mode must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  const char* mode = env->get_chars(env, stack, obj_mode);
  
  FILE* stream = fdopen(fd, mode);
  if (!stream) {
    env->die(env, stack, "[System Error]fdopen failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  void* obj_stream = env->new_pointer_object_by_name(env, stack, "Sys::IO::FileStream", stream, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_stream;
  
  return 0;
}

int32_t SPVM__Sys__IO__fileno(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_stream = stack[0].oval;
  
  if (!obj_stream) {
    return env->die(env, stack, "$stream must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  FILE* stream = env->get_pointer(env, stack, obj_stream);
  
  int32_t fd = fileno(stream);
  if (fd == -1) {
    env->die(env, stack, "[System Error]fileno failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = fd;
  
  return 0;
}

int32_t SPVM__Sys__IO__fread(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_ptr = stack[0].oval;
  
  if (!obj_ptr) {
    return env->die(env, stack, "$ptr must be defined.", __func__, FILE_NAME, __LINE__);
  }
  char* ptr = (char*)env->get_chars(env, stack, obj_ptr);
  int32_t ptr_length = env->length(env, stack, obj_ptr);
  
  int32_t size = stack[1].ival;
  if (!(size >= 0)) {
    return env->die(env, stack, "$size must be more than or equal to 0.", __func__, FILE_NAME, __LINE__);
  }
  
  int32_t nmemb = stack[2].ival;
  if (!(nmemb >= 0)) {
    return env->die(env, stack, "$nmemb must be more than or equal to 0.", __func__, FILE_NAME, __LINE__);
  }
  
  void* obj_stream = stack[3].oval;
  if (!obj_stream) {
    return env->die(env, stack, "$stream must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  int32_t ptr_offset = stack[4].ival;
  if (!(nmemb * size <= ((ptr_length - ptr_offset))  )) {
    return env->die(env, stack, "$nmemb * $size must be less than or equal to the length of $ptr - $ptr_offset.", __func__, FILE_NAME, __LINE__);
  }
  
  FILE* stream = env->get_pointer(env, stack, obj_stream);
  
  int32_t read_length = fread(ptr + ptr_offset, size, nmemb, stream);
  
  if (read_length < nmemb) {
    if (ferror(stream)) {
      env->die(env, stack, "[System Error]fread failed.", __func__, FILE_NAME, __LINE__);
      return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
    }
  }
  
  stack[0].ival = read_length;
  
  return 0;
}

int32_t SPVM__Sys__IO__feof(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_stream = stack[0].oval;
  
  if (!obj_stream) {
    return env->die(env, stack, "$stream must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  FILE* stream = env->get_pointer(env, stack, obj_stream);
  
  int32_t ret = feof(stream);
  
  stack[0].ival = ret;
  
  return 0;
}

int32_t SPVM__Sys__IO__ferror(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_stream = stack[0].oval;
  
  if (!obj_stream) {
    return env->die(env, stack, "$stream must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  FILE* stream = env->get_pointer(env, stack, obj_stream);
  
  int32_t ret = ferror(stream);
  
  stack[0].ival = ret;
  
  return 0;
}

int32_t SPVM__Sys__IO__clearerr(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_stream = stack[0].oval;
  
  if (!obj_stream) {
    return env->die(env, stack, "$stream must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  FILE* stream = env->get_pointer(env, stack, obj_stream);
  
  clearerr(stream);
  
  return 0;
}

int32_t SPVM__Sys__IO__getc(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_stream = stack[0].oval;
  
  if (!obj_stream) {
    return env->die(env, stack, "$stream must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  FILE* stream = env->get_pointer(env, stack, obj_stream);
  
  int32_t ch = getc(stream);
  
  if (ch == EOF) {
    if (ferror(stream)) {
      env->die(env, stack, "[System Error]getc failed.", __func__, FILE_NAME, __LINE__);
      return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
    }
  }
  
  stack[0].ival = ch;
  
  return 0;
}

int32_t SPVM__Sys__IO__ungetc(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t c = stack[0].ival;
  
  void* obj_stream = stack[1].oval;
  if (!obj_stream) {
    return env->die(env, stack, "$stream must be defined.", __func__, FILE_NAME, __LINE__);
  }
  FILE* stream = env->get_pointer(env, stack, obj_stream);
  
  int32_t status = ungetc(c, stream);
  if (status == EOF) {
    env->die(env, stack, "[System Error]ungetc failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__IO__fgets(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_s = stack[0].oval;
  if (!obj_s) {
    return env->die(env, stack, "$s must be defined.", __func__, FILE_NAME, __LINE__);
  }
  char* s = (char*)env->get_chars(env, stack, obj_s);
  int32_t s_length = env->length(env, stack, obj_s);
  
  int32_t size = stack[1].ival;
  if (!(size >= 0)) {
    return env->die(env, stack, "$size must be more than or equal to 0.", __func__, FILE_NAME, __LINE__);
  }
  
  void* obj_stream = stack[2].oval;
  if (!obj_stream) {
    return env->die(env, stack, "$stream must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  int32_t s_offset = stack[3].ival;
  
  if (!(size <= s_length - s_offset)) {
    return env->die(env, stack, "$size must be less than the length of $s - $s_offset.", __func__, FILE_NAME, __LINE__);
  }
  
  FILE* stream = env->get_pointer(env, stack, obj_stream);
  
  char* ret_s = fgets(s + s_offset, size, stream);
  
  if (ret_s) {
    stack[0].oval = obj_s;
  }
  else {
    stack[0].oval = NULL;
  }
  
  return 0;
}

int32_t SPVM__Sys__IO__fwrite(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_ptr = stack[0].oval;
  if (!obj_ptr) {
    return env->die(env, stack, "$ptr must be defined.", __func__, FILE_NAME, __LINE__);
  }
  char* ptr = (char*)env->get_chars(env, stack, obj_ptr);
  int32_t ptr_length = env->length(env, stack, obj_ptr);
  
  int32_t size = stack[1].ival;
  if (!(size >= 0)) {
    return env->die(env, stack, "$size must be more than or equal to 0.", __func__, FILE_NAME, __LINE__);
  }
  
  int32_t nmemb = stack[2].ival;
  if (!(nmemb >= 0)) {
    return env->die(env, stack, "$nmemb must be more than or equal to 0.", __func__, FILE_NAME, __LINE__);
  }
  
  void* obj_stream = stack[3].oval;
  if (!obj_stream) {
    return env->die(env, stack, "$stream must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  int32_t ptr_offset = stack[4].ival;
  if (!(nmemb * size <= ((ptr_length - ptr_offset))  )) {
    return env->die(env, stack, "$nmemb * $size must be less than or equal to the length of $ptr - $ptr_offset.", __func__, FILE_NAME, __LINE__);
  }
  
  FILE* stream = env->get_pointer(env, stack, obj_stream);
  
  int32_t write_length = fwrite(ptr + ptr_offset, size, nmemb, stream);
  
  if (write_length < nmemb) {
    if (ferror(stream)) {
      env->die(env, stack, "[System Error]fwrite failed.", __func__, FILE_NAME, __LINE__);
      return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
    }
  }
  
  stack[0].ival = write_length;
  
  return 0;
}

int32_t SPVM__Sys__IO__fclose(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_stream = stack[0].oval;
  
  if (!obj_stream) {
    return env->die(env, stack, "$stream must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  FILE* stream = env->get_pointer(env, stack, obj_stream);
  
  int32_t status = fclose(stream);
  if (status == EOF) {
    env->die(env, stack, "[System Error]fclose failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  env->set_field_byte_by_name(env, stack, obj_stream, "closed", 1, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__IO__fseek(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_stream = stack[0].oval;
  
  if (!obj_stream) {
    return env->die(env, stack, "$stream must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  FILE* stream = env->get_pointer(env, stack, obj_stream);
  
  int64_t offset = stack[1].lval;
  
  if (!(offset >= 0)) {
    return env->die(env, stack, "$offset must be greater than or equal to 0.", __func__, FILE_NAME, __LINE__);
  }
  
  int32_t whence = stack[2].ival;
  
  int32_t status = fseek(stream, offset, whence);
  if (status == -1) {
    env->die(env, stack, "[System Error]fseek failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__IO__ftell(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_stream = stack[0].oval;
  
  if (!obj_stream) {
    return env->die(env, stack, "$stream must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  FILE* stream = env->get_pointer(env, stack, obj_stream);
  
  int64_t offset = ftell(stream);
  if (offset == -1) {
    env->die(env, stack, "[System Error]ftell failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].lval = offset;
  
  return 0;
}

int32_t SPVM__Sys__IO__fflush(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_stream = stack[0].oval;
  
  if (!obj_stream) {
    return env->die(env, stack, "$stream must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  FILE* stream = env->get_pointer(env, stack, obj_stream);
  
  int32_t status = fflush(stream);
  if (status == EOF) {
    env->die(env, stack, "[System Error]fflush failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__IO__freopen(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_path = stack[0].oval;
  if (!obj_path) {
    return env->die(env, stack, "$path must be defined.", __func__, FILE_NAME, __LINE__);
  }
  const char* path = env->get_chars(env, stack, obj_path);
  
  void* obj_mode = stack[1].oval;
  if (!obj_mode) {
    return env->die(env, stack, "$mode must be defined.", __func__, FILE_NAME, __LINE__);
  }
  const char* mode = env->get_chars(env, stack, obj_mode);
  
  void* obj_stream = stack[2].oval;
  if (!obj_stream) {
    return env->die(env, stack, "$stream must be defined.", __func__, FILE_NAME, __LINE__);
  }
  FILE* stream = env->get_pointer(env, stack, obj_stream);
  
  FILE* reopened_stream = freopen(path, mode, stream);
  
  if (!reopened_stream) {
    env->die(env, stack, "[System Error]freopen failed:%s. $path is \"%s\".", env->strerror(env, stack, errno, 0), path, __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].oval = obj_stream;
  
  return 0;
}

int32_t SPVM__Sys__IO__setvbuf(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_stream = stack[0].oval;
  if (!obj_stream) {
    return env->die(env, stack, "$stream must be defined.", __func__, FILE_NAME, __LINE__);
  }
  FILE* stream = env->get_pointer(env, stack, obj_stream);
  
  void* obj_buf = stack[1].oval;
  char* buf = NULL;
  int32_t buf_length = -1;
  if (obj_buf) {
    buf = (char*)env->get_chars(env, stack, obj_buf);
    buf_length = env->length(env, stack, obj_buf);
  }
  
  int32_t mode = stack[2].ival;
  
  int32_t size = stack[3].ival;
  
  if (buf) {
    if (!(size >= 0)) {
      return env->die(env, stack, "$size must be greater than or equal to 0.", __func__, FILE_NAME, __LINE__);
    }
    if (!(size <= buf_length)) {
      return env->die(env, stack, "$size must be less than or equal to the length of $buf.", __func__, FILE_NAME, __LINE__);
    }
  }
  
  int32_t status = setvbuf(stream, buf, mode, size);
  if (!(status == 0)) {
    env->die(env, stack, "[System Error]setvbuf failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__IO__open(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_path = stack[0].oval;
  
  if (!obj_path) {
    return env->die(env, stack, "$path must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  int32_t flags = stack[1].ival;
  
  int32_t mode = stack[2].ival;
  
  const char* path = env->get_chars(env, stack, obj_path);
  
  int32_t fd = open(path, flags, mode);
  if (fd == -1) {
    env->die(env, stack, "[System Error]open failed:%s. $path is \"%s\".", env->strerror(env, stack, errno, 0), path, __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = fd;
  
  return 0;
}

int32_t SPVM__Sys__IO__read(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  int32_t fd = stack[0].ival;
  
  void* obj_buf = stack[1].oval;
  if (!obj_buf) {
    return env->die(env, stack, "$buf must be defined.", __func__, FILE_NAME, __LINE__);
  }
  char* buf = (char*)env->get_chars(env, stack, obj_buf);
  int32_t buf_length = env->length(env, stack, obj_buf);
  
  int32_t count = stack[2].ival;
  if (!(count >= 0)) {
    return env->die(env, stack, "$count must be more than or equal to 0.", __func__, FILE_NAME, __LINE__);
  }
  
  int32_t buf_offset = stack[3].ival;
  if (!(count <= buf_length - buf_offset)) {
    return env->die(env, stack, "$count must be less than the length of $buf - $buf_offset.", __func__, FILE_NAME, __LINE__);
  }
  
  int32_t read_length = read(fd, buf + buf_offset, count);
  if (read_length == -1) {
    env->die(env, stack, "[System Error]read failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = read_length;
  
  return 0;
}

int32_t SPVM__Sys__IO__write(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  int32_t fd = stack[0].ival;
  
  void* obj_buf = stack[1].oval;
  if (!obj_buf) {
    return env->die(env, stack, "$buf must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  char* buf = (char*)env->get_chars(env, stack, obj_buf);
  int32_t buf_length = env->length(env, stack, obj_buf);
  
  int32_t count = stack[2].ival;
  
  int32_t buf_offset = stack[3].ival;
  
  if (!(buf_offset >= 0)) {
    return env->die(env, stack, "$buf_offse must be greater than or equal to 0.", __func__, FILE_NAME, __LINE__);
  }
  
  if (count < 0) {
    count = buf_length - buf_offset;
  }
  
  if (!(count <= buf_length - buf_offset)) {
    return env->die(env, stack, "$count must be less than the length of $buf - $buf_offset.", __func__, FILE_NAME, __LINE__);
  }
  
  int32_t write_length = write(fd, buf + buf_offset, count);
  if (write_length == -1) {
    env->die(env, stack, "[System Error]write failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = write_length;
  
  return 0;
}

int32_t SPVM__Sys__IO__lseek(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t fd = stack[0].ival;
  
  int64_t offset = stack[1].lval;
  
  if (!(offset >= 0)) {
    return env->die(env, stack, "$offset must be greater than or equal to 0.", __func__, FILE_NAME, __LINE__);
  }
  
  int32_t whence = stack[2].ival;
  
  int64_t cur_offset = lseek(fd, offset, whence);
  if (cur_offset == -1) {
    env->die(env, stack, "[System Error]lseek failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  
  stack[0].lval = cur_offset;
  
  return 0;
}

int32_t SPVM__Sys__IO__close(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t fd = stack[0].ival;
  
  int32_t status = close(fd);
  if (status == -1) {
    env->die(env, stack, "[System Error]close failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__IO__fsync(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  return env->die(env, stack, "fsync is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
#else
  int32_t fd = stack[0].ival;
  
  int32_t status = fsync(fd);
  if (status == -1) {
    env->die(env, stack, "[System Error]fsync failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
#endif
}

int32_t SPVM__Sys__IO__fcntl(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  return env->die(env, stack, "fcntl is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
#else
  
  int32_t error_id = 0;
  
  int32_t fd = stack[0].ival;
  
  int32_t command = stack[1].ival;
  
  int32_t ret = -1;
  
  void* obj_command_arg = stack[2].oval;
  
  if (!obj_command_arg) {
    ret = fcntl(fd, command, NULL);
  }
  else {
    int32_t command_arg_basic_type_id = env->get_object_basic_type_id(env, stack, obj_command_arg);
    int32_t command_arg_type_dimension = env->get_object_type_dimension(env, stack, obj_command_arg);
    
    // Int
    if (command_arg_basic_type_id == SPVM_NATIVE_C_BASIC_TYPE_ID_INT_CLASS && command_arg_type_dimension == 0) {
      int32_t value = env->get_field_int_by_name(env, stack, obj_command_arg, "value", &error_id, __func__, FILE_NAME, __LINE__);
      ret = fcntl(fd, command, value);
    }
    else if (env->is_type_by_name(env, stack, obj_command_arg, "Sys::IO::Flock", 0)) {
      struct flock* st_flock = env->get_pointer(env, stack, obj_command_arg);
      ret = fcntl(fd, command, st_flock);
    }
    else {
      return env->die(env, stack, "$command_arg must be an instance of the Int class or Sys::IO::Flock class.", __func__, FILE_NAME, __LINE__);
    }
  }
  
  stack[0].ival = ret;
  
  return 0;
#endif
}

int32_t SPVM__Sys__IO__ftruncate(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t fd = stack[0].ival;
  
  int64_t length = stack[1].lval;
  
  int32_t status = ftruncate(fd, length);
  
  if (status == -1) {
    env->die(env, stack, "[System Error]ftruncate failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__IO__flock(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "The flock method in the class Sys::IO is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  
  int32_t fd = stack[0].ival;

  int32_t operation = stack[1].ival;
  
  int32_t status = flock(fd, operation);
  if (status == -1) {
    env->die(env, stack, "[System Error]flock failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
#endif
}

int32_t SPVM__Sys__IO__access(SPVM_ENV* env, SPVM_VALUE* stack) {

  void* obj_pathname = stack[0].oval;
  
  if (!obj_pathname) {
    return env->die(env, stack, "$pathname must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  const char* pathname = env->get_chars(env, stack, obj_pathname);
  
  int32_t mode = stack[1].ival;
  
  int32_t status = access(pathname, mode);
  
  if (status == -1) {
    const char* pathname = env->get_chars(env, stack, obj_pathname);
    env->die(env, stack, "[System Error]access failed:%s.", env->strerror(env, stack, errno, 0), pathname, __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__IO__faccessat(SPVM_ENV* env, SPVM_VALUE* stack) {
  
#if defined(_WIN32)
  return env->die(env, stack, "faccessat is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
#else
  int32_t dirfd = stack[0].ival;
  
  void* obj_pathname = stack[1].oval;
  if (!obj_pathname) {
    return env->die(env, stack, "$pathname must be defined.", __func__, FILE_NAME, __LINE__);
  }
  const char* pathname = env->get_chars(env, stack, obj_pathname);
  
  int32_t mode = stack[2].ival;
  
  int32_t flags = stack[3].ival;
  
  int32_t status = faccessat(dirfd, pathname, mode, flags);
  
  if (status == -1) {
    const char* pathname = env->get_chars(env, stack, obj_pathname);
    env->die(env, stack, "[System Error]faccessat failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
#endif
}

int32_t SPVM__Sys__IO__truncate(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_path = stack[0].oval;
  if (!obj_path) {
    return env->die(env, stack, "$path must be defined.", __func__, FILE_NAME, __LINE__);
  }
  const char* path = env->get_chars(env, stack, obj_path);
  
  int64_t length = stack[1].lval;
  if (!(length >= 0)) {
    return env->die(env, stack, "$length must be less than or equal to 0.", __func__, FILE_NAME, __LINE__);
  }
  
  int32_t status = truncate(path, length);
  if (status == -1) {
    env->die(env, stack, "[System Error]truncate failed:%s. $path is \"%s\".", env->strerror(env, stack, errno, 0), path, __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__IO__mkdir(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_path = stack[0].oval;
  
  if (!obj_path) {
    return env->die(env, stack, "$path must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  const char* path = env->get_chars(env, stack, obj_path);
  
  int32_t mode = stack[1].ival;
  
#if defined(_WIN32)
  int32_t status = _mkdir(path);
#else
  int32_t status = mkdir(path, mode);
#endif
  
  if (status == -1) {
    env->die(env, stack, "[System Error]mkdir failed:%s. $path is \"%s\".", env->strerror(env, stack, errno, 0), path, __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__IO__umask(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t mode = stack[0].ival;
  
  int32_t old_mode = umask(mode);
  
  stack[0].ival = old_mode;
  
  return 0;
}

int32_t SPVM__Sys__IO__rmdir(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_path = stack[0].oval;
  
  if (!obj_path) {
    return env->die(env, stack, "$path must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  const char* path = env->get_chars(env, stack, obj_path);
  
  int32_t status = rmdir(path);
  if (status == -1) {
    env->die(env, stack, "[System Error]rmdir failed:%s. $path is \"%s\".", env->strerror(env, stack, errno, 0), path, __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__IO__unlink(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_pathname = stack[0].oval;
  
  if (!obj_pathname) {
    return env->die(env, stack, "$pathname must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  const char* pathname = env->get_chars(env, stack, obj_pathname);
  
  int32_t status = unlink(pathname);
  if (status == -1) {
    env->die(env, stack, "[System Error]unlink failed:%s. $pathname is \"%s\".", env->strerror(env, stack, errno, 0), pathname, __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__IO__rename(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_oldpath = stack[0].oval;
  
  if (!obj_oldpath) {
    return env->die(env, stack, "$oldpath must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  const char* oldpath = env->get_chars(env, stack, obj_oldpath);
  
  void* obj_newpath = stack[1].oval;
  
  if (!obj_newpath) {
    return env->die(env, stack, "$newpath must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  const char* newpath = env->get_chars(env, stack, obj_newpath);
  
  int32_t status = rename(oldpath, newpath);
  if (status == -1) {
    env->die(env, stack, "[System Error]rename failed:%s. $oldpath is \"%s\". $newpath is \"%s\".", env->strerror(env, stack, errno, 0), oldpath, newpath, __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__IO__getcwd(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_buf = stack[0].oval;
  
  int32_t size = stack[1].ival;
  
  if (!(size >= 0)) {
    return env->die(env, stack, "$size must be greater than or equal to 0.", __func__, FILE_NAME, __LINE__);
  }
  
  char* ret_buf;
  if (obj_buf) {
    char* buf = (char*)env->get_chars(env, stack, obj_buf);
    int32_t buf_length = env->length(env, stack, obj_buf);
    if (!(size <= buf_length)) {
      return env->die(env, stack, "$size must be less than or equal to the lenght of $buf.", __func__, FILE_NAME, __LINE__);
    }
    
    ret_buf = getcwd(buf, size);
  }
  else {
    ret_buf = getcwd(NULL, size);
    if (ret_buf) {
      obj_buf = env->new_string(env, stack, ret_buf, strlen(ret_buf));
      free(ret_buf);
    }
  }
  
  if (!ret_buf) {
    env->die(env, stack, "[System Error]getcwd failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].oval = obj_buf;
  
  return 0;
}

int32_t SPVM__Sys__IO___getdcwd(SPVM_ENV* env, SPVM_VALUE* stack) {
#if !defined(_WIN32)
  env->die(env, stack, "_getdcwd is not supported in this system(!defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  int32_t error_id = 0;
  
  int32_t drive = stack[0].ival;
  
  void* obj_buffer = stack[1].oval;
  
  int32_t maxlen = stack[2].ival;
  
  if (!(maxlen > 0)) {
    return env->die(env, stack, "$maxlen must be greater than 0.", __func__, FILE_NAME, __LINE__);
  }
  
  char* ret_buffer;
  if (obj_buffer) {
    char* buffer = (char*)env->get_chars(env, stack, obj_buffer);
    int32_t buffer_length = env->length(env, stack, obj_buffer);
    if (!(maxlen <= buffer_length)) {
      return env->die(env, stack, "$maxlen must be less than or equal to the lenght of $buffer.", __func__, FILE_NAME, __LINE__);
    }
    
    ret_buffer = _getdcwd(drive, buffer, maxlen);
  }
  else {
    ret_buffer = _getdcwd(drive, NULL, maxlen);
    if (ret_buffer) {
      obj_buffer = env->new_string(env, stack, ret_buffer, strlen(ret_buffer));
      free(ret_buffer);
    }
  }
  
  if (!ret_buffer) {
    env->die(env, stack, "[System Error]_getdcwd failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].oval = obj_buffer;
  
  return 0;
#endif
}

int32_t SPVM__Sys__IO__realpath(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "realpath is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  
  void* obj_path = stack[0].oval;
  
  if (!obj_path) {
    return env->die(env, stack, "$path must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  const char* path = env->get_chars(env, stack, obj_path);
  
  void* obj_resolved_path = stack[1].oval;
  
  char* ret_resolved_path;
  if (obj_resolved_path) {
    char* resolved_path = (char*)env->get_chars(env, stack, obj_resolved_path);
    ret_resolved_path = realpath(path, resolved_path);
  }
  else {
    ret_resolved_path = realpath(path, NULL);
    if (ret_resolved_path) {
      obj_resolved_path = env->new_string(env, stack, ret_resolved_path, strlen(ret_resolved_path));
      free(ret_resolved_path);
    }
  }
  
  if (!ret_resolved_path) {
    env->die(env, stack, "[System Error]realpath failed:%s. $path is \"%s\".", env->strerror(env, stack, errno, 0), path, __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].oval = obj_resolved_path;

  return 0;
#endif
}

int32_t SPVM__Sys__IO___fullpath(SPVM_ENV* env, SPVM_VALUE* stack) {
#if !defined(_WIN32)
  env->die(env, stack, "_fullpath is not supported in this system(!defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  void* obj_absPath = stack[0].oval;
  
  void* obj_relPath = stack[1].oval;

  if (!obj_relPath) {
    return env->die(env, stack, "$relPath must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  char* relPath = (char*)env->get_chars(env, stack, obj_relPath);
  
  int32_t maxLength = stack[2].ival;
  
  char* ret_absPath;
  if (obj_absPath) {
    char* absPath = (char*)env->get_chars(env, stack, obj_absPath);
    ret_absPath = _fullpath(absPath, relPath, maxLength);
  }
  else {
    ret_absPath = _fullpath(NULL, relPath, 0);
    if (ret_absPath) {
      obj_absPath = env->new_string(env, stack, ret_absPath, strlen(ret_absPath));
      free(ret_absPath);
    }
  }
  
  if (!ret_absPath) {
    env->die(env, stack, "[System Error]_fullpath failed:%s. $relPath is \"%s\".", env->strerror(env, stack, errno, 0), relPath, __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].oval = obj_absPath;

  return 0;
#endif
}

int32_t SPVM__Sys__IO__chdir(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_path = stack[0].oval;
  if (!obj_path) {
    return env->die(env, stack, "$path must be defined.", __func__, FILE_NAME, __LINE__);
  }
  const char* path = env->get_chars(env, stack, obj_path);
  
  int32_t status = chdir(path);
  if (status == -1) {
    env->die(env, stack, "[System Error]chdir failed:%s. $path is \"%s\".", env->strerror(env, stack, errno, 0), path, __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__IO__chmod(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_path = stack[0].oval;
  if (!obj_path) {
    return env->die(env, stack, "$path must be defined.", __func__, FILE_NAME, __LINE__);
  }
  const char* path = env->get_chars(env, stack, obj_path);
  
  int32_t mode = stack[1].ival;
  
  int32_t status = chmod(path, mode);
  if (status == -1) {
    env->die(env, stack, "[System Error]chmod failed:%s. $path is \"%s\".", env->strerror(env, stack, errno, 0), path, __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__IO__chown(SPVM_ENV* env, SPVM_VALUE* stack) {
  
#if defined(_WIN32)
  env->die(env, stack, "chown is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  void* obj_path = stack[0].oval;
  if (!obj_path) {
    return env->die(env, stack, "$path must be defined.", __func__, FILE_NAME, __LINE__);
  }
  const char* path = env->get_chars(env, stack, obj_path);
  
  int32_t owner = stack[1].ival;
  
  int32_t group = stack[2].ival;
  
  int32_t status = chown(path, owner, group);
  if (status == -1) {
    env->die(env, stack, "[System Error]chown failed:%s. $path is \"%s\".", env->strerror(env, stack, errno, 0), path, __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
#endif
}

int32_t SPVM__Sys__IO__symlink(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "symlink is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  int32_t error_id = 0;
  
  void* obj_oldpath = stack[0].oval;
  if (!obj_oldpath) {
    return env->die(env, stack, "$oldpath must be defined.", __func__, FILE_NAME, __LINE__);
  }
  const char* oldpath = env->get_chars(env, stack, obj_oldpath);

  void* obj_newpath = stack[1].oval;
  if (!obj_newpath) {
    return env->die(env, stack, "$newpath must be defined.", __func__, FILE_NAME, __LINE__);
  }
  const char* newpath = env->get_chars(env, stack, obj_newpath);
  
  int32_t status = symlink(oldpath, newpath);
  if (status == -1) {
    env->die(env, stack, "[System Error]symlink failed:%s. $oldpath is \"%s\". $newpath is \"%s\"", env->strerror(env, stack, errno, 0), oldpath, newpath, __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
#endif
}

int32_t SPVM__Sys__IO__readlink(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "readlink is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  int32_t error_id = 0;
  
  void* obj_path = stack[0].oval;
  if (!obj_path) {
    return env->die(env, stack, "$path must be defined.", __func__, FILE_NAME, __LINE__);
  }
  const char* path = env->get_chars(env, stack, obj_path);

  void* obj_buf = stack[1].oval;
  if (!obj_buf) {
    return env->die(env, stack, "$buf must be defined.", __func__, FILE_NAME, __LINE__);
  }
  char* buf = (char*)env->get_chars(env, stack, obj_buf);
  int32_t buf_length = env->length(env, stack, obj_buf);
  
  int32_t bufsiz = stack[2].ival;
  if (!(bufsiz >= 0)) {
    return env->die(env, stack, "$bufsiz must be greater than or equal to 0.", __func__, FILE_NAME, __LINE__);
  }
  if (!(bufsiz <= buf_length)) {
    return env->die(env, stack, "$bufsiz must be less than or equal to the length of $buf.", __func__, FILE_NAME, __LINE__);
  }
  
  int32_t placed_length = readlink(path, buf, bufsiz);
  if (placed_length == -1) {
    env->die(env, stack, "[System Error]readlink failed:%s. $path is \"%s\".", env->strerror(env, stack, errno, 0), path, __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = placed_length;
  
  return 0;
#endif
}

int32_t SPVM__Sys__IO__opendir(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_dir = stack[0].oval;
  if (!obj_dir) {
    return env->die(env, stack, "$dir must be defined.", __func__, FILE_NAME, __LINE__);
  }
  const char* dir = env->get_chars(env, stack, obj_dir);
  
  DIR* dir_stream = opendir(dir);
  if (!dir_stream) {
    env->die(env, stack, "[System Error]opendir failed:%s. $dir is \"%s\".", env->strerror(env, stack, errno, 0), dir, __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  void* obj_dir_stream = env->new_pointer_object_by_name(env, stack, "Sys::IO::DirStream", dir_stream, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_dir_stream;
  
  return 0;
}

int32_t SPVM__Sys__IO__closedir(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_dirp = stack[0].oval;
  if (!obj_dirp) {
    return env->die(env, stack, "$dirp must be defined.", __func__, FILE_NAME, __LINE__);
  }
  DIR* dirp = env->get_pointer(env, stack, obj_dirp);
  
  int32_t status = closedir(dirp);
  if (status == -1) {
    env->die(env, stack, "[System Error]closedir failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  env->set_field_byte_by_name(env, stack, obj_dirp, "closed", 1, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__IO__readdir(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_dirp = stack[0].oval;
  if (!obj_dirp) {
    return env->die(env, stack, "$dirp must be defined.", __func__, FILE_NAME, __LINE__);
  }
  DIR* dirp = env->get_pointer(env, stack, obj_dirp);
  
  errno = 0;
  struct dirent* dirent = readdir(dirp);
  if (errno != 0) {
    env->die(env, stack, "[System Error]readdir failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  if (dirent) {
    void* obj_dirent = env->new_pointer_object_by_name(env, stack, "Sys::IO::Dirent", dirent, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    stack[0].oval = obj_dirent;
  }
  else {
    stack[0].oval = NULL;
  }
  
  return 0;
}

int32_t SPVM__Sys__IO__rewinddir(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_dirp = stack[0].oval;
  
  if (!obj_dirp) {
    return env->die(env, stack, "$dirp must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  DIR* dirp = env->get_pointer(env, stack, obj_dirp);
  
  rewinddir(dirp);
  
  return 0;
}

int32_t SPVM__Sys__IO__telldir(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_dirp = stack[0].oval;
  if (!obj_dirp) {
    return env->die(env, stack, "$dirp must be defined.", __func__, FILE_NAME, __LINE__);
  }
  DIR* dirp = env->get_pointer(env, stack, obj_dirp);
  
  int64_t offset = telldir(dirp);
  if (offset == -1) {
    env->die(env, stack, "[System Error]telldir failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].lval = offset;
  
  return 0;
}

int32_t SPVM__Sys__IO__seekdir(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_dirp = stack[0].oval;
  
  if (!obj_dirp) {
    return env->die(env, stack, "$dirp must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  DIR* dirp = env->get_pointer(env, stack, obj_dirp);

  int64_t offset = stack[1].ival;
  
  if (!(offset >= 0)) {
    return env->die(env, stack, "$offset must be less than or equal to 0.", __func__, FILE_NAME, __LINE__);
  }
  
  seekdir(dirp, offset);
  
  return 0;
}

int32_t SPVM__Sys__IO__popen(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "popen is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  int32_t error_id = 0;
  
  void* obj_command = stack[0].oval;
  if (!obj_command) {
    return env->die(env, stack, "$command must be defined.", __func__, FILE_NAME, __LINE__);
  }
  const char* command = env->get_chars(env, stack, obj_command);
  
  void* obj_type = stack[1].oval;
  
  if (!obj_type) {
    return env->die(env, stack, "$type must be defined.", __func__, FILE_NAME, __LINE__);
  }
  const char* type = env->get_chars(env, stack, obj_type);
  
  FILE* stream = popen(command, type);
  
  if (!stream) {
    env->die(env, stack, "[System Error]popen failed:%s.", env->strerror(env, stack, errno, 0), command, __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  void* obj_stream = env->new_pointer_object_by_name(env, stack, "Sys::IO::FileStream", stream, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  env->set_field_byte_by_name(env, stack, obj_stream, "is_pipe", 1, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_stream;
  
  return 0;
#endif
}

int32_t SPVM__Sys__IO___popen(SPVM_ENV* env, SPVM_VALUE* stack) {
#if !defined(_WIN32)
  env->die(env, stack, "_popen is not supported in this system(!defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  int32_t error_id = 0;
  
  void* obj_command = stack[0].oval;
  if (!obj_command) {
    return env->die(env, stack, "$command must be defined.", __func__, FILE_NAME, __LINE__);
  }
  const char* command = env->get_chars(env, stack, obj_command);
  
  void* obj_type = stack[1].oval;
  
  if (!obj_type) {
    return env->die(env, stack, "$type must be defined.", __func__, FILE_NAME, __LINE__);
  }
  const char* type = env->get_chars(env, stack, obj_type);
  
  FILE* stream = _popen(command, type);
  
  if (!stream) {
    env->die(env, stack, "[System Error]_popen failed:%s.", env->strerror(env, stack, errno, 0), command, __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  void* obj_stream = env->new_pointer_object_by_name(env, stack, "Sys::IO::FileStream", stream, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  env->set_field_byte_by_name(env, stack, obj_stream, "is_pipe", 1, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_stream;
  
  return 0;
#endif
}

int32_t SPVM__Sys__IO__pclose(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "pclose is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  int32_t error_id = 0;
  
  void* obj_stream = stack[0].oval;
  if (!obj_stream) {
    return env->die(env, stack, "$stream must be defined.", __func__, FILE_NAME, __LINE__);
  }
  FILE* stream = env->get_pointer(env, stack, obj_stream);
  
  int32_t status = pclose(stream);
  
  if (status == -1) {
    env->die(env, stack, "[System Error]pclose failed:%s.", env->strerror(env, stack, errno, 0), stream, __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
#endif
}

int32_t SPVM__Sys__IO___pclose(SPVM_ENV* env, SPVM_VALUE* stack) {
#if !defined(_WIN32)
  env->die(env, stack, "_pclose is not supported in this system(!defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  int32_t error_id = 0;
  
  void* obj_stream = stack[0].oval;
  if (!obj_stream) {
    return env->die(env, stack, "$stream must be defined.", __func__, FILE_NAME, __LINE__);
  }
  FILE* stream = env->get_pointer(env, stack, obj_stream);
  
  int32_t status = _pclose(stream);
  
  if (status == -1) {
    env->die(env, stack, "[System Error]_pclose failed:%s.", env->strerror(env, stack, errno, 0), stream, __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
#endif
}

int32_t SPVM__Sys__IO__INIT_STDIN(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  FILE* stream = stdin;
  
  void* obj_stream = env->new_pointer_object_by_name(env, stack, "Sys::IO::FileStream", stream, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  env->set_field_byte_by_name(env, stack, obj_stream, "no_destroy", 1, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_stream;
  
  return 0;
}

int32_t SPVM__Sys__IO__INIT_STDOUT(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  FILE* stream = stdout;
  
  void* obj_stream = env->new_pointer_object_by_name(env, stack, "Sys::IO::FileStream", stream, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  env->set_field_byte_by_name(env, stack, obj_stream, "no_destroy", 1, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_stream;
  
  return 0;
}

int32_t SPVM__Sys__IO__INIT_STDERR(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  FILE* stream = stderr;
  
  void* obj_stream = env->new_pointer_object_by_name(env, stack, "Sys::IO::FileStream", stream, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  env->set_field_byte_by_name(env, stack, obj_stream, "no_destroy", 1, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_stream;
  
  return 0;
}

int32_t SPVM__Sys__IO__INIT_SPVM_STDIN(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* runtime = env->runtime;
  
  FILE* spvm_stdin = env->api->runtime->get_spvm_stdin(runtime);
  
  FILE* stream = spvm_stdin;
  
  void* obj_stream = env->new_pointer_object_by_name(env, stack, "Sys::IO::FileStream", stream, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  env->set_field_byte_by_name(env, stack, obj_stream, "no_destroy", 1, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_stream;
  
  return 0;
}

int32_t SPVM__Sys__IO__INIT_SPVM_STDOUT(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* runtime = env->runtime;
  
  FILE* spvm_stdout = env->api->runtime->get_spvm_stdout(runtime);
  
  FILE* stream = spvm_stdout;
  
  void* obj_stream = env->new_pointer_object_by_name(env, stack, "Sys::IO::FileStream", stream, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  env->set_field_byte_by_name(env, stack, obj_stream, "no_destroy", 1, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_stream;
  
  return 0;
}

int32_t SPVM__Sys__IO__INIT_SPVM_STDERR(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* runtime = env->runtime;
  
  FILE* spvm_stderr = env->api->runtime->get_spvm_stderr(runtime);
  
  FILE* stream = spvm_stderr;
  
  void* obj_stream = env->new_pointer_object_by_name(env, stack, "Sys::IO::FileStream", stream, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  
  env->set_field_byte_by_name(env, stack, obj_stream, "no_destroy", 1, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_stream;
  
  return 0;
}
