# OpenSSL::Versions

OpenSSL source code uses a hexadecimal number which encodes various bits of
information. The meaning of various parts have changed over the history of the
library. For example, you have

    #define OPENSSL_VERSION_NUMBER	0x0913	/* Version 0.9.1c is 0913 */

versus

    #define OPENSSL_VERSION_NUMBER	0x1000007fL /* OpenSSL 1.0.0g */

The evolution of the version number scheme is explained in the
`crypto/opensslv.h` file in the distribution. If you have already built
OpenSSL, you can determine its version by invoking the command line utility:

    $ openssl version
    OpenSSL 1.0.0g 18 Jan 2012

However, if all you have is the source code, and you want to determine exact
version information on the basis of the string representation of the
`OPENSSL_VERSION_NUMBER` macro, you have to use pattern matching and deal with
a bunch of corner cases. 

The `Makefile.PL` for `Crypt::SSLeay` contained a simplistic approach to
parsing the value of `OPENSSL_VERSION_NUMBER` which people had tweaked over
time to deal with changes. I added functions to deal with specific ranges of
version numbers. But, I did not think those functions belonged in a
`Makefile.PL`.

So, I put them in their own module. To test the routines, I downloaded all
available versions of OpenSSL from http://www.openssl.org/source/ (excluding
archives with 'fips' and 'engine' in their names, and built a mapping between
the value of OPENSSL_VERSION_NUMBER in each archive and the corresponding human
friendly version string in the name of the archive.

## INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

## SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc OpenSSL::Versions

You can also look for information at:

* [RT, CPAN's request tracker (report bugs
  here)](http://rt.cpan.org/NoAuth/Bugs.html?Dist=OpenSSL-Versions)

* [AnnoCPAN, Annotated CPAN documentation](http://annocpan.org/dist/OpenSSL-Versions)

* [CPAN Ratings](http://cpanratings.perl.org/d/OpenSSL-Versions)

* [Search CPAN](http://search.cpan.org/dist/OpenSSL-Versions/)

## LICENSE AND COPYRIGHT

Copyright &copy; 2012 A. Sinan Unur

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

