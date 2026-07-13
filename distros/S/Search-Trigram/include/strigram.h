#ifndef STRIGRAM_H
#define STRIGRAM_H

#include <stddef.h>

/* MSVC < 2010 lacks <stdint.h>; supply minimal typedefs */
#if defined(_MSC_VER) && _MSC_VER < 1600
  typedef unsigned char  uint8_t;
  typedef unsigned int   uint32_t;
#  define UINT32_MAX 0xffffffffU
#else
#  include <stdint.h>
#endif

typedef struct strigram_s strigram_t;

typedef struct {
    uint32_t    doc_id;
    float       score;
    const char *text;
    uint32_t    text_len;
} strigram_result_t;

strigram_t *strigram_new(void);
void        strigram_free(strigram_t *idx);
void        strigram_clear(strigram_t *idx);

uint32_t    strigram_add(strigram_t *idx, const char *text, uint32_t len);

void        strigram_remove(strigram_t *idx, uint32_t doc_id);
void        strigram_optimize(strigram_t *idx);

strigram_result_t *strigram_search(strigram_t *idx,
                                   const char *query, uint32_t qlen,
                                   uint32_t    limit,
                                   uint32_t   *result_count);

void strigram_results_free(strigram_result_t *results);

uint32_t strigram_doc_count(const strigram_t *idx);
uint32_t strigram_trigram_count(const strigram_t *idx);

#endif /* STRIGRAM_H */
