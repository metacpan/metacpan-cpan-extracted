## The Net::Z3950::ZOOM, ZOOM and Net::Z3950 modules

This distribution contains three Perl modules for the price of one.
They all provide facilities for building information retrieval clients
using the standard Z39.50 and SRW/U protocols, but do so using
different APIs.

- If you are new to this distribution, then you should use the ZOOM
  API, and ignore the others.  It is the cleanest, most elegant and
  intuitive, and most closely follows the letter as well as the spirit
  of the [Abstract ZOOM API](http://zoom.z3950.org/api/)

- If you have used the old Net::Z3950 module and have to maintain an
  application that calls that API, then you will want to use the
  Net::Z3950 classes provided in this distribution, which provide an
  API compatible with the old module's implemented on top of the new
  ZOOM code.

- You should definitely not use the Net::Z3950::ZOOM API, which is not
  object-oriented, and instead provides the thinnest possible layer on
  top of the ZOOM-C functions in the YAZ toolkit.  This API exists
  only in order to have ZOOM API built on top of it.


### INSTALLATION

To install this module, type the following:

    perl Makefile.PL
    make
    make test
    make install


### DEBIAN PACKAGES

To build Debian packages, do:

    dh-make-perl --build


### DEPENDENCIES

This module requires these other modules and libraries:

- The YAZ toolkit for Z39.50 and SRW/U communication.  This is
  available as a package on several platforms -- for example, Debian
  GNU/Linux supports "apt-get install yaz".  For others, you will need
  to download and build the source-code, which is much more
  straightforward that you probably expect.  You can get it from
  [http://indexdata.com/yaz](http://indexdata.com/yaz) .

  NOTE THAT THE ZOOM-Perl MODULE ABSOLUTELY REQUIRES RELEASE 2.0.11 OR
  BETTER OF THE YAZ TOOLKIT.  You need version 2.1.17 or better if you
  want to run clever asynchronous programs that use the END event,
  which did not exist prior to that release.


### SOURCE CODE

https://github.com/indexdata/zoom-perl


### COPYRIGHT AND LICENCE

Copyright (C) 2005-2017 by Index Data.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


