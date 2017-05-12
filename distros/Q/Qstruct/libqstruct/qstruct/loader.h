#ifndef _QSTRUCT_LOADER_H
#define _QSTRUCT_LOADER_H

#include <inttypes.h>
#include <stdint.h>

#include "qstruct/utils.h"



#define QSTRUCT_GETTER_PREAMBLE(size_of_val) \
  uint32_t body_size, body_count; \
  uint64_t content_size; \
  int exceeds_bounds; \
  size_t body_offset, actual_offset; \
  \
  if (buf_size < QSTRUCT_HEADER_SIZE) return -1; \
  QSTRUCT_LOAD_4BYTE_LE(buf + 8, &body_size); \
  QSTRUCT_LOAD_4BYTE_LE(buf + 12, &body_count); \
  \
  if (body_index >= body_count) return -9; \
  \
  content_size = (body_size * body_count) + QSTRUCT_HEADER_SIZE; \
  if (content_size > SIZE_MAX/2) return -3; \
  \
  body_offset = QSTRUCT_HEADER_SIZE + (QSTRUCT_ALIGN_UP(body_size, QSTRUCT_BODY_SIZE_TO_ALIGNMENT(body_size)) * body_index); \
  actual_offset = body_offset + byte_offset; \
  \
  exceeds_bounds = ((byte_offset + (size_of_val) > body_size) || \
                    (body_offset + (size_of_val) > buf_size));




static QSTRUCT_INLINE int qstruct_sanity_check(char *buf, size_t buf_size) {
  uint32_t body_index = 0, byte_offset = 0;
  QSTRUCT_GETTER_PREAMBLE(0)

  if (content_size > buf_size) return -2;

  return 0;
}


static QSTRUCT_INLINE int qstruct_unpack_header(char *buf, size_t buf_size, uint64_t *output_magic_id, uint32_t *output_body_size, uint32_t *output_body_count) {
  uint32_t body_index = 0, byte_offset = 0;
  QSTRUCT_GETTER_PREAMBLE(0)

  QSTRUCT_LOAD_4BYTE_LE(buf, output_magic_id);
  *output_body_size = body_size;
  *output_body_count = body_count;

  return 0;
}



static QSTRUCT_INLINE int qstruct_get_uint64(char *buf, size_t buf_size, uint32_t body_index, uint32_t byte_offset, uint64_t *output) {
  QSTRUCT_GETTER_PREAMBLE(8)

  if (exceeds_bounds) {
    *output = 0; // default value
  } else {
    QSTRUCT_LOAD_8BYTE_LE(buf + actual_offset, output);
  }

  return 0;
}

static QSTRUCT_INLINE int qstruct_get_uint32(char *buf, size_t buf_size, uint32_t body_index, uint32_t byte_offset, uint32_t *output) {
  QSTRUCT_GETTER_PREAMBLE(4)

  if (exceeds_bounds) {
    *output = 0; // default value
  } else {
    QSTRUCT_LOAD_4BYTE_LE(buf + actual_offset, output);
  }

  return 0;
}

static QSTRUCT_INLINE int qstruct_get_uint16(char *buf, size_t buf_size, uint32_t body_index, uint32_t byte_offset, uint16_t *output) {
  QSTRUCT_GETTER_PREAMBLE(2)

  if (exceeds_bounds) {
    *output = 0; // default value
  } else {
    QSTRUCT_LOAD_2BYTE_LE(buf + actual_offset, output);
  }

  return 0;
}

static QSTRUCT_INLINE int qstruct_get_uint8(char *buf, size_t buf_size, uint32_t body_index, uint32_t byte_offset, uint8_t *output) {
  QSTRUCT_GETTER_PREAMBLE(1)

  if (exceeds_bounds) {
    *output = 0; // default value
  } else {
    *output = *((uint8_t*)(buf + actual_offset));
  }

  return 0;
}

static QSTRUCT_INLINE int qstruct_get_bool(char *buf, size_t buf_size, uint32_t body_index, uint32_t byte_offset, int bit_offset, int *output) {
  QSTRUCT_GETTER_PREAMBLE(1)

  if (exceeds_bounds) {
    *output = 0; // default to false
  } else {
    *output = !!(*((uint8_t *)(buf + actual_offset)) & bit_offset);
  }

  return 0;
}


static QSTRUCT_INLINE int qstruct_get_pointer(char *buf, size_t buf_size, uint32_t body_index, uint32_t byte_offset, char **output, size_t *output_size, int alignment) {
  uint64_t length, start_offset;
  QSTRUCT_GETTER_PREAMBLE(16)

  if (exceeds_bounds) {
    *output = 0; // default value
    *output_size = 0;
  } else {
    QSTRUCT_LOAD_8BYTE_LE(buf + actual_offset, &length);

    if (alignment == 1 && length & 0xF) {
      *output = buf + actual_offset + 1;
      *output_size = (size_t)(length & 0xF);
    } else {
      length = length >> 8;
      QSTRUCT_LOAD_8BYTE_LE(buf + actual_offset + 8, &start_offset);
      if (start_offset + length > SIZE_MAX) return -6;
      if (start_offset + length > buf_size) return -7;
      *output = buf + start_offset;
      *output_size = (size_t)length;
    }
  }

  return 0;
}


static QSTRUCT_INLINE int qstruct_get_raw_bytes(char *buf, size_t buf_size, uint32_t body_index, uint32_t byte_offset, size_t length, char **output, size_t *output_size) {
  QSTRUCT_GETTER_PREAMBLE(length)

  if (exceeds_bounds) {
    *output = 0; // default value
    *output_size = 0;
  } else {
    *output = buf + actual_offset;
    *output_size = length;
  }

  return 0;
}


#endif
