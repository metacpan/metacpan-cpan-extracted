# Peta::NN::Backend::Plain

Peta::NN on plain Perl arrays

## Synopsis

```perl
my $net = Peta::NN->new(input => 2, layers => [ [dense => 2] ], backend => 'plain');
```

## Description

Needs nothing but perl, runs on perl5, and gives bit-identical results on
every perl. See [Peta::NN::Backend](Peta-NN-Backend.md) for the operations.

## Methods

This class implements the backend interface described in
[Peta::NN::Backend, THE BACKEND INTERFACE](Peta-NN-Backend.md) and adds nothing to it.

---

From the POD of `lib/Peta/NN/Backend/Plain.pm`; change it there.
