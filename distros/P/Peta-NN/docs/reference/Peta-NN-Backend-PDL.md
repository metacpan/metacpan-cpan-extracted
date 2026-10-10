# Peta::NN::Backend::PDL

Peta::NN on PDL ndarrays

## Synopsis

```perl
my $net = Peta::NN->new(input => 2, layers => [ [dense => 2] ], backend => 'pdl');
```

## Description

Double precision, on the CPU. Results agree with the plain backend to
rounding, not to the bit: a matrix product sums in another order. See
[Peta::NN::Backend](Peta-NN-Backend.md) for the operations.

## Methods

This class implements the backend interface described in
[Peta::NN::Backend, THE BACKEND INTERFACE](Peta-NN-Backend.md) and adds nothing to it.

---

From the POD of `lib/Peta/NN/Backend/PDL.pm`; change it there.
