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
static int32_t FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length = -1;
static int32_t FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__rows_length = -1;
static int32_t FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length = -1;
static int32_t FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__columns_length = -1;
static int32_t FIELD_ID_SPVM__AI__Util__FloatMatrix__values = -1;
static int32_t FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__values = -1;
// Sub id declarations
static int32_t SUB_ID_SPVM__AI__Util__mat_newf = -1;
static int32_t SUB_ID_SPVM__StringBuffer__new = -1;
static int32_t SUB_ID_SPVM__StringBuffer__push = -1;
static int32_t SUB_ID_SPVM__StringBuffer__to_string = -1;
static int32_t SUB_ID_SPVM__AI__Util__mat_new_zerof = -1;
// Basic type id declarations
static int32_t BASIC_TYPE_ID_float = -1;
static int32_t BASIC_TYPE_ID_SPVM__AI__Util__FloatMatrix = -1;
// Function Declarations
// [SIG]SPVM::AI::Util::FloatMatrix(SPVM::AI::Util::FloatMatrix)
int32_t SPPRECOMPILE__SPVM__AI__Util__mat_transposef(SPVM_ENV* env, SPVM_VALUE* stack);

// [SIG]string(SPVM::AI::Util::FloatMatrix)
int32_t SPPRECOMPILE__SPVM__AI__Util__mat_strf(SPVM_ENV* env, SPVM_VALUE* stack);

// [SIG]SPVM::AI::Util::FloatMatrix(SPVM::AI::Util::FloatMatrix,SPVM::AI::Util::FloatMatrix)
int32_t SPPRECOMPILE__SPVM__AI__Util__mat_addf(SPVM_ENV* env, SPVM_VALUE* stack);

// [SIG]SPVM::AI::Util::FloatMatrix(SPVM::AI::Util::FloatMatrix,SPVM::AI::Util::FloatMatrix)
int32_t SPPRECOMPILE__SPVM__AI__Util__mat_subf(SPVM_ENV* env, SPVM_VALUE* stack);

// [SIG]SPVM::AI::Util::FloatMatrix(float,SPVM::AI::Util::FloatMatrix)
int32_t SPPRECOMPILE__SPVM__AI__Util__mat_scamulf(SPVM_ENV* env, SPVM_VALUE* stack);

// [SIG]SPVM::AI::Util::FloatMatrix(SPVM::AI::Util::FloatMatrix,SPVM::AI::Util::FloatMatrix)
int32_t SPPRECOMPILE__SPVM__AI__Util__mat_mulf(SPVM_ENV* env, SPVM_VALUE* stack);

// [SIG]SPVM::AI::Util::FloatMatrix(float[],int,int)
int32_t SPPRECOMPILE__SPVM__AI__Util__mat_newf(SPVM_ENV* env, SPVM_VALUE* stack);

// [SIG]SPVM::AI::Util::FloatMatrix(int,int)
int32_t SPPRECOMPILE__SPVM__AI__Util__mat_new_zerof(SPVM_ENV* env, SPVM_VALUE* stack);

// [SIG]SPVM::AI::Util::FloatMatrix(int)
int32_t SPPRECOMPILE__SPVM__AI__Util__mat_new_identf(SPVM_ENV* env, SPVM_VALUE* stack);


// Function Implementations
int32_t SPPRECOMPILE__SPVM__AI__Util__mat_transposef(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t object_header_byte_size = (intptr_t)env->object_header_byte_size;
  void* object_vars[5] = {0};
  float float_vars[1];
  int32_t int_vars[11];
  int32_t exception_flag = 0;
  int32_t mortal_stack[7];
  int32_t mortal_stack_top = 0;
  char convert_string_buffer[21];
  // Copy arguments to variables
  object_vars[0] = *(void**)&stack[0];
  if (object_vars[0] != NULL) { SPVM_API_INC_REF_COUNT_ONLY(object_vars[0]); }

L0: // INIT_INT
  int_vars[0] = 0;
L1: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 0;
  mortal_stack_top++;
L2: // GET_FIELD_INT
  {
    if (__builtin_expect(FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length < 0, 0)) {
      FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length = env->get_field_id(env, "SPVM::AI::Util::FloatMatrix", "rows_length", "int");
      if (FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length < 0) {
        void* exception = env->new_string_raw(env, "Field not found SPVM::AI::Util::FloatMatrix rows_length");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
      FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__rows_length = env->get_field_offset(env, FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length);
    };
    void* object = object_vars[0];
    if (__builtin_expect(object == NULL, 0)) {
      env->set_exception(env, env->new_string_raw(env, "Object must be not undef."));
      exception_flag = 1;
    }
    else {
      int_vars[1] = *(int32_t*)((intptr_t)object + object_header_byte_size + FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__rows_length);
    }
  }
L3: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_transposef";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 6;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L51;
  }
L4: // GET_FIELD_INT
  {
    if (__builtin_expect(FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length < 0, 0)) {
      FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length = env->get_field_id(env, "SPVM::AI::Util::FloatMatrix", "columns_length", "int");
      if (FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length < 0) {
        void* exception = env->new_string_raw(env, "Field not found SPVM::AI::Util::FloatMatrix columns_length");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
      FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__columns_length = env->get_field_offset(env, FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length);
    };
    void* object = object_vars[0];
    if (__builtin_expect(object == NULL, 0)) {
      env->set_exception(env, env->new_string_raw(env, "Object must be not undef."));
      exception_flag = 1;
    }
    else {
      int_vars[3] = *(int32_t*)((intptr_t)object + object_header_byte_size + FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__columns_length);
    }
  }
L5: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_transposef";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 7;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L51;
  }
L6: // MULTIPLY_INT
  int_vars[4] = int_vars[1] * int_vars[3];
L7: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 1;
  mortal_stack_top++;
L8: // NEW_FLOAT_ARRAY
  {
    int32_t length = *(int32_t*)&int_vars[4];
    if (length >= 0) {
      void* object = env->new_float_array_raw(env, length);
      if (object == NULL) {
        void* exception = env->new_string_raw(env, "Can't allocate memory for float array");
        env->set_exception(env, exception);
        exception_flag = 1;
      }
      else {
        SPVM_API_OBJECT_ASSIGN((void**)&object_vars[1], object);
      }
    }
    else {
      void* exception = env->new_string_raw(env, "Array length must be more than or equal to 0");
      env->set_exception(env, exception);
      exception_flag = 1;
    }
  }
L9: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_transposef";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 10;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L51;
  }
L10: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 2;
  mortal_stack_top++;
L11: // PUSH_ARG_OBJECT
  *(void**)&stack[0] = object_vars[1];
L12: // PUSH_ARG_INT
  *(int32_t*)&stack[1] = int_vars[3];
L13: // PUSH_ARG_INT
  *(int32_t*)&stack[2] = int_vars[1];
L14: // CALL_SUB_OBJECT
  // SPVM::AI::Util->mat_newf
  {
    if (SUB_ID_SPVM__AI__Util__mat_newf < 0) {
      SUB_ID_SPVM__AI__Util__mat_newf = env->get_sub_id(env, "SPVM::AI::Util", "mat_newf", "SPVM::AI::Util::FloatMatrix(float[],int,int)");
      if (SUB_ID_SPVM__AI__Util__mat_newf < 0) {
        void* exception = env->new_string_raw(env, "Subroutine not found SPVM::AI::Util mat_newf");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
    }
    int32_t call_sub_id = SUB_ID_SPVM__AI__Util__mat_newf;
    exception_flag = SPPRECOMPILE__SPVM__AI__Util__mat_newf(env, stack);
    if (!exception_flag) {
      SPVM_API_OBJECT_ASSIGN(&object_vars[2], stack[0].oval);
    }
  }
L15: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_transposef";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 10;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L51;
  }
L16: // INIT_UNDEF
  SPVM_API_OBJECT_ASSIGN(&object_vars[1], NULL);
L17: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 1;
  mortal_stack_top++;
L18: // GET_FIELD_OBJECT
  {
    if (__builtin_expect(FIELD_ID_SPVM__AI__Util__FloatMatrix__values < 0, 0)) {
      FIELD_ID_SPVM__AI__Util__FloatMatrix__values = env->get_field_id(env, "SPVM::AI::Util::FloatMatrix", "values", "float[]");
      if (FIELD_ID_SPVM__AI__Util__FloatMatrix__values < 0) {
        void* exception = env->new_string_raw(env, "Field not found SPVM::AI::Util::FloatMatrix values");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
      FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__values = env->get_field_offset(env, FIELD_ID_SPVM__AI__Util__FloatMatrix__values);
    };
    void* object = object_vars[0];
    if (__builtin_expect(object == NULL, 0)) {
      env->set_exception(env, env->new_string_raw(env, "Object must be not undef."));
      exception_flag = 1;
    }
    else {
      void* get_field_object = *(void**)((intptr_t)object + object_header_byte_size + FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__values);
      SPVM_API_OBJECT_ASSIGN(&object_vars[1], get_field_object);    }
  }
L19: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_transposef";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 12;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L51;
  }
L20: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 3;
  mortal_stack_top++;
L21: // GET_FIELD_OBJECT
  {
    if (__builtin_expect(FIELD_ID_SPVM__AI__Util__FloatMatrix__values < 0, 0)) {
      FIELD_ID_SPVM__AI__Util__FloatMatrix__values = env->get_field_id(env, "SPVM::AI::Util::FloatMatrix", "values", "float[]");
      if (FIELD_ID_SPVM__AI__Util__FloatMatrix__values < 0) {
        void* exception = env->new_string_raw(env, "Field not found SPVM::AI::Util::FloatMatrix values");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
      FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__values = env->get_field_offset(env, FIELD_ID_SPVM__AI__Util__FloatMatrix__values);
    };
    void* object = object_vars[2];
    if (__builtin_expect(object == NULL, 0)) {
      env->set_exception(env, env->new_string_raw(env, "Object must be not undef."));
      exception_flag = 1;
    }
    else {
      void* get_field_object = *(void**)((intptr_t)object + object_header_byte_size + FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__values);
      SPVM_API_OBJECT_ASSIGN(&object_vars[3], get_field_object);    }
  }
L22: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_transposef";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 13;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L51;
  }
L23: // MOVE_CONSTANT_INT
  int_vars[5] = 0;
L24: // GOTO
  goto L44;
L25: // MOVE_CONSTANT_INT
  int_vars[6] = 0;
L26: // GOTO
  goto L38;
L27: // MULTIPLY_INT
  int_vars[7] = int_vars[6] * int_vars[1];
L28: // ADD_INT
  int_vars[8] = int_vars[7] + int_vars[5];
L29: // ARRAY_FETCH_FLOAT
  {
    void* array = object_vars[1];
    int32_t index = int_vars[8];
    if (__builtin_expect(array == NULL, 0)) { 
      env->set_exception(env, env->new_string_raw(env, "Array must not be undef")); 
      exception_flag = 1;
    } 
    else { 
      if (__builtin_expect(index < 0 || index >= *(int32_t*)((intptr_t)array + (intptr_t)env->object_length_offset), 0)) { 
        env->set_exception(env, env->new_string_raw(env, "Index is out of range")); 
        exception_flag = 1;
      } 
      else { 
        float_vars[0] = ((float*)((intptr_t)array + object_header_byte_size))[index];
      } 
    } 
  } 
L30: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_transposef";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 17;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L51;
  }
L31: // MULTIPLY_INT
  int_vars[9] = int_vars[5] * int_vars[3];
L32: // ADD_INT
  int_vars[10] = int_vars[9] + int_vars[6];
L33: // ARRAY_STORE_FLOAT
  {
    void* array = object_vars[3];
    int32_t index = int_vars[10];
    if (__builtin_expect(array == NULL, 0)) { 
      env->set_exception(env, env->new_string_raw(env, "Array must not be undef")); 
      exception_flag = 1;
    } 
    else { 
      if (__builtin_expect(index < 0 || index >= *(int32_t*)((intptr_t)array + (intptr_t)env->object_length_offset), 0)) { 
        env->set_exception(env, env->new_string_raw(env, "Index is out of range")); 
        exception_flag = 1;
      } 
      else { 
((float*)((intptr_t)array + object_header_byte_size))[index]
 = float_vars[0];
      } 
    } 
  } 
L34: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_transposef";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 17;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L51;
  }
L35: // MOVE_INT
  int_vars[7] = int_vars[6];
L36: // MOVE_CONSTANT_INT
  int_vars[8] = 1;
L37: // ADD_INT
  int_vars[6] = int_vars[7] + int_vars[8];
L38: // LT_INT
  int_vars[0] = (int_vars[6] < int_vars[3]);
L39: // BOOL_INT
  int_vars[0] = int_vars[0];
L40: // IF_NE_ZERO
  if (int_vars[0]) { goto L27; }
L41: // MOVE_INT
  int_vars[6] = int_vars[5];
L42: // MOVE_CONSTANT_INT
  int_vars[8] = 1;
L43: // ADD_INT
  int_vars[5] = int_vars[6] + int_vars[8];
L44: // LT_INT
  int_vars[0] = (int_vars[5] < int_vars[1]);
L45: // BOOL_INT
  int_vars[0] = int_vars[0];
L46: // IF_NE_ZERO
  if (int_vars[0]) { goto L25; }
L47: // RETURN_OBJECT
  *(void**)&stack[0] = object_vars[2];
  if (*(void**)&stack[0] != NULL) {
    SPVM_API_INC_REF_COUNT_ONLY(*(void**)&stack[0]);
  }
  goto L51;
L48: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 4;
  mortal_stack_top++;
L49: // INIT_UNDEF
  SPVM_API_OBJECT_ASSIGN(&object_vars[4], NULL);
L50: // RETURN_OBJECT
  *(void**)&stack[0] = object_vars[4];
  if (*(void**)&stack[0] != NULL) {
    SPVM_API_INC_REF_COUNT_ONLY(*(void**)&stack[0]);
  }
  goto L51;
L51: // LEAVE_SCOPE
  {
    int32_t original_mortal_stack_top = 0;
    {
      int32_t mortal_stack_index;
      for (mortal_stack_index = original_mortal_stack_top; mortal_stack_index < mortal_stack_top; mortal_stack_index++) {
        int32_t var_index = mortal_stack[mortal_stack_index];
        void** object_address = (void**)&object_vars[var_index];
        if (*object_address != NULL) {
          if (SPVM_API_GET_REF_COUNT(*object_address) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*object_address); }
          else { env->dec_ref_count(env, *object_address); }
          *object_address = NULL;
        }
      }
    }
    mortal_stack_top = original_mortal_stack_top;
  }
L52: // END_SUB
  if (!exception_flag) {
    if (stack[0].oval != NULL) { SPVM_API_DEC_REF_COUNT_ONLY(stack[0].oval); }
  }
  return exception_flag;
}

