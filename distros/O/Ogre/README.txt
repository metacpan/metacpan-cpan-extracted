Perl-Ogre
=========

This is a Perl binding for OGRE, Object-Oriented Graphics Rendering Engine,
a C++ library found at http://www.ogre3d.org/ .

The wrapping is currently incomplete, but there are interesting
examples working now (see examples/README.txt).
See TODO.txt for the things I'd like to do. Suggest more things
(preferably submitted with patches) if you like.

My aim is mostly to be able to run OGRE's samples and tutorials from Perl.
(The tutorials and documentation for OGRE are excellent.
I highly recommend going through them before trying this Perl wrapper.)


DEPENDENCIES

Only versions >= 1.8 of OGRE are supported, so you need to install
that either by building from source or by installing a package.
You need to install the "dev" versions of packages,
since this module links against the libraries.

Makefile.PL uses pkg-config to get information about the libraries and header
files needed to build against OGRE, so you should be able to do this:

  pkg-config --libs OGRE
  pkg-config --cflags OGRE
  pkg-config --modversion OGRE

The last one should say at least 1.8.

The C++ compiler used by default is `g++`, but you can specify a different
C++ compiler by setting the "CXX" environmental variable. Anything more,
and you'll have to hack at Makefile.PL.

I have the impression that OGRE doesn't install pkg-config on Windows
(though nobody ever answers when I ask...), so this package will probably
not currently work on Windows. I'd like it to, but I don't use Windows.
Please let me know how if you get it working. Patches for Mac OS would
be welcome as well (in particular, look in Ogre/ExampleApplication
for "macBundlePath").


OPTIONAL

If you have Gtk2 installed, which in practice means that the following
outputs a version number:

  pkg-config --modversion gtk+-2.0

(Ubuntu package "libgtk2.0-dev")
then a static method, Ogre->getWindowHandleString, will be built.
The string returned can be passed to the `params' argument of
Ogre::Root::createRenderWindow in order to use a window (widget)
already created by gtk2-perl or wxPerl, thereby letting you embed
an Ogre widget in a GUI application. This feature is currently
EXPERIMENTAL, meaning its usage might change in the future
or be dropped altogether if it doesn't work.

Some scripts under examples/ require these Perl modules:

 - OIS

I recommend installing it, but you don't have to.
(I have other OGRE-related modules: Ogre::AL and Ogre::BetaGUI .)


INSTALLATION

To install this module, do the usual:

   perl Makefile.PL
   make
   make test
   make install

You might have to edit Makefile.PL to get it to work for your system.
If so, please let me know.


COPYRIGHT AND LICENCE

Please report any patches/bugs/suggestions to <slanning@cpan.org>.

Copyright 2007-2013, Scott Lanning. All rights reserved.

This Perl library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The license for OGRE follows
(from https://bitbucket.org/sinbad/ogre )

--------------8<-----------------------------------------------------------

OGRE (www.ogre3d.org) is made available under the MIT License.

Copyright (c) 2000-2013 Torus Knot Software Ltd

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

--------------8<-----------------------------------------------------------
