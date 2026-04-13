# Sort::DJB

Perl XS bindings for Daniel J. Bernstein's [djbsort](https://sorting.cr.yp.to/) 
library. A fast, constant-time sorting using bitonic sorting networks.

## Features

- **12 sort functions** covering int32, uint32, int64, uint64, float32, float64
  in both ascending and descending order
- **Self-contained** - bundles the portable djbsort C implementation; no 
  external library required
- **Architecture-aware crypto primitives** - bundled headers include inline 
  assembly for x86_64, aarch64, arm, and sparc with portable C fallback
- **Constant-time** - data-independent execution flow; suitable for 
  cryptographic applications where timing side-channels must be avoided
- **Pure Perl fallback** - `Sort::DJB::Pure` implements the same bitonic 
  sorting network algorithm entirely in Perl. 
  But is actually slower than Perl's builtin sort.

## Installation

```bash
tar xzf Sort-DJB-0.2.tar.gz
cd Sort-DJB-0.2
perl Makefile.PL
make
make test
make install
```

Or with cpanm:

```bash
cpanm Sort-DJB-0.2.tar.gz
```

## Usage

```perl
use Sort::DJB qw(:all);

# Sort signed 32-bit integers
my $sorted = sort_int32([5, 3, 1, 4, 2]);
# => [1, 2, 3, 4, 5]

# Sort descending
my $desc = sort_int32down([5, 3, 1, 4, 2]);
# => [5, 4, 3, 2, 1]

# Doubles
my $floats = sort_float64([3.14, 1.41, 2.72, 0.58]);
# => [0.58, 1.41, 2.72, 3.14]

# Metadata
print Sort::DJB::version();              # "20260210"
print Sort::DJB::arch();                 # "portable"
print Sort::DJB::int32_implementation(); # "portable4"
```

### Available Functions

All functions take an array reference and return a new sorted array reference.

| Function           | Data Type        | Direction  |
|--------------------|------------------|------------|
| `sort_int32`       | signed 32-bit    | ascending  |
| `sort_int32down`   | signed 32-bit    | descending |
| `sort_uint32`      | unsigned 32-bit  | ascending  |
| `sort_uint32down`  | unsigned 32-bit  | descending |
| `sort_int64`       | signed 64-bit    | ascending  |
| `sort_int64down`   | signed 64-bit    | descending |
| `sort_uint64`      | unsigned 64-bit  | ascending  |
| `sort_uint64down`  | unsigned 64-bit  | descending |
| `sort_float32`     | 32-bit float     | ascending  |
| `sort_float32down` | 32-bit float     | descending |
| `sort_float64`     | 64-bit double    | ascending  |
| `sort_float64down` | 64-bit double    | descending |

### Export Tags

```perl
use Sort::DJB qw(:all);      # everything
use Sort::DJB qw(:int32);    # sort_int32, sort_int32down
use Sort::DJB qw(:float64);  # sort_float64, sort_float64down
```

### Pure Perl

```perl
use Sort::DJB::Pure;

my $sorted = Sort::DJB::Pure::sort_int32([5, 3, 1, 4, 2]);
```

Same algorithm, no C compiler needed. Useful for portability and educational purposes.

## Performance

Summary at n=100,000 int32 elements (with system-installed djbsort AVX2):

| Rank | Implementation                      | Rate    | vs Perl sort |
|------|-------------------------------------|---------|--------------|
| 1    | Sort::DJB XS (AVX2 bitonic)         | 407/s   | 9.0x faster  |
| 2    | Sort::Packed (pack+sort+unpack)     | 147/s   | 3.2x faster  |
| 3    | Sort::Key::Radix (O(n) radix)       | 103/s   | 2.3x faster  |
| 4    | Perl builtin sort                   | 45.5/s  | baseline     |
| 5    | Sort::Key (key-cached mergesort)    | 34.3/s  | 0.75x        |
| 6    | Sort::DJB::Pure (Perl bitonic)      | 0.81/s  | 0.018x       |

The bundled portable C build (without SIMD) is still 2-3x faster than Perl's
builtin sort. Link against a system-installed djbsort with AVX2 for 9x speedup.

See [PERFORMANCE.md](PERFORMANCE.md) for full benchmark results across all data
types and array sizes.

## Algorithm

djbsort uses **bitonic sorting networks** -- a comparison-based sorting approach
where the sequence of comparisons is fixed regardless of input data. This makes
it:

- **Branch-free** -- no data-dependent branches, enabling SIMD vectorization
- **Constant-time** -- execution time depends only on array size, not content
- **Parallelizable** -- independent comparisons can execute simultaneously

The algorithm has O(n log^2 n) comparisons (vs O(n log n) for quicksort/mergesort),
but the SIMD implementation processes 8 int32s or 4 int64s per instruction,
more than compensating for the extra comparisons.

## Project Structure

```
Sort-DJB-0.2/
  Makefile.PL              Build system
  DJB.xs                   XS bindings (C/Perl bridge)
  lib/Sort/DJB.pm          Main module
  lib/Sort/DJB/Pure.pm     Pure Perl implementation
  djbsort_src/             Bundled djbsort C sources
    djbsort.h              Public API header
    crypto_int{32,64}.h    Constant-time integer primitives
    int32_sort.c           Core int32 bitonic sort (portable)
    int64_sort.c           Core int64 bitonic sort (portable)
    *_sort.c               Type conversion wrappers
    djbsort_dispatch.c     Public symbol dispatch layer
  t/01_basic.t             Test suite (75 tests)
  bench/benchmark.pl       Benchmark vs CPAN sorting modules
  PERFORMANCE.md           Detailed benchmark results
```

## Requirements

- Perl 5.10 or later
- C compiler (gcc, clang)
- No external libraries required

## License

See [LICENSE](LICENSE) for details.

![License](https://img.shields.io/github/license/hackman/Sort-DJB)


## License

GPLv2

## Links

- repo: https://github.com/hackman/Sort-DJB/
- djbsort homepage: https://sorting.cr.yp.to/
- djbsort source: https://sorting.cr.yp.to/software.html
