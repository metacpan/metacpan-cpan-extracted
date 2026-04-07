# Performance Analysis

## Benchmark Environment

- Linux x86_64, single core
- Go 1.24.4 with gaissmai/bart v0.26.1
- Perl 5.40 with 64-bit integers
- Net::Patricia 1.24 (XS/C, libpatricia)
- Net::BART 0.01 (pure Perl)
- Net::BART::XS 0.01 (C with XS bindings, `__builtin_popcountll`/`__builtin_clzll`)
- Random IPv4 prefixes (/8../32), 50K random IP lookups per run
- Best of 3 runs reported

## Complete Comparison: Go vs Perl Implementations

### Lookup (longest-prefix match) — ops/sec

All implementations use string-based APIs (parsing included), except "Go pre-parsed"
which uses native `netip.Addr` objects with zero parsing overhead.

| Table size | Go BART (pre-parsed) | Go BART (from strings) | Net::BART::XS (C) | Net::Patricia (C) | Net::BART (Perl) |
|:----------:|---------------------:|-----------------------:|-------------------:|-------------------:|-----------------:|
| 100        |           25,653K    |              21,759K   |          3,186K    |             719K   |           310K   |
| 1K         |           50,257K    |              18,348K   |          3,047K    |             687K   |           179K   |
| 10K        |           50,972K    |               6,388K   |          2,818K    |             660K   |           149K   |
| 100K       |           15,517K    |               7,899K   |          1,992K    |             477K   |            98K   |

### Contains (any prefix matches?) — ops/sec

| Table size | Go BART (pre-parsed) | Go BART (from strings) | Net::BART::XS (C) | Net::BART (Perl) |
|:----------:|---------------------:|-----------------------:|-------------------:|-----------------:|
| 100        |           39,849K    |              22,173K   |          3,387K    |           409K   |
| 1K         |           67,333K    |              20,706K   |          3,277K    |           241K   |
| 10K        |          118,429K    |              20,652K   |          3,232K    |           248K   |
| 100K       |          132,355K    |              24,681K   |          2,878K    |           219K   |

### All Operations at 100K Prefixes — Latency

| Operation | Go (pre-parsed) | Go (from strings) | Net::BART::XS | Net::Patricia | Net::BART |
|-----------|:---------------:|:------------------:|:--------------:|:-------------:|:---------:|
| Insert    |     0.26 µs     |       0.43 µs      |     0.78 µs    |     3.1 µs    |  14.8 µs  |
| Lookup    |     0.06 µs     |       0.13 µs      |     0.50 µs    |     2.1 µs    |  10.2 µs  |
| Contains  |     0.008 µs    |       0.04 µs      |     0.35 µs    |       n/a     |   4.6 µs  |
| Get/Exact |     0.07 µs     |       0.12 µs      |     0.54 µs    |     2.6 µs    |  11.0 µs  |
| Delete    |     0.50 µs     |          —          |     1.29 µs    |     5.8 µs    |  29.3 µs  |

### Relative Speed (Lookup at 100K, all vs Go pre-parsed)

| Implementation       |  ops/sec | vs Go pre-parsed |
|----------------------|---------:|-----------------:|
| Go BART (pre-parsed) | 15,517K  |            1.0x  |
| Go BART (strings)    |  7,899K  |            0.5x  |
| Net::BART::XS        |  1,992K  |          ~0.13x  |
| Net::Patricia         |    477K  |          ~0.03x  |
| Net::BART (Perl)      |     98K  |         ~0.006x  |

## Perl Implementations Comparison

### 100 Prefixes

| Operation | Net::Patricia (C) | Net::BART (Perl) | Net::BART::XS (C) | XS vs Perl | XS vs Patricia |
|-----------|-------------------:|-----------------:|-------------------:|-----------:|---------------:|
| Insert    |         472K ops/s |       103K ops/s |        2,383K ops/s |     23.1x |          5.1x |
| Lookup    |         719K ops/s |       310K ops/s |        3,186K ops/s |     10.3x |          4.4x |
| Contains  |                n/a |       409K ops/s |        3,387K ops/s |      8.3x |            n/a |
| Get/Exact |         529K ops/s |       142K ops/s |        2,638K ops/s |     18.6x |          5.0x |
| Delete    |         242K ops/s |        47K ops/s |        1,205K ops/s |     25.4x |          5.0x |

### 1K Prefixes

| Operation | Net::Patricia (C) | Net::BART (Perl) | Net::BART::XS (C) | XS vs Perl | XS vs Patricia |
|-----------|-------------------:|-----------------:|-------------------:|-----------:|---------------:|
| Insert    |         456K ops/s |        88K ops/s |        2,150K ops/s |     24.4x |          4.7x |
| Lookup    |         687K ops/s |       179K ops/s |        3,047K ops/s |     17.0x |          4.4x |
| Contains  |                n/a |       241K ops/s |        3,277K ops/s |     13.6x |            n/a |
| Get/Exact |         507K ops/s |       124K ops/s |        2,623K ops/s |     21.2x |          5.2x |
| Delete    |         237K ops/s |        43K ops/s |        1,140K ops/s |     26.4x |          4.8x |

