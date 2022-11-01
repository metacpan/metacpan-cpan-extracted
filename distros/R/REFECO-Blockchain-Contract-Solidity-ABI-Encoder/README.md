# solidity-abi-encoder

Solidity contracts ABI argument encoding utility

# Supports:

- address
- bool
- bytes(\d+)?
- (u)?int(\d+)?
- string
- tuple

Also arrays `((\[(\d+)?\])+)?` for the above mentioned types.

# Usage:

```perl
my $encoder = REFECO::Blockchain::Contract::Solidity::ABI::Encoder->new();
$encoder->function('test')
    # string
    ->append(string => 'Hello, World!')
    # bytes
    ->append(bytes => unpack("H*", 'Hello, World!'))
    # tuple
    ->append('(uint256,address)' => [75000000000000, '0x0000000000000000000000000000000000000000'])
    # arrays
    ->append('bool[]', [1, 0, 1, 0])
    # multidimensional arrays
    ->append('uint256[][][2]', [[[1]], [[2]]])
    # tuples arrays and tuples inside tuples
    ->append('((int256)[2])' => [[[1], [2]]])->encode;

my $decoder = REFECO::Blockchain::Contract::Solidity::ABI::Decoder->new();
$decoder
    ->append('uint256')
    ->append('bytes[]')
    ->decode('0x...');
```

# Installation

## cpanminus

```
cpanm REFECO::Blockchain::Contract::Solidity::ABI::Encoder
```

## make

```
perl Makefile.PL
make
make test
make install
```

# Support and Documentation

After installing, you can find documentation for this module with the
perldoc command.

```
perldoc REFECO::Blockchain::Contract::Solidity::ABI::Encoder
```

You can also look for information at:

- [RT, CPAN's request tracker (report bugs here)](https://rt.cpan.org/NoAuth/Bugs.html?Dist=REFECO-Blockchain-Contract-Solidity-ABI-Encoder )

- [CPAN Ratings](https://cpanratings.perl.org/d/REFECO-Blockchain-Contract-Solidity-ABI-Encoder )

- [Search CPAN](https://metacpan.org/release/REFECO-Blockchain-Contract-Solidity-ABI-Encoder)

# License and Copyright

This software is Copyright (c) 2022 by Reginaldo Costa.

This is free software, licensed under:

  [The Artistic License 2.0 (GPL Compatible)](https://www.perlfoundation.org/artistic-license-20.html)

