Params/CallbackRequest version 1.20
===================================

Params::CallbackRequest provides functional and object-oriented callbacks to
method and function parameters. Callbacks may be either code references
provided to the `new()` constructor, or methods defined in subclasses of
Params::Callback. Callbacks are triggered either for every call to the
Params::CallbackRequest `execute()` method, or by specially named keys in the
parameters to `execute()`.

The idea behind this module is to provide a sort of plugin architecture for
Perl templating systems. Callbacks are executed by the contents of a request
to the Perl templating server, before the templating system itself executes.
This approach allows you to carry out logical processing of data submitted
from a form, to affect the contents of the request parameters before they're
passed to the templating system for processing, and even to redirect or abort
the request before the templating system handles it.

Installation
------------

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

This module requires these other modules and libraries:

* Params::Validate 0.59 or later
* Exception::Class 1.10 or later

The object-oriented callback interface requires Perl 5.6 or later and
these other modules and libraries:

* Attribute::Handlers 0.77 or later
* Class::ISA

The test suite requires:

* Test::Simple 0.17 or later

Copyright and License
---------------------

Copyright 2003-2011 David E. Wheeler. Some Rights Reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