### 10K Prefixes

| Operation | Net::Patricia (C) | Net::BART (Perl) | Net::BART::XS (C) | XS vs Perl | XS vs Patricia |
|-----------|-------------------:|-----------------:|-------------------:|-----------:|---------------:|
| Insert    |         440K ops/s |        96K ops/s |        2,236K ops/s |     23.3x |          5.1x |
| Lookup    |         660K ops/s |       149K ops/s |        2,818K ops/s |     18.9x |          4.3x |
| Contains  |                n/a |       248K ops/s |        3,232K ops/s |     13.0x |            n/a |
| Get/Exact |         458K ops/s |       103K ops/s |        2,233K ops/s |     21.7x |          4.9x |
| Delete    |         211K ops/s |        41K ops/s |        1,097K ops/s |     26.6x |          5.2x |

### 100K Prefixes

| Operation | Net::Patricia (C) | Net::BART (Perl) | Net::BART::XS (C) | XS vs Perl | XS vs Patricia |
|-----------|-------------------:|-----------------:|-------------------:|-----------:|---------------:|
| Insert    |         318K ops/s |        68K ops/s |        1,274K ops/s |     18.9x |          4.0x |
| Lookup    |         477K ops/s |        98K ops/s |        1,992K ops/s |     20.3x |          4.2x |
| Contains  |                n/a |       218K ops/s |        2,878K ops/s |     13.2x |            n/a |
| Get/Exact |         388K ops/s |        91K ops/s |        1,865K ops/s |     20.5x |          4.8x |
| Delete    |         173K ops/s |        34K ops/s |          777K ops/s |     22.7x |          4.5x |

### Correctness

All three Perl implementations were cross-checked with 5,000 random prefixes and 10,000
random IP lookups: **10,000/10,000 results agree**.

## Why Go BART Is Faster Than Net::BART::XS

The Go implementation (gaissmai/bart) has several advantages over our C/XS port:

1. **Zero-copy IP parsing.** Go's `netip.Addr` is a value type (no heap allocation).
   Pre-parsed lookups avoid all string handling. Even with string parsing, Go's
   `netip.ParseAddr` is heavily optimized.

2. **Generics with monomorphization.** `bart.Table[int]` is specialized at compile time,
   avoiding the `void*` casts and SV* refcounting overhead required by the Perl XS layer.

3. **No refcount overhead.** Go uses garbage collection, so inserting/removing values
   doesn't require per-operation reference count maintenance.

4. **Escape analysis.** Go's compiler can stack-allocate the lookup stack and intermediate
   values, while C/XS must interact with Perl's heap-allocated SVs.

5. **`Contains` is extremely fast** in Go because it never allocates and the entire
   hot path stays in registers. At 100K prefixes, Go achieves 132M ops/sec (8ns/op)
   — this is essentially a few cache hits and branch predictions.

## Why Net::BART::XS Is Faster Than Net::Patricia

1. **Fewer memory accesses per lookup.** IPv4 traverses at most 4 nodes (one per octet)
   vs up to 32 for a patricia trie.

2. **O(1) LPM per node.** Precomputed ancestor bitsets + bitwise AND, not pointer-chasing.

3. **Hardware popcount/clz.** `POPCNT` and `LZCNT` instructions make rank/bit-find
   nearly free on modern x86.

4. **Cache-friendly layout.** Popcount-compressed sparse arrays pack data tightly.

## Net::BART (Pure Perl) Optimizations

1. **Byte lookup table for popcount** — constant-time via 256-entry table
2. **Array-based blessed objects** — `$self->[N]` vs `$self->{key}` (~30% faster)
3. **Inlined hot paths** — LPM test, child lookup bypass method dispatch
4. **Fast IPv4 parser** — `index`/`substr` instead of regex (3x faster)
5. **Non-method recursion** — plain functions avoid `$self->` dispatch
6. **Unrolled rank computation** — eliminates loop overhead

## Scaling Behavior

| Table size | Go pre-parsed | Go from strings | BART::XS | Patricia |
|------------|:-------------:|:---------------:|:--------:|:--------:|
| 100        |    25,653K/s  |      21,759K/s  |  3,186K/s|    719K/s|
| 1K         |    50,257K/s  |      18,348K/s  |  3,047K/s|    687K/s|
| 10K        |    50,972K/s  |       6,388K/s  |  2,818K/s|    660K/s|
| 100K       |    15,517K/s  |       7,899K/s  |  1,992K/s|    477K/s|

All implementations scale sub-linearly. The BART algorithm's fixed 4-level depth for
IPv4 provides excellent worst-case behavior. Net::BART::XS maintains a consistent
~4x advantage over Net::Patricia across all table sizes.
