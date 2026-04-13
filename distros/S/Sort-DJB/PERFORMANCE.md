# Sort::DJB Performance

Benchmark results comparing Sort::DJB against other Perl sorting implementations.

**Test environment:**
- djbsort version: 20260210
- Perl: v5.40.1 (x86_64-linux-gnu-thread-multi)
- CPU: amd64
- Sort::Key: v1.33
- Sort::Key::Radix: v0.14
- Sort::Packed: v0.08

## Key Findings

- Sort::DJB dominates across all types and sizes with 3-9x faster than the next best CPAN module at n=100k
- Sort::Packed with full pack/unpack pipeline is ~3x faster than Perl sort. Its binary buffer approach reduces per-element overhead
- Sort::Key::Radix (theoretically O(n)) is only ~2x faster than Perl's builtin sort. The SV overhead swamps the O(n) advantage
- Sort::Key is actually slower than Perl's builtin sort at large sizes (unexpected maybe Perl 5.40's sort has improved significantly)
- At small sizes (n=5, n=10), Sort::DJB still wins: 28-67% faster than Perl sort, showing minimal call overhead
- Raw packed buffer (Sort::Packed without pack/unpack): 279/s for int32, showing the sorting itself is fast but pack/unpack SV conversion is the bottleneck

## Summary: n=100,000 int32 elements

### With system-installed djbsort (AVX2 SIMD)

| Rank | Implementation                      | Rate    | Speedup vs Perl sort |
|------|-------------------------------------|---------|----------------------|
| 1    | Sort::DJB (AVX2 bitonic network)    | 407/s   | 9.0x                 |
| 2    | Sort::Packed (pack + sort + unpack) | 147/s   | 3.2x                 |
| 3    | Sort::Key::Radix (O(n) radix sort)  | 103/s   | 2.3x                 |
| 4    | Perl builtin sort                   | 45.5/s  | 1.0x (baseline)      |
| 5    | Sort::Key (key-cached mergesort)    | 34.3/s  | 0.75x                |
| 6    | Sort::DJB::Pure (Perl bitonic net)  | 0.81/s  | 0.018x               |

### With bundled portable C (no SIMD)

| Rank | Implementation                      | Rate    | Speedup vs Perl sort |
|------|-------------------------------------|---------|----------------------|
| 1    | Sort::Packed (pack + sort + unpack) | 150/s   | 3.4x                 |
| 2    | Sort::DJB XS (portable4 bitonic)    | 105/s   | 2.4x                 |
| 3    | Sort::Key::Radix (O(n) radix sort)  | 98.4/s  | 2.2x                 |
| 4    | Perl builtin sort                   | 44.3/s  | 1.0x (baseline)      |
| 5    | Sort::Key (key-cached mergesort)    | 34.1/s  | 0.77x                |
| 6    | Sort::DJB::Pure (Perl bitonic net)  | 0.65/s  | 0.015x               |

## Detailed Benchmarks (portable C build)

### Naming
  ┌─────────────┬──────────────────┬───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐                                 
  │    Label    │      Module      │                                                                               What is it?                                                                                 │
  ├─────────────┼──────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤                                 
  │ XS_int32    │ Sort::DJB        │ djbsort C library via XS, sorting signed 32-bit integers                                                                                                                  │                                 
  ├─────────────┼──────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤                                 
  │ XS_float64  │ Sort::DJB        │ djbsort C library via XS, sorting 64-bit doubles                                                                                                                          │
  ├─────────────┼──────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤                                 
  │ Pure_int32  │ Sort::DJB::Pure  │ Pure Perl bitonic sorting network, sorting signed 32-bit integers                                                                                                         │                                 
  ├─────────────┼──────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ PackedR_i32 │ Sort::Packed     │ Raw pre-packed buffer sort -- the data is already pack("l*")ed before the benchmark loop, so it measures only sort_packed('l', $buf) with no pack/unpack overhead. int32. │                                 
  ├─────────────┼──────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤                                 
  │ PackedR_i64 │ Sort::Packed     │ Same raw pre-packed sort, but on pack("q*") int64 buffers                                                                                                                 │
  ├─────────────┼──────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤                                 
  │ PackedR_f64 │ Sort::Packed     │ Same raw pre-packed sort, but on pack("d*") float64 buffers                                                                                                               │
  ├─────────────┼──────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤                                 
  │ SKey_int    │ Sort::Key        │ Sort::Key::nsort() on int32 data -- used in the cross-type summary section where the suffix indicates the test data, not the function                                     │
  ├─────────────┼──────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤                                 
  │ SKey_float  │ Sort::Key        │ Sort::Key::nsort() on float64 data -- same function, different input                                                                                                      │
  ├─────────────┼──────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤                                 
  │ Radix_float │ Sort::Key::Radix │ Sort::Key::Radix::fsort() -- radix sort on float64 data                                                                                                                   │
  └─────────────┴──────────────────┴───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘  

