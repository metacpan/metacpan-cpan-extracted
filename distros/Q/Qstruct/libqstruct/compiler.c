#include <inttypes.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include "qstruct/compiler.h"


static int alignment_of_type(struct qstruct_item *item) {
  if (item->type & QSTRUCT_TYPE_MOD_ARRAY_DYN) return 8;

  switch(item->type & 0xFFFF) {
    case QSTRUCT_TYPE_STRING:
    case QSTRUCT_TYPE_BLOB:
    case QSTRUCT_TYPE_DOUBLE:
    case QSTRUCT_TYPE_INT64:
    case QSTRUCT_TYPE_NESTED:
      return 8;
    case QSTRUCT_TYPE_FLOAT:
    case QSTRUCT_TYPE_INT32:
      return 4;
    case QSTRUCT_TYPE_INT16:
      return 2;
    case QSTRUCT_TYPE_INT8:
      return 1;
    case QSTRUCT_TYPE_BOOL:
      return 0; // special-case for single-bit booleans
  }

  assert(0); // unknown type
}


static int size_of_type(struct qstruct_item *item) {
  if (item->type & QSTRUCT_TYPE_MOD_ARRAY_DYN) return 16;

  switch(item->type & 0xFFFF) {
    case QSTRUCT_TYPE_STRING:
    case QSTRUCT_TYPE_BLOB:
    case QSTRUCT_TYPE_NESTED:
      return 16;
    case QSTRUCT_TYPE_DOUBLE:
    case QSTRUCT_TYPE_INT64:
      return 8;
    case QSTRUCT_TYPE_FLOAT:
    case QSTRUCT_TYPE_INT32:
      return 4;
    case QSTRUCT_TYPE_INT16:
      return 2;
    case QSTRUCT_TYPE_INT8:
      return 1;
    case QSTRUCT_TYPE_BOOL:
      assert(0); // don't call this function for the single-bit boolean special case
  }

  assert(0); // unknown type
}


static int worst_case_size_of_type(struct qstruct_item *item) {
  if (item->type & QSTRUCT_TYPE_MOD_ARRAY_DYN) return 16;

  switch(item->type & 0xFFFF) {
    case QSTRUCT_TYPE_STRING:
    case QSTRUCT_TYPE_BLOB:
    case QSTRUCT_TYPE_NESTED:
      return 16;
    case QSTRUCT_TYPE_DOUBLE:
    case QSTRUCT_TYPE_INT64:
    case QSTRUCT_TYPE_FLOAT:
    case QSTRUCT_TYPE_INT32:
    case QSTRUCT_TYPE_INT16:
    case QSTRUCT_TYPE_INT8:
    case QSTRUCT_TYPE_BOOL:
      return 8; // any of these can occupy 8 bytes (ie if followed by a string and nothing else)
  };

  assert(0); // unknown type
}



int calculate_qstruct_packing(struct qstruct_definition *def) {
  struct qstruct_item *item;
  uint32_t curr_body_offset = 0, max_body_size = 0, space_needed;
  uint32_t curr_alignment_offsets[17]; // 17 includes special single-bit boolean offset in elem 0
  uint32_t i, desired_alignment, curr_item;
  char *packing_array;

  for (i=0; i<17; i++) curr_alignment_offsets[i] = 0;

  for(curr_item = 0; curr_item < def->num_items; curr_item++) {
    item = def->items + curr_item;

    max_body_size += worst_case_size_of_type(item) * item->fixed_array_size;
  }

  packing_array = calloc(max_body_size, 1);
  if (packing_array == NULL) return -1;

  for(curr_item = 0; curr_item < def->num_items; curr_item++) {
    item = def->items + curr_item;

    desired_alignment = alignment_of_type(item);

    if (desired_alignment == 0) {
      // special case for single-bit booleans

      while (packing_array[curr_alignment_offsets[0]] == '\xFF') {
        curr_alignment_offsets[0]++;
        assert(curr_alignment_offsets[0] < max_body_size);
      }

      item->byte_offset = curr_alignment_offsets[0];
      item->bit_offset = packing_array[curr_alignment_offsets[0]] + 1;

      packing_array[curr_alignment_offsets[0]] = (packing_array[curr_alignment_offsets[0]] << 1) + 1;

      if (curr_alignment_offsets[0] + 1 > curr_body_offset)
        curr_body_offset = curr_alignment_offsets[0] + 1;

      continue;
    }

    space_needed = size_of_type(item) * item->fixed_array_size;

    try_to_fit:

    assert(curr_alignment_offsets[desired_alignment] + space_needed <= max_body_size);

    for(i = 0; i < space_needed; i++) {
      if (packing_array[curr_alignment_offsets[desired_alignment] + i] != '\0') {
        curr_alignment_offsets[desired_alignment] += desired_alignment;
        goto try_to_fit;
      }
    }

    for(i = 0; i < space_needed; i++) {
      packing_array[curr_alignment_offsets[desired_alignment] + i] = 0xFF;
    }

    item->byte_offset = curr_alignment_offsets[desired_alignment];
    item->bit_offset = 0;

    curr_alignment_offsets[desired_alignment] += space_needed;

    if (curr_alignment_offsets[desired_alignment] > curr_body_offset)
      curr_body_offset = curr_alignment_offsets[desired_alignment];
  }

  free(packing_array);

  def->body_size = curr_body_offset;

  return 0;
}
