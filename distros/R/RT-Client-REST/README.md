# This is README file for RT::Client::REST distribution.

RT::Client::REST is a set of object-oriented Perl modules designed to
make communicating with RT using REST protocol easy.  Most of the
features have been implemented and tested with rt 3.6.0 and later.
Please see POD for details on usage.

To build:
    perl Makefile.PL
    make

To test, you will need Test::Exception -- as this is an object-oriented
distribution, a lot of tests deal with making sure that the exceptions
that are thrown are correct, so I do not (and you do not) want to skip
those:
    make test

To install:
    make install

Author:
    Dmitri Tikhonov <dtikhonov@yahoo.com>
    RT::Client::REST is based on 'rt' command-line utility distributed
        with RT 3.x written by Abhijit Menon-Sen <ams@wiw.org> and
        donated to RT project.

License:
    This module is licensed under the same terms as perl itself.