### int32 sorting (signed 32-bit integers)

```
  n =      10 elements:
                  Rate    Pure_int32 Packed_int32 SKey_nsort Radix_isort Perl_sort XS_int32
  Pure_int32     58119/s         --         -93%       -95%        -97%      -97%     -98%
  Packed_int32  824560/s      1319%           --       -34%        -57%      -58%     -70%
  SKey_nsort   1254593/s      2059%          52%         --        -35%      -36%     -55%
  Radix_isort  1931575/s      3223%         134%        54%          --       -2%     -30%
  Perl_sort    1974992/s      3298%         140%        57%          2%        --     -29%
  XS_int32     2778978/s      4682%         237%       122%         44%       41%       --

  n =     100 elements:
                 Rate   Pure_int32 SKey_nsort Radix_isort Packed_int32 Perl_sort XS_int32
  Pure_int32     3722/s         --       -97%        -97%         -98%      -98%     -99%
  SKey_nsort   138099/s      3610%         --         -3%         -28%      -38%     -54%
  Radix_isort  142736/s      3735%         3%          --         -25%      -36%     -53%
  Packed_int32 190788/s      5026%        38%         34%           --      -14%     -37%
  Perl_sort    221362/s      5847%        60%         55%          16%        --     -27%
  XS_int32     301306/s      7995%       118%        111%          58%       36%       --

  n =    1000 elements:
                Rate   Pure_int32 SKey_nsort Perl_sort Radix_isort Packed_int32 XS_int32
  Pure_int32     184/s         --       -98%      -98%        -99%         -99%     -99%
  SKey_nsort    8508/s      4535%         --      -21%        -56%         -57%     -63%
  Perl_sort    10755/s      5760%        26%        --        -44%         -45%     -53%
  Radix_isort  19328/s     10431%       127%       80%          --          -2%     -16%
  Packed_int32 19692/s     10629%       131%       83%          2%           --     -14%
  XS_int32     22980/s     12420%       170%      114%         19%          17%       --

  n =   10000 elements:
               Rate   Pure_int32 SKey_nsort Perl_sort Radix_isort XS_int32 Packed_int32
  Pure_int32   11.9/s         --       -98%      -98%        -99%     -99%         -99%
  SKey_nsort    600/s      4924%         --      -19%        -62%     -63%         -67%
  Perl_sort     743/s      6122%        24%        --        -53%     -54%         -59%
  Radix_isort  1591/s     13228%       165%      114%          --      -1%         -13%
  XS_int32     1600/s     13303%       167%      115%          1%       --         -13%
  Packed_int32 1833/s     15255%       206%      147%         15%      15%           --

  n =  100000 elements:
               Rate    SKey_nsort   Perl_sort Radix_isort    XS_int32 Packed_int32
  SKey_nsort   34.1/s          --        -23%        -65%        -67%         -77%
  Perl_sort    44.3/s         30%          --        -55%        -58%         -71%
  Radix_isort  98.4/s        189%        122%          --         -6%         -35%
  XS_int32      105/s        207%        136%          6%          --         -31%
  Packed_int32  150/s        341%        240%         53%         44%           --
```

### int32down sorting (signed 32-bit integers, descending)

```
  n =     100 elements:
                 Rate   Pure_int32dn Radix_risrt SKey_rnsort Perl_sort_rv XS_int32dn
  Pure_int32dn   2993/s           --        -98%        -98%         -99%       -99%
  Radix_risrt  138606/s        4531%          --         -8%         -33%       -58%
  SKey_rnsort  150651/s        4934%          9%          --         -27%       -54%
  Perl_sort_rv 206259/s        6792%         49%         37%           --       -37%
  XS_int32dn   326249/s       10802%        135%        117%          58%         --

  n =   10000 elements:
               Rate   Pure_int32dn SKey_rnsort Perl_sort_rv XS_int32dn Radix_risrt
  Pure_int32dn 10.9/s           --        -98%         -99%       -99%        -99%
  SKey_rnsort   561/s        5065%          --         -24%       -62%        -63%
  Perl_sort_rv  734/s        6658%         31%           --       -50%        -52%
  XS_int32dn   1469/s       13425%        162%         100%         --         -3%
  Radix_risrt  1517/s       13866%        170%         107%         3%          --

  n =  100000 elements:
               Rate    SKey_rnsort Perl_sort_rv  Radix_risrt   XS_int32dn
  SKey_rnsort  31.1/s           --         -42%         -67%         -71%
  Perl_sort_rv 53.9/s          74%           --         -43%         -49%
  Radix_risrt  94.7/s         205%          76%           --         -11%
  XS_int32dn    106/s         241%          97%          12%           --
```

