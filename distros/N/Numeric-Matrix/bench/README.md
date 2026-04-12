# Numeric::Matrix Benchmarks

Comparing XS (with BLAS/SIMD) vs Pure Perl implementations.

## Running

```bash
cd /Users/lnation/Semantic/Numeric-Matrix
perl -I$PWD/blib/lib -I$PWD/blib/arch bench/matmul.pl
perl -I$PWD/blib/lib -I$PWD/blib/arch bench/elementwise.pl
perl -I$PWD/blib/lib -I$PWD/blib/arch bench/softmax.pl
perl -I$PWD/blib/lib -I$PWD/blib/arch bench/customops.pl
```

## Results Summary (Apple M1)

### Matrix Multiplication (BLAS cblas_dgemm)

| Size | XS speedup |
|------|------------|
| 32x32 | ~1,150x |
| 64x64 | ~4,100x |
| 128x128 | ~6,400x |
| 256x256 | ~8,600x |

### Element-wise Operations (SIMD/scalar)

| Operation | 10k elements | 100k elements | 1M elements |
|-----------|--------------|---------------|-------------|
| add | 188x | 155x | 69x |
| mul | 191x | 158x | 79x |
| scale | 183x | 191x | 83x |
| exp | 23x | 24x | 20x |

### Softmax (fused max/exp/sum with vDSP)

| Size | XS speedup |
|------|------------|
| 100x64 | ~34x |
| 1000x256 | ~29x |
| 10000x1024 | ~29x |

### Custom Ops (method dispatch elimination)

| Operation | Ops/sec | Notes |
|-----------|---------|-------|
| rows | 26M | Near-zero overhead accessor |
| cols | 25M | Near-zero overhead accessor |
| sum | 3.5k | Dominated by O(n) reduction |
| matmul | 120k | Dominated by BLAS compute |

## Observations

- Matrix multiplication shows the largest gains due to BLAS (Accelerate framework on macOS)
- Element-wise operations benefit from SIMD vectorization (ARM NEON)
- Softmax uses vDSP_maxvD, vvexp, vDSP_sveD, vDSP_vsdivD from Accelerate
- Custom ops eliminate Perl method dispatch overhead via call checkers
- For cheap operations (rows/cols), custom ops provide ~100x improvement over method dispatch
- For compute-heavy operations (matmul, sum), dispatch overhead is negligible
