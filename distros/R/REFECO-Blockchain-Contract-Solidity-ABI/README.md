# perl ABI

Application Binary Interface (ABI) utility for encoding and decoding solidity smart contract arguments

# Table of contents

- [Supported types](#supports)
- [Usage](#usage)
- [Installation](#installation)
- [Support and Documentation](#support-and-documentation)
- [License and Copyright](#license-and-copyright)

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

For more information check this [post](https://www.refeco.dev/solidity/2022/10/24/perl-abi-introduction.html)

# Installation

## cpanminus

```
cpanm REFECO::Blockchain::Contract::Solidity::ABI
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
perldoc REFECO::Blockchain::Contract::Solidity::ABI
```

You can also look for information at:

- [Search CPAN](https://metacpan.org/release/REFECO-Blockchain-Contract-Solidity-ABI)

# License and Copyright

This software is Copyright (c) 2022 by Reginaldo Costa.

This is free software, licensed under:

  [The Artistic License 2.0 (GPL Compatible)](https://www.perlfoundation.org/artistic-license-20.html)

