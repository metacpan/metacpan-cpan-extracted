# NAME

TOML::XS - Turbo-charged [TOML](https://toml.io) parsing!

<div>
    <a href='https://coveralls.io/github/FGasper/p5-TOML-XS?branch=master'><img src='https://coveralls.io/repos/github/FGasper/p5-TOML-XS/badge.svg?branch=master' alt='Coverage Status' /></a>
</div>

# SYNOPSIS

    # NB: Don’t read_text(), or stuff may break.
    my $toml = File::Slurper::read_binary('/path/to/toml/file');

    my $struct = TOML::XS::from_toml($toml)->to_struct();

# DESCRIPTION

This module facilitates parsing of TOML documents in Perl via XS,
which can yield dramatic performance gains relative to pure-Perl TOML
libraries.

It is currently implemented as a wrapper around the
[tomlc99](https://github.com/cktan/tomlc99) C library.

# FUNCTIONS

## $doc = TOML::XS::from\_toml($byte\_string)

Converts a byte string (i.e., raw, undecoded bytes) that contains a
serialized TOML document to a [TOML::XS::Document](https://metacpan.org/pod/TOML::XS::Document) instance.

# MAPPING TOML TO PERL

Most TOML data items map naturally to Perl. The following details
are relevant:

- Strings are character-decoded.
- Booleans are represented as [TOML::XS::true](https://metacpan.org/pod/TOML::XS::true) and [TOML::XS::false](https://metacpan.org/pod/TOML::XS::false),
which are namespace aliases for the relevant constants from
[Types::Serialiser](https://metacpan.org/pod/Types::Serialiser).
- Timestamps are represented as [TOML::XS::Timestamp](https://metacpan.org/pod/TOML::XS::Timestamp) instances.

# NOTE ON CHARACTER DECODING

This library mimics the default behaviour of popular JSON modules:
the TOML input to the parser is expected to be a byte string, while the
strings that the parser outputs are character strings.

# PERFORMANCE

On my system the included (_very_ simple!) benchmark outputs:

    Including TOML::Tiny …

    small …
                Rate toml_tiny   toml_xs
    toml_tiny  1009/s        --      -95%
    toml_xs   21721/s     2053%        --

    large …
                (warning: too few iterations for a reliable count)
              s/iter toml_tiny   toml_xs
    toml_tiny   1.65        --      -93%
    toml_xs    0.110     1400%        --

# COPYRIGHT & LICENSE

Copyright 2021 Gasper Software Consulting. All rights reserved.

This library is licensed under the same license as Perl itself.

[tomlc99](https://github.com/cktan/tomlc99) is licensed under the
[MIT License](https://mit-license.org/).
