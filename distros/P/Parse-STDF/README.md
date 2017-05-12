Parse::STDF - Module for parsing files in Standard Test Data Format
===================================================================

Standard Test Data Format (STDF) is a widely used standard file format for semiconductor test information. 
It is a commonly used format produced by automatic test equipment (ATE) platforms from companies such as 
LTX-Credence, Roos Instruments, Teradyne, Advantest, and others.

A STDF file is compacted into a binary format according to a well defined specification originally designed by 
Teradyne. The record layouts, field definitions, and sizes are all described within the specification. Over the 
years, parser tools have been developed to decode this binary format in several scripting languages, but as 
of yet nothing has been released to CPAN for Perl.

Parse::STDF is a first attempt. It is an object oriented module containing methods which invoke APIs of
an underlying C library called libstdf (see <http://freestdf.sourceforge.net/>).  libstdf performs 
the grunt work of reading and parsing binary data into STDF records represented as C-structs.  These 
structs are in turn referenced as Perl objects.


INSTALLATION
------------

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Depending on your environment, you may need to add extra cc and linker flags.
Here's an example which links with libzzip (used by libstdf).

    perl Build.PL --extra_ccflags="-m32 -I/path/to/libzzip/include" \
                  --extra_ldflags="-m32 -Xlinker -rpath /path/to/libzzip/lib"
    ./Build
    ./Build test
    ./Build install


For compatibility, the older idiom is tolerated:

    perl Makefile.PL
    make
    make test
    make install


DEPENDENCIES
------------

* libstdf and development headers
* C compiler
* SWIG (optional)
* Unix OS


TESTED PLATFORMS
----------------

The following platforms have been tested:

* RHEL Linux 5.x, 6.x
* Ubuntu 12.04 LTS


COPYRIGHT AND LICENSE
---------------------

  Copyright (C) 2014 Erick Jordan <ejordan@cpan.org>

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