int32_t SPPRECOMPILE__SPVM__AI__Util__mat_strf(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t object_header_byte_size = (intptr_t)env->object_header_byte_size;
  void* object_vars[5] = {0};
  float float_vars[1];
  int32_t int_vars[11];
  int32_t exception_flag = 0;
  int32_t mortal_stack[9];
  int32_t mortal_stack_top = 0;
  char convert_string_buffer[21];
  // Copy arguments to variables
  object_vars[0] = *(void**)&stack[0];
  if (object_vars[0] != NULL) { SPVM_API_INC_REF_COUNT_ONLY(object_vars[0]); }

L0: // INIT_INT
  int_vars[0] = 0;
L1: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 0;
  mortal_stack_top++;
L2: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 1;
  mortal_stack_top++;
L3: // GET_FIELD_OBJECT
  {
    if (__builtin_expect(FIELD_ID_SPVM__AI__Util__FloatMatrix__values < 0, 0)) {
      FIELD_ID_SPVM__AI__Util__FloatMatrix__values = env->get_field_id(env, "SPVM::AI::Util::FloatMatrix", "values", "float[]");
      if (FIELD_ID_SPVM__AI__Util__FloatMatrix__values < 0) {
        void* exception = env->new_string_raw(env, "Field not found SPVM::AI::Util::FloatMatrix values");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
      FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__values = env->get_field_offset(env, FIELD_ID_SPVM__AI__Util__FloatMatrix__values);
    };
    void* object = object_vars[0];
    if (__builtin_expect(object == NULL, 0)) {
      env->set_exception(env, env->new_string_raw(env, "Object must be not undef."));
      exception_flag = 1;
    }
    else {
      void* get_field_object = *(void**)((intptr_t)object + object_header_byte_size + FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__values);
      SPVM_API_OBJECT_ASSIGN(&object_vars[1], get_field_object);    }
  }
L4: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_strf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 25;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L71;
  }
L5: // GET_FIELD_INT
  {
    if (__builtin_expect(FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length < 0, 0)) {
      FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length = env->get_field_id(env, "SPVM::AI::Util::FloatMatrix", "rows_length", "int");
      if (FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length < 0) {
        void* exception = env->new_string_raw(env, "Field not found SPVM::AI::Util::FloatMatrix rows_length");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
      FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__rows_length = env->get_field_offset(env, FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length);
    };
    void* object = object_vars[0];
    if (__builtin_expect(object == NULL, 0)) {
      env->set_exception(env, env->new_string_raw(env, "Object must be not undef."));
      exception_flag = 1;
    }
    else {
      int_vars[2] = *(int32_t*)((intptr_t)object + object_header_byte_size + FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__rows_length);
    }
  }
L6: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_strf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 26;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L71;
  }
L7: // GET_FIELD_INT
  {
    if (__builtin_expect(FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length < 0, 0)) {
      FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length = env->get_field_id(env, "SPVM::AI::Util::FloatMatrix", "columns_length", "int");
      if (FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length < 0) {
        void* exception = env->new_string_raw(env, "Field not found SPVM::AI::Util::FloatMatrix columns_length");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
      FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__columns_length = env->get_field_offset(env, FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length);
    };
    void* object = object_vars[0];
    if (__builtin_expect(object == NULL, 0)) {
      env->set_exception(env, env->new_string_raw(env, "Object must be not undef."));
      exception_flag = 1;
    }
    else {
      int_vars[3] = *(int32_t*)((intptr_t)object + object_header_byte_size + FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__columns_length);
    }
  }
L8: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_strf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 27;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L71;
  }
L9: // MULTIPLY_INT
  int_vars[4] = int_vars[2] * int_vars[3];
L10: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 2;
  mortal_stack_top++;
L11: // CALL_SUB_OBJECT
  // SPVM::StringBuffer->new
  {
    if (SUB_ID_SPVM__StringBuffer__new < 0) {
      SUB_ID_SPVM__StringBuffer__new = env->get_sub_id(env, "SPVM::StringBuffer", "new", "SPVM::StringBuffer()");
      if (SUB_ID_SPVM__StringBuffer__new < 0) {
        void* exception = env->new_string_raw(env, "Subroutine not found SPVM::StringBuffer new");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
    }
    int32_t call_sub_id = SUB_ID_SPVM__StringBuffer__new;
    exception_flag = env->call_sub(env, call_sub_id, stack);
    if (!exception_flag) {
      SPVM_API_OBJECT_ASSIGN(&object_vars[2], stack[0].oval);
    }
  }
L12: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_strf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 30;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L71;
  }
L13: // MOVE_CONSTANT_INT
  int_vars[5] = 0;
L14: // GOTO
  goto L59;
L15: // MOVE_INT
  int_vars[6] = int_vars[5];
L16: // GOTO
  goto L44;
L17: // ARRAY_FETCH_FLOAT
  {
    void* array = object_vars[1];
    int32_t index = int_vars[6];
    if (__builtin_expect(array == NULL, 0)) { 
      env->set_exception(env, env->new_string_raw(env, "Array must not be undef")); 
      exception_flag = 1;
    } 
    else { 
      if (__builtin_expect(index < 0 || index >= *(int32_t*)((intptr_t)array + (intptr_t)env->object_length_offset), 0)) { 
        env->set_exception(env, env->new_string_raw(env, "Index is out of range")); 
        exception_flag = 1;
      } 
      else { 
        float_vars[0] = ((float*)((intptr_t)array + object_header_byte_size))[index];
      } 
    } 
  } 
L18: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_strf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 33;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L71;
  }
L19: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 3;
  mortal_stack_top++;
L20: // CONVERT_FLOAT_TO_STRING
  {
    sprintf(convert_string_buffer, "%g", float_vars[0]);
    int32_t string_length = strlen(convert_string_buffer);
    void* string = env->new_string_len_raw(env, convert_string_buffer, string_length);
    SPVM_API_OBJECT_ASSIGN(&object_vars[3], string);
  }
L21: // PUSH_ARG_OBJECT
  *(void**)&stack[0] = object_vars[2];
L22: // PUSH_ARG_OBJECT
  *(void**)&stack[1] = object_vars[3];
L23: // CALL_SUB_VOID
  // SPVM::StringBuffer->push
  {
    if (SUB_ID_SPVM__StringBuffer__push < 0) {
      SUB_ID_SPVM__StringBuffer__push = env->get_sub_id(env, "SPVM::StringBuffer", "push", "void(self,string)");
      if (SUB_ID_SPVM__StringBuffer__push < 0) {
        void* exception = env->new_string_raw(env, "Subroutine not found SPVM::StringBuffer push");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
    }
    int32_t call_sub_id = SUB_ID_SPVM__StringBuffer__push;
    exception_flag = env->call_sub(env, call_sub_id, stack);
    if (!exception_flag) {
    }
  }
L24: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_strf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 33;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L71;
  }
L25: // INIT_UNDEF
  SPVM_API_OBJECT_ASSIGN(&object_vars[3], NULL);
L26: // SUBTRACT_INT
  int_vars[7] = int_vars[4] - int_vars[3];
L27: // MOVE_CONSTANT_INT
  int_vars[8] = 1;
L28: // ADD_INT
  int_vars[9] = int_vars[7] + int_vars[8];
L29: // LT_INT
  int_vars[0] = (int_vars[6] < int_vars[9]);
L30: // BOOL_INT
  int_vars[0] = int_vars[0];
L31: // IF_EQ_ZERO
  if (int_vars[0] == 0) { goto L40; }
L32: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 3;
  mortal_stack_top++;
L33: // NEW_STRING
  {    void* string = env->new_string_len_raw(env, "\x20", 1);
    if (string == NULL) {
      void* exception = env->new_string_raw(env, "Can't allocate memory for string");
      env->set_exception(env, exception);
      exception_flag = 1;
    }
    else {
      SPVM_API_OBJECT_ASSIGN(&object_vars[3], string);
    }
  }L34: // PUSH_ARG_OBJECT
  *(void**)&stack[0] = object_vars[2];
L35: // PUSH_ARG_OBJECT
  *(void**)&stack[1] = object_vars[3];
L36: // CALL_SUB_VOID
  // SPVM::StringBuffer->push
  {
    if (SUB_ID_SPVM__StringBuffer__push < 0) {
      SUB_ID_SPVM__StringBuffer__push = env->get_sub_id(env, "SPVM::StringBuffer", "push", "void(self,string)");
      if (SUB_ID_SPVM__StringBuffer__push < 0) {
        void* exception = env->new_string_raw(env, "Subroutine not found SPVM::StringBuffer push");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
    }
    int32_t call_sub_id = SUB_ID_SPVM__StringBuffer__push;
    exception_flag = env->call_sub(env, call_sub_id, stack);
    if (!exception_flag) {
    }
  }
L37: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_strf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 35;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L71;
  }
L38: // INIT_UNDEF
  SPVM_API_OBJECT_ASSIGN(&object_vars[3], NULL);
L39: // GOTO
  goto L41;
L40: // LEAVE_SCOPE
  {
    int32_t original_mortal_stack_top = 4;
    {
      int32_t mortal_stack_index;
      for (mortal_stack_index = original_mortal_stack_top; mortal_stack_index < mortal_stack_top; mortal_stack_index++) {
        int32_t var_index = mortal_stack[mortal_stack_index];
        void** object_address = (void**)&object_vars[var_index];
        if (*object_address != NULL) {
          if (SPVM_API_GET_REF_COUNT(*object_address) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*object_address); }
          else { env->dec_ref_count(env, *object_address); }
          *object_address = NULL;
        }
      }
    }
    mortal_stack_top = original_mortal_stack_top;
  }
L41: // LEAVE_SCOPE
  {
    int32_t original_mortal_stack_top = 4;
    {
      int32_t mortal_stack_index;
      for (mortal_stack_index = original_mortal_stack_top; mortal_stack_index < mortal_stack_top; mortal_stack_index++) {
        int32_t var_index = mortal_stack[mortal_stack_index];
        void** object_address = (void**)&object_vars[var_index];
        if (*object_address != NULL) {
          if (SPVM_API_GET_REF_COUNT(*object_address) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*object_address); }
          else { env->dec_ref_count(env, *object_address); }
          *object_address = NULL;
        }
      }
    }
    mortal_stack_top = original_mortal_stack_top;
  }
L42: // LEAVE_SCOPE
  {
    int32_t original_mortal_stack_top = 3;
    {
      int32_t mortal_stack_index;
      for (mortal_stack_index = original_mortal_stack_top; mortal_stack_index < mortal_stack_top; mortal_stack_index++) {
        int32_t var_index = mortal_stack[mortal_stack_index];
        void** object_address = (void**)&object_vars[var_index];
        if (*object_address != NULL) {
          if (SPVM_API_GET_REF_COUNT(*object_address) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*object_address); }
          else { env->dec_ref_count(env, *object_address); }
          *object_address = NULL;
        }
      }
    }
    mortal_stack_top = original_mortal_stack_top;
  }
L43: // ADD_INT
  int_vars[6] = int_vars[6] + int_vars[2];
L44: // LT_INT
  int_vars[0] = (int_vars[6] < int_vars[4]);
L45: // BOOL_INT
  int_vars[0] = int_vars[0];
L46: // IF_NE_ZERO
  if (int_vars[0]) { goto L17; }
L47: // LEAVE_SCOPE
  {
    int32_t original_mortal_stack_top = 3;
    {
      int32_t mortal_stack_index;
      for (mortal_stack_index = original_mortal_stack_top; mortal_stack_index < mortal_stack_top; mortal_stack_index++) {
        int32_t var_index = mortal_stack[mortal_stack_index];
        void** object_address = (void**)&object_vars[var_index];
        if (*object_address != NULL) {
          if (SPVM_API_GET_REF_COUNT(*object_address) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*object_address); }
          else { env->dec_ref_count(env, *object_address); }
          *object_address = NULL;
        }
      }
    }
    mortal_stack_top = original_mortal_stack_top;
  }
L48: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 3;
  mortal_stack_top++;
L49: // NEW_STRING
  {    void* string = env->new_string_len_raw(env, "\x0A", 1);
    if (string == NULL) {
      void* exception = env->new_string_raw(env, "Can't allocate memory for string");
      env->set_exception(env, exception);
      exception_flag = 1;
    }
    else {
      SPVM_API_OBJECT_ASSIGN(&object_vars[3], string);
    }
  }L50: // PUSH_ARG_OBJECT
  *(void**)&stack[0] = object_vars[2];
L51: // PUSH_ARG_OBJECT
  *(void**)&stack[1] = object_vars[3];
L52: // CALL_SUB_VOID
  // SPVM::StringBuffer->push
  {
    if (SUB_ID_SPVM__StringBuffer__push < 0) {
      SUB_ID_SPVM__StringBuffer__push = env->get_sub_id(env, "SPVM::StringBuffer", "push", "void(self,string)");
      if (SUB_ID_SPVM__StringBuffer__push < 0) {
        void* exception = env->new_string_raw(env, "Subroutine not found SPVM::StringBuffer push");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
    }
    int32_t call_sub_id = SUB_ID_SPVM__StringBuffer__push;
    exception_flag = env->call_sub(env, call_sub_id, stack);
    if (!exception_flag) {
    }
  }
L53: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_strf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 38;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L71;
  }
L54: // INIT_UNDEF
  SPVM_API_OBJECT_ASSIGN(&object_vars[3], NULL);
L55: // LEAVE_SCOPE
  {
    int32_t original_mortal_stack_top = 3;
    {
      int32_t mortal_stack_index;
      for (mortal_stack_index = original_mortal_stack_top; mortal_stack_index < mortal_stack_top; mortal_stack_index++) {
        int32_t var_index = mortal_stack[mortal_stack_index];
        void** object_address = (void**)&object_vars[var_index];
        if (*object_address != NULL) {
          if (SPVM_API_GET_REF_COUNT(*object_address) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*object_address); }
          else { env->dec_ref_count(env, *object_address); }
          *object_address = NULL;
        }
      }
    }
    mortal_stack_top = original_mortal_stack_top;
  }
L56: // MOVE_INT
  int_vars[6] = int_vars[5];
L57: // MOVE_CONSTANT_INT
  int_vars[7] = 1;
L58: // ADD_INT
  int_vars[5] = int_vars[6] + int_vars[7];
L59: // LT_INT
  int_vars[0] = (int_vars[5] < int_vars[2]);
L60: // BOOL_INT
  int_vars[0] = int_vars[0];
L61: // IF_NE_ZERO
  if (int_vars[0]) { goto L15; }
L62: // LEAVE_SCOPE
  {
    int32_t original_mortal_stack_top = 3;
    {
      int32_t mortal_stack_index;
      for (mortal_stack_index = original_mortal_stack_top; mortal_stack_index < mortal_stack_top; mortal_stack_index++) {
        int32_t var_index = mortal_stack[mortal_stack_index];
        void** object_address = (void**)&object_vars[var_index];
        if (*object_address != NULL) {
          if (SPVM_API_GET_REF_COUNT(*object_address) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*object_address); }
          else { env->dec_ref_count(env, *object_address); }
          *object_address = NULL;
        }
      }
    }
    mortal_stack_top = original_mortal_stack_top;
  }
L63: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 3;
  mortal_stack_top++;
L64: // PUSH_ARG_OBJECT
  *(void**)&stack[0] = object_vars[2];
L65: // CALL_SUB_OBJECT
  // SPVM::StringBuffer->to_string
  {
    if (SUB_ID_SPVM__StringBuffer__to_string < 0) {
      SUB_ID_SPVM__StringBuffer__to_string = env->get_sub_id(env, "SPVM::StringBuffer", "to_string", "string(self)");
      if (SUB_ID_SPVM__StringBuffer__to_string < 0) {
        void* exception = env->new_string_raw(env, "Subroutine not found SPVM::StringBuffer to_string");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
    }
    int32_t call_sub_id = SUB_ID_SPVM__StringBuffer__to_string;
    exception_flag = env->call_sub(env, call_sub_id, stack);
    if (!exception_flag) {
      SPVM_API_OBJECT_ASSIGN(&object_vars[3], stack[0].oval);
    }
  }
L66: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_strf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 41;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L71;
  }
L67: // RETURN_OBJECT
  *(void**)&stack[0] = object_vars[3];
  if (*(void**)&stack[0] != NULL) {
    SPVM_API_INC_REF_COUNT_ONLY(*(void**)&stack[0]);
  }
  goto L71;
L68: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 4;
  mortal_stack_top++;
L69: // INIT_UNDEF
  SPVM_API_OBJECT_ASSIGN(&object_vars[4], NULL);
L70: // RETURN_OBJECT
  *(void**)&stack[0] = object_vars[4];
  if (*(void**)&stack[0] != NULL) {
    SPVM_API_INC_REF_COUNT_ONLY(*(void**)&stack[0]);
  }
  goto L71;
L71: // LEAVE_SCOPE
  {
    int32_t original_mortal_stack_top = 0;
    {
      int32_t mortal_stack_index;
      for (mortal_stack_index = original_mortal_stack_top; mortal_stack_index < mortal_stack_top; mortal_stack_index++) {
        int32_t var_index = mortal_stack[mortal_stack_index];
        void** object_address = (void**)&object_vars[var_index];
        if (*object_address != NULL) {
          if (SPVM_API_GET_REF_COUNT(*object_address) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*object_address); }
          else { env->dec_ref_count(env, *object_address); }
          *object_address = NULL;
        }
      }
    }
    mortal_stack_top = original_mortal_stack_top;
  }
L72: // END_SUB
  if (!exception_flag) {
    if (stack[0].oval != NULL) { SPVM_API_DEC_REF_COUNT_ONLY(stack[0].oval); }
  }
  return exception_flag;
}

