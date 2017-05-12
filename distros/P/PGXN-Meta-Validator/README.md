PGXN/Meta/Validator version 0.16.0
==================================

This library's module, PGXN::Meta::Validator, provides a simple Perl interface
to validate the metadata read from a `META.json` file to ensure that it
adheres to the [PGXN Meta Spec](http://pgxn.org/spec/).

INSTALLATION

To install this module, type the following:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Or, if you don't have Module::Build installed, type the following:

    perl Makefile.PL
    make
    make test
    make install

Dependencies
------------

PGXN-Meta::Validator requires the following modules:

* perl 5.10.0

Copyright and Licence
---------------------

Copyright (c) 2011 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
