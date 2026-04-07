# Net::BART - Balanced Routing Tables for Perl

Fast IPv4/IPv6 longest-prefix-match (LPM) routing table lookups for Perl, available in two flavors:

- **Net::BART** — pure Perl, zero dependencies
- **Net::BART::XS** — C implementation via XS, **4-5x faster than Net::Patricia**

Based on the Go implementation [gaissmai/bart](https://github.com/gaissmai/bart), which builds on Knuth's ART (Allotment Routing Tables) algorithm.

## Synopsis

```perl
# Pure Perl — works everywhere, no compiler needed
use Net::BART;
my $table = Net::BART->new;

# XS/C — same API, maximum performance
use Net::BART::XS;
my $table = Net::BART::XS->new;

# Insert prefixes with associated values
$table->insert("10.0.0.0/8",       "private-rfc1918");
$table->insert("10.1.0.0/16",      "office-network");
$table->insert("10.1.42.0/24",     "dev-team");
$table->insert("0.0.0.0/0",        "default-gw");
$table->insert("2001:db8::/32",    "documentation");

# Longest-prefix match
my ($val, $ok) = $table->lookup("10.1.42.7");
# $val = "dev-team", $ok = 1

my ($val, $ok) = $table->lookup("10.1.99.1");
# $val = "office-network", $ok = 1

# Exact match
my ($val, $ok) = $table->get("10.1.0.0/16");
# $val = "office-network", $ok = 1

# Fast containment check
$table->contains("10.1.42.7");  # 1
$table->contains("172.16.0.1"); # 1 (matches default route)

# Delete
my ($old, $ok) = $table->delete("10.1.42.0/24");
# $old = "dev-team", $ok = 1

# Walk all prefixes (Net::BART only)
$table->walk(sub {
    my ($prefix, $value) = @_;
    print "$prefix => $value\n";
});

# Counts
printf "Total: %d (IPv4: %d, IPv6: %d)\n",
    $table->size, $table->size4, $table->size6;
```

## Installation

**Net::BART** (pure Perl) requires no installation — add `lib/` to `@INC`:

```bash
perl -Ilib your_script.pl
```

**Net::BART::XS** requires a C compiler:

```bash
cd lib/Net/BART && perl Makefile.PL && make && make test
```

Then add both `lib/` and the blib paths to `@INC`:

```bash
perl -Ilib -Ilib/Net/BART/blib/arch -Ilib/Net/BART/blib/lib your_script.pl
```

Requires Perl 5.10+ with 64-bit integer support.

## API

Both `Net::BART` and `Net::BART::XS` share the same API:

| Method | Description | Returns |
|--------|-------------|---------|
| `->new` | Create empty routing table | object |
| `->insert($prefix, $val)` | Insert/update a CIDR prefix | 1 if new, 0 if updated |
| `->lookup($ip)` | Longest-prefix match | `($value, 1)` or `(undef, 0)` |
| `->contains($ip)` | Any prefix contains this IP? | 1 or 0 |
| `->get($prefix)` | Exact prefix match | `($value, 1)` or `(undef, 0)` |
| `->delete($prefix)` | Remove a prefix | `($old_value, 1)` or `(undef, 0)` |
| `->size` / `->size4` / `->size6` | Prefix count | integer |
| `->walk($cb)` | Iterate all prefixes (Net::BART only) | void |

**Prefix formats:** `"10.0.0.0/8"`, `"2001:db8::/32"`, `"0.0.0.0/0"`, `"::/0"`

**IP formats:** `"10.1.2.3"`, `"2001:db8::1"` (for lookup/contains)

## Performance

### Lookup Comparison — All Implementations (ops/sec, 100K prefixes)

Benchmarked with random IPv4 prefixes, 50K lookups per run, best of 3.
Go BART is the [reference implementation](https://github.com/gaissmai/bart) (v0.26.1).

```
  Go BART (pre-parsed)  ████████████████████████████████████████████████  15,517K   0.06 µs
  Go BART (from string) ████████████████████████                          7,899K   0.13 µs
  Net::BART::XS         ██████                                            1,992K   0.50 µs
  Net::Patricia          █▌                                                 477K   2.10 µs
  Net::BART (pure Perl)  ▎                                                   98K  10.20 µs
```

### Full Comparison at 100K Prefixes — Latency per Operation

| Operation | Go (pre-parsed) | Go (strings) | Net::BART::XS | Net::Patricia | Net::BART |
|-----------|:---------------:|:------------:|:--------------:|:-------------:|:---------:|
| Insert    |     0.26 µs     |    0.43 µs   |   **0.78 µs**  |     3.1 µs    |  14.8 µs  |
| Lookup    |     0.06 µs     |    0.13 µs   |   **0.50 µs**  |     2.1 µs    |  10.2 µs  |
| Contains  |     0.008 µs    |    0.04 µs   |   **0.35 µs**  |       n/a     |   4.6 µs  |
| Get/Exact |     0.07 µs     |    0.12 µs   |   **0.54 µs**  |     2.6 µs    |  11.0 µs  |
| Delete    |     0.50 µs     |       —      |   **1.29 µs**  |     5.8 µs    |  29.3 µs  |

### Lookup Scaling Across Table Sizes (ops/sec)

| Table size | Go (pre-parsed) | Go (strings) | Net::BART::XS | Net::Patricia | Net::BART |
|:----------:|:---------------:|:------------:|:--------------:|:-------------:|:---------:|
| 100        |       25,653K   |     21,759K  |      3,186K    |         719K  |      310K |
| 1K         |       50,257K   |     18,348K  |      3,047K    |         687K  |      179K |
| 10K        |       50,972K   |      6,388K  |      2,818K    |         660K  |      149K |
| 100K       |       15,517K   |      7,899K  |      1,992K    |         477K  |       98K |

### Perl-Only Comparison at 100K Prefixes

| Operation | Net::Patricia (C) | Net::BART (Perl) | Net::BART::XS (C) | XS vs Patricia |
|-----------|-------------------:|-----------------:|-------------------:|:--------------:|
| Insert    |         318K ops/s |        68K ops/s |      **1,274K**/s  |      4.0x      |
| Lookup    |         477K ops/s |        98K ops/s |      **1,992K**/s  |      4.2x      |
| Contains  |                n/a |       218K ops/s |      **2,878K**/s  |       n/a      |
| Get/Exact |         388K ops/s |        91K ops/s |      **1,865K**/s  |      4.8x      |
| Delete    |         173K ops/s |        34K ops/s |        **777K**/s  |      4.5x      |

All Perl implementations produce **identical results** (cross-checked with 10K random lookups).

See [PERFORMANCE.md](PERFORMANCE.md) for the complete analysis.

### Why Is Go Faster Than C/XS?

The Go BART implementation is **4-8x faster** than Net::BART::XS for lookup, despite both using the same algorithm in compiled languages. The gap comes from:

- **Zero-cost value types.** Go's `netip.Addr` is a stack-allocated value with no heap allocation, while Perl XS must wrap every value in a heap-allocated SV with reference counting.
- **Generics.** `bart.Table[int]` is monomorphized at compile time — no `void*` casts or type dispatch at runtime.
- **No refcount overhead.** Go's garbage collector handles memory in bulk; Perl requires per-operation `SvREFCNT_inc`/`SvREFCNT_dec`.
- **`Contains` at 8ns/op** in Go is essentially a few cache hits — the entire hot path stays in registers with zero allocation.

### Why Is Net::BART::XS Faster Than Net::Patricia?

- **8-bit stride multibit trie** — IPv4 traverses at most 4 nodes vs up to 32 in a patricia trie
- **O(1) LPM per node** — precomputed ancestor bitsets + bitwise AND, not pointer-chasing
- **Hardware intrinsics** — `POPCNT` and `LZCNT` instructions for rank/bit-find in single cycles
- **Cache-friendly** — popcount-compressed sparse arrays pack data tightly

### Choosing an Implementation

| | Go BART | Net::BART::XS | Net::Patricia | Net::BART |
|-|:---:|:---:|:---:|:---:|
| **Language** | Go | C (Perl XS) | C (Perl XS) | Pure Perl |
| **Lookup (100K)** | 0.06-0.13 µs | 0.50 µs | 2.1 µs | 10.2 µs |
| **Dependencies** | Go runtime | C compiler | C compiler + libpatricia | None |
| **IPv6** | Native | Native | Separate trie object | Native |
| **Values** | Go generics | Any Perl scalar | Integers / closures | Any Perl scalar |
| **Best for** | Go projects | Perl, max throughput | Existing Perl codebases | Portability |

## How It Works

BART is a **multibit trie** with a fixed stride of 8 bits. Each IP address is decomposed into octets, and each octet indexes one level of the trie:

- **IPv4**: at most 4 trie levels (one per octet)
- **IPv6**: at most 16 trie levels (one per octet)

### ART Index Mapping

Within each trie node, prefixes of length /0 through /7 (relative to the stride) are stored in a **complete binary tree** with indices 1-255:

```
Index 1:         /0 (default route within stride)
Indices 2-3:     /1 prefixes
Indices 4-7:     /2 prefixes
Indices 8-15:    /3 prefixes
Indices 16-31:   /4 prefixes
Indices 32-63:   /5 prefixes
Indices 64-127:  /6 prefixes
Indices 128-255: /7 prefixes
```

### O(1) Longest-Prefix Match Per Node

A precomputed lookup table maps each index to its ancestor set in the binary tree. LPM at a node becomes a bitwise AND of the node's prefix bitset with the ancestor bitset, followed by finding the highest set bit — all O(1) operations.

### Memory Efficiency

**Popcount-compressed sparse arrays** store only occupied slots. A 256-bit bitset tracks which indices are present, and a compact array holds only the values. Lookup is O(1): test the bit, compute rank via popcount, index into the array.

### Path Compression

- **LeafNode**: non-stride-aligned prefixes stored directly when no child exists
- **FringeNode**: stride-aligned prefixes (/8, /16, /24, /32) stored without prefix data

## Project Structure

```
lib/
  Net/
    BART.pm                    # Pure Perl implementation
    BART/
      Art.pm                   # ART index mapping functions
      BitSet256.pm             # 256-bit bitset (4 x uint64)
      LPM.pm                   # Precomputed ancestor lookup table
      Node.pm                  # BartNode, LeafNode, FringeNode
      SparseArray256.pm        # Popcount-compressed sparse array
      bart.h                   # C implementation of BART algorithm
      XS.xs                    # XS bindings
      XS.pm                    # XS Perl wrapper
      Makefile.PL              # Build script for XS module
t/
    01-bitset256.t             # BitSet256 unit tests
    02-sparse-array.t          # SparseArray256 unit tests
    03-art.t                   # ART index mapping tests
    04-table.t                 # Integration tests
```

## Running Tests

```bash
# Pure Perl tests
prove -Ilib t/

# Build and test XS module
cd lib/Net/BART && perl Makefile.PL && make && make test

# Run three-way benchmark (requires Net::Patricia)
perl bench_all.pl
```

## References

- [gaissmai/bart](https://github.com/gaissmai/bart) — Go implementation this port is based on
- Knuth, D. E. — *The Art of Computer Programming, Volume 4, Fascicle 7* — Allotment Routing Tables (ART)

## License

Same terms as Perl itself.