int32_t SPPRECOMPILE__SPVM__AI__Util__mat_addf(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t object_header_byte_size = (intptr_t)env->object_header_byte_size;
  void* object_vars[7] = {0};
  float float_vars[4];
  int32_t int_vars[10];
  int32_t exception_flag = 0;
  int32_t mortal_stack[11];
  int32_t mortal_stack_top = 0;
  char convert_string_buffer[21];
  // Copy arguments to variables
  object_vars[0] = *(void**)&stack[0];
  if (object_vars[0] != NULL) { SPVM_API_INC_REF_COUNT_ONLY(object_vars[0]); }
  object_vars[1] = *(void**)&stack[1];
  if (object_vars[1] != NULL) { SPVM_API_INC_REF_COUNT_ONLY(object_vars[1]); }

L0: // INIT_INT
  int_vars[0] = 0;
L1: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 0;
  mortal_stack_top++;
L2: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 1;
  mortal_stack_top++;
L3: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 2;
  mortal_stack_top++;
L4: // GET_FIELD_OBJECT
  {
    if (__builtin_expect(FIELD_ID_SPVM__AI__Util__FloatMatrix__values < 0, 0)) {
      FIELD_ID_SPVM__AI__Util__FloatMatrix__values = env->get_field_id(env, "SPVM::AI::Util::FloatMatrix", "values", "float[]");
      if (FIELD_ID_SPVM__AI__Util__FloatMatrix__values < 0) {
        void* exception = env->new_string_raw(env, "Field not found SPVM::AI::Util::FloatMatrix values");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
      FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__values = env->get_field_offset(env, FIELD_ID_SPVM__AI__Util__FloatMatrix__values);
    };
    void* object = object_vars[0];
    if (__builtin_expect(object == NULL, 0)) {
      env->set_exception(env, env->new_string_raw(env, "Object must be not undef."));
      exception_flag = 1;
    }
    else {
      void* get_field_object = *(void**)((intptr_t)object + object_header_byte_size + FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__values);
      SPVM_API_OBJECT_ASSIGN(&object_vars[2], get_field_object);    }
  }
L5: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_addf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 47;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L75;
  }
L6: // GET_FIELD_INT
  {
    if (__builtin_expect(FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length < 0, 0)) {
      FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length = env->get_field_id(env, "SPVM::AI::Util::FloatMatrix", "rows_length", "int");
      if (FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length < 0) {
        void* exception = env->new_string_raw(env, "Field not found SPVM::AI::Util::FloatMatrix rows_length");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
      FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__rows_length = env->get_field_offset(env, FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length);
    };
    void* object = object_vars[0];
    if (__builtin_expect(object == NULL, 0)) {
      env->set_exception(env, env->new_string_raw(env, "Object must be not undef."));
      exception_flag = 1;
    }
    else {
      int_vars[2] = *(int32_t*)((intptr_t)object + object_header_byte_size + FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__rows_length);
    }
  }
L7: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_addf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 48;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L75;
  }
L8: // GET_FIELD_INT
  {
    if (__builtin_expect(FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length < 0, 0)) {
      FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length = env->get_field_id(env, "SPVM::AI::Util::FloatMatrix", "columns_length", "int");
      if (FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length < 0) {
        void* exception = env->new_string_raw(env, "Field not found SPVM::AI::Util::FloatMatrix columns_length");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
      FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__columns_length = env->get_field_offset(env, FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length);
    };
    void* object = object_vars[0];
    if (__builtin_expect(object == NULL, 0)) {
      env->set_exception(env, env->new_string_raw(env, "Object must be not undef."));
      exception_flag = 1;
    }
    else {
      int_vars[3] = *(int32_t*)((intptr_t)object + object_header_byte_size + FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__columns_length);
    }
  }
L9: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_addf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 49;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L75;
  }
L10: // GET_FIELD_INT
  {
    if (__builtin_expect(FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length < 0, 0)) {
      FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length = env->get_field_id(env, "SPVM::AI::Util::FloatMatrix", "rows_length", "int");
      if (FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length < 0) {
        void* exception = env->new_string_raw(env, "Field not found SPVM::AI::Util::FloatMatrix rows_length");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
      FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__rows_length = env->get_field_offset(env, FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length);
    };
    void* object = object_vars[1];
    if (__builtin_expect(object == NULL, 0)) {
      env->set_exception(env, env->new_string_raw(env, "Object must be not undef."));
      exception_flag = 1;
    }
    else {
      int_vars[4] = *(int32_t*)((intptr_t)object + object_header_byte_size + FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__rows_length);
    }
  }
L11: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_addf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 51;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L75;
  }
L12: // GET_FIELD_INT
  {
    if (__builtin_expect(FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length < 0, 0)) {
      FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length = env->get_field_id(env, "SPVM::AI::Util::FloatMatrix", "columns_length", "int");
      if (FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length < 0) {
        void* exception = env->new_string_raw(env, "Field not found SPVM::AI::Util::FloatMatrix columns_length");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
      FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__columns_length = env->get_field_offset(env, FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length);
    };
    void* object = object_vars[1];
    if (__builtin_expect(object == NULL, 0)) {
      env->set_exception(env, env->new_string_raw(env, "Object must be not undef."));
      exception_flag = 1;
    }
    else {
      int_vars[5] = *(int32_t*)((intptr_t)object + object_header_byte_size + FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__columns_length);
    }
  }
L13: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_addf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 52;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L75;
  }
L14: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 3;
  mortal_stack_top++;
L15: // GET_FIELD_OBJECT
  {
    if (__builtin_expect(FIELD_ID_SPVM__AI__Util__FloatMatrix__values < 0, 0)) {
      FIELD_ID_SPVM__AI__Util__FloatMatrix__values = env->get_field_id(env, "SPVM::AI::Util::FloatMatrix", "values", "float[]");
      if (FIELD_ID_SPVM__AI__Util__FloatMatrix__values < 0) {
        void* exception = env->new_string_raw(env, "Field not found SPVM::AI::Util::FloatMatrix values");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
      FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__values = env->get_field_offset(env, FIELD_ID_SPVM__AI__Util__FloatMatrix__values);
    };
    void* object = object_vars[1];
    if (__builtin_expect(object == NULL, 0)) {
      env->set_exception(env, env->new_string_raw(env, "Object must be not undef."));
      exception_flag = 1;
    }
    else {
      void* get_field_object = *(void**)((intptr_t)object + object_header_byte_size + FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__values);
      SPVM_API_OBJECT_ASSIGN(&object_vars[3], get_field_object);    }
  }
L16: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_addf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 53;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L75;
  }
L17: // NE_INT
  int_vars[0] = (int_vars[2] != int_vars[4]);
L18: // BOOL_INT
  int_vars[0] = int_vars[0];
L19: // IF_EQ_ZERO
  if (int_vars[0] == 0) { goto L27; }
L20: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 4;
  mortal_stack_top++;
L21: // NEW_STRING
  {    void* string = env->new_string_len_raw(env, "\x6D\x61\x74\x31\x20\x72\x6F\x77\x20\x6D\x75\x73\x74\x20\x62\x65\x20\x65\x71\x75\x61\x6C\x73\x20\x74\x6F\x20\x6D\x61\x74\x32\x20\x72\x6F\x77", 35);
    if (string == NULL) {
      void* exception = env->new_string_raw(env, "Can't allocate memory for string");
      env->set_exception(env, exception);
      exception_flag = 1;
    }
    else {
      SPVM_API_OBJECT_ASSIGN(&object_vars[4], string);
    }
  }L22: // SET_EXCEPTION_VAR
  env->set_exception(env, object_vars[4]);
L23: // SET_CROAK_FLAG_TRUE
  exception_flag = 1;
L24: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_addf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 56;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L75;
  }
L25: // INIT_UNDEF
  SPVM_API_OBJECT_ASSIGN(&object_vars[4], NULL);
L26: // GOTO
  goto L28;
L27: // LEAVE_SCOPE
  {
    int32_t original_mortal_stack_top = 4;
    {
      int32_t mortal_stack_index;
      for (mortal_stack_index = original_mortal_stack_top; mortal_stack_index < mortal_stack_top; mortal_stack_index++) {
        int32_t var_index = mortal_stack[mortal_stack_index];
        void** object_address = (void**)&object_vars[var_index];
        if (*object_address != NULL) {
          if (SPVM_API_GET_REF_COUNT(*object_address) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*object_address); }
          else { env->dec_ref_count(env, *object_address); }
          *object_address = NULL;
        }
      }
    }
    mortal_stack_top = original_mortal_stack_top;
  }
L28: // LEAVE_SCOPE
  {
    int32_t original_mortal_stack_top = 4;
    {
      int32_t mortal_stack_index;
      for (mortal_stack_index = original_mortal_stack_top; mortal_stack_index < mortal_stack_top; mortal_stack_index++) {
        int32_t var_index = mortal_stack[mortal_stack_index];
        void** object_address = (void**)&object_vars[var_index];
        if (*object_address != NULL) {
          if (SPVM_API_GET_REF_COUNT(*object_address) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*object_address); }
          else { env->dec_ref_count(env, *object_address); }
          *object_address = NULL;
        }
      }
    }
    mortal_stack_top = original_mortal_stack_top;
  }
L29: // NE_INT
  int_vars[0] = (int_vars[3] != int_vars[5]);
L30: // BOOL_INT
  int_vars[0] = int_vars[0];
L31: // IF_EQ_ZERO
  if (int_vars[0] == 0) { goto L39; }
L32: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 4;
  mortal_stack_top++;
L33: // NEW_STRING
  {    void* string = env->new_string_len_raw(env, "\x6D\x61\x74\x31\x20\x63\x6F\x6C\x20\x6D\x75\x73\x74\x20\x62\x65\x20\x65\x71\x75\x61\x6C\x73\x20\x74\x6F\x20\x6D\x61\x74\x32\x20\x63\x6F\x6C", 35);
    if (string == NULL) {
      void* exception = env->new_string_raw(env, "Can't allocate memory for string");
      env->set_exception(env, exception);
      exception_flag = 1;
    }
    else {
      SPVM_API_OBJECT_ASSIGN(&object_vars[4], string);
    }
  }L34: // SET_EXCEPTION_VAR
  env->set_exception(env, object_vars[4]);
L35: // SET_CROAK_FLAG_TRUE
  exception_flag = 1;
L36: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_addf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 60;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L75;
  }
L37: // INIT_UNDEF
  SPVM_API_OBJECT_ASSIGN(&object_vars[4], NULL);
L38: // GOTO
  goto L40;
L39: // LEAVE_SCOPE
  {
    int32_t original_mortal_stack_top = 4;
    {
      int32_t mortal_stack_index;
      for (mortal_stack_index = original_mortal_stack_top; mortal_stack_index < mortal_stack_top; mortal_stack_index++) {
        int32_t var_index = mortal_stack[mortal_stack_index];
        void** object_address = (void**)&object_vars[var_index];
        if (*object_address != NULL) {
          if (SPVM_API_GET_REF_COUNT(*object_address) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*object_address); }
          else { env->dec_ref_count(env, *object_address); }
          *object_address = NULL;
        }
      }
    }
    mortal_stack_top = original_mortal_stack_top;
  }
L40: // LEAVE_SCOPE
  {
    int32_t original_mortal_stack_top = 4;
    {
      int32_t mortal_stack_index;
      for (mortal_stack_index = original_mortal_stack_top; mortal_stack_index < mortal_stack_top; mortal_stack_index++) {
        int32_t var_index = mortal_stack[mortal_stack_index];
        void** object_address = (void**)&object_vars[var_index];
        if (*object_address != NULL) {
          if (SPVM_API_GET_REF_COUNT(*object_address) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*object_address); }
          else { env->dec_ref_count(env, *object_address); }
          *object_address = NULL;
        }
      }
    }
    mortal_stack_top = original_mortal_stack_top;
  }
L41: // MULTIPLY_INT
  int_vars[6] = int_vars[2] * int_vars[3];
L42: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 4;
  mortal_stack_top++;
L43: // NEW_FLOAT_ARRAY
  {
    int32_t length = *(int32_t*)&int_vars[6];
    if (length >= 0) {
      void* object = env->new_float_array_raw(env, length);
      if (object == NULL) {
        void* exception = env->new_string_raw(env, "Can't allocate memory for float array");
        env->set_exception(env, exception);
        exception_flag = 1;
      }
      else {
        SPVM_API_OBJECT_ASSIGN((void**)&object_vars[4], object);
      }
    }
    else {
      void* exception = env->new_string_raw(env, "Array length must be more than or equal to 0");
      env->set_exception(env, exception);
      exception_flag = 1;
    }
  }
L44: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_addf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 64;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L75;
  }
L45: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 5;
  mortal_stack_top++;
L46: // PUSH_ARG_OBJECT
  *(void**)&stack[0] = object_vars[4];
L47: // PUSH_ARG_INT
  *(int32_t*)&stack[1] = int_vars[2];
L48: // PUSH_ARG_INT
  *(int32_t*)&stack[2] = int_vars[3];
L49: // CALL_SUB_OBJECT
  // SPVM::AI::Util->mat_newf
  {
    if (SUB_ID_SPVM__AI__Util__mat_newf < 0) {
      SUB_ID_SPVM__AI__Util__mat_newf = env->get_sub_id(env, "SPVM::AI::Util", "mat_newf", "SPVM::AI::Util::FloatMatrix(float[],int,int)");
      if (SUB_ID_SPVM__AI__Util__mat_newf < 0) {
        void* exception = env->new_string_raw(env, "Subroutine not found SPVM::AI::Util mat_newf");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
    }
    int32_t call_sub_id = SUB_ID_SPVM__AI__Util__mat_newf;
    exception_flag = SPPRECOMPILE__SPVM__AI__Util__mat_newf(env, stack);
    if (!exception_flag) {
      SPVM_API_OBJECT_ASSIGN(&object_vars[5], stack[0].oval);
    }
  }
L50: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_addf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 64;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L75;
  }
L51: // INIT_UNDEF
  SPVM_API_OBJECT_ASSIGN(&object_vars[4], NULL);
L52: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 4;
  mortal_stack_top++;
L53: // GET_FIELD_OBJECT
  {
    if (__builtin_expect(FIELD_ID_SPVM__AI__Util__FloatMatrix__values < 0, 0)) {
      FIELD_ID_SPVM__AI__Util__FloatMatrix__values = env->get_field_id(env, "SPVM::AI::Util::FloatMatrix", "values", "float[]");
      if (FIELD_ID_SPVM__AI__Util__FloatMatrix__values < 0) {
        void* exception = env->new_string_raw(env, "Field not found SPVM::AI::Util::FloatMatrix values");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
      FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__values = env->get_field_offset(env, FIELD_ID_SPVM__AI__Util__FloatMatrix__values);
    };
    void* object = object_vars[5];
    if (__builtin_expect(object == NULL, 0)) {
      env->set_exception(env, env->new_string_raw(env, "Object must be not undef."));
      exception_flag = 1;
    }
    else {
      void* get_field_object = *(void**)((intptr_t)object + object_header_byte_size + FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__values);
      SPVM_API_OBJECT_ASSIGN(&object_vars[4], get_field_object);    }
  }
L54: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_addf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 65;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L75;
  }
L55: // MOVE_CONSTANT_INT
  int_vars[7] = 0;
L56: // GOTO
  goto L68;
L57: // ARRAY_FETCH_FLOAT
  {
    void* array = object_vars[2];
    int32_t index = int_vars[7];
    if (__builtin_expect(array == NULL, 0)) { 
      env->set_exception(env, env->new_string_raw(env, "Array must not be undef")); 
      exception_flag = 1;
    } 
    else { 
      if (__builtin_expect(index < 0 || index >= *(int32_t*)((intptr_t)array + (intptr_t)env->object_length_offset), 0)) { 
        env->set_exception(env, env->new_string_raw(env, "Index is out of range")); 
        exception_flag = 1;
      } 
      else { 
        float_vars[0] = ((float*)((intptr_t)array + object_header_byte_size))[index];
      } 
    } 
  } 
L58: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_addf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 68;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L75;
  }
L59: // ARRAY_FETCH_FLOAT
  {
    void* array = object_vars[3];
    int32_t index = int_vars[7];
    if (__builtin_expect(array == NULL, 0)) { 
      env->set_exception(env, env->new_string_raw(env, "Array must not be undef")); 
      exception_flag = 1;
    } 
    else { 
      if (__builtin_expect(index < 0 || index >= *(int32_t*)((intptr_t)array + (intptr_t)env->object_length_offset), 0)) { 
        env->set_exception(env, env->new_string_raw(env, "Index is out of range")); 
        exception_flag = 1;
      } 
      else { 
        float_vars[1] = ((float*)((intptr_t)array + object_header_byte_size))[index];
      } 
    } 
  } 
L60: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_addf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 68;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L75;
  }
L61: // ADD_FLOAT
  float_vars[2] = float_vars[0] + float_vars[1];
L62: // MOVE_FLOAT
  float_vars[3] = float_vars[2];
L63: // ARRAY_STORE_FLOAT
  {
    void* array = object_vars[4];
    int32_t index = int_vars[7];
    if (__builtin_expect(array == NULL, 0)) { 
      env->set_exception(env, env->new_string_raw(env, "Array must not be undef")); 
      exception_flag = 1;
    } 
    else { 
      if (__builtin_expect(index < 0 || index >= *(int32_t*)((intptr_t)array + (intptr_t)env->object_length_offset), 0)) { 
        env->set_exception(env, env->new_string_raw(env, "Index is out of range")); 
        exception_flag = 1;
      } 
      else { 
((float*)((intptr_t)array + object_header_byte_size))[index]
 = float_vars[3];
      } 
    } 
  } 
L64: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_addf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 68;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L75;
  }
L65: // MOVE_INT
  int_vars[8] = int_vars[7];
L66: // MOVE_CONSTANT_INT
  int_vars[9] = 1;
L67: // ADD_INT
  int_vars[7] = int_vars[8] + int_vars[9];
L68: // LT_INT
  int_vars[0] = (int_vars[7] < int_vars[6]);
L69: // BOOL_INT
  int_vars[0] = int_vars[0];
L70: // IF_NE_ZERO
  if (int_vars[0]) { goto L57; }
L71: // RETURN_OBJECT
  *(void**)&stack[0] = object_vars[5];
  if (*(void**)&stack[0] != NULL) {
    SPVM_API_INC_REF_COUNT_ONLY(*(void**)&stack[0]);
  }
  goto L75;
L72: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 6;
  mortal_stack_top++;
L73: // INIT_UNDEF
  SPVM_API_OBJECT_ASSIGN(&object_vars[6], NULL);
