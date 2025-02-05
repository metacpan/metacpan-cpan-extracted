# NAME

Random::RDTSC - Perl wrapper for RDTSC-based random number generation

# SYNOPSIS

```perl
use Random::RDTSC qw(get_rdtsc rdtsc_rand64);

my $timestamp  = get_rdtsc();
my $random_val = rdtsc_rand64();

print "TSC: $timestamp, Random: $random_val\n";
```

# DESCRIPTION

This module provides access to the `get_rdtsc()` and `rdtsc_rand64()`
functions from the `rdtsc_rand` library, allowing for high-resolution
timestamps and random number generation based on the CPU's RDTSC instruction.

`Random::RDTSC` is not vetted for true randomness. It is designed to be a
good starting point for other pseudo random number generators. If you use
the numbers from `Random::RDTSC` as seeds for other PRNGs you can have good,
self-starting random numbers.

`Random::RDTSC` is not seedable and thus _not repeatable_. Repeatability
can be helpful for testing and validating code. You should use a seedable
PRNG to get repeatable random numbers.

Based on [rdtsc\_rand](https://github.com/scottchiefbaker/rdtsc_rand).

# FUNCTIONS

## get\_rdtsc

    my $tsc = get_rdtsc();

Returns the current timestamp counter value.

## rdtsc\_rand64

    my $rand = rdtsc_rand64();

Returns a 64-bit random number based on the timestamp counter.

# CAVEATS

## Are there better sources of randomness?

Most definitely. Your operating system gathers a source of entropy for
randomness that is very high quality. For cryptographic applications and
anything where true randomness is required you should use those instead.
`Random::RDTSC` is designed to be quick and simple.

# AUTHOR

Scott Baker - https://www.perturb.org/

# LICENSE

This library is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
