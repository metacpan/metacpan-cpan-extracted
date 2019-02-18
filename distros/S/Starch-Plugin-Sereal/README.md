# NAME

Starch::Plugin::Sereal - Use Sereal for cloning and diffing Starch data structures.

# SYNOPSIS

    my $starch = Starch->new(
        plugins => ['::Sereal'],
    );

# DESCRIPTION

By default ["clone\_data" in Starch::State](https://metacpan.org/pod/Starch::State#clone_data) and ["is\_data\_diff" in Starch::State](https://metacpan.org/pod/Starch::State#is_data_diff)
use [Storable](https://metacpan.org/pod/Storable) to do the heavy lifting.  This module replaces those two methods
with ones that use [Sereal](https://metacpan.org/pod/Sereal) which can be leaps and bounds faster than Storable.

In this author's testing `is_data_diff` will be about 3x faster with Sereal and
`clone_data` will be about 1.5x faster with Sereal.

# MANAGER ATTRIBUTES

These attributes are added to the [Starch::Manager](https://metacpan.org/pod/Starch::Manager) class.

## sereal\_encoder

An instance of [Sereal::Encoder](https://metacpan.org/pod/Sereal::Encoder).

## sereal\_decoder

An instance of [Sereal::Decoder](https://metacpan.org/pod/Sereal::Decoder).

## canonical\_sereal\_encoder

An instance of [Sereal::Encoder](https://metacpan.org/pod/Sereal::Encoder) with the `canonical` option set.

# MODIFIED MANAGER METHODS

These methods are added to the [Starch::Manager](https://metacpan.org/pod/Starch::Manager) class.

## clone\_data

Modified to use ["sereal\_encoder"](#sereal_encoder) and ["sereal\_decoder"](#sereal_decoder) to clone
a data structure.

## is\_data\_diff

Modified to use ["canonical\_sereal\_encoder"](#canonical_sereal_encoder) to encode the two data
structures.

# SUPPORT

Please submit bugs and feature requests to the
Starch-Plugin-Sereal GitHub issue tracker:

[https://github.com/bluefeet/Starch-Plugin-Sereal/issues](https://github.com/bluefeet/Starch-Plugin-Sereal/issues)

# AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

# ACKNOWLEDGEMENTS

Thanks to [ZipRecruiter](https://www.ziprecruiter.com/)
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