L74: // RETURN_OBJECT
  *(void**)&stack[0] = object_vars[6];
  if (*(void**)&stack[0] != NULL) {
    SPVM_API_INC_REF_COUNT_ONLY(*(void**)&stack[0]);
  }
  goto L75;
L75: // LEAVE_SCOPE
  {
    int32_t original_mortal_stack_top = 0;
    {
      int32_t mortal_stack_index;
      for (mortal_stack_index = original_mortal_stack_top; mortal_stack_index < mortal_stack_top; mortal_stack_index++) {
        int32_t var_index = mortal_stack[mortal_stack_index];
        void** object_address = (void**)&object_vars[var_index];
        if (*object_address != NULL) {
          if (SPVM_API_GET_REF_COUNT(*object_address) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*object_address); }
          else { env->dec_ref_count(env, *object_address); }
          *object_address = NULL;
        }
      }
    }
    mortal_stack_top = original_mortal_stack_top;
  }
L76: // END_SUB
  if (!exception_flag) {
    if (stack[0].oval != NULL) { SPVM_API_DEC_REF_COUNT_ONLY(stack[0].oval); }
  }
  return exception_flag;
}

int32_t SPPRECOMPILE__SPVM__AI__Util__mat_subf(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t object_header_byte_size = (intptr_t)env->object_header_byte_size;
  void* object_vars[7] = {0};
  float float_vars[4];
  int32_t int_vars[10];
  int32_t exception_flag = 0;
  int32_t mortal_stack[11];
  int32_t mortal_stack_top = 0;
  char convert_string_buffer[21];
  // Copy arguments to variables
  object_vars[0] = *(void**)&stack[0];
  if (object_vars[0] != NULL) { SPVM_API_INC_REF_COUNT_ONLY(object_vars[0]); }
  object_vars[1] = *(void**)&stack[1];
  if (object_vars[1] != NULL) { SPVM_API_INC_REF_COUNT_ONLY(object_vars[1]); }

L0: // INIT_INT
  int_vars[0] = 0;
L1: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 0;
  mortal_stack_top++;
L2: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 1;
  mortal_stack_top++;
L3: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 2;
  mortal_stack_top++;
L4: // GET_FIELD_OBJECT
  {
    if (__builtin_expect(FIELD_ID_SPVM__AI__Util__FloatMatrix__values < 0, 0)) {
      FIELD_ID_SPVM__AI__Util__FloatMatrix__values = env->get_field_id(env, "SPVM::AI::Util::FloatMatrix", "values", "float[]");
      if (FIELD_ID_SPVM__AI__Util__FloatMatrix__values < 0) {
        void* exception = env->new_string_raw(env, "Field not found SPVM::AI::Util::FloatMatrix values");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
      FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__values = env->get_field_offset(env, FIELD_ID_SPVM__AI__Util__FloatMatrix__values);
    };
    void* object = object_vars[0];
    if (__builtin_expect(object == NULL, 0)) {
      env->set_exception(env, env->new_string_raw(env, "Object must be not undef."));
      exception_flag = 1;
    }
    else {
      void* get_field_object = *(void**)((intptr_t)object + object_header_byte_size + FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__values);
      SPVM_API_OBJECT_ASSIGN(&object_vars[2], get_field_object);    }
  }
L5: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_subf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 75;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L75;
  }
L6: // GET_FIELD_INT
  {
    if (__builtin_expect(FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length < 0, 0)) {
      FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length = env->get_field_id(env, "SPVM::AI::Util::FloatMatrix", "rows_length", "int");
      if (FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length < 0) {
        void* exception = env->new_string_raw(env, "Field not found SPVM::AI::Util::FloatMatrix rows_length");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
      FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__rows_length = env->get_field_offset(env, FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length);
    };
    void* object = object_vars[0];
    if (__builtin_expect(object == NULL, 0)) {
      env->set_exception(env, env->new_string_raw(env, "Object must be not undef."));
      exception_flag = 1;
    }
    else {
      int_vars[2] = *(int32_t*)((intptr_t)object + object_header_byte_size + FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__rows_length);
    }
  }
L7: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_subf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 76;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L75;
  }
L8: // GET_FIELD_INT
  {
    if (__builtin_expect(FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length < 0, 0)) {
      FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length = env->get_field_id(env, "SPVM::AI::Util::FloatMatrix", "columns_length", "int");
      if (FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length < 0) {
        void* exception = env->new_string_raw(env, "Field not found SPVM::AI::Util::FloatMatrix columns_length");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
      FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__columns_length = env->get_field_offset(env, FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length);
    };
    void* object = object_vars[0];
    if (__builtin_expect(object == NULL, 0)) {
      env->set_exception(env, env->new_string_raw(env, "Object must be not undef."));
      exception_flag = 1;
    }
    else {
      int_vars[3] = *(int32_t*)((intptr_t)object + object_header_byte_size + FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__columns_length);
    }
  }
L9: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_subf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 77;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L75;
  }
L10: // GET_FIELD_INT
  {
    if (__builtin_expect(FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length < 0, 0)) {
      FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length = env->get_field_id(env, "SPVM::AI::Util::FloatMatrix", "rows_length", "int");
      if (FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length < 0) {
        void* exception = env->new_string_raw(env, "Field not found SPVM::AI::Util::FloatMatrix rows_length");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
      FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__rows_length = env->get_field_offset(env, FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length);
    };
    void* object = object_vars[1];
    if (__builtin_expect(object == NULL, 0)) {
      env->set_exception(env, env->new_string_raw(env, "Object must be not undef."));
      exception_flag = 1;
    }
    else {
      int_vars[4] = *(int32_t*)((intptr_t)object + object_header_byte_size + FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__rows_length);
    }
  }
L11: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_subf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 79;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L75;
  }
L12: // GET_FIELD_INT
  {
    if (__builtin_expect(FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length < 0, 0)) {
      FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length = env->get_field_id(env, "SPVM::AI::Util::FloatMatrix", "columns_length", "int");
      if (FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length < 0) {
        void* exception = env->new_string_raw(env, "Field not found SPVM::AI::Util::FloatMatrix columns_length");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
      FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__columns_length = env->get_field_offset(env, FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length);
    };
    void* object = object_vars[1];
    if (__builtin_expect(object == NULL, 0)) {
      env->set_exception(env, env->new_string_raw(env, "Object must be not undef."));
      exception_flag = 1;
    }
    else {
      int_vars[5] = *(int32_t*)((intptr_t)object + object_header_byte_size + FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__columns_length);
    }
  }
L13: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_subf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 80;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L75;
  }
L14: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 3;
  mortal_stack_top++;
L15: // GET_FIELD_OBJECT
  {
    if (__builtin_expect(FIELD_ID_SPVM__AI__Util__FloatMatrix__values < 0, 0)) {
      FIELD_ID_SPVM__AI__Util__FloatMatrix__values = env->get_field_id(env, "SPVM::AI::Util::FloatMatrix", "values", "float[]");
      if (FIELD_ID_SPVM__AI__Util__FloatMatrix__values < 0) {
        void* exception = env->new_string_raw(env, "Field not found SPVM::AI::Util::FloatMatrix values");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
      FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__values = env->get_field_offset(env, FIELD_ID_SPVM__AI__Util__FloatMatrix__values);
    };
    void* object = object_vars[1];
    if (__builtin_expect(object == NULL, 0)) {
      env->set_exception(env, env->new_string_raw(env, "Object must be not undef."));
      exception_flag = 1;
    }
    else {
      void* get_field_object = *(void**)((intptr_t)object + object_header_byte_size + FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__values);
      SPVM_API_OBJECT_ASSIGN(&object_vars[3], get_field_object);    }
  }
L16: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_subf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 81;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L75;
  }
L17: // NE_INT
  int_vars[0] = (int_vars[2] != int_vars[4]);
L18: // BOOL_INT
  int_vars[0] = int_vars[0];
L19: // IF_EQ_ZERO
  if (int_vars[0] == 0) { goto L27; }
L20: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 4;
  mortal_stack_top++;
L21: // NEW_STRING
  {    void* string = env->new_string_len_raw(env, "\x6D\x61\x74\x31\x20\x72\x6F\x77\x20\x6D\x75\x73\x74\x20\x62\x65\x20\x65\x71\x75\x61\x6C\x73\x20\x74\x6F\x20\x6D\x61\x74\x32\x20\x72\x6F\x77", 35);
    if (string == NULL) {
      void* exception = env->new_string_raw(env, "Can't allocate memory for string");
      env->set_exception(env, exception);
      exception_flag = 1;
    }
    else {
      SPVM_API_OBJECT_ASSIGN(&object_vars[4], string);
    }
  }L22: // SET_EXCEPTION_VAR
  env->set_exception(env, object_vars[4]);
L23: // SET_CROAK_FLAG_TRUE
  exception_flag = 1;
L24: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_subf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 84;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L75;
  }
L25: // INIT_UNDEF
  SPVM_API_OBJECT_ASSIGN(&object_vars[4], NULL);
L26: // GOTO
  goto L28;
L27: // LEAVE_SCOPE
  {
    int32_t original_mortal_stack_top = 4;
    {
      int32_t mortal_stack_index;
      for (mortal_stack_index = original_mortal_stack_top; mortal_stack_index < mortal_stack_top; mortal_stack_index++) {
        int32_t var_index = mortal_stack[mortal_stack_index];
        void** object_address = (void**)&object_vars[var_index];
        if (*object_address != NULL) {
          if (SPVM_API_GET_REF_COUNT(*object_address) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*object_address); }
          else { env->dec_ref_count(env, *object_address); }
          *object_address = NULL;
        }
      }
    }
    mortal_stack_top = original_mortal_stack_top;
  }
L28: // LEAVE_SCOPE
  {
    int32_t original_mortal_stack_top = 4;
    {
      int32_t mortal_stack_index;
      for (mortal_stack_index = original_mortal_stack_top; mortal_stack_index < mortal_stack_top; mortal_stack_index++) {
        int32_t var_index = mortal_stack[mortal_stack_index];
        void** object_address = (void**)&object_vars[var_index];
        if (*object_address != NULL) {
          if (SPVM_API_GET_REF_COUNT(*object_address) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*object_address); }
          else { env->dec_ref_count(env, *object_address); }
          *object_address = NULL;
        }
      }
    }
    mortal_stack_top = original_mortal_stack_top;
  }
L29: // NE_INT
  int_vars[0] = (int_vars[3] != int_vars[5]);
L30: // BOOL_INT
  int_vars[0] = int_vars[0];
L31: // IF_EQ_ZERO
  if (int_vars[0] == 0) { goto L39; }
L32: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 4;
  mortal_stack_top++;
L33: // NEW_STRING
  {    void* string = env->new_string_len_raw(env, "\x6D\x61\x74\x31\x20\x63\x6F\x6C\x20\x6D\x75\x73\x74\x20\x62\x65\x20\x65\x71\x75\x61\x6C\x73\x20\x74\x6F\x20\x6D\x61\x74\x32\x20\x63\x6F\x6C", 35);
    if (string == NULL) {
      void* exception = env->new_string_raw(env, "Can't allocate memory for string");
      env->set_exception(env, exception);
      exception_flag = 1;
    }
    else {
      SPVM_API_OBJECT_ASSIGN(&object_vars[4], string);
    }
  }L34: // SET_EXCEPTION_VAR
  env->set_exception(env, object_vars[4]);
L35: // SET_CROAK_FLAG_TRUE
  exception_flag = 1;
L36: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_subf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 88;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L75;
  }
L37: // INIT_UNDEF
  SPVM_API_OBJECT_ASSIGN(&object_vars[4], NULL);
L38: // GOTO
  goto L40;
L39: // LEAVE_SCOPE
  {
    int32_t original_mortal_stack_top = 4;
    {
      int32_t mortal_stack_index;
      for (mortal_stack_index = original_mortal_stack_top; mortal_stack_index < mortal_stack_top; mortal_stack_index++) {
        int32_t var_index = mortal_stack[mortal_stack_index];
        void** object_address = (void**)&object_vars[var_index];
        if (*object_address != NULL) {
          if (SPVM_API_GET_REF_COUNT(*object_address) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*object_address); }
          else { env->dec_ref_count(env, *object_address); }
          *object_address = NULL;
        }
      }
    }
    mortal_stack_top = original_mortal_stack_top;
  }
L40: // LEAVE_SCOPE
  {
    int32_t original_mortal_stack_top = 4;
    {
      int32_t mortal_stack_index;
      for (mortal_stack_index = original_mortal_stack_top; mortal_stack_index < mortal_stack_top; mortal_stack_index++) {
        int32_t var_index = mortal_stack[mortal_stack_index];
        void** object_address = (void**)&object_vars[var_index];
        if (*object_address != NULL) {
          if (SPVM_API_GET_REF_COUNT(*object_address) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*object_address); }
          else { env->dec_ref_count(env, *object_address); }
          *object_address = NULL;
        }
      }
    }
    mortal_stack_top = original_mortal_stack_top;
  }
L41: // MULTIPLY_INT
  int_vars[6] = int_vars[2] * int_vars[3];
L42: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 4;
  mortal_stack_top++;
L43: // NEW_FLOAT_ARRAY
  {
    int32_t length = *(int32_t*)&int_vars[6];
    if (length >= 0) {
      void* object = env->new_float_array_raw(env, length);
      if (object == NULL) {
        void* exception = env->new_string_raw(env, "Can't allocate memory for float array");
        env->set_exception(env, exception);
        exception_flag = 1;
      }
      else {
        SPVM_API_OBJECT_ASSIGN((void**)&object_vars[4], object);
      }
    }
    else {
      void* exception = env->new_string_raw(env, "Array length must be more than or equal to 0");
      env->set_exception(env, exception);
      exception_flag = 1;
    }
  }
L44: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_subf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 92;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L75;
  }
L45: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 5;
  mortal_stack_top++;
L46: // PUSH_ARG_OBJECT
  *(void**)&stack[0] = object_vars[4];
L47: // PUSH_ARG_INT
  *(int32_t*)&stack[1] = int_vars[2];
L48: // PUSH_ARG_INT
  *(int32_t*)&stack[2] = int_vars[3];
L49: // CALL_SUB_OBJECT
  // SPVM::AI::Util->mat_newf
  {
    if (SUB_ID_SPVM__AI__Util__mat_newf < 0) {
      SUB_ID_SPVM__AI__Util__mat_newf = env->get_sub_id(env, "SPVM::AI::Util", "mat_newf", "SPVM::AI::Util::FloatMatrix(float[],int,int)");
      if (SUB_ID_SPVM__AI__Util__mat_newf < 0) {
        void* exception = env->new_string_raw(env, "Subroutine not found SPVM::AI::Util mat_newf");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
    }
    int32_t call_sub_id = SUB_ID_SPVM__AI__Util__mat_newf;
    exception_flag = SPPRECOMPILE__SPVM__AI__Util__mat_newf(env, stack);
    if (!exception_flag) {
      SPVM_API_OBJECT_ASSIGN(&object_vars[5], stack[0].oval);
    }
  }
L50: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_subf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 92;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L75;
  }
L51: // INIT_UNDEF
  SPVM_API_OBJECT_ASSIGN(&object_vars[4], NULL);
L52: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 4;
  mortal_stack_top++;
L53: // GET_FIELD_OBJECT
  {
    if (__builtin_expect(FIELD_ID_SPVM__AI__Util__FloatMatrix__values < 0, 0)) {
      FIELD_ID_SPVM__AI__Util__FloatMatrix__values = env->get_field_id(env, "SPVM::AI::Util::FloatMatrix", "values", "float[]");
      if (FIELD_ID_SPVM__AI__Util__FloatMatrix__values < 0) {
        void* exception = env->new_string_raw(env, "Field not found SPVM::AI::Util::FloatMatrix values");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
      FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__values = env->get_field_offset(env, FIELD_ID_SPVM__AI__Util__FloatMatrix__values);
    };
    void* object = object_vars[5];
    if (__builtin_expect(object == NULL, 0)) {
      env->set_exception(env, env->new_string_raw(env, "Object must be not undef."));
      exception_flag = 1;
    }
    else {
      void* get_field_object = *(void**)((intptr_t)object + object_header_byte_size + FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__values);
      SPVM_API_OBJECT_ASSIGN(&object_vars[4], get_field_object);    }
  }
L54: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_subf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 93;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L75;
  }
L55: // MOVE_CONSTANT_INT
  int_vars[7] = 0;
L56: // GOTO
  goto L68;
L57: // ARRAY_FETCH_FLOAT
  {
    void* array = object_vars[2];
    int32_t index = int_vars[7];
    if (__builtin_expect(array == NULL, 0)) { 
      env->set_exception(env, env->new_string_raw(env, "Array must not be undef")); 
      exception_flag = 1;
    } 
    else { 
      if (__builtin_expect(index < 0 || index >= *(int32_t*)((intptr_t)array + (intptr_t)env->object_length_offset), 0)) { 
        env->set_exception(env, env->new_string_raw(env, "Index is out of range")); 
        exception_flag = 1;
      } 
      else { 
        float_vars[0] = ((float*)((intptr_t)array + object_header_byte_size))[index];
      } 
    } 
  } 
L58: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_subf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 96;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L75;
  }
