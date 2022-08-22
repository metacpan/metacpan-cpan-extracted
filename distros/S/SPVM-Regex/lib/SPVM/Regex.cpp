#include "spvm_native.h"

#include "re2/re2.h"

#include <iostream>
#include <string>
#include <assert.h>
#include <cstdio>
#include <vector>
#include<memory>

const char* FILE_NAME = "SPVM/Regex.cpp";

extern "C" {

int32_t SPVM__Regex__compile(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)env;
  (void)stack;
  
  int32_t e;

  void* obj_self = stack[0].oval;
  
  void* obj_pattern = stack[1].oval;
  
  if (!obj_pattern) {
    return env->die(env, stack, "The regex pattern must be defined", FILE_NAME, __LINE__);
  }
  
  const char* pattern = env->get_chars(env, stack, obj_pattern);
  int32_t pattern_length = env->length(env, stack, obj_pattern);
  
  RE2::Options options;
  options.set_log_errors(false);
  re2::StringPiece stp_pattern(pattern, pattern_length);
  
  std::unique_ptr<RE2> re2(new RE2(stp_pattern, options));
  
  std::string error = re2->error();
  std::string error_arg = re2->error_arg();
  
  if (!re2->ok()) {
    return env->die(env, stack, "The regex pattern %s can't be compiled. [Error]%s. [Fragment]%s", pattern, error.data(), error_arg.data(), FILE_NAME, __LINE__);
  }
  
  void* obj_re2 = env->new_pointer_by_name(env, stack, "Regex::Re2", re2.release(), &e, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  env->set_field_object_by_name_v2(env, stack, obj_self, "Regex", "re2", obj_re2, &e, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  return 0;
}

int32_t SPVM__Regex__match_forward(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)env;
  (void)stack;
  
  int32_t e = 0;
  
  int32_t items = env->get_args_stack_length(env, stack);
  
  void* obj_self = stack[0].oval;
  
  void* obj_string = stack[1].oval;
  
  if (!obj_string) {
    return env->die(env, stack, "The string must be defined", FILE_NAME, __LINE__);
  }
  
  const char* string = env->get_chars(env, stack, obj_string);
  int32_t string_length = env->length(env, stack, obj_string);
  
  int32_t* offset_ref = stack[2].iref;
  int32_t offset = *offset_ref;
  if (offset < 0) {
    return env->die(env, stack, "The string offset must be greater than or equal to 0", FILE_NAME, __LINE__);
  }
  
  int32_t length;
  if (items > 3) {
    length = stack[3].ival;
  }
  else {
    length = -1;
  }
  
  if (length < 0) {
    length = string_length - offset;
  }
  
  if (!(offset + length <= string_length)) {
    return env->die(env, stack, "The offset + the length must be less than or equal to the length of the string", FILE_NAME, __LINE__);
  }
  
  void* obj_re2 = env->get_field_object_by_name_v2(env, stack, obj_self, "Regex", "re2", &e, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  if (!obj_re2) {
    return env->die(env, stack, "The regex compililation is not yet performed", FILE_NAME, __LINE__);
  }
  
  RE2* re2 = (RE2*)env->get_pointer(env, stack, obj_re2);
  
  re2::StringPiece stp_string(string, string_length);
  
  int32_t captures_length = re2->NumberOfCapturingGroups();
  int32_t doller0_and_captures_length = captures_length + 1;
  
  std::vector<re2::StringPiece> submatch(doller0_and_captures_length);
  int32_t match = re2->Match(stp_string, offset, offset + length, re2::RE2::Anchor::UNANCHORED, submatch.data(), doller0_and_captures_length);
  
  if (match) {
    // Captures
    {
      void* obj_captures = env->new_object_array(env, stack, SPVM_NATIVE_C_BASIC_TYPE_ID_STRING, doller0_and_captures_length);
      if (!obj_captures) {
        return env->die(env, stack, "Captures can't be created", FILE_NAME, __LINE__);; 
      }
      for (int32_t i = 0; i < doller0_and_captures_length; ++i) {
        if (i == 0) {
          int32_t match_start = (submatch[0].data() - string);
          int32_t match_length = submatch[0].length();
          
          env->set_field_int_by_name(env, stack, obj_self, "Regex", "match_start", match_start, &e, FILE_NAME, __LINE__);
          if (e) { return e; }
          
          env->set_field_int_by_name(env, stack, obj_self, "Regex", "match_length", match_length, &e, FILE_NAME, __LINE__);
          if (e) { return e; }
        }
        else {
          void* obj_capture = env->new_string(env, stack, submatch[i].data(), submatch[i].length());
          env->set_elem_object(env, stack, obj_captures, i, obj_capture);
        }
      }
      env->set_field_object_by_name_v2(env, stack, obj_self, "Regex", "captures", obj_captures, &e, FILE_NAME, __LINE__);
      if (e) { return e; }
    }
    
    // Next offset
    int32_t next_offset = (submatch[0].data() - string) + submatch[0].length();
    *offset_ref = next_offset;
    
    stack[0].ival = 1;
  }
  else {
    stack[0].ival = 0;
  }
  
  return 0;
}

int32_t SPVM__Regex__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t e;
  
  void* obj_self = stack[0].oval;

  void* obj_re2 = env->get_field_object_by_name_v2(env, stack, obj_self, "Regex", "re2", &e, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  if (obj_re2) {
    // Free RE2 object
    RE2* re2 = (RE2*)env->get_pointer(env, stack, obj_re2);
    if (re2) {
      delete re2;
      env->set_pointer(env, stack, obj_re2, NULL);
    }
  }
  
  return 0;
}
}
