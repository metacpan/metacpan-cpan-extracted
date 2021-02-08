# NAME

String::CRC32 - Perl interface for cyclic redundancy check generation

# SYNOPSIS

    use String::CRC32;
    
    $crc = crc32("some string");
    $crc = crc32("some string", initvalue);

    $somestring = "some string";
    $crc = crc32($somestring);
    printf "%08x\n", $crc;

    open my $fh, '<', 'location/of/some.file' or die $!;
    binmode $fh;
    $crc = crc32($fh);
    close $fh;

# DESCRIPTION

The **CRC32** module calculates CRC sums of 32 bit lengths as integers.
It generates the same CRC values as ZMODEM, PKZIP, PICCHECK and
many others.

Despite its name, this module is able to compute
the checksum of files as well as strings.

# EXAMPLES

    $crc = crc32("some string");

results in the same as

    $crc = crc32(" string", crc32("some"));

This is useful for subsequent CRC checking of substrings.

You may even check files:

    open my $fh, '<', 'location/of/some.file' or die $!;
    binmode $fh;
    $crc = crc32($fh);
    close $fh;

A init value may also have been supplied in the above example.

# AUTHOR

Soenke J. Peters &lt;peters\_\_perl@opcenter.de>

Current maintainer: LEEJO 

Address bug reports and comments to: [https://github.com/leejo/string-crc32/issues](https://github.com/leejo/string-crc32/issues)

# LICENSE

CRC algorithm code taken from CRC-32 by Craig Bruce. 
The module stuff is inspired by a similar perl module called 
String::CRC by David Sharnoff & Matthew Dillon.
Horst Fickenscher told me that it could be useful to supply an init
value to the crc checking function and so I included this possibility.

The author of this package disclaims all copyrights and 
releases it into the public domain.
