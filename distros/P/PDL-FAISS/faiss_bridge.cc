#include "faiss_bridge.h"

#include <faiss/IndexFlat.h>

#include <exception>
#include <memory>
#include <string>

struct PdlFaissIndex {
    std::unique_ptr<faiss::Index> index;
};

static thread_local std::string g_last_error;

extern "C" const char* pdl_faiss_last_error(void) {
    return g_last_error.c_str();
}

extern "C" PdlFaissIndex* pdl_faiss_new_flat_l2(int dim) {
    try {
        auto* out = new PdlFaissIndex();
        out->index = std::make_unique<faiss::IndexFlatL2>(dim);
        return out;
    } catch (const std::exception& e) {
        g_last_error = e.what();
        return nullptr;
    }
}

extern "C" PdlFaissIndex* pdl_faiss_new_flat_ip(int dim) {
    try {
        auto* out = new PdlFaissIndex();
        out->index = std::make_unique<faiss::IndexFlatIP>(dim);
        return out;
    } catch (const std::exception& e) {
        g_last_error = e.what();
        return nullptr;
    }
}

extern "C" void pdl_faiss_free(PdlFaissIndex* idx) {
    delete idx;
}

extern "C" int pdl_faiss_dim(const PdlFaissIndex* idx) {
    return (idx && idx->index) ? idx->index->d : 0;
}

extern "C" int64_t pdl_faiss_ntotal(const PdlFaissIndex* idx) {
    return (idx && idx->index) ? static_cast<int64_t>(idx->index->ntotal) : 0;
}

extern "C" int pdl_faiss_add(PdlFaissIndex* idx, int64_t n, const float* x) {
    try {
        idx->index->add(static_cast<faiss::idx_t>(n), x);
        return 1;
    } catch (const std::exception& e) {
        g_last_error = e.what();
        return 0;
    }
}

extern "C" int pdl_faiss_search(
    const PdlFaissIndex* idx,
    int64_t              nq,
    const float*         xq,
    int                  k,
    float*               distances,
    int64_t*             labels
) {
    try {
        idx->index->search(
            static_cast<faiss::idx_t>(nq),
            xq,
            static_cast<faiss::idx_t>(k),
            distances,
            reinterpret_cast<faiss::idx_t*>(labels)
        );
        return 1;
    } catch (const std::exception& e) {
        g_last_error = e.what();
        return 0;
    }
}
