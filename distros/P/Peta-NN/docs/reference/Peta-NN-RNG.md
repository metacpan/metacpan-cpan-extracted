# Peta::NN::RNG

seeded random numbers that are the same on every perl

## Synopsis

```perl
my $rng = Peta::NN::RNG->new(42);
my $u   = $rng->uniform;        # (0, 1)
my $k   = $rng->below(10);      # 0 .. 9
my $z   = $rng->normal;         # mean 0, deviation 1
$rng->shuffle(\@order);
```

## Methods

### new

`Peta::NN::RNG->new($seed)`; the seed defaults to 1.

### uniform

A number in the open interval (0, 1).

### below

`below($n)`: a whole number from 0 to `$n - 1`.

### normal

A standard normal number.

### shuffle

`shuffle(\@list)`: shuffles the list in place.

---

From the POD of `lib/Peta/NN/RNG.pm`; change it there.
