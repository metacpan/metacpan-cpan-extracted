#include "torch_bridge.h"

#include <torch/torch.h>

#include <cstring>
#include <exception>
#include <string>
#include <vector>

struct PdlTorchTensor {
    torch::Tensor tensor;
    std::string   device_str;
};

static thread_local std::string g_last_error;

static void set_error(const std::string& msg) {
    g_last_error = msg;
}

extern "C" const char* pdl_torch_last_error(void) {
    return g_last_error.c_str();
}

extern "C" int pdl_torch_cuda_is_available(void) {
    try {
        return torch::cuda::is_available() ? 1 : 0;
    } catch (const std::exception& e) {
        set_error(e.what());
        return 0;
    }
}

static torch::ScalarType to_torch_dtype(int dtype) {
    switch (dtype) {
        case PDL_TORCH_UINT8:   return torch::kUInt8;
        case PDL_TORCH_INT8:    return torch::kInt8;
        case PDL_TORCH_INT16:   return torch::kInt16;
        case PDL_TORCH_INT32:   return torch::kInt32;
        case PDL_TORCH_INT64:   return torch::kInt64;
        case PDL_TORCH_FLOAT32: return torch::kFloat32;
        case PDL_TORCH_FLOAT64: return torch::kFloat64;
        case PDL_TORCH_CFLOAT:  return torch::kComplexFloat;
        case PDL_TORCH_CDOUBLE: return torch::kComplexDouble;
        default:                return torch::kFloat64;
    }
}

static int from_torch_dtype(torch::ScalarType st) {
    switch (st) {
        case torch::kUInt8:          return PDL_TORCH_UINT8;
        case torch::kInt8:           return PDL_TORCH_INT8;
        case torch::kInt16:          return PDL_TORCH_INT16;
        case torch::kInt32:          return PDL_TORCH_INT32;
        case torch::kInt64:          return PDL_TORCH_INT64;
        case torch::kFloat32:        return PDL_TORCH_FLOAT32;
        case torch::kFloat64:        return PDL_TORCH_FLOAT64;
        case torch::kComplexFloat:   return PDL_TORCH_CFLOAT;
        case torch::kComplexDouble:  return PDL_TORCH_CDOUBLE;
        default:                     return -1;
    }
}

static PdlTorchTensor* wrap_tensor(torch::Tensor t) {
    auto* out = new PdlTorchTensor();
    out->tensor     = std::move(t);
    out->device_str = out->tensor.device().str();
    return out;
}

extern "C" PdlTorchTensor* pdl_torch_from_buffer(
    const void*    data,
    int            dtype,
    const int64_t* dims,
    int            ndims,
    const char*    device
) {
    try {
        std::vector<int64_t> sizes(ndims);
        for (int i = 0; i < ndims; ++i) {
            sizes[i] = dims[i];
        }
        auto opts = torch::TensorOptions().dtype(to_torch_dtype(dtype)).device(torch::kCPU);
        /* Clone so the tensor owns its memory independently of the Perl SV lifecycle */
        torch::Tensor t = torch::from_blob(const_cast<void*>(data), sizes, opts).clone();
        if (device && device[0] != '\0' && std::strcmp(device, "cpu") != 0) {
            t = t.to(torch::Device(device));
        }
        return wrap_tensor(std::move(t));
    } catch (const std::exception& e) {
        set_error(e.what());
        return nullptr;
    }
}

extern "C" void pdl_torch_free(PdlTorchTensor* t) {
    delete t;
}

extern "C" int pdl_torch_dtype(const PdlTorchTensor* t) {
    if (!t) return -1;
    return from_torch_dtype(t->tensor.scalar_type());
}

extern "C" int pdl_torch_ndims(const PdlTorchTensor* t) {
    if (!t) return 0;
    return static_cast<int>(t->tensor.dim());
}

extern "C" int64_t pdl_torch_dim(const PdlTorchTensor* t, int axis) {
    if (!t || axis < 0 || axis >= t->tensor.dim()) return 0;
    return t->tensor.size(axis);
}

extern "C" int64_t pdl_torch_numel(const PdlTorchTensor* t) {
    if (!t) return 0;
    return t->tensor.numel();
}

extern "C" const char* pdl_torch_device(const PdlTorchTensor* t) {
    if (!t) return "cpu";
    return t->device_str.c_str();
}

extern "C" int pdl_torch_to_cpu_buffer(const PdlTorchTensor* t, void* dst, size_t nbytes) {
    try {
        if (!t || !dst) {
            set_error("Null tensor or destination buffer");
            return 0;
        }
        torch::Tensor cpu_t = t->tensor.to(torch::kCPU).contiguous();
        size_t actual = static_cast<size_t>(cpu_t.nbytes());
        if (actual > nbytes) {
            set_error("Destination buffer too small for tensor");
            return 0;
        }
        if (actual > 0) {
            std::memcpy(dst, cpu_t.data_ptr(), actual);
        }
        return 1;
    } catch (const std::exception& e) {
        set_error(e.what());
        return 0;
    }
}

extern "C" PdlTorchTensor* pdl_torch_to_device(const PdlTorchTensor* t, const char* device) {
    try {
        return wrap_tensor(t->tensor.to(torch::Device(device ? device : "cpu")));
    } catch (const std::exception& e) {
        set_error(e.what());
        return nullptr;
    }
}

extern "C" PdlTorchTensor* pdl_torch_add(const PdlTorchTensor* a, const PdlTorchTensor* b) {
    try {
        return wrap_tensor(torch::add(a->tensor, b->tensor));
    } catch (const std::exception& e) {
        set_error(e.what());
        return nullptr;
    }
}

extern "C" PdlTorchTensor* pdl_torch_sub(const PdlTorchTensor* a, const PdlTorchTensor* b) {
    try {
        return wrap_tensor(torch::sub(a->tensor, b->tensor));
    } catch (const std::exception& e) {
        set_error(e.what());
        return nullptr;
    }
}

extern "C" PdlTorchTensor* pdl_torch_mul(const PdlTorchTensor* a, const PdlTorchTensor* b) {
    try {
        return wrap_tensor(torch::mul(a->tensor, b->tensor));
    } catch (const std::exception& e) {
        set_error(e.what());
        return nullptr;
    }
}

extern "C" PdlTorchTensor* pdl_torch_div(const PdlTorchTensor* a, const PdlTorchTensor* b) {
    try {
        return wrap_tensor(torch::div(a->tensor, b->tensor));
    } catch (const std::exception& e) {
        set_error(e.what());
        return nullptr;
    }
}

extern "C" PdlTorchTensor* pdl_torch_matmul(const PdlTorchTensor* a, const PdlTorchTensor* b) {
    try {
        return wrap_tensor(torch::matmul(a->tensor, b->tensor));
    } catch (const std::exception& e) {
        set_error(e.what());
        return nullptr;
    }
}

extern "C" PdlTorchTensor* pdl_torch_sum(const PdlTorchTensor* t) {
    try {
        return wrap_tensor(t->tensor.sum());
    } catch (const std::exception& e) {
        set_error(e.what());
        return nullptr;
    }
}

extern "C" PdlTorchTensor* pdl_torch_mean(const PdlTorchTensor* t) {
    try {
        return wrap_tensor(t->tensor.to(torch::kFloat64).mean());
    } catch (const std::exception& e) {
        set_error(e.what());
        return nullptr;
    }
}
