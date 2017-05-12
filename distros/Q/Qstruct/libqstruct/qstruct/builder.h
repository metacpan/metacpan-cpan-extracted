#ifndef _QSTRUCT_BUILDER_H
#define _QSTRUCT_BUILDER_H

#include <inttypes.h>
#include <stdint.h>
#include <stdlib.h>
#include <assert.h>

#include "qstruct/utils.h"


struct qstruct_builder {
  char *buf;
  size_t buf_size;
  size_t msg_size;
  uint32_t body_size;
  uint32_t body_count;
};

static QSTRUCT_INLINE struct qstruct_builder *qstruct_builder_new(uint64_t magic_id, uint32_t body_size, uint32_t body_count) {
  struct qstruct_builder *builder;
  uint64_t content_size64;
  size_t content_size;

  content_size64 = QSTRUCT_ALIGN_UP(body_size, QSTRUCT_BODY_SIZE_TO_ALIGNMENT(body_size)) * body_count;
  if (content_size64 > SIZE_MAX/2) return NULL;

  content_size = (size_t) content_size64;

  builder = malloc(sizeof(struct qstruct_builder));
  if (builder == NULL) return NULL;

  builder->body_size = body_size;
  builder->body_count = body_count;
  builder->msg_size = QSTRUCT_HEADER_SIZE + content_size;
  builder->buf_size = builder->msg_size + 4096;

  builder->buf = calloc(builder->buf_size, 1);

  if (builder->buf == NULL) {
    free(builder);
    return NULL;
  }

  QSTRUCT_STORE_8BYTE_LE(&magic_id, builder->buf);
  QSTRUCT_STORE_4BYTE_LE(&body_size, builder->buf + 8);
  QSTRUCT_STORE_4BYTE_LE(&body_count, builder->buf + 12);

  return builder;
}

static QSTRUCT_INLINE void qstruct_builder_free(struct qstruct_builder *builder) {
  if (builder->buf) free(builder->buf);
  free(builder);
}

static QSTRUCT_INLINE size_t qstruct_builder_get_msg_size(struct qstruct_builder *builder) {
  return builder->msg_size;
}

static QSTRUCT_INLINE char *qstruct_builder_get_buf(struct qstruct_builder *builder) {
  return builder->buf;
}

static QSTRUCT_INLINE char *qstruct_builder_steal_buf(struct qstruct_builder *builder) {
  char *buf;

  buf = builder->buf;
  builder->buf = NULL;

  return buf;
}

static QSTRUCT_INLINE int qstruct_builder_expand_msg(struct qstruct_builder *builder, size_t new_buf_size) {
  char *new_buf;

  if (new_buf_size > builder->buf_size) {
    new_buf = realloc(builder->buf, new_buf_size);
    if (new_buf == NULL) return -1;

    builder->buf = new_buf;
    new_buf = NULL;

    memset(builder->buf + builder->buf_size, '\0', new_buf_size - builder->buf_size);
    builder->buf_size = new_buf_size;
  }

  if (new_buf_size > builder->msg_size) builder->msg_size = new_buf_size;

  return 0;
}



#define QSTRUCT_BUILDER_SETTER_PREAMBLE(size_of_val) \
  uint32_t actual_offset = QSTRUCT_HEADER_SIZE + (QSTRUCT_ALIGN_UP(builder->body_size, QSTRUCT_BODY_SIZE_TO_ALIGNMENT(builder->body_size)) * body_index) + byte_offset; \
  if (actual_offset + (size_of_val) > builder->msg_size) return -1; \
  if (body_index >= builder->body_count) return -2;



static QSTRUCT_INLINE int qstruct_builder_set_uint64(struct qstruct_builder *builder, uint32_t body_index, uint32_t byte_offset, uint64_t value) {
  QSTRUCT_BUILDER_SETTER_PREAMBLE(8)

  QSTRUCT_STORE_8BYTE_LE(&value, builder->buf + actual_offset);

  return 0;
}

static QSTRUCT_INLINE int qstruct_builder_set_uint32(struct qstruct_builder *builder, uint32_t body_index, uint32_t byte_offset, uint32_t value) {
  QSTRUCT_BUILDER_SETTER_PREAMBLE(4)

  QSTRUCT_STORE_4BYTE_LE(&value, builder->buf + actual_offset);

  return 0;
}

static QSTRUCT_INLINE int qstruct_builder_set_uint16(struct qstruct_builder *builder, uint32_t body_index, uint32_t byte_offset, uint16_t value) {
  QSTRUCT_BUILDER_SETTER_PREAMBLE(2)

  QSTRUCT_STORE_2BYTE_LE(&value, builder->buf + actual_offset);

  return 0;
}

static QSTRUCT_INLINE int qstruct_builder_set_uint8(struct qstruct_builder *builder, uint32_t body_index, uint32_t byte_offset, uint8_t value) {
  QSTRUCT_BUILDER_SETTER_PREAMBLE(1)

  *((char*)(builder->buf + actual_offset)) = *((char*)&value);

  return 0;
}

static QSTRUCT_INLINE int qstruct_builder_set_bool(struct qstruct_builder *builder, uint32_t body_index, uint32_t byte_offset, int bit_offset, int value) {
  QSTRUCT_BUILDER_SETTER_PREAMBLE(1)

  if (value) {
    *((uint8_t *)(builder->buf + actual_offset)) |= bit_offset;
  } else {
    *((uint8_t *)(builder->buf + actual_offset)) &= ~bit_offset;
  }

  return 0;
}

static QSTRUCT_INLINE int qstruct_builder_set_pointer(struct qstruct_builder *builder, uint32_t body_index, uint32_t byte_offset, char *value, size_t value_size, int alignment, size_t *output_data_start) {
  size_t data_start;
  uint64_t data_start64, value_size64;

  QSTRUCT_BUILDER_SETTER_PREAMBLE(16)

  if (alignment == 1 && value_size < 16) {
    data_start = actual_offset + 1;
    *((uint8_t *)(builder->buf + actual_offset)) = (uint8_t) value_size;
  } else {
    data_start = QSTRUCT_ALIGN_UP(builder->msg_size, alignment);
    if (qstruct_builder_expand_msg(builder, data_start + value_size)) return -4;
    data_start64 = (uint64_t)data_start;
    value_size64 = (uint64_t)value_size << 8;
    QSTRUCT_STORE_8BYTE_LE(&value_size64, builder->buf + actual_offset);
    QSTRUCT_STORE_8BYTE_LE(&data_start64, builder->buf + actual_offset + 8);
  }

  if (value) memcpy(builder->buf + data_start, value, value_size);
  if (output_data_start) *output_data_start = data_start - QSTRUCT_HEADER_SIZE;

  return 0;
}


static QSTRUCT_INLINE int qstruct_builder_set_raw_bytes(struct qstruct_builder *builder, uint32_t body_index, uint32_t byte_offset, char *value, size_t value_size) {
  QSTRUCT_BUILDER_SETTER_PREAMBLE(value_size)

  memcpy(builder->buf + actual_offset, value, value_size);

  return 0;
}

#endif
