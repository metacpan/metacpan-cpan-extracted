PDL::Drawing::Prima
===================

A PDL interface to the Prima drawing commands.

Buried deep inside the wonderful, Perl-centric Prima toolkit is a set of
cross-platform C functions that handle all of the drawing operations. PDL's
strength is its threading engine, and this module provides a fully
PDL-threaded subset of Prima drawing functions. As such, this module
provides a way to quickly perform many drawing operations on Prima Widgets.

Prima makes it very easy to call subclassed functions from C code (and
therefore PDL::PP code), so these bindings perform the drawing operations on
any object whose class is derived from Prima::Drawable. This means that
you can perform these drawing operations on Widgets, rasterized canvases,
and even Postscript canvases.

For more information about this module and what it provides, see the
documentation for PDL::Drawing::Prima.

Installation
============

There are a number of ways to install this module. The simplest is to
install it using CPAN:

  cpan PDL::Drawing::Prima

or using cpanm:

  cpanm PDL::Drawing::Prima

If you have your hands on the actual source code (from the git repository
listed below, or by C<look>ing at this module from the CPAN shell), you
would do the following:


  # Linux/Mac           # Windows
  perl Makefile.PL      perl Makefile.PL
  make                  gmake
  make test             gmake test
  make install          gmake install

The test suite is tiny at the moment. I apologize. To make up for it, you
can look into the examples directory and see if they work. A more
comprehensive test suite is on the list of things to do next.
If this project gets a bit of momentum behind it, I truly hope that the
test suite gets some much-needed attention.

Development setup
=================

I find that I forget to update my Changes file without a commit hook to remind
me. That commit hook is distributed with this repository, called
git-pre-commit-hook.pl. After you have cloned this repository, you can enable
it by copying it to your repo's commit hooks directory with something like this:

  cp git-pre-commit-hook.pl .git/hooks/pre-commit

Dependencies
============

The installation of this module depends on a working C compiler. It also
depends on the Perl Data Language and the Prima GUI toolkit. You can
install both of these using CPAN.

Note that Prima may give trouble on Linux systems, not because it is Windows
or Mac-centric, but because you may not have the X11 header files installed.
Of course, the installation script will tell you if this is a problem, and
on most systems it is easily resolved.

There is another potential hurdle installing this module if you are using
the Prima package that comes with Debian's repository. Last time I checked,
the Prima Debian package was improperly built and does not list the correct
location of Prima's CORE directory. That makes it impossible to link against
apricot.h (Prima's main library). I may be able to write a special
exception into the Makefile.PL for this, but I haven't gotten around to it
yet.


Code repository
===============

This project is being actively developed at Github. Find the latest at:

  https://github.com/dk/PDL-Drawing-Prima

Copyright and licence
=====================

Portions of this module's code are copyright (c) 2011 The Board of Trustees at
the University of Illinois.

Portions of this module's code are copyright (c) 2011-2012 Northwestern
University.

This module's documentation are copyright (c) 2011-2012 David Mertens.

All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

Author: David Mertens <dcmertens.perl.csharp@gmail.com>

Note that my email is intentionally obfuscated. Knowing that I am a
Perl programmer, you can probably remove the part that does not belong.

Currently supported by: Dmitry Karasik <dmitry@karasik.eu.org>
