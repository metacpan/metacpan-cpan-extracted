# NAME

Net::BitTorrent::Protocol::BEP03::Bencode - Utility functions for BEP03: The BitTorrent Protocol Specification

# SYNOPSIS

```perl
my $data = bencode( ... );
my $ref = bdecode( $data );
```

# Description

Bencoding is the BitTorrent protocol's basic serialization and data organization format. The specification supports
integers, lists (arrays), dictionaries (hashes), and byte strings.

# Functions

By default, nothing is exported.

You may import any of the following functions by name or with the `:all` tag.

## `bencode( ... )`

```perl
$data = bencode( 100 );
$data = bencode( { balance => '100.3', first => 'John', last => 'Smith' } );
$data = bencode( [ { count => 1, product => 'apple' }, 30] );
```

Expects a single value (basic scalar, array reference, or hash reference) and returns a single string.

## `bdecode( ... )`

```
$data = bdecode( 'i100e' );
$data = bdecode( 'd7:balance5:100.35:first4:John4:last5:Smithe' );
$data = bdecode( 'ld5:counti1e7:product5:appleei30ee' );
```

Expects a bencoded string.  The return value depends on the type of data contained in the string.

This function will `die` on malformed data.

# See Also

- The BitTorrent Protocol Specification

    [https://bittorrent.org/beps/bep\_0003.html](https://bittorrent.org/beps/bep_0003.html)

- Other Bencode related modules:
    - [Convert::Bencode](https://metacpan.org/pod/Convert%3A%3ABencode)
    - [Bencode](https://metacpan.org/pod/Bencode)
    - [Convert::Bencode\_XS](https://metacpan.org/pod/Convert%3A%3ABencode_XS)

# Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

# License and Legal

Copyright (C) 2008-2026 by Sanko Robinson <sanko@cpan.org>

This program is free software; you can redistribute it and/or modify it under the terms of [The Artistic License
2.0](http://www.perlfoundation.org/artistic_license_2_0). See the `LICENSE` file included with this distribution or
[notes on the Artistic License 2.0](http://www.perlfoundation.org/artistic_2_0_notes) for clarification.

When separated from the distribution, all original POD documentation is covered by the [Creative Commons
Attribution-Share Alike 3.0 License](http://creativecommons.org/licenses/by-sa/3.0/us/legalcode). See the
[clarification of the CCA-SA3.0](http://creativecommons.org/licenses/by-sa/3.0/us/).

Neither this module nor the [Author](#author) is affiliated with BitTorrent, Inc.
