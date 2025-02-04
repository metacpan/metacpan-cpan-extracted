# NAME

Random::Simple - Generate good random numbers in a user consumable way.

# SYNOPSIS

use Random::Simple;

```perl
my $coin_flip      = random_int(1, 2);
my $die_roll       = random_int(1, 6);
my $random_percent = random_float() * 100;
my $buffer         = random_bytes(8);

my @arr            = ('red', 'green', 'blue');
my $rand_item      = random_elem(@arr);
```

# DESCRIPTION

Perl's internal `rand()` function uses `drand48` which is an older
pseudorandom number generator and may have limitations. `Random::Simple` uses
PCG which is: modern, simple, well vetted, and fast. Using `Random::Simple`
will automatically upgrade/override the core `rand()` function to use a
better PRNG.

`Random::Simple` is automatically seeded with entropy directly
from your OS. On Linux this is `/dev/urandom` and on Windows it uses
CryptGenRandom.

When you `use Random::Simple` we automatically upgrade `rand()` and `srand()`
to use a modern PRNG with better statistical properties. As a bonus you also
get a handful of other useful random related methods.

# METHODS

- **random\_int($min, $max)**

    returns a non-biased integer between `$min` and `$max` (inclusive). Range must be no larger than 2\*\*32 - 2.

- **random\_float()**

    returns a random floating point value between 0 and 1 (inclusive).

- **random\_bytes($number)**

    returns a string of random bytes with length of `$number`.

- **random\_elem(@array)**

    returns a random element from `@array`.

- **srand()**

    emulates `CORE::srand()` using a better PRNG.

- **rand()**

    emulates `CORE::rand()` using a better PRNG.

- **Random::Simple::seed($seed1, $seed2)**

    Seed the PRNG with two unsigned 64bit integers for predictable and repeatable
    random numbers. `Random::Simple` will automatically seed itself from your
    operating system's randomness if not manually seeded. Manual seeding should
    only be used in specific cases where you need repeatable or testable
    randomness.

# CAVEATS

PCG uses two 64bit unsigned integers for seeding. High quality seeds are needed
to generate good random numbers. `Random::Simple` automatically generates high
quality seeds by reading random bytes from your operating system and converting
appropriately.

If you manually seed `Random::Simple`, then make sure you use good seeds that
are mostly non-zero. The larger the number the better seed it will make. A good
seed is a decimal number with 18 or 19 digits.

# BUGS

Submit issues on Github: [https://github.com/scottchiefbaker/perl-Random-Simple/issues](https://github.com/scottchiefbaker/perl-Random-Simple/issues)

# SEE ALSO

- [Math::Random::PCG32](https://metacpan.org/pod/Math%3A%3ARandom%3A%3APCG32)
- [Math::Random::ISAAC](https://metacpan.org/pod/Math%3A%3ARandom%3A%3AISAAC)
- [Math::Random::MT](https://metacpan.org/pod/Math%3A%3ARandom%3A%3AMT)
- [Math::Random::Secure](https://metacpan.org/pod/Math%3A%3ARandom%3A%3ASecure)

# AUTHOR

Scott Baker - [https://www.perturb.org/](https://www.perturb.org/)
