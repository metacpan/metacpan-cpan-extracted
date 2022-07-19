#include "spvm_native.h"

#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>

const char* FILE_NAME = "SPVM/Cwd.c";

int32_t SPVM__Cwd__getcwd(SPVM_ENV* env, SPVM_VALUE* stack) {

  char* cur_dir = getcwd(NULL, 0);
  
  void* obj_cur_dir = NULL;
  if (cur_dir) {
    int32_t cur_dir_len = strlen(cur_dir);
    for (int32_t i = 0; i < cur_dir_len; i++) {
      if (cur_dir[i] == '\\') {
        cur_dir[i] = '/';
      }
    }
    obj_cur_dir = env->new_string_nolen(env, stack, cur_dir);
    free(cur_dir);
  }
  
  stack[0].oval = obj_cur_dir;

  return 0;
}

int32_t SPVM__Cwd__realpath(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_file = stack[0].oval;
  
  if (!obj_file) {
    return env->die(env, stack, "The file must be defined", FILE_NAME, __LINE__);
  }

  const char* file = env->get_chars(env, stack, obj_file);
  
  char* ret_realpath = realpath(file, NULL);
  
  void* obj_realpath = env->new_string(env, stack, ret_realpath, strlen(ret_realpath));
  
  free(ret_realpath);
  
  stack[0].oval = obj_realpath;

  return 0;
}