L59: // ARRAY_FETCH_FLOAT
  {
    void* array = object_vars[3];
    int32_t index = int_vars[7];
    if (__builtin_expect(array == NULL, 0)) { 
      env->set_exception(env, env->new_string_raw(env, "Array must not be undef")); 
      exception_flag = 1;
    } 
    else { 
      if (__builtin_expect(index < 0 || index >= *(int32_t*)((intptr_t)array + (intptr_t)env->object_length_offset), 0)) { 
        env->set_exception(env, env->new_string_raw(env, "Index is out of range")); 
        exception_flag = 1;
      } 
      else { 
        float_vars[1] = ((float*)((intptr_t)array + object_header_byte_size))[index];
      } 
    } 
  } 
L60: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_subf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 96;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L75;
  }
L61: // SUBTRACT_FLOAT
  float_vars[2] = float_vars[0] - float_vars[1];
L62: // MOVE_FLOAT
  float_vars[3] = float_vars[2];
L63: // ARRAY_STORE_FLOAT
  {
    void* array = object_vars[4];
    int32_t index = int_vars[7];
    if (__builtin_expect(array == NULL, 0)) { 
      env->set_exception(env, env->new_string_raw(env, "Array must not be undef")); 
      exception_flag = 1;
    } 
    else { 
      if (__builtin_expect(index < 0 || index >= *(int32_t*)((intptr_t)array + (intptr_t)env->object_length_offset), 0)) { 
        env->set_exception(env, env->new_string_raw(env, "Index is out of range")); 
        exception_flag = 1;
      } 
      else { 
((float*)((intptr_t)array + object_header_byte_size))[index]
 = float_vars[3];
      } 
    } 
  } 
L64: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_subf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 96;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L75;
  }
L65: // MOVE_INT
  int_vars[8] = int_vars[7];
L66: // MOVE_CONSTANT_INT
  int_vars[9] = 1;
L67: // ADD_INT
  int_vars[7] = int_vars[8] + int_vars[9];
L68: // LT_INT
  int_vars[0] = (int_vars[7] < int_vars[6]);
L69: // BOOL_INT
  int_vars[0] = int_vars[0];
L70: // IF_NE_ZERO
  if (int_vars[0]) { goto L57; }
L71: // RETURN_OBJECT
  *(void**)&stack[0] = object_vars[5];
  if (*(void**)&stack[0] != NULL) {
    SPVM_API_INC_REF_COUNT_ONLY(*(void**)&stack[0]);
  }
  goto L75;
L72: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 6;
  mortal_stack_top++;
L73: // INIT_UNDEF
  SPVM_API_OBJECT_ASSIGN(&object_vars[6], NULL);
L74: // RETURN_OBJECT
  *(void**)&stack[0] = object_vars[6];
  if (*(void**)&stack[0] != NULL) {
    SPVM_API_INC_REF_COUNT_ONLY(*(void**)&stack[0]);
  }
  goto L75;
L75: // LEAVE_SCOPE
  {
    int32_t original_mortal_stack_top = 0;
    {
      int32_t mortal_stack_index;
      for (mortal_stack_index = original_mortal_stack_top; mortal_stack_index < mortal_stack_top; mortal_stack_index++) {
        int32_t var_index = mortal_stack[mortal_stack_index];
        void** object_address = (void**)&object_vars[var_index];
        if (*object_address != NULL) {
          if (SPVM_API_GET_REF_COUNT(*object_address) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*object_address); }
          else { env->dec_ref_count(env, *object_address); }
          *object_address = NULL;
        }
      }
    }
    mortal_stack_top = original_mortal_stack_top;
  }
L76: // END_SUB
  if (!exception_flag) {
    if (stack[0].oval != NULL) { SPVM_API_DEC_REF_COUNT_ONLY(stack[0].oval); }
  }
  return exception_flag;
}

int32_t SPPRECOMPILE__SPVM__AI__Util__mat_scamulf(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t object_header_byte_size = (intptr_t)env->object_header_byte_size;
  void* object_vars[5] = {0};
  float float_vars[4];
  int32_t int_vars[8];
  int32_t exception_flag = 0;
  int32_t mortal_stack[7];
  int32_t mortal_stack_top = 0;
  char convert_string_buffer[21];
  // Copy arguments to variables
  float_vars[0] = *(float*)&stack[0];
  object_vars[0] = *(void**)&stack[1];
  if (object_vars[0] != NULL) { SPVM_API_INC_REF_COUNT_ONLY(object_vars[0]); }

L0: // INIT_INT
  int_vars[0] = 0;
L1: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 0;
  mortal_stack_top++;
L2: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 1;
  mortal_stack_top++;
L3: // GET_FIELD_OBJECT
  {
    if (__builtin_expect(FIELD_ID_SPVM__AI__Util__FloatMatrix__values < 0, 0)) {
      FIELD_ID_SPVM__AI__Util__FloatMatrix__values = env->get_field_id(env, "SPVM::AI::Util::FloatMatrix", "values", "float[]");
      if (FIELD_ID_SPVM__AI__Util__FloatMatrix__values < 0) {
        void* exception = env->new_string_raw(env, "Field not found SPVM::AI::Util::FloatMatrix values");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
      FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__values = env->get_field_offset(env, FIELD_ID_SPVM__AI__Util__FloatMatrix__values);
    };
    void* object = object_vars[0];
    if (__builtin_expect(object == NULL, 0)) {
      env->set_exception(env, env->new_string_raw(env, "Object must be not undef."));
      exception_flag = 1;
    }
    else {
      void* get_field_object = *(void**)((intptr_t)object + object_header_byte_size + FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__values);
      SPVM_API_OBJECT_ASSIGN(&object_vars[1], get_field_object);    }
  }
L4: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_scamulf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 103;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L41;
  }
L5: // GET_FIELD_INT
  {
    if (__builtin_expect(FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length < 0, 0)) {
      FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length = env->get_field_id(env, "SPVM::AI::Util::FloatMatrix", "rows_length", "int");
      if (FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length < 0) {
        void* exception = env->new_string_raw(env, "Field not found SPVM::AI::Util::FloatMatrix rows_length");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
      FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__rows_length = env->get_field_offset(env, FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length);
    };
    void* object = object_vars[0];
    if (__builtin_expect(object == NULL, 0)) {
      env->set_exception(env, env->new_string_raw(env, "Object must be not undef."));
      exception_flag = 1;
    }
    else {
      int_vars[2] = *(int32_t*)((intptr_t)object + object_header_byte_size + FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__rows_length);
    }
  }
L6: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_scamulf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 104;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L41;
  }
L7: // GET_FIELD_INT
  {
    if (__builtin_expect(FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length < 0, 0)) {
      FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length = env->get_field_id(env, "SPVM::AI::Util::FloatMatrix", "columns_length", "int");
      if (FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length < 0) {
        void* exception = env->new_string_raw(env, "Field not found SPVM::AI::Util::FloatMatrix columns_length");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
      FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__columns_length = env->get_field_offset(env, FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length);
    };
    void* object = object_vars[0];
    if (__builtin_expect(object == NULL, 0)) {
      env->set_exception(env, env->new_string_raw(env, "Object must be not undef."));
      exception_flag = 1;
    }
    else {
      int_vars[3] = *(int32_t*)((intptr_t)object + object_header_byte_size + FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__columns_length);
    }
  }
L8: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_scamulf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 105;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L41;
  }
L9: // MULTIPLY_INT
  int_vars[4] = int_vars[2] * int_vars[3];
L10: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 2;
  mortal_stack_top++;
L11: // NEW_FLOAT_ARRAY
  {
    int32_t length = *(int32_t*)&int_vars[4];
    if (length >= 0) {
      void* object = env->new_float_array_raw(env, length);
      if (object == NULL) {
        void* exception = env->new_string_raw(env, "Can't allocate memory for float array");
        env->set_exception(env, exception);
        exception_flag = 1;
      }
      else {
        SPVM_API_OBJECT_ASSIGN((void**)&object_vars[2], object);
      }
    }
    else {
      void* exception = env->new_string_raw(env, "Array length must be more than or equal to 0");
      env->set_exception(env, exception);
      exception_flag = 1;
    }
  }
L12: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_scamulf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 108;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L41;
  }
L13: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 3;
  mortal_stack_top++;
L14: // PUSH_ARG_OBJECT
  *(void**)&stack[0] = object_vars[2];
L15: // PUSH_ARG_INT
  *(int32_t*)&stack[1] = int_vars[2];
L16: // PUSH_ARG_INT
  *(int32_t*)&stack[2] = int_vars[3];
L17: // CALL_SUB_OBJECT
  // SPVM::AI::Util->mat_newf
  {
    if (SUB_ID_SPVM__AI__Util__mat_newf < 0) {
      SUB_ID_SPVM__AI__Util__mat_newf = env->get_sub_id(env, "SPVM::AI::Util", "mat_newf", "SPVM::AI::Util::FloatMatrix(float[],int,int)");
      if (SUB_ID_SPVM__AI__Util__mat_newf < 0) {
        void* exception = env->new_string_raw(env, "Subroutine not found SPVM::AI::Util mat_newf");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
    }
    int32_t call_sub_id = SUB_ID_SPVM__AI__Util__mat_newf;
    exception_flag = SPPRECOMPILE__SPVM__AI__Util__mat_newf(env, stack);
    if (!exception_flag) {
      SPVM_API_OBJECT_ASSIGN(&object_vars[3], stack[0].oval);
    }
  }
L18: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_scamulf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 108;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L41;
  }
L19: // INIT_UNDEF
  SPVM_API_OBJECT_ASSIGN(&object_vars[2], NULL);
L20: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 2;
  mortal_stack_top++;
L21: // GET_FIELD_OBJECT
  {
    if (__builtin_expect(FIELD_ID_SPVM__AI__Util__FloatMatrix__values < 0, 0)) {
      FIELD_ID_SPVM__AI__Util__FloatMatrix__values = env->get_field_id(env, "SPVM::AI::Util::FloatMatrix", "values", "float[]");
      if (FIELD_ID_SPVM__AI__Util__FloatMatrix__values < 0) {
        void* exception = env->new_string_raw(env, "Field not found SPVM::AI::Util::FloatMatrix values");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
      FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__values = env->get_field_offset(env, FIELD_ID_SPVM__AI__Util__FloatMatrix__values);
    };
    void* object = object_vars[3];
    if (__builtin_expect(object == NULL, 0)) {
      env->set_exception(env, env->new_string_raw(env, "Object must be not undef."));
      exception_flag = 1;
    }
    else {
      void* get_field_object = *(void**)((intptr_t)object + object_header_byte_size + FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__values);
      SPVM_API_OBJECT_ASSIGN(&object_vars[2], get_field_object);    }
  }
L22: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_scamulf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 109;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L41;
  }
L23: // MOVE_CONSTANT_INT
  int_vars[5] = 0;
L24: // GOTO
  goto L34;
L25: // ARRAY_FETCH_FLOAT
  {
    void* array = object_vars[1];
    int32_t index = int_vars[5];
    if (__builtin_expect(array == NULL, 0)) { 
      env->set_exception(env, env->new_string_raw(env, "Array must not be undef")); 
      exception_flag = 1;
    } 
    else { 
      if (__builtin_expect(index < 0 || index >= *(int32_t*)((intptr_t)array + (intptr_t)env->object_length_offset), 0)) { 
        env->set_exception(env, env->new_string_raw(env, "Index is out of range")); 
        exception_flag = 1;
      } 
      else { 
        float_vars[1] = ((float*)((intptr_t)array + object_header_byte_size))[index];
      } 
    } 
  } 
L26: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_scamulf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 112;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L41;
  }
L27: // MULTIPLY_FLOAT
  float_vars[2] = float_vars[0] * float_vars[1];
L28: // MOVE_FLOAT
  float_vars[3] = float_vars[2];
L29: // ARRAY_STORE_FLOAT
  {
    void* array = object_vars[2];
    int32_t index = int_vars[5];
    if (__builtin_expect(array == NULL, 0)) { 
      env->set_exception(env, env->new_string_raw(env, "Array must not be undef")); 
      exception_flag = 1;
    } 
    else { 
      if (__builtin_expect(index < 0 || index >= *(int32_t*)((intptr_t)array + (intptr_t)env->object_length_offset), 0)) { 
        env->set_exception(env, env->new_string_raw(env, "Index is out of range")); 
        exception_flag = 1;
      } 
      else { 
((float*)((intptr_t)array + object_header_byte_size))[index]
 = float_vars[3];
      } 
    } 
  } 
L30: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_scamulf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 112;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L41;
  }
L31: // MOVE_INT
  int_vars[6] = int_vars[5];
L32: // MOVE_CONSTANT_INT
  int_vars[7] = 1;
L33: // ADD_INT
  int_vars[5] = int_vars[6] + int_vars[7];
L34: // LT_INT
  int_vars[0] = (int_vars[5] < int_vars[4]);
L35: // BOOL_INT
  int_vars[0] = int_vars[0];
L36: // IF_NE_ZERO
  if (int_vars[0]) { goto L25; }
L37: // RETURN_OBJECT
  *(void**)&stack[0] = object_vars[3];
  if (*(void**)&stack[0] != NULL) {
    SPVM_API_INC_REF_COUNT_ONLY(*(void**)&stack[0]);
  }
  goto L41;
L38: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 4;
  mortal_stack_top++;
L39: // INIT_UNDEF
  SPVM_API_OBJECT_ASSIGN(&object_vars[4], NULL);
L40: // RETURN_OBJECT
  *(void**)&stack[0] = object_vars[4];
  if (*(void**)&stack[0] != NULL) {
    SPVM_API_INC_REF_COUNT_ONLY(*(void**)&stack[0]);
  }
  goto L41;
L41: // LEAVE_SCOPE
  {
    int32_t original_mortal_stack_top = 0;
    {
      int32_t mortal_stack_index;
      for (mortal_stack_index = original_mortal_stack_top; mortal_stack_index < mortal_stack_top; mortal_stack_index++) {
        int32_t var_index = mortal_stack[mortal_stack_index];
        void** object_address = (void**)&object_vars[var_index];
        if (*object_address != NULL) {
          if (SPVM_API_GET_REF_COUNT(*object_address) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*object_address); }
          else { env->dec_ref_count(env, *object_address); }
          *object_address = NULL;
        }
      }
    }
    mortal_stack_top = original_mortal_stack_top;
  }
L42: // END_SUB
  if (!exception_flag) {
    if (stack[0].oval != NULL) { SPVM_API_DEC_REF_COUNT_ONLY(stack[0].oval); }
  }
  return exception_flag;
}

