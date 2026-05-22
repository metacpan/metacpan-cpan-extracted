[![Actions Status](https://github.com/dstroma/string-obfuscate/actions/workflows/test.yml/badge.svg)](https://github.com/dstroma/string-obfuscate/actions)
# NAME

String::Obfuscate - Reversibly obfuscate a string with a substitution cipher.

# VERSION

version 0.01

# SYNOPSIS

    use String::Obfuscate;
    my $obf = String::Obfuscate->new(seed => 123);
    $obf->obfuscate('hello');   # 'xn88Y'
    $obf->deobfuscate('xn88Y'); # 'hello'

# DESCRIPTION

String::Obfuscate implements a substitution type cipher adequate to obfuscate
a string without being cryptographically secure. The cipher mapping is
dynamically generated based on a seed or seeds which are fed to a random number
generator.

Specify seed(s) yourself to get a predictable result. Otherwise, the order will
be different with each String::Obfuscate object, but obfuscated strings can
still be reversed with the same object, or by asking the object for the seed and
and re-using the same seed.

If no seed is supplied, this module will create one based on the time and PID,
however this method may change in the future.

Randomness is supplied by the Math::Random::ISAAC, module which has both XS
and pure-perl implementations. This has several advantages:
 - The XS module is very fast while the PP module can be used as a fallback
 - Using a discrete RNG prevents alterating the state of perl's built-in RNG
 - The same algorithm can be implemented in another language if desired

If version 1.54 or greater of List::Util::XS is not available, a pure-perl
implementation of the same shuffle algorithm will be used (not List::Util::PP
which uses a different shuffle algorithm). Again, this ensures reproducibility.

Only ASCII letters and numbers are scrambled, but you can specify your own
character set to the new constructor with the chars param, which takes a
reference (to a string or an array of characters). This is done to prevent
excessive string copying and for a possible future feature where a plain string
might have a special meaning, such as the name of a character set.

Internally, this module generates a pair of encoding/decoding subroutines that
use a translation regex. Once the object is created, encoding and decoding is
very fast. However, if desired, you can dump the source code of the generated
subroutines/regexes.

Included in this distribution are String::Obfuscate::Base64 and
String::Obfuscate::Base64::URL which will convert the string to base 64 using
the standard or URL encoding, respectively, then obfuscate it. These subclasses
do not let you specify a character set. If the string you desire to obfuscate
contains binary data or UTF-8 characters, it is recommended you use one of
these Base64 subclasses.

# REQUIREMENTS

    Math::Random::ISAAC (::XS or ::PP)

    perl v5.20 or greater

A minimum perl version of 5.20 is required as this module uses subroutine
signatures and postfix dereferencing. As of this writing, this version is
approximately 12 years old. You are encouraged to upgrade.

# RECOMMENDATIONS

    List::Util::XS version 1.54 or greater

Older versions of List::Util do not allow you to specify a custom RNG.

# RATIONALE

This module can be used to obscure non-security-sensitive data in a way that
is several orders of magnitude faster than encrypting it, while using a more
complex cipher than one with a fixed rotation (such as Crypt::Cipher::Rot47,
which is only slightly faster than this module).

# CONSTRUCTOR

- **new PARAMS**

    Returns a new [String::Obfuscate](https://metacpan.org/pod/String%3A%3AObfuscate) object constructed according to PARAMS,
    where PARAMS are name/value pairs. All PARAMS are optional. If a seed is not
    specified, one will be created.

        $ob = String::Obfuscate->new;
        $ob = String::Obfuscate->new(seed => 123);
        $ob = String::Obfuscate->new(chars => ['a'..'f',0..9]);
        $ob = String::Obfuscate->new(passphrase => 'abcdefg');

- chars

    The characters used to generate the cipher, specified as an arrayref or stringref.

- seed

    The seed or seed(s). May be specified as a number or an arrayref of multiple
    seeds. The random number generator can take up to 255 seeds.

- passphrase

    Instead of specifying a seed, you can specify a string passphrase which will
    be converted to a series of seeds. The first seed is the length of the string,
    then four-character groups are converted to 32-bit integers using unpack.

- retain\_source

    Set to a true value, the source code of the generated encoding/decoding
    subroutines will be saved before being eval-ed.

# OBJECT METHODS

- **seed()**

    Returns the seed. Regardless of how the seed was originally supplied, this
    method will always return an arrayref.

    Note the seed is set at object creation and cannot be changed later.

- **chars()**
- **chars\_shuffled()**

    Returns the source or destination character list as an arrayref.

    These are set at object creation and cannot be changed later.

- **dump\_source()**

    Returns a two-element array. The first element is a string representation of
    the obfuscation subroutine; the second element is the deobfuscation subroutine.
    If retain\_source was not passed to new(), this method can still be called, but
    the subroutines will be re-generated.

- **obfuscate($string)**

    Returns the obfuscated version of $string without altering the original.

- **deobfuscate($string)**

    Returns the deobfuscated version of $string without altering the original.

# AUTHOR

Dondi Michael Stroma <dstroma@gmail.com>

# COPYRIGHT

Copyright (C) 2025 by Dondi Michael Stroma. All rights reserved.

# LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
