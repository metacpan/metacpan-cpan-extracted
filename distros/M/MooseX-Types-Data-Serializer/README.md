# NAME

MooseX::Types::Data::Serializer - A Data::Serializer type library for Moose.

# SYNOPSIS

```perl
package MyClass;
use Moose;
use MooseX::Types::Data::Serializer;

has serializer => (
    is       => 'ro',
    isa      => 'Data::Serializer',
    required => 1,
    coerce   => 1,
);

has raw_serializer => (
    is       => 'ro',
    isa      => 'Data::Serializer::Raw',
    required => 1,
    coerce   => 1,
);

# String will be coerced in to a Data::Serializer object:
MyClass->new(
    serializer     => 'YAML',
    raw_serializer => 'Storable',
);

# Hashref will be coerced as well:
MyClass->new(
    serializer => { serializer => 'YAML', digester => 'MD5' },
    raw_serializer => { serializer => 'Storable' },
);

use MooseX::Types::Data::Serializer qw( Serializer RawSerializer );
my $serializer = to_Serializer( 'YAML' );
my $raw_serializer = to_RawSerializer({ serializer=>'Storable', digester=>'MD5' });
if (is_Serializer($serializer)) { ... }
if (is_RawSerializer($raw_serializer)) { ... }
```

# DESCRIPTION

This module provides [Data::Serializer](https://metacpan.org/pod/Data%3A%3ASerializer) types and coercians for [Moose](https://metacpan.org/pod/Moose) attributes.

Two standard Moose types are provided; Data::Serializer and Data::Serializer::Raw.
In addition, two other MooseX::Types types are provided; Serializer and RawSerializer.

See the [MooseX::Types](https://metacpan.org/pod/MooseX%3A%3ATypes) documentation for details on how that works.

# TYPES

## Data::Serializer

This is a standard Moose type that provides coercion from a string or a hashref.  If
a string is passed then it is used for the 'serializer' argumen to Data::Serializer->new().
If a hashref is being coerced from then it will be de-referenced and used as the
arguments to Data::Serializer->new().

## Data::Serializer::Raw

This type works just like Data::Serializer, but for the [Data::Serializer::Raw](https://metacpan.org/pod/Data%3A%3ASerializer%3A%3ARaw) module.

## Serializer

This is a [MooseX::Types](https://metacpan.org/pod/MooseX%3A%3ATypes) type that works just like the Data::Serializer type.

## RawSerializer

Just like the Serializer type, but for Data::Serializer::Raw.

# AUTHOR

```
Aran Clary Deltac <bluefeet@gmail.com>
```

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
