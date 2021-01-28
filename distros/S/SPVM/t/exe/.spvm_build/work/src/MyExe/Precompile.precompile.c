#ifndef SPVM_CSOURCE_BUILDER_PRECOMPILE_H
#define SPVM_CSOURCE_BUILDER_PRECOMPILE_H
#include <spvm_native.h>

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <inttypes.h>
#define SPVM_API_GET_OBJECT_NO_WEAKEN_ADDRESS(object) ((void*)((intptr_t)object & ~(intptr_t)1))
#define SPVM_API_GET_REF_COUNT(object) ((*(int32_t*)((intptr_t)object + (intptr_t)env->object_ref_count_offset)))
#define SPVM_API_INC_REF_COUNT_ONLY(object) ((*(int32_t*)((intptr_t)object + (intptr_t)env->object_ref_count_offset))++)
#define SPVM_API_INC_REF_COUNT(object)\
do {\
  if (object != NULL) {\
    SPVM_API_INC_REF_COUNT_ONLY(object);\
  }\
} while (0)\

#define SPVM_API_DEC_REF_COUNT_ONLY(object) ((*(int32_t*)((intptr_t)object + (intptr_t)env->object_ref_count_offset))--)
#define SPVM_API_DEC_REF_COUNT(object)\
do {\
  if (object != NULL) {\
    if (SPVM_API_GET_REF_COUNT(object) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(object); }\
    else { env->dec_ref_count(env, object); }\
  }\
} while (0)\

#define SPVM_API_ISWEAK(dist_address) (((intptr_t)*(void**)dist_address) & 1)

#define SPVM_API_OBJECT_ASSIGN(dist_address, src_object) \
do {\
  void* tmp_object = SPVM_API_GET_OBJECT_NO_WEAKEN_ADDRESS(src_object);\
  if (tmp_object != NULL) {\
    SPVM_API_INC_REF_COUNT_ONLY(tmp_object);\
  }\
  if (*(void**)(dist_address) != NULL) {\
    if (__builtin_expect(SPVM_API_ISWEAK(dist_address), 0)) { env->unweaken(env, dist_address); }\
    if (SPVM_API_GET_REF_COUNT(*(void**)(dist_address)) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*(void**)(dist_address)); }\
    else { env->dec_ref_count(env, *(void**)(dist_address)); }\
  }\
  *(void**)(dist_address) = tmp_object;\
} while (0)\

#endif
// Package variable id declarations
// Field id declarations
// Sub id declarations
// Basic type id declarations
// Function Declarations
// [SIG]int(int,int)
int32_t SPPRECOMPILE__MyExe__Precompile__sum(SPVM_ENV* env, SPVM_VALUE* stack);


// Function Implementations
int32_t SPPRECOMPILE__MyExe__Precompile__sum(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t object_header_byte_size = (intptr_t)env->object_header_byte_size;
  int32_t int_vars[7];
  int32_t exception_flag = 0;
  int32_t mortal_stack[1];
  int32_t mortal_stack_top = 0;
  char convert_string_buffer[21];
  // Copy arguments to variables
  int_vars[1] = *(int32_t*)&stack[0];
  int_vars[2] = *(int32_t*)&stack[1];

L0: // INIT_INT
  int_vars[0] = 0;
L1: // ADD_INT
  int_vars[3] = int_vars[1] + int_vars[2];
L2: // RETURN_INT
  *(int32_t*)&stack[0] = int_vars[3];
  goto L5;
L3: // INIT_INT
  int_vars[5] = 0;
L4: // RETURN_INT
  *(int32_t*)&stack[0] = int_vars[5];
  goto L5;
L5: // END_SUB
  if (!exception_flag) {
  }
  return exception_flag;
}


