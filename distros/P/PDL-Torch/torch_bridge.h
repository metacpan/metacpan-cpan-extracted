#ifndef PDL_TORCH_BRIDGE_H
#define PDL_TORCH_BRIDGE_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Dtype enum matching PDL/Torch scalar types */
typedef enum {
    PDL_TORCH_UINT8   = 0,
    PDL_TORCH_INT8    = 1,
    PDL_TORCH_INT16   = 2,
    PDL_TORCH_INT32   = 3,
    PDL_TORCH_INT64   = 4,
    PDL_TORCH_FLOAT32 = 5,
    PDL_TORCH_FLOAT64 = 6,
    PDL_TORCH_CFLOAT  = 7,
    PDL_TORCH_CDOUBLE = 8
} PdlTorchDtype;

typedef struct PdlTorchTensor PdlTorchTensor;

const char* pdl_torch_last_error(void);
int         pdl_torch_cuda_is_available(void);

PdlTorchTensor* pdl_torch_from_buffer(
    const void*   data,
    int           dtype,
    const int64_t* dims,
    int           ndims,
    const char*   device
);

void pdl_torch_free(PdlTorchTensor* t);

int         pdl_torch_dtype(const PdlTorchTensor* t);
int         pdl_torch_ndims(const PdlTorchTensor* t);
int64_t     pdl_torch_dim(const PdlTorchTensor* t, int axis);
int64_t     pdl_torch_numel(const PdlTorchTensor* t);
const char* pdl_torch_device(const PdlTorchTensor* t);

int pdl_torch_to_cpu_buffer(const PdlTorchTensor* t, void* dst, size_t nbytes);

PdlTorchTensor* pdl_torch_to_device(const PdlTorchTensor* t, const char* device);
PdlTorchTensor* pdl_torch_add(const PdlTorchTensor* a, const PdlTorchTensor* b);
PdlTorchTensor* pdl_torch_sub(const PdlTorchTensor* a, const PdlTorchTensor* b);
PdlTorchTensor* pdl_torch_mul(const PdlTorchTensor* a, const PdlTorchTensor* b);
PdlTorchTensor* pdl_torch_div(const PdlTorchTensor* a, const PdlTorchTensor* b);
PdlTorchTensor* pdl_torch_matmul(const PdlTorchTensor* a, const PdlTorchTensor* b);
PdlTorchTensor* pdl_torch_sum(const PdlTorchTensor* t);
PdlTorchTensor* pdl_torch_mean(const PdlTorchTensor* t);

#ifdef __cplusplus
}
#endif

#endif /* PDL_TORCH_BRIDGE_H */
