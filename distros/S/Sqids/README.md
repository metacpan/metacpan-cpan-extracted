[![Actions Status](https://github.com/sqids/sqids-perl/actions/workflows/test.yml/badge.svg)](https://github.com/sqids/sqids-perl/actions)
# NAME

Sqids - generate short unique identifiers from numbers

# SYNOPSIS

    use Sqids;
    my $sqids = Sqids->new;

    # encode/decode a single number
    my $id = $sqids->encode(123);         # 'UKk'
    my $num = $sqids->decode('UKk');      # 123

    # or a list or arrayref
    $id = $sqids->encode(1, 2, 3);        # '86Rf07'
    $id = $sqids->encode([1, 2, 3]);      # '86Rf07'
    my @nums = $sqids->decode('86Rf07');  # (1, 2, 3)

    # also get results in an arrayref
    my $nums = $sqids->decode('86Rf07');  # [1, 2, 3]

# DESCRIPTION

[Sqids](https://sqids.org/perl) (_pronounced "squids"_) is a small
library that lets you **generate unique IDs from numbers**. It's good for link
shortening, fast & URL-safe ID generation and decoding back into numbers for
quicker database lookups.

Features:

- **Encode multiple numbers** - generate short IDs from one or several non-negative numbers
- **Quick decoding** - easily decode IDs back into numbers
- **Unique IDs** - generate unique IDs by shuffling the alphabet once
- **ID padding** - provide minimum length to make IDs more uniform
- **URL safe** - auto-generated IDs do not contain common profanity
- **Randomized output** - Sequential input provides nonconsecutive IDs
- **Many implementations** - Support for [40+ programming languages](https://sqids.org/)

## Use-cases

Good for:

- Generating IDs for public URLs (eg: link shortening)
- Generating IDs for internal systems (eg: event tracking)
- Decoding for quicker database lookups (eg: by primary keys)

Not good for:

- Sensitive data (this is not an encryption library)
- User IDs (can be decoded revealing user count)

## Getting started

Install Sqids via:

    cpanm Sqids

# METHODS

## new

    my $sqids = Sqids->new();

Make a new Sqids object. This constructor accepts a few options, either
as a hashref or a list (using [Class::Tiny](https://metacpan.org/pod/Class%3A%3ATiny)):

    my $sqids = Sqids->new(
        alphabet => 'abcdefg',
        min_length => 4,
        blocklist => ['word'],
    );

- alphabet

    You can randomize IDs by providing a custom alphabet:

        my $sqids = Sqids->new({
          alphabet => 'FxnXM1kBN6cuhsAvjW3Co7l2RePyY8DwaU04Tzt9fHQrqSVKdpimLGIJOgb5ZE',
        });
        my $id = $sqids->encode(1, 2, 3); # "B4aajs"
        my $numbers = $sqids->decode($id); # [1, 2, 3]

- min\_length

    Enforce a _minimum_ length for IDs:

        my $sqids = Sqids->new( min_length => 10 );
        my $id = $sqids->encode(1, 2, 3); # "86Rf07xd4z"
        my $numbers = $sqids->decode($id); # [1, 2, 3]

- blocklist

    Prevent specific words from appearing anywhere in the auto-generated IDs:

        my $sqids = Sqids->new( blocklist => ['86Rf07'] );
        my $id = $sqids->encode([1, 2, 3]); # "se8ojk"
        my $numbers = $sqids->decode($id); # [1, 2, 3]

## encode

    my $id = $sqids->encode($n1, [$n2, ...]);

Encode a single number (or a list of numbers, or a single arrayref of numbers) into a string.

## decode

    my @numbers = $sqids->decode($id);

Decode an id into its number (or numbers). Returns a list in list context,
or a scalar (one number) or arrayref (multiple numbers) in scalar context.

**Note**: Because of the algorithm's design, **multiple IDs can decode back
into the same sequence of numbers**. If it's important to your design that IDs
are canonical, you have to manually re-encode decoded numbers and check that
the generated ID matches.

# SEE ALSO

[Sqids](https://sqids.org)

# LICENSE

Copyright (C) Matthew Somerville. MIT.

# AUTHOR

Matthew Somerville <matthew@mysociety.org>
