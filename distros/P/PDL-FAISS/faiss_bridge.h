#ifndef PDL_FAISS_BRIDGE_H
#define PDL_FAISS_BRIDGE_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct PdlFaissIndex PdlFaissIndex;

const char* pdl_faiss_last_error(void);

PdlFaissIndex* pdl_faiss_new_flat_l2(int dim);
PdlFaissIndex* pdl_faiss_new_flat_ip(int dim);
void           pdl_faiss_free(PdlFaissIndex* idx);

int     pdl_faiss_dim(const PdlFaissIndex* idx);
int64_t pdl_faiss_ntotal(const PdlFaissIndex* idx);

int pdl_faiss_add(PdlFaissIndex* idx, int64_t n, const float* x);
int pdl_faiss_search(
    const PdlFaissIndex* idx,
    int64_t              nq,
    const float*         xq,
    int                  k,
    float*               distances,
    int64_t*             labels
);

#ifdef __cplusplus
}
#endif

#endif /* PDL_FAISS_BRIDGE_H */
