# PDL::Torch

LibTorch (PyTorch C++) GPU/CPU tensor acceleration for [PDL](https://pdl.perl.org/).

## Features

- Direct C99 XS + C++17 bridge using the PDL C API (`pdl.h`/`pdlcore.h`) and LibTorch (`torch/torch.h`).
- Supports `byte`, `sbyte`, `short`, `long`, `longlong`, `float`, `double`, `cfloat`, and `cdouble` ndarrays.
- Operator overloading (`+`, `-`, `*`, `/`, `x` for matrix multiplication) on `PDL::Torch::Tensor`.
- Deterministic VRAM/RAM cleanup via Perl reference counting (`DESTROY`).
- Automatic LibTorch discovery via `$ENV{LIBTORCH}`, `/usr/include/torch/torch.h` (`libtorch-dev`), or Python `torch`.

## Synopsis

```perl
use PDL;
use PDL::Torch qw(pdl2tensor tensor2pdl cuda_available);

my $device = cuda_available() ? 'cuda' : 'cpu';

my $a = pdl2tensor(double([[1, 2], [3, 4]]), $device);
my $b = pdl2tensor(double([[5, 6], [7, 8]]), $device);

my $c = ($a + $b) x $a;
print $c->pdl(), "\n";
```

## Prerequisites

- Perl 5.10+
- `PDL` (>= 2.080)
- `ExtUtils::CppGuess` (>= 0.26)
- LibTorch (`LIBTORCH=/path/to/libtorch`, Debian `libtorch-dev`, or Python `torch`)