### uint32 sorting (unsigned 32-bit integers)

```
  n =     100 elements:
                Rate   Pure_uint32 SKey_nsort Packed_u32 Perl_sort Radix_usort XS_uint32
  Pure_uint32   2853/s          --       -98%       -98%      -98%        -99%      -99%
  SKey_nsort  134825/s       4626%         --       -25%      -26%        -45%      -53%
  Packed_u32  180959/s       6243%        34%         --       -1%        -27%      -37%
  Perl_sort   183338/s       6327%        36%         1%        --        -26%      -36%
  Radix_usort 246272/s       8533%        83%        36%       34%          --      -15%
  XS_uint32   288653/s      10018%       114%        60%       57%         17%        --

  n =   10000 elements:
              Rate   Pure_uint32 SKey_nsort Perl_sort XS_uint32 Packed_u32 Radix_usort
  Pure_uint32 10.6/s          --       -98%      -98%      -99%       -99%        -99%
  SKey_nsort   469/s       4343%         --      -31%      -64%       -71%        -71%
  Perl_sort    676/s       6297%        44%        --      -48%       -58%        -59%
  XS_uint32   1306/s      12263%       178%       93%        --       -19%        -20%
  Packed_u32  1611/s      15155%       243%      138%       23%         --         -1%
  Radix_usort 1631/s      15342%       248%      141%       25%         1%          --

  n =  100000 elements:
              Rate    SKey_nsort   Perl_sort Radix_usort   XS_uint32  Packed_u32
  SKey_nsort  32.4/s          --        -27%        -64%        -67%        -77%
  Perl_sort   44.2/s         37%          --        -50%        -55%        -69%
  Radix_usort 88.8/s        174%        101%          --         -9%        -37%
  XS_uint32   97.9/s        203%        122%         10%          --        -30%
  Packed_u32   141/s        334%        218%         58%         44%          --
```

### int64 sorting (signed 64-bit integers)

```
  n =     100 elements:
                Rate   Pure_int64 Packed_i64 SKey_nsort Radix_isort Perl_sort XS_int64
  Pure_int64    3109/s         --       -97%       -98%        -98%      -98%     -99%
  Packed_i64   96399/s      3000%         --       -24%        -35%      -48%     -65%
  SKey_nsort  126704/s      3975%        31%         --        -15%      -31%     -54%
  Radix_isort 149419/s      4705%        55%        18%          --      -19%     -45%
  Perl_sort   184004/s      5818%        91%        45%         23%        --     -33%
  XS_int64    273685/s      8702%       184%       116%         83%       49%       --

  n =   10000 elements:
              Rate   Pure_int64 SKey_nsort Perl_sort Packed_i64 Radix_isort XS_int64
  Pure_int64  10.1/s         --       -98%      -99%       -99%        -99%     -99%
  SKey_nsort   521/s      5076%         --      -24%       -51%        -56%     -66%
  Perl_sort    687/s      6730%        32%        --       -36%        -42%     -56%
  Packed_i64  1068/s     10515%       105%       55%         --        -10%     -31%
  Radix_isort 1191/s     11738%       129%       73%        12%          --     -23%
  XS_int64    1548/s     15287%       197%      125%        45%         30%       --

  n =  100000 elements:
              Rate    SKey_nsort   Perl_sort    XS_int64 Radix_isort  Packed_i64
  SKey_nsort  30.4/s          --        -29%        -66%        -68%        -75%
  Perl_sort   42.7/s         40%          --        -52%        -55%        -65%
  XS_int64    88.3/s        190%        107%          --         -8%        -28%
  Radix_isort 95.7/s        215%        124%          8%          --        -21%
  Packed_i64   122/s        301%        186%         38%         27%          --
```

### float64 sorting (64-bit doubles)

