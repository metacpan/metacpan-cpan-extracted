# NAME

SerealX::Store - Sereal based persistence for Perl data structures

# SYNOPSIS

    use SerealX::Store;

    my $st = SerealX::Store->new();
    my $data = {
      foo => 1,
      bar => 'nut',
      baz => [1, 'barf'],
      qux => { a => 1, b => 'ugh' },
      ugh => undef
    };
    $st->store($data, "/tmp/dummy");
    my $decoded = $st->retrieve("/tmp/dummy");

# DESCRIPTION

This module serializes Perl data structures using [Sereal::Encoder](https://metacpan.org/pod/Sereal::Encoder) and stores
them on disk for the purpose of retrieving them at a later time. At retrieval
[Sereal::Decoder](https://metacpan.org/pod/Sereal::Decoder) is used to deserialize the data.

The rationale behind this module is to eventually provide a [Storable](https://metacpan.org/pod/Storable) like
API, while using the excellent [Sereal](https://metacpan.org/pod/Sereal) protocol for the heavy lifting.

# METHODS

## new

Constructor used to instantiate the object. Optionally takes a hash reference
as the frist parameter. The following options are recognised:

- encoder

    Options to pass to the Sereal::Encoder object constructor. Its value should be
    a hash reference containing any of the options that influence the behaviour of
    the encoder, as described by its documentation. When this is the case, the
    encoder object will be instantiated in the constructor, otherwise instantiation
    would only happen when the `store` method is called for the first time.

- decoder

    Options to pass to the Sereal::Decoder object constructor. Its format and
    behaviour is equivalent to the `encoder` option above. If its value is not a
    hash reference, the decoder object will only be instantiated when the
    `retrieve` method is called for the first time.

## store

Given a Perl data structure and a path as arguments, will encode the data
structure into a binary string and write it to a file at the specified path.
The method will return a true value upon success or croak if no path is given
or if any other errors are encountered.

    $st->store($data, "/tmp/dummy");
    

## retrieve

Given a path as argument, will retrieve the data from the file at the specified
path, deserialize and return it. The method will croak upon failure.

    $st->retrieve($data, "/tmp/dummy");

# SEE ALSO

[Sereal](https://metacpan.org/pod/Sereal), [Storable](https://metacpan.org/pod/Storable)

# AUTHOR

Gelu Lupaş <gvl@cpan.org>

# COPYRIGHT AND LICENSE

Copyright (c) 2013-2014 the SerealX::Store ["AUTHOR"](#author) as listed
above.

This is free software, licensed under:

    The MIT License (MIT)