int32_t SPPRECOMPILE__SPVM__AI__Util__mat_mulf(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t object_header_byte_size = (intptr_t)env->object_header_byte_size;
  void* object_vars[7] = {0};
  float float_vars[5];
  int32_t int_vars[17];
  int32_t exception_flag = 0;
  int32_t mortal_stack[10];
  int32_t mortal_stack_top = 0;
  char convert_string_buffer[21];
  // Copy arguments to variables
  object_vars[0] = *(void**)&stack[0];
  if (object_vars[0] != NULL) { SPVM_API_INC_REF_COUNT_ONLY(object_vars[0]); }
  object_vars[1] = *(void**)&stack[1];
  if (object_vars[1] != NULL) { SPVM_API_INC_REF_COUNT_ONLY(object_vars[1]); }

L0: // INIT_INT
  int_vars[0] = 0;
L1: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 0;
  mortal_stack_top++;
L2: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 1;
  mortal_stack_top++;
L3: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 2;
  mortal_stack_top++;
L4: // GET_FIELD_OBJECT
  {
    if (__builtin_expect(FIELD_ID_SPVM__AI__Util__FloatMatrix__values < 0, 0)) {
      FIELD_ID_SPVM__AI__Util__FloatMatrix__values = env->get_field_id(env, "SPVM::AI::Util::FloatMatrix", "values", "float[]");
      if (FIELD_ID_SPVM__AI__Util__FloatMatrix__values < 0) {
        void* exception = env->new_string_raw(env, "Field not found SPVM::AI::Util::FloatMatrix values");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
      FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__values = env->get_field_offset(env, FIELD_ID_SPVM__AI__Util__FloatMatrix__values);
    };
    void* object = object_vars[0];
    if (__builtin_expect(object == NULL, 0)) {
      env->set_exception(env, env->new_string_raw(env, "Object must be not undef."));
      exception_flag = 1;
    }
    else {
      void* get_field_object = *(void**)((intptr_t)object + object_header_byte_size + FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__values);
      SPVM_API_OBJECT_ASSIGN(&object_vars[2], get_field_object);    }
  }
L5: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_mulf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 119;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L89;
  }
L6: // GET_FIELD_INT
  {
    if (__builtin_expect(FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length < 0, 0)) {
      FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length = env->get_field_id(env, "SPVM::AI::Util::FloatMatrix", "rows_length", "int");
      if (FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length < 0) {
        void* exception = env->new_string_raw(env, "Field not found SPVM::AI::Util::FloatMatrix rows_length");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
      FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__rows_length = env->get_field_offset(env, FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length);
    };
    void* object = object_vars[0];
    if (__builtin_expect(object == NULL, 0)) {
      env->set_exception(env, env->new_string_raw(env, "Object must be not undef."));
      exception_flag = 1;
    }
    else {
      int_vars[2] = *(int32_t*)((intptr_t)object + object_header_byte_size + FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__rows_length);
    }
  }
L7: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_mulf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 120;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L89;
  }
L8: // GET_FIELD_INT
  {
    if (__builtin_expect(FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length < 0, 0)) {
      FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length = env->get_field_id(env, "SPVM::AI::Util::FloatMatrix", "columns_length", "int");
      if (FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length < 0) {
        void* exception = env->new_string_raw(env, "Field not found SPVM::AI::Util::FloatMatrix columns_length");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
      FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__columns_length = env->get_field_offset(env, FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length);
    };
    void* object = object_vars[0];
    if (__builtin_expect(object == NULL, 0)) {
      env->set_exception(env, env->new_string_raw(env, "Object must be not undef."));
      exception_flag = 1;
    }
    else {
      int_vars[3] = *(int32_t*)((intptr_t)object + object_header_byte_size + FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__columns_length);
    }
  }
L9: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_mulf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 121;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L89;
  }
L10: // GET_FIELD_INT
  {
    if (__builtin_expect(FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length < 0, 0)) {
      FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length = env->get_field_id(env, "SPVM::AI::Util::FloatMatrix", "rows_length", "int");
      if (FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length < 0) {
        void* exception = env->new_string_raw(env, "Field not found SPVM::AI::Util::FloatMatrix rows_length");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
      FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__rows_length = env->get_field_offset(env, FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length);
    };
    void* object = object_vars[1];
    if (__builtin_expect(object == NULL, 0)) {
      env->set_exception(env, env->new_string_raw(env, "Object must be not undef."));
      exception_flag = 1;
    }
    else {
      int_vars[4] = *(int32_t*)((intptr_t)object + object_header_byte_size + FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__rows_length);
    }
  }
L11: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_mulf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 123;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L89;
  }
L12: // GET_FIELD_INT
  {
    if (__builtin_expect(FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length < 0, 0)) {
      FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length = env->get_field_id(env, "SPVM::AI::Util::FloatMatrix", "columns_length", "int");
      if (FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length < 0) {
        void* exception = env->new_string_raw(env, "Field not found SPVM::AI::Util::FloatMatrix columns_length");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
      FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__columns_length = env->get_field_offset(env, FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length);
    };
    void* object = object_vars[1];
    if (__builtin_expect(object == NULL, 0)) {
      env->set_exception(env, env->new_string_raw(env, "Object must be not undef."));
      exception_flag = 1;
    }
    else {
      int_vars[5] = *(int32_t*)((intptr_t)object + object_header_byte_size + FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__columns_length);
    }
  }
L13: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_mulf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 124;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L89;
  }
L14: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 3;
  mortal_stack_top++;
L15: // GET_FIELD_OBJECT
  {
    if (__builtin_expect(FIELD_ID_SPVM__AI__Util__FloatMatrix__values < 0, 0)) {
      FIELD_ID_SPVM__AI__Util__FloatMatrix__values = env->get_field_id(env, "SPVM::AI::Util::FloatMatrix", "values", "float[]");
      if (FIELD_ID_SPVM__AI__Util__FloatMatrix__values < 0) {
        void* exception = env->new_string_raw(env, "Field not found SPVM::AI::Util::FloatMatrix values");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
      FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__values = env->get_field_offset(env, FIELD_ID_SPVM__AI__Util__FloatMatrix__values);
    };
    void* object = object_vars[1];
    if (__builtin_expect(object == NULL, 0)) {
      env->set_exception(env, env->new_string_raw(env, "Object must be not undef."));
      exception_flag = 1;
    }
    else {
      void* get_field_object = *(void**)((intptr_t)object + object_header_byte_size + FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__values);
      SPVM_API_OBJECT_ASSIGN(&object_vars[3], get_field_object);    }
  }
L16: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_mulf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 125;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L89;
  }
L17: // NE_INT
  int_vars[0] = (int_vars[3] != int_vars[4]);
L18: // BOOL_INT
  int_vars[0] = int_vars[0];
L19: // IF_EQ_ZERO
  if (int_vars[0] == 0) { goto L27; }
L20: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 4;
  mortal_stack_top++;
L21: // NEW_STRING
  {    void* string = env->new_string_len_raw(env, "\x6D\x61\x74\x31\x20\x63\x6F\x6C\x20\x6D\x75\x73\x74\x20\x62\x65\x20\x65\x71\x75\x61\x6C\x73\x20\x74\x6F\x20\x6D\x61\x74\x32\x20\x72\x6F\x77", 35);
    if (string == NULL) {
      void* exception = env->new_string_raw(env, "Can't allocate memory for string");
      env->set_exception(env, exception);
      exception_flag = 1;
    }
    else {
      SPVM_API_OBJECT_ASSIGN(&object_vars[4], string);
    }
  }L22: // SET_EXCEPTION_VAR
  env->set_exception(env, object_vars[4]);
L23: // SET_CROAK_FLAG_TRUE
  exception_flag = 1;
L24: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_mulf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 128;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L89;
  }
L25: // INIT_UNDEF
  SPVM_API_OBJECT_ASSIGN(&object_vars[4], NULL);
L26: // GOTO
  goto L28;
L27: // LEAVE_SCOPE
  {
    int32_t original_mortal_stack_top = 4;
    {
      int32_t mortal_stack_index;
      for (mortal_stack_index = original_mortal_stack_top; mortal_stack_index < mortal_stack_top; mortal_stack_index++) {
        int32_t var_index = mortal_stack[mortal_stack_index];
        void** object_address = (void**)&object_vars[var_index];
        if (*object_address != NULL) {
          if (SPVM_API_GET_REF_COUNT(*object_address) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*object_address); }
          else { env->dec_ref_count(env, *object_address); }
          *object_address = NULL;
        }
      }
    }
    mortal_stack_top = original_mortal_stack_top;
  }
L28: // LEAVE_SCOPE
  {
    int32_t original_mortal_stack_top = 4;
    {
      int32_t mortal_stack_index;
      for (mortal_stack_index = original_mortal_stack_top; mortal_stack_index < mortal_stack_top; mortal_stack_index++) {
        int32_t var_index = mortal_stack[mortal_stack_index];
        void** object_address = (void**)&object_vars[var_index];
        if (*object_address != NULL) {
          if (SPVM_API_GET_REF_COUNT(*object_address) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*object_address); }
          else { env->dec_ref_count(env, *object_address); }
          *object_address = NULL;
        }
      }
    }
    mortal_stack_top = original_mortal_stack_top;
  }
L29: // MULTIPLY_INT
  int_vars[6] = int_vars[2] * int_vars[5];
L30: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 4;
  mortal_stack_top++;
L31: // NEW_FLOAT_ARRAY
  {
    int32_t length = *(int32_t*)&int_vars[6];
    if (length >= 0) {
      void* object = env->new_float_array_raw(env, length);
      if (object == NULL) {
        void* exception = env->new_string_raw(env, "Can't allocate memory for float array");
        env->set_exception(env, exception);
        exception_flag = 1;
      }
      else {
        SPVM_API_OBJECT_ASSIGN((void**)&object_vars[4], object);
      }
    }
    else {
      void* exception = env->new_string_raw(env, "Array length must be more than or equal to 0");
      env->set_exception(env, exception);
      exception_flag = 1;
    }
  }
L32: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_mulf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 132;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L89;
  }
L33: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 5;
  mortal_stack_top++;
L34: // PUSH_ARG_OBJECT
  *(void**)&stack[0] = object_vars[4];
L35: // PUSH_ARG_INT
  *(int32_t*)&stack[1] = int_vars[2];
L36: // PUSH_ARG_INT
  *(int32_t*)&stack[2] = int_vars[5];
L37: // CALL_SUB_OBJECT
  // SPVM::AI::Util->mat_newf
  {
    if (SUB_ID_SPVM__AI__Util__mat_newf < 0) {
      SUB_ID_SPVM__AI__Util__mat_newf = env->get_sub_id(env, "SPVM::AI::Util", "mat_newf", "SPVM::AI::Util::FloatMatrix(float[],int,int)");
      if (SUB_ID_SPVM__AI__Util__mat_newf < 0) {
        void* exception = env->new_string_raw(env, "Subroutine not found SPVM::AI::Util mat_newf");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
    }
    int32_t call_sub_id = SUB_ID_SPVM__AI__Util__mat_newf;
    exception_flag = SPPRECOMPILE__SPVM__AI__Util__mat_newf(env, stack);
    if (!exception_flag) {
      SPVM_API_OBJECT_ASSIGN(&object_vars[5], stack[0].oval);
    }
  }
L38: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_mulf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 132;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L89;
  }
L39: // INIT_UNDEF
  SPVM_API_OBJECT_ASSIGN(&object_vars[4], NULL);
L40: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 4;
  mortal_stack_top++;
L41: // GET_FIELD_OBJECT
  {
    if (__builtin_expect(FIELD_ID_SPVM__AI__Util__FloatMatrix__values < 0, 0)) {
      FIELD_ID_SPVM__AI__Util__FloatMatrix__values = env->get_field_id(env, "SPVM::AI::Util::FloatMatrix", "values", "float[]");
      if (FIELD_ID_SPVM__AI__Util__FloatMatrix__values < 0) {
        void* exception = env->new_string_raw(env, "Field not found SPVM::AI::Util::FloatMatrix values");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
      FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__values = env->get_field_offset(env, FIELD_ID_SPVM__AI__Util__FloatMatrix__values);
    };
    void* object = object_vars[5];
    if (__builtin_expect(object == NULL, 0)) {
      env->set_exception(env, env->new_string_raw(env, "Object must be not undef."));
      exception_flag = 1;
    }
    else {
      void* get_field_object = *(void**)((intptr_t)object + object_header_byte_size + FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__values);
      SPVM_API_OBJECT_ASSIGN(&object_vars[4], get_field_object);    }
  }
L42: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_mulf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 133;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L89;
  }
L43: // GET_FIELD_INT
  {
    if (__builtin_expect(FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length < 0, 0)) {
      FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length = env->get_field_id(env, "SPVM::AI::Util::FloatMatrix", "rows_length", "int");
      if (FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length < 0) {
        void* exception = env->new_string_raw(env, "Field not found SPVM::AI::Util::FloatMatrix rows_length");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
      FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__rows_length = env->get_field_offset(env, FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length);
    };
    void* object = object_vars[5];
    if (__builtin_expect(object == NULL, 0)) {
      env->set_exception(env, env->new_string_raw(env, "Object must be not undef."));
      exception_flag = 1;
    }
    else {
      int_vars[7] = *(int32_t*)((intptr_t)object + object_header_byte_size + FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__rows_length);
    }
  }
L44: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_mulf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 134;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L89;
  }
L45: // MOVE_CONSTANT_INT
  int_vars[8] = 0;
L46: // GOTO
  goto L82;
L47: // MOVE_CONSTANT_INT
  int_vars[9] = 0;
L48: // GOTO
  goto L76;
L49: // MOVE_CONSTANT_INT
  int_vars[10] = 0;
L50: // GOTO
  goto L70;
L51: // MULTIPLY_INT
  int_vars[11] = int_vars[9] * int_vars[7];
L52: // ADD_INT
  int_vars[12] = int_vars[8] + int_vars[11];
L53: // ARRAY_FETCH_FLOAT
  {
    void* array = object_vars[4];
    int32_t index = int_vars[12];
    if (__builtin_expect(array == NULL, 0)) { 
      env->set_exception(env, env->new_string_raw(env, "Array must not be undef")); 
      exception_flag = 1;
    } 
    else { 
      if (__builtin_expect(index < 0 || index >= *(int32_t*)((intptr_t)array + (intptr_t)env->object_length_offset), 0)) { 
        env->set_exception(env, env->new_string_raw(env, "Index is out of range")); 
        exception_flag = 1;
      } 
      else { 
        float_vars[0] = ((float*)((intptr_t)array + object_header_byte_size))[index];
      } 
    } 
  } 
L54: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_mulf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 139;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L89;
  }
L55: // MULTIPLY_INT
  int_vars[13] = int_vars[10] * int_vars[2];
L56: // ADD_INT
  int_vars[14] = int_vars[8] + int_vars[13];
L57: // ARRAY_FETCH_FLOAT
  {
    void* array = object_vars[2];
    int32_t index = int_vars[14];
    if (__builtin_expect(array == NULL, 0)) { 
      env->set_exception(env, env->new_string_raw(env, "Array must not be undef")); 
      exception_flag = 1;
    } 
    else { 
      if (__builtin_expect(index < 0 || index >= *(int32_t*)((intptr_t)array + (intptr_t)env->object_length_offset), 0)) { 
        env->set_exception(env, env->new_string_raw(env, "Index is out of range")); 
        exception_flag = 1;
      } 
      else { 
        float_vars[1] = ((float*)((intptr_t)array + object_header_byte_size))[index];
      } 
    } 
  } 
L58: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_mulf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 140;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L89;
  }
L59: // MULTIPLY_INT
  int_vars[15] = int_vars[9] * int_vars[4];
L60: // ADD_INT
  int_vars[16] = int_vars[10] + int_vars[15];
L61: // ARRAY_FETCH_FLOAT
  {
    void* array = object_vars[3];
    int32_t index = int_vars[16];
    if (__builtin_expect(array == NULL, 0)) { 
      env->set_exception(env, env->new_string_raw(env, "Array must not be undef")); 
      exception_flag = 1;
    } 
    else { 
      if (__builtin_expect(index < 0 || index >= *(int32_t*)((intptr_t)array + (intptr_t)env->object_length_offset), 0)) { 
        env->set_exception(env, env->new_string_raw(env, "Index is out of range")); 
        exception_flag = 1;
      } 
      else { 
        float_vars[2] = ((float*)((intptr_t)array + object_header_byte_size))[index];
      } 
    } 
  } 
L62: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_mulf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 140;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L89;
  }
L63: // MULTIPLY_FLOAT
  float_vars[3] = float_vars[1] * float_vars[2];
L64: // ADD_FLOAT
  float_vars[4] = float_vars[0] + float_vars[3];
L65: // ARRAY_STORE_FLOAT
  {
    void* array = object_vars[4];
    int32_t index = int_vars[12];
    if (__builtin_expect(array == NULL, 0)) { 
      env->set_exception(env, env->new_string_raw(env, "Array must not be undef")); 
      exception_flag = 1;
    } 
    else { 
      if (__builtin_expect(index < 0 || index >= *(int32_t*)((intptr_t)array + (intptr_t)env->object_length_offset), 0)) { 
        env->set_exception(env, env->new_string_raw(env, "Index is out of range")); 
        exception_flag = 1;
      } 
      else { 
((float*)((intptr_t)array + object_header_byte_size))[index]
 = float_vars[4];
      } 
    } 
  } 
L66: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_mulf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 140;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L89;
  }
L67: // MOVE_INT
  int_vars[11] = int_vars[10];
L68: // MOVE_CONSTANT_INT
  int_vars[12] = 1;
L69: // ADD_INT
  int_vars[10] = int_vars[11] + int_vars[12];
L70: // LT_INT
  int_vars[0] = (int_vars[10] < int_vars[3]);
L71: // BOOL_INT
  int_vars[0] = int_vars[0];
L72: // IF_NE_ZERO
  if (int_vars[0]) { goto L51; }
L73: // MOVE_INT
  int_vars[10] = int_vars[9];
L74: // MOVE_CONSTANT_INT
  int_vars[12] = 1;
L75: // ADD_INT
  int_vars[9] = int_vars[10] + int_vars[12];
L76: // LT_INT
  int_vars[0] = (int_vars[9] < int_vars[5]);
L77: // BOOL_INT
  int_vars[0] = int_vars[0];
L78: // IF_NE_ZERO
  if (int_vars[0]) { goto L49; }
L79: // MOVE_INT
  int_vars[9] = int_vars[8];
L80: // MOVE_CONSTANT_INT
  int_vars[11] = 1;
L81: // ADD_INT
  int_vars[8] = int_vars[9] + int_vars[11];
L82: // LT_INT
  int_vars[0] = (int_vars[8] < int_vars[2]);
L83: // BOOL_INT
  int_vars[0] = int_vars[0];
L84: // IF_NE_ZERO
  if (int_vars[0]) { goto L47; }
L85: // RETURN_OBJECT
  *(void**)&stack[0] = object_vars[5];
  if (*(void**)&stack[0] != NULL) {
    SPVM_API_INC_REF_COUNT_ONLY(*(void**)&stack[0]);
  }
  goto L89;
L86: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 6;
  mortal_stack_top++;
L87: // INIT_UNDEF
  SPVM_API_OBJECT_ASSIGN(&object_vars[6], NULL);
L88: // RETURN_OBJECT
  *(void**)&stack[0] = object_vars[6];
  if (*(void**)&stack[0] != NULL) {
    SPVM_API_INC_REF_COUNT_ONLY(*(void**)&stack[0]);
  }
  goto L89;