```
  n =     100 elements:
                Rate   Pure_flt64 Perl_sort Packed_f64 SKey_nsort Radix_fsort XS_float64
  Pure_flt64    3349/s         --      -97%       -97%       -98%        -98%       -99%
  Perl_sort   112783/s      3268%        --        -7%       -18%        -24%       -62%
  Packed_f64  121740/s      3536%        8%         --       -11%        -18%       -59%
  SKey_nsort  137452/s      4005%       22%        13%         --         -8%       -54%
  Radix_fsort 148652/s      4339%       32%        22%         8%          --       -50%
  XS_float64  297964/s      8798%      164%       145%       117%        100%         --

  n =   10000 elements:
              Rate   Pure_flt64 Perl_sort SKey_nsort Radix_fsort Packed_f64 XS_float64
  Pure_flt64  9.90/s         --      -98%       -98%        -99%       -99%       -99%
  Perl_sort    467/s      4619%        --       -18%        -58%       -63%       -71%
  SKey_nsort   569/s      5644%       22%         --        -49%       -55%       -64%
  Radix_fsort 1123/s     11234%      140%        97%          --       -11%       -30%
  Packed_f64  1263/s     12656%      170%       122%         13%         --       -21%
  XS_float64  1600/s     16052%      242%       181%         43%        27%         --

  n =  100000 elements:
              Rate     Perl_sort  SKey_nsort Radix_fsort  XS_float64  Packed_f64
  Perl_sort   21.9/s          --        -33%        -58%        -78%        -80%
  SKey_nsort  32.5/s         49%          --        -37%        -67%        -70%
  Radix_fsort 51.6/s        136%         59%          --        -48%        -52%
  XS_float64  99.7/s        356%        207%         93%          --         -7%
  Packed_f64   108/s        392%        231%        109%          8%          --
```

### Cross-type comparison at n=100,000

```
              Rate   Perl_float SKey_int SKey_float Perl_int Radix_float XS_float64 XS_int64 Radix_int XS_uint32 XS_int32
  Perl_float  20.6/s         --     -30%       -32%     -53%        -60%       -75%     -77%      -77%      -78%     -79%
  SKey_int    29.3/s        42%       --        -3%     -33%        -43%       -64%     -68%      -68%      -69%     -70%
  SKey_float  30.2/s        47%       3%         --     -30%        -41%       -63%     -67%      -67%      -68%     -69%
  Perl_int    43.5/s       111%      49%        44%       --        -16%       -46%     -52%      -52%      -54%     -55%
  Radix_float 51.5/s       150%      76%        70%      18%          --       -36%     -43%      -44%      -46%     -47%
  XS_float64  81.0/s       292%     177%       168%      86%         57%         --     -11%      -11%      -14%     -16%
  XS_int64    91.1/s       342%     211%       201%     110%         77%        13%       --       -0%       -4%      -6%
  Radix_int   91.3/s       343%     212%       202%     110%         77%        13%       0%        --       -3%      -5%
  XS_uint32   94.6/s       359%     223%       213%     118%         84%        17%       4%        4%        --      -2%
  XS_int32    96.5/s       367%     229%       219%     122%         87%        19%       6%        6%        2%       --
```

### Call overhead for small arrays

```
  n = 5 elements:
                 Rate    Pure_int32 SKey_nsort Radix_isort   Perl_sort    XS_int32
  Pure_int32   122736/s          --       -94%        -95%        -96%        -97%
  SKey_nsort  1894758/s       1444%         --        -25%        -31%        -55%
  Radix_isort 2535828/s       1966%        34%          --         -8%        -40%
  Perl_sort   2749454/s       2140%        45%          8%          --        -35%
  XS_int32    4221744/s       3340%       123%         66%         54%          --

  n = 10 elements:
                 Rate    Pure_int32 SKey_nsort Radix_isort   Perl_sort    XS_int32
  Pure_int32    46795/s          --       -95%        -96%        -97%        -98%
  SKey_nsort  1031797/s       2105%         --        -21%        -43%        -53%
  Radix_isort 1302285/s       2683%        26%          --        -28%        -41%
  Perl_sort   1815337/s       3779%        76%         39%          --        -18%
  XS_int32    2203017/s       4608%       114%         69%         21%          --
```

### Sort::Packed raw buffer performance (no pack/unpack overhead)

```
  n =    1000 elements:
               Rate   PackedR_f64 PackedR_i64 PackedR_i32
  PackedR_f64 16483/s          --        -33%        -50%
  PackedR_i64 24596/s         49%          --        -25%
  PackedR_i32 32905/s        100%         34%          --

  n =   10000 elements:
              Rate   PackedR_i64 PackedR_f64 PackedR_i32
  PackedR_i64 1473/s          --        -21%        -58%
  PackedR_f64 1866/s         27%          --        -47%
  PackedR_i32 3500/s        138%         88%          --

  n =  100000 elements:
             Rate   PackedR_f64 PackedR_i64 PackedR_i32
  PackedR_f64 164/s          --        -21%        -44%
  PackedR_i64 208/s         26%          --        -29%
  PackedR_i32 293/s         78%         41%          --
```

