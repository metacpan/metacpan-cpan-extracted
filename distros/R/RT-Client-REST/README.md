RT::Client::REST
================

`RT::Client::REST` is a set of object-oriented Perl modules designed to
make communicating with RT using REST protocol easy.  Most of the
features have been implemented and tested with rt 3.6.0 and later.
Please see POD for details on usage.

To build
--------

Download the latest release from the CPAN, then extract and run:

```shell
perl Makefile.PL
make
```

To test, you will need `Test::Exception` -- as this is an object-oriented
distribution, a lot of tests deal with making sure that the exceptions
that are thrown are correct, so I do not (and you do not) want to skip
those:

```shell
make test
```

To install
----------

```shell
make install
```

Author
------

See **CONTRIBUTORS** file

`RT::Client::REST` is based on 'rt' command-line utility distributed with RT 3.x

License
-------

This module is licensed under both the Aristic 1.0 and GPL 1.0, the same terms as Perl itself.

[![CPAN version](https://badge.fury.io/pl/RT-Client-REST.svg)](https://metacpan.org/pod/RT::Client::REST)