L89: // LEAVE_SCOPE
  {
    int32_t original_mortal_stack_top = 0;
    {
      int32_t mortal_stack_index;
      for (mortal_stack_index = original_mortal_stack_top; mortal_stack_index < mortal_stack_top; mortal_stack_index++) {
        int32_t var_index = mortal_stack[mortal_stack_index];
        void** object_address = (void**)&object_vars[var_index];
        if (*object_address != NULL) {
          if (SPVM_API_GET_REF_COUNT(*object_address) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*object_address); }
          else { env->dec_ref_count(env, *object_address); }
          *object_address = NULL;
        }
      }
    }
    mortal_stack_top = original_mortal_stack_top;
  }
L90: // END_SUB
  if (!exception_flag) {
    if (stack[0].oval != NULL) { SPVM_API_DEC_REF_COUNT_ONLY(stack[0].oval); }
  }
  return exception_flag;
}

int32_t SPPRECOMPILE__SPVM__AI__Util__mat_newf(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t object_header_byte_size = (intptr_t)env->object_header_byte_size;
  void* object_vars[3] = {0};
  int32_t int_vars[7];
  int32_t exception_flag = 0;
  int32_t mortal_stack[6];
  int32_t mortal_stack_top = 0;
  char convert_string_buffer[21];
  // Copy arguments to variables
  object_vars[0] = *(void**)&stack[0];
  if (object_vars[0] != NULL) { SPVM_API_INC_REF_COUNT_ONLY(object_vars[0]); }
  int_vars[1] = *(int32_t*)&stack[1];
  int_vars[2] = *(int32_t*)&stack[2];

L0: // INIT_INT
  int_vars[0] = 0;
L1: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 0;
  mortal_stack_top++;
L2: // BOOL_OBJECT
  int_vars[0] = !!object_vars[0];
L3: // IF_NE_ZERO
  if (int_vars[0]) { goto L11; }
L4: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 1;
  mortal_stack_top++;
L5: // NEW_STRING
  {    void* string = env->new_string_len_raw(env, "\x56\x61\x6C\x75\x65\x73\x20\x6D\x75\x73\x74\x20\x64\x65\x66\x69\x6E\x65\x64", 19);
    if (string == NULL) {
      void* exception = env->new_string_raw(env, "Can't allocate memory for string");
      env->set_exception(env, exception);
      exception_flag = 1;
    }
    else {
      SPVM_API_OBJECT_ASSIGN(&object_vars[1], string);
    }
  }L6: // SET_EXCEPTION_VAR
  env->set_exception(env, object_vars[1]);
L7: // SET_CROAK_FLAG_TRUE
  exception_flag = 1;
L8: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_newf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 150;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L40;
  }
L9: // INIT_UNDEF
  SPVM_API_OBJECT_ASSIGN(&object_vars[1], NULL);
L10: // GOTO
  goto L12;
L11: // LEAVE_SCOPE
  {
    int32_t original_mortal_stack_top = 1;
    {
      int32_t mortal_stack_index;
      for (mortal_stack_index = original_mortal_stack_top; mortal_stack_index < mortal_stack_top; mortal_stack_index++) {
        int32_t var_index = mortal_stack[mortal_stack_index];
        void** object_address = (void**)&object_vars[var_index];
        if (*object_address != NULL) {
          if (SPVM_API_GET_REF_COUNT(*object_address) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*object_address); }
          else { env->dec_ref_count(env, *object_address); }
          *object_address = NULL;
        }
      }
    }
    mortal_stack_top = original_mortal_stack_top;
  }
L12: // LEAVE_SCOPE
  {
    int32_t original_mortal_stack_top = 1;
    {
      int32_t mortal_stack_index;
      for (mortal_stack_index = original_mortal_stack_top; mortal_stack_index < mortal_stack_top; mortal_stack_index++) {
        int32_t var_index = mortal_stack[mortal_stack_index];
        void** object_address = (void**)&object_vars[var_index];
        if (*object_address != NULL) {
          if (SPVM_API_GET_REF_COUNT(*object_address) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*object_address); }
          else { env->dec_ref_count(env, *object_address); }
          *object_address = NULL;
        }
      }
    }
    mortal_stack_top = original_mortal_stack_top;
  }
L13: // MULTIPLY_INT
  int_vars[4] = int_vars[1] * int_vars[2];
L14: // ARRAY_LENGTH
  if (object_vars[0] == NULL) {
    env->set_exception(env, env->new_string_raw(env, "Can't get array length of undef value."));
    exception_flag = 1;
  }
  else {
    int_vars[5] = *(int32_t*)((intptr_t)object_vars[0] + (intptr_t)env->object_length_offset);
  }
L15: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_newf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 153;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L40;
  }
L16: // EQ_INT
  int_vars[0] = (int_vars[4] == int_vars[5]);
L17: // BOOL_INT
  int_vars[0] = int_vars[0];
L18: // IF_NE_ZERO
  if (int_vars[0]) { goto L26; }
L19: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 1;
  mortal_stack_top++;
L20: // NEW_STRING
  {    void* string = env->new_string_len_raw(env, "\x56\x61\x6C\x75\x65\x73\x20\x6C\x65\x6E\x67\x74\x68\x20\x6D\x75\x73\x74\x20\x62\x65\x20\x72\x6F\x77\x20\x2A\x20\x63\x6F\x6C", 31);
    if (string == NULL) {
      void* exception = env->new_string_raw(env, "Can't allocate memory for string");
      env->set_exception(env, exception);
      exception_flag = 1;
    }
    else {
      SPVM_API_OBJECT_ASSIGN(&object_vars[1], string);
    }
  }L21: // SET_EXCEPTION_VAR
  env->set_exception(env, object_vars[1]);
L22: // SET_CROAK_FLAG_TRUE
  exception_flag = 1;
L23: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_newf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 154;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L40;
  }
L24: // INIT_UNDEF
  SPVM_API_OBJECT_ASSIGN(&object_vars[1], NULL);
L25: // GOTO
  goto L27;
L26: // LEAVE_SCOPE
  {
    int32_t original_mortal_stack_top = 1;
    {
      int32_t mortal_stack_index;
      for (mortal_stack_index = original_mortal_stack_top; mortal_stack_index < mortal_stack_top; mortal_stack_index++) {
        int32_t var_index = mortal_stack[mortal_stack_index];
        void** object_address = (void**)&object_vars[var_index];
        if (*object_address != NULL) {
          if (SPVM_API_GET_REF_COUNT(*object_address) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*object_address); }
          else { env->dec_ref_count(env, *object_address); }
          *object_address = NULL;
        }
      }
    }
    mortal_stack_top = original_mortal_stack_top;
  }
L27: // LEAVE_SCOPE
  {
    int32_t original_mortal_stack_top = 1;
    {
      int32_t mortal_stack_index;
      for (mortal_stack_index = original_mortal_stack_top; mortal_stack_index < mortal_stack_top; mortal_stack_index++) {
        int32_t var_index = mortal_stack[mortal_stack_index];
        void** object_address = (void**)&object_vars[var_index];
        if (*object_address != NULL) {
          if (SPVM_API_GET_REF_COUNT(*object_address) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*object_address); }
          else { env->dec_ref_count(env, *object_address); }
          *object_address = NULL;
        }
      }
    }
    mortal_stack_top = original_mortal_stack_top;
  }
L28: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 1;
  mortal_stack_top++;
L29: // NEW_OBJECT
  {
    if (BASIC_TYPE_ID_SPVM__AI__Util__FloatMatrix < 0) {
      BASIC_TYPE_ID_SPVM__AI__Util__FloatMatrix = env->get_basic_type_id(env, "SPVM::AI::Util::FloatMatrix");
      if (BASIC_TYPE_ID_SPVM__AI__Util__FloatMatrix < 0) {
        void* exception = env->new_string_raw(env, "Basic type not found SPVM::AI::Util::FloatMatrix");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
    }
    int32_t basic_type_id = BASIC_TYPE_ID_SPVM__AI__Util__FloatMatrix;
    void* object = env->new_object_raw(env, basic_type_id);
    if (object == NULL) {
      void* exception = env->new_string_raw(env, "Can't allocate memory for object");
      env->set_exception(env, exception);
      exception_flag = 1;
    }
    else {
      SPVM_API_OBJECT_ASSIGN(&object_vars[1], object);
    }
  }
L30: // SET_FIELD_OBJECT
  {
    if (__builtin_expect(FIELD_ID_SPVM__AI__Util__FloatMatrix__values < 0, 0)) {
      FIELD_ID_SPVM__AI__Util__FloatMatrix__values = env->get_field_id(env, "SPVM::AI::Util::FloatMatrix", "values", "float[]");
      if (FIELD_ID_SPVM__AI__Util__FloatMatrix__values < 0) {
        void* exception = env->new_string_raw(env, "Field not found SPVM::AI::Util::FloatMatrix values");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
      FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__values = env->get_field_offset(env, FIELD_ID_SPVM__AI__Util__FloatMatrix__values);
    };
    void* object = object_vars[1];    if (__builtin_expect(object == NULL, 0)) {
      env->set_exception(env, env->new_string_raw(env, "Object must be not undef."));
      exception_flag = 1;
    }
    else {
      void* get_field_object_address = (void**)((intptr_t)object + object_header_byte_size + FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__values);
      SPVM_API_OBJECT_ASSIGN(get_field_object_address,object_vars[0]    );
    }
  }
L31: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_newf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 157;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L40;
  }
L32: // SET_FIELD_INT
  {
    if (__builtin_expect(FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length < 0, 0)) {
      FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length = env->get_field_id(env, "SPVM::AI::Util::FloatMatrix", "rows_length", "int");
      if (FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length < 0) {
        void* exception = env->new_string_raw(env, "Field not found SPVM::AI::Util::FloatMatrix rows_length");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
      FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__rows_length = env->get_field_offset(env, FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length);
    };
    void* object = object_vars[1];
    if (__builtin_expect(object == NULL, 0)) {
      env->set_exception(env, env->new_string_raw(env, "Object must be not undef."));
      exception_flag = 1;
    }
    else {
      *(int32_t*)((intptr_t)object + object_header_byte_size + FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__rows_length) = int_vars[1];
    }
  }
L33: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_newf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 158;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L40;
  }
L34: // SET_FIELD_INT
  {
    if (__builtin_expect(FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length < 0, 0)) {
      FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length = env->get_field_id(env, "SPVM::AI::Util::FloatMatrix", "columns_length", "int");
      if (FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length < 0) {
        void* exception = env->new_string_raw(env, "Field not found SPVM::AI::Util::FloatMatrix columns_length");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
      FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__columns_length = env->get_field_offset(env, FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length);
    };
    void* object = object_vars[1];
    if (__builtin_expect(object == NULL, 0)) {
      env->set_exception(env, env->new_string_raw(env, "Object must be not undef."));
      exception_flag = 1;
    }
    else {
      *(int32_t*)((intptr_t)object + object_header_byte_size + FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__columns_length) = int_vars[2];
    }
  }
L35: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_newf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 159;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L40;
  }
L36: // RETURN_OBJECT
  *(void**)&stack[0] = object_vars[1];
  if (*(void**)&stack[0] != NULL) {
    SPVM_API_INC_REF_COUNT_ONLY(*(void**)&stack[0]);
  }
  goto L40;
L37: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 2;
  mortal_stack_top++;
L38: // INIT_UNDEF
  SPVM_API_OBJECT_ASSIGN(&object_vars[2], NULL);
L39: // RETURN_OBJECT
  *(void**)&stack[0] = object_vars[2];
  if (*(void**)&stack[0] != NULL) {
    SPVM_API_INC_REF_COUNT_ONLY(*(void**)&stack[0]);
  }
  goto L40;
L40: // LEAVE_SCOPE
  {
    int32_t original_mortal_stack_top = 0;
    {
      int32_t mortal_stack_index;
      for (mortal_stack_index = original_mortal_stack_top; mortal_stack_index < mortal_stack_top; mortal_stack_index++) {
        int32_t var_index = mortal_stack[mortal_stack_index];
        void** object_address = (void**)&object_vars[var_index];
        if (*object_address != NULL) {
          if (SPVM_API_GET_REF_COUNT(*object_address) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*object_address); }
          else { env->dec_ref_count(env, *object_address); }
          *object_address = NULL;
        }
      }
    }
    mortal_stack_top = original_mortal_stack_top;
  }
L41: // END_SUB
  if (!exception_flag) {
    if (stack[0].oval != NULL) { SPVM_API_DEC_REF_COUNT_ONLY(stack[0].oval); }
  }
  return exception_flag;
}

int32_t SPPRECOMPILE__SPVM__AI__Util__mat_new_zerof(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t object_header_byte_size = (intptr_t)env->object_header_byte_size;
  void* object_vars[2] = {0};
  int32_t int_vars[7];
  int32_t exception_flag = 0;
  int32_t mortal_stack[6];
  int32_t mortal_stack_top = 0;
  char convert_string_buffer[21];
  // Copy arguments to variables
  int_vars[1] = *(int32_t*)&stack[0];
  int_vars[2] = *(int32_t*)&stack[1];

L0: // INIT_INT
  int_vars[0] = 0;
L1: // MOVE_CONSTANT_INT
  int_vars[3] = 0;
L2: // GT_INT
  int_vars[0] = (int_vars[1] > int_vars[3]);
L3: // BOOL_INT
  int_vars[0] = int_vars[0];
L4: // IF_NE_ZERO
  if (int_vars[0]) { goto L12; }
L5: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 0;
  mortal_stack_top++;
L6: // NEW_STRING
  {    void* string = env->new_string_len_raw(env, "\x52\x6F\x77\x20\x6D\x75\x73\x74\x20\x62\x65\x20\x6D\x6F\x72\x65\x20\x74\x68\x61\x6E\x20\x30", 23);
    if (string == NULL) {
      void* exception = env->new_string_raw(env, "Can't allocate memory for string");
      env->set_exception(env, exception);
      exception_flag = 1;
    }
    else {
      SPVM_API_OBJECT_ASSIGN(&object_vars[0], string);
    }
  }L7: // SET_EXCEPTION_VAR
  env->set_exception(env, object_vars[0]);
L8: // SET_CROAK_FLAG_TRUE
  exception_flag = 1;
L9: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_new_zerof";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 165;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L44;
  }
L10: // INIT_UNDEF
  SPVM_API_OBJECT_ASSIGN(&object_vars[0], NULL);
L11: // GOTO
  goto L13;
L12: // LEAVE_SCOPE
  {
    int32_t original_mortal_stack_top = 0;
    {
      int32_t mortal_stack_index;
      for (mortal_stack_index = original_mortal_stack_top; mortal_stack_index < mortal_stack_top; mortal_stack_index++) {
        int32_t var_index = mortal_stack[mortal_stack_index];
        void** object_address = (void**)&object_vars[var_index];
        if (*object_address != NULL) {
          if (SPVM_API_GET_REF_COUNT(*object_address) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*object_address); }
          else { env->dec_ref_count(env, *object_address); }
          *object_address = NULL;
        }
      }
    }
    mortal_stack_top = original_mortal_stack_top;
  }
L13: // LEAVE_SCOPE
  {
    int32_t original_mortal_stack_top = 0;
    {
      int32_t mortal_stack_index;
      for (mortal_stack_index = original_mortal_stack_top; mortal_stack_index < mortal_stack_top; mortal_stack_index++) {
        int32_t var_index = mortal_stack[mortal_stack_index];
        void** object_address = (void**)&object_vars[var_index];
        if (*object_address != NULL) {
          if (SPVM_API_GET_REF_COUNT(*object_address) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*object_address); }
          else { env->dec_ref_count(env, *object_address); }
          *object_address = NULL;
        }
      }
    }
    mortal_stack_top = original_mortal_stack_top;
  }
L14: // MOVE_CONSTANT_INT
  int_vars[4] = 0;
L15: // GT_INT
  int_vars[0] = (int_vars[2] > int_vars[4]);
L16: // BOOL_INT
  int_vars[0] = int_vars[0];
L17: // IF_NE_ZERO
  if (int_vars[0]) { goto L25; }
L18: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 0;
  mortal_stack_top++;
L19: // NEW_STRING
  {    void* string = env->new_string_len_raw(env, "\x43\x6F\x6C\x20\x6D\x75\x73\x74\x20\x62\x65\x20\x6D\x6F\x72\x65\x20\x74\x68\x61\x6E\x20\x30", 23);
    if (string == NULL) {
      void* exception = env->new_string_raw(env, "Can't allocate memory for string");
      env->set_exception(env, exception);
      exception_flag = 1;
    }
    else {
      SPVM_API_OBJECT_ASSIGN(&object_vars[0], string);
    }
  }L20: // SET_EXCEPTION_VAR
  env->set_exception(env, object_vars[0]);
L21: // SET_CROAK_FLAG_TRUE
  exception_flag = 1;
L22: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_new_zerof";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 168;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L44;
  }
L23: // INIT_UNDEF
  SPVM_API_OBJECT_ASSIGN(&object_vars[0], NULL);
