# PDL::IO::Arrow

Read and write [PDL](https://metacpan.org/pod/PDL) ndarrays via **Apache Arrow IPC** and **Apache Parquet**, backed by a C++20 / XS bridge using `libarrow`, `libparquet`, and the PDL C API (`pdl.h` / `pdlcore.h`).

## Features

- **Direct PDL C API buffer transfer:** Reads and writes contiguous `pdl->data` buffers directly in XS without `get_dataref` / Perl SV string copies.
- **Apache Arrow IPC & Apache Parquet:** Supports `rarrow`, `warrow`, `rparquet`, and `wparquet`.
- **Full numeric & complex type support:** `double` (`float64`), `float` (`float32`), `sbyte` (`int8`), `byte` (`uint8`/`bool`), `short` (`int16`), `ushort` (`uint16`), `long` (`int32`), `ulong` (`uint32`), `longlong` (`int64`), `ulonglong` (`uint64`), `cfloat` (`FixedSizeList(float32, 2)`), and `cdouble` (`FixedSizeList(float64, 2)`).
- **Cross-ecosystem interoperability:** Exchanges columnar data with Apache Spark (Spark Connect), BigQuery Storage Read API, DuckDB, Polars, and RAPIDS cuDF.

## Synopsis

```perl
use PDL;
use PDL::IO::Arrow qw(rarrow warrow rparquet wparquet);

# Write named PDL ndarrays to Parquet or Arrow IPC
wparquet({
    id    => long([1, 2, 3]),
    score => double([0.5, 1.5, 2.5]),
}, 'out.parquet');

# Read back into PDL ndarrays
my $cols = rparquet('out.parquet');
print $cols->{score}, "\n";
```

## Prerequisites

- Debian / Ubuntu: `sudo apt-get install libarrow-dev libparquet-dev pdl`
- Perl: `PDL >= 2.080`, `ExtUtils::CppGuess >= 0.26`

## Installation

```bash
perl Makefile.PL
make
make test
make install
```

## License

Apache License, Version 2.0.
