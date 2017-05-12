#ifndef _QSTRUCT_COMPILER_H
#define _QSTRUCT_COMPILER_H

#include <inttypes.h>

#include "uthash.h"


#define QSTRUCT_HEADER_SIZE 16

#define QSTRUCT_TYPE_STRING 1
#define QSTRUCT_TYPE_BLOB 2
#define QSTRUCT_TYPE_BOOL 3
#define QSTRUCT_TYPE_FLOAT 4
#define QSTRUCT_TYPE_DOUBLE 5
#define QSTRUCT_TYPE_INT8 6
#define QSTRUCT_TYPE_INT16 7
#define QSTRUCT_TYPE_INT32 8
#define QSTRUCT_TYPE_INT64 9
#define QSTRUCT_TYPE_NESTED 10

#define QSTRUCT_TYPE_MOD_UNSIGNED (1<<16)
#define QSTRUCT_TYPE_MOD_ARRAY_FIX (1<<17)
#define QSTRUCT_TYPE_MOD_ARRAY_DYN (1<<18)


struct qstruct_definition {
  char *name;
  size_t name_len;
  struct qstruct_item *items;
  size_t num_items;
  uint32_t body_size;
  struct qstruct_definition *next;

  // private
  UT_hash_handle hh;
};

struct qstruct_item {
  char *name;
  size_t name_len;
  int type;
  uint32_t fixed_array_size;
  uint32_t byte_offset;
  int bit_offset;
  struct qstruct_definition *nested_def;
  char *nested_name;
  size_t nested_name_len;
  size_t item_order;

  // private
  int occupied;
  UT_hash_handle hh;
};


struct qstruct_definition *parse_qstructs(char *schema, size_t schema_size, char *err_buf, size_t err_buf_size);
void free_qstruct_definitions(struct qstruct_definition *def);

#endif