L24: // GOTO
  goto L26;
L25: // LEAVE_SCOPE
  {
    int32_t original_mortal_stack_top = 0;
    {
      int32_t mortal_stack_index;
      for (mortal_stack_index = original_mortal_stack_top; mortal_stack_index < mortal_stack_top; mortal_stack_index++) {
        int32_t var_index = mortal_stack[mortal_stack_index];
        void** object_address = (void**)&object_vars[var_index];
        if (*object_address != NULL) {
          if (SPVM_API_GET_REF_COUNT(*object_address) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*object_address); }
          else { env->dec_ref_count(env, *object_address); }
          *object_address = NULL;
        }
      }
    }
    mortal_stack_top = original_mortal_stack_top;
  }
L26: // LEAVE_SCOPE
  {
    int32_t original_mortal_stack_top = 0;
    {
      int32_t mortal_stack_index;
      for (mortal_stack_index = original_mortal_stack_top; mortal_stack_index < mortal_stack_top; mortal_stack_index++) {
        int32_t var_index = mortal_stack[mortal_stack_index];
        void** object_address = (void**)&object_vars[var_index];
        if (*object_address != NULL) {
          if (SPVM_API_GET_REF_COUNT(*object_address) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*object_address); }
          else { env->dec_ref_count(env, *object_address); }
          *object_address = NULL;
        }
      }
    }
    mortal_stack_top = original_mortal_stack_top;
  }
L27: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 0;
  mortal_stack_top++;
L28: // NEW_OBJECT
  {
    if (BASIC_TYPE_ID_SPVM__AI__Util__FloatMatrix < 0) {
      BASIC_TYPE_ID_SPVM__AI__Util__FloatMatrix = env->get_basic_type_id(env, "SPVM::AI::Util::FloatMatrix");
      if (BASIC_TYPE_ID_SPVM__AI__Util__FloatMatrix < 0) {
        void* exception = env->new_string_raw(env, "Basic type not found SPVM::AI::Util::FloatMatrix");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
    }
    int32_t basic_type_id = BASIC_TYPE_ID_SPVM__AI__Util__FloatMatrix;
    void* object = env->new_object_raw(env, basic_type_id);
    if (object == NULL) {
      void* exception = env->new_string_raw(env, "Can't allocate memory for object");
      env->set_exception(env, exception);
      exception_flag = 1;
    }
    else {
      SPVM_API_OBJECT_ASSIGN(&object_vars[0], object);
    }
  }
L29: // MULTIPLY_INT
  int_vars[4] = int_vars[1] * int_vars[2];
L30: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 1;
  mortal_stack_top++;
L31: // NEW_FLOAT_ARRAY
  {
    int32_t length = *(int32_t*)&int_vars[4];
    if (length >= 0) {
      void* object = env->new_float_array_raw(env, length);
      if (object == NULL) {
        void* exception = env->new_string_raw(env, "Can't allocate memory for float array");
        env->set_exception(env, exception);
        exception_flag = 1;
      }
      else {
        SPVM_API_OBJECT_ASSIGN((void**)&object_vars[1], object);
      }
    }
    else {
      void* exception = env->new_string_raw(env, "Array length must be more than or equal to 0");
      env->set_exception(env, exception);
      exception_flag = 1;
    }
  }
L32: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_new_zerof";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 172;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L44;
  }
L33: // SET_FIELD_OBJECT
  {
    if (__builtin_expect(FIELD_ID_SPVM__AI__Util__FloatMatrix__values < 0, 0)) {
      FIELD_ID_SPVM__AI__Util__FloatMatrix__values = env->get_field_id(env, "SPVM::AI::Util::FloatMatrix", "values", "float[]");
      if (FIELD_ID_SPVM__AI__Util__FloatMatrix__values < 0) {
        void* exception = env->new_string_raw(env, "Field not found SPVM::AI::Util::FloatMatrix values");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
      FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__values = env->get_field_offset(env, FIELD_ID_SPVM__AI__Util__FloatMatrix__values);
    };
    void* object = object_vars[0];    if (__builtin_expect(object == NULL, 0)) {
      env->set_exception(env, env->new_string_raw(env, "Object must be not undef."));
      exception_flag = 1;
    }
    else {
      void* get_field_object_address = (void**)((intptr_t)object + object_header_byte_size + FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__values);
      SPVM_API_OBJECT_ASSIGN(get_field_object_address,object_vars[1]    );
    }
  }
L34: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_new_zerof";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 172;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L44;
  }
L35: // INIT_UNDEF
  SPVM_API_OBJECT_ASSIGN(&object_vars[1], NULL);
L36: // SET_FIELD_INT
  {
    if (__builtin_expect(FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length < 0, 0)) {
      FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length = env->get_field_id(env, "SPVM::AI::Util::FloatMatrix", "rows_length", "int");
      if (FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length < 0) {
        void* exception = env->new_string_raw(env, "Field not found SPVM::AI::Util::FloatMatrix rows_length");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
      FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__rows_length = env->get_field_offset(env, FIELD_ID_SPVM__AI__Util__FloatMatrix__rows_length);
    };
    void* object = object_vars[0];
    if (__builtin_expect(object == NULL, 0)) {
      env->set_exception(env, env->new_string_raw(env, "Object must be not undef."));
      exception_flag = 1;
    }
    else {
      *(int32_t*)((intptr_t)object + object_header_byte_size + FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__rows_length) = int_vars[1];
    }
  }
L37: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_new_zerof";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 173;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L44;
  }
L38: // SET_FIELD_INT
  {
    if (__builtin_expect(FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length < 0, 0)) {
      FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length = env->get_field_id(env, "SPVM::AI::Util::FloatMatrix", "columns_length", "int");
      if (FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length < 0) {
        void* exception = env->new_string_raw(env, "Field not found SPVM::AI::Util::FloatMatrix columns_length");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
      FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__columns_length = env->get_field_offset(env, FIELD_ID_SPVM__AI__Util__FloatMatrix__columns_length);
    };
    void* object = object_vars[0];
    if (__builtin_expect(object == NULL, 0)) {
      env->set_exception(env, env->new_string_raw(env, "Object must be not undef."));
      exception_flag = 1;
    }
    else {
      *(int32_t*)((intptr_t)object + object_header_byte_size + FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__columns_length) = int_vars[2];
    }
  }
L39: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_new_zerof";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 174;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L44;
  }
L40: // RETURN_OBJECT
  *(void**)&stack[0] = object_vars[0];
  if (*(void**)&stack[0] != NULL) {
    SPVM_API_INC_REF_COUNT_ONLY(*(void**)&stack[0]);
  }
  goto L44;
L41: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 1;
  mortal_stack_top++;
L42: // INIT_UNDEF
  SPVM_API_OBJECT_ASSIGN(&object_vars[1], NULL);
L43: // RETURN_OBJECT
  *(void**)&stack[0] = object_vars[1];
  if (*(void**)&stack[0] != NULL) {
    SPVM_API_INC_REF_COUNT_ONLY(*(void**)&stack[0]);
  }
  goto L44;
L44: // LEAVE_SCOPE
  {
    int32_t original_mortal_stack_top = 0;
    {
      int32_t mortal_stack_index;
      for (mortal_stack_index = original_mortal_stack_top; mortal_stack_index < mortal_stack_top; mortal_stack_index++) {
        int32_t var_index = mortal_stack[mortal_stack_index];
        void** object_address = (void**)&object_vars[var_index];
        if (*object_address != NULL) {
          if (SPVM_API_GET_REF_COUNT(*object_address) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*object_address); }
          else { env->dec_ref_count(env, *object_address); }
          *object_address = NULL;
        }
      }
    }
    mortal_stack_top = original_mortal_stack_top;
  }
L45: // END_SUB
  if (!exception_flag) {
    if (stack[0].oval != NULL) { SPVM_API_DEC_REF_COUNT_ONLY(stack[0].oval); }
  }
  return exception_flag;
}

int32_t SPPRECOMPILE__SPVM__AI__Util__mat_new_identf(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t object_header_byte_size = (intptr_t)env->object_header_byte_size;
  void* object_vars[3] = {0};
  float float_vars[1];
  int32_t int_vars[7];
  int32_t exception_flag = 0;
  int32_t mortal_stack[5];
  int32_t mortal_stack_top = 0;
  char convert_string_buffer[21];
  // Copy arguments to variables
  int_vars[1] = *(int32_t*)&stack[0];

L0: // INIT_INT
  int_vars[0] = 0;
L1: // MOVE_CONSTANT_INT
  int_vars[2] = 1;
L2: // LT_INT
  int_vars[0] = (int_vars[1] < int_vars[2]);
L3: // BOOL_INT
  int_vars[0] = int_vars[0];
L4: // IF_EQ_ZERO
  if (int_vars[0] == 0) { goto L12; }
L5: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 0;
  mortal_stack_top++;
L6: // NEW_STRING
  {    void* string = env->new_string_len_raw(env, "\x44\x69\x6D\x65\x6E\x73\x69\x6F\x6E\x20\x6D\x75\x73\x74\x20\x62\x65\x20\x6D\x6F\x72\x65\x20\x74\x68\x61\x6E\x20\x30", 29);
    if (string == NULL) {
      void* exception = env->new_string_raw(env, "Can't allocate memory for string");
      env->set_exception(env, exception);
      exception_flag = 1;
    }
    else {
      SPVM_API_OBJECT_ASSIGN(&object_vars[0], string);
    }
  }L7: // SET_EXCEPTION_VAR
  env->set_exception(env, object_vars[0]);
L8: // SET_CROAK_FLAG_TRUE
  exception_flag = 1;
L9: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_new_identf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 180;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L40;
  }
L10: // INIT_UNDEF
  SPVM_API_OBJECT_ASSIGN(&object_vars[0], NULL);
L11: // GOTO
  goto L13;
L12: // LEAVE_SCOPE
  {
    int32_t original_mortal_stack_top = 0;
    {
      int32_t mortal_stack_index;
      for (mortal_stack_index = original_mortal_stack_top; mortal_stack_index < mortal_stack_top; mortal_stack_index++) {
        int32_t var_index = mortal_stack[mortal_stack_index];
        void** object_address = (void**)&object_vars[var_index];
        if (*object_address != NULL) {
          if (SPVM_API_GET_REF_COUNT(*object_address) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*object_address); }
          else { env->dec_ref_count(env, *object_address); }
          *object_address = NULL;
        }
      }
    }
    mortal_stack_top = original_mortal_stack_top;
  }
L13: // LEAVE_SCOPE
  {
    int32_t original_mortal_stack_top = 0;
    {
      int32_t mortal_stack_index;
      for (mortal_stack_index = original_mortal_stack_top; mortal_stack_index < mortal_stack_top; mortal_stack_index++) {
        int32_t var_index = mortal_stack[mortal_stack_index];
        void** object_address = (void**)&object_vars[var_index];
        if (*object_address != NULL) {
          if (SPVM_API_GET_REF_COUNT(*object_address) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*object_address); }
          else { env->dec_ref_count(env, *object_address); }
          *object_address = NULL;
        }
      }
    }
    mortal_stack_top = original_mortal_stack_top;
  }
L14: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 0;
  mortal_stack_top++;
L15: // PUSH_ARG_INT
  *(int32_t*)&stack[0] = int_vars[1];
L16: // PUSH_ARG_INT
  *(int32_t*)&stack[1] = int_vars[1];
L17: // CALL_SUB_OBJECT
  // SPVM::AI::Util->mat_new_zerof
  {
    if (SUB_ID_SPVM__AI__Util__mat_new_zerof < 0) {
      SUB_ID_SPVM__AI__Util__mat_new_zerof = env->get_sub_id(env, "SPVM::AI::Util", "mat_new_zerof", "SPVM::AI::Util::FloatMatrix(int,int)");
      if (SUB_ID_SPVM__AI__Util__mat_new_zerof < 0) {
        void* exception = env->new_string_raw(env, "Subroutine not found SPVM::AI::Util mat_new_zerof");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
    }
    int32_t call_sub_id = SUB_ID_SPVM__AI__Util__mat_new_zerof;
    exception_flag = SPPRECOMPILE__SPVM__AI__Util__mat_new_zerof(env, stack);
    if (!exception_flag) {
      SPVM_API_OBJECT_ASSIGN(&object_vars[0], stack[0].oval);
    }
  }
L18: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_new_identf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 183;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L40;
  }
L19: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 1;
  mortal_stack_top++;
L20: // GET_FIELD_OBJECT
  {
    if (__builtin_expect(FIELD_ID_SPVM__AI__Util__FloatMatrix__values < 0, 0)) {
      FIELD_ID_SPVM__AI__Util__FloatMatrix__values = env->get_field_id(env, "SPVM::AI::Util::FloatMatrix", "values", "float[]");
      if (FIELD_ID_SPVM__AI__Util__FloatMatrix__values < 0) {
        void* exception = env->new_string_raw(env, "Field not found SPVM::AI::Util::FloatMatrix values");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
      FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__values = env->get_field_offset(env, FIELD_ID_SPVM__AI__Util__FloatMatrix__values);
    };
    void* object = object_vars[0];
    if (__builtin_expect(object == NULL, 0)) {
      env->set_exception(env, env->new_string_raw(env, "Object must be not undef."));
      exception_flag = 1;
    }
    else {
      void* get_field_object = *(void**)((intptr_t)object + object_header_byte_size + FIELD_BYTE_OFFSET_SPVM__AI__Util__FloatMatrix__values);
      SPVM_API_OBJECT_ASSIGN(&object_vars[1], get_field_object);    }
  }
L21: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_new_identf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 184;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L40;
  }
L22: // MOVE_CONSTANT_INT
  int_vars[3] = 0;
L23: // GOTO
  goto L33;
L24: // MOVE_CONSTANT_INT
  int_vars[4] = 1;
L25: // CONVERT_INT_TO_FLOAT
  float_vars[0] = (float)int_vars[4];
L26: // MULTIPLY_INT
  int_vars[5] = int_vars[3] * int_vars[1];
L27: // ADD_INT
  int_vars[6] = int_vars[5] + int_vars[3];
L28: // ARRAY_STORE_FLOAT
  {
    void* array = object_vars[1];
    int32_t index = int_vars[6];
    if (__builtin_expect(array == NULL, 0)) { 
      env->set_exception(env, env->new_string_raw(env, "Array must not be undef")); 
      exception_flag = 1;
    } 
    else { 
      if (__builtin_expect(index < 0 || index >= *(int32_t*)((intptr_t)array + (intptr_t)env->object_length_offset), 0)) { 
        env->set_exception(env, env->new_string_raw(env, "Index is out of range")); 
        exception_flag = 1;
      } 
      else { 
((float*)((intptr_t)array + object_header_byte_size))[index]
 = float_vars[0];
      } 
    } 
  } 
L29: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "SPVM::AI::Util";
    const char* sub_name = "mat_new_identf";
    const char* file = "/home/kimoto/labo/SPVM-AI-Util/SPVM-AI-Util-0.01/blib/lib/SPVM/AI/Util.spvm";
    int32_t line = 186;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L40;
  }
L30: // MOVE_INT
  int_vars[4] = int_vars[3];
L31: // MOVE_CONSTANT_INT
  int_vars[5] = 1;
L32: // ADD_INT
  int_vars[3] = int_vars[4] + int_vars[5];
L33: // LT_INT
  int_vars[0] = (int_vars[3] < int_vars[1]);
L34: // BOOL_INT
  int_vars[0] = int_vars[0];
L35: // IF_NE_ZERO
  if (int_vars[0]) { goto L24; }
L36: // RETURN_OBJECT
  *(void**)&stack[0] = object_vars[0];
  if (*(void**)&stack[0] != NULL) {
    SPVM_API_INC_REF_COUNT_ONLY(*(void**)&stack[0]);
  }
  goto L40;
L37: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 2;
  mortal_stack_top++;
L38: // INIT_UNDEF
  SPVM_API_OBJECT_ASSIGN(&object_vars[2], NULL);
L39: // RETURN_OBJECT
  *(void**)&stack[0] = object_vars[2];
  if (*(void**)&stack[0] != NULL) {
    SPVM_API_INC_REF_COUNT_ONLY(*(void**)&stack[0]);
  }
  goto L40;
L40: // LEAVE_SCOPE
  {
    int32_t original_mortal_stack_top = 0;
    {
      int32_t mortal_stack_index;
      for (mortal_stack_index = original_mortal_stack_top; mortal_stack_index < mortal_stack_top; mortal_stack_index++) {
        int32_t var_index = mortal_stack[mortal_stack_index];
        void** object_address = (void**)&object_vars[var_index];
        if (*object_address != NULL) {
          if (SPVM_API_GET_REF_COUNT(*object_address) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*object_address); }
          else { env->dec_ref_count(env, *object_address); }
          *object_address = NULL;
        }
      }
    }
    mortal_stack_top = original_mortal_stack_top;
  }
L41: // END_SUB
  if (!exception_flag) {
    if (stack[0].oval != NULL) { SPVM_API_DEC_REF_COUNT_ONLY(stack[0].oval); }
  }
  return exception_flag;
}


