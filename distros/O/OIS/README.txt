Perl OIS
========

This is a Perl binding for OIS, Object-Oriented Input System,
a crossplatform C++ input framework, found at
http://sourceforge.net/projects/wgois . I made it so that
Ogre (http://search.cpan.org/~slanning/Ogre/ ) can be useful,
but there might be uses outside of Ogre.

The wrapping isn't really complete, but I'm focusing on being
able to use it with Ogre. (OIS::Component and OIS::ForceEffect, and their
subclasses are basically the only parts not wrapped. Also changes
between 1.0 and 1.2 aren't taken into account yet.)

There is no documentation, which is no doubt frustrating.
Then again, OIS itself isn't really very documented. :)
There are examples in the Ogre module, and you can look at
the (inadequate) tests under the t/ directory.


DEPENDENCIES

You should install the latest version of OIS. That's 1.2 as I'm writing this.
If you run Ubuntu, see below for installation instructions.

Makefile.PL uses pkg-config to get information about the libraries and header
files needed to build against OIS, so you should be able to do this:

  pkg-config --libs OIS
  pkg-config --cflags OIS
  pkg-config --modversion OIS

This latter should say at least 1.2.0.

The C++ compiler used by default is `g++`, but you can specify a different
C++ compiler by setting the CXX environmental variable. Anything more,
and you'll have to hack at Makefile.PL.


INSTALLATION

To install this module, do the usual:

   perl Makefile.PL
   make
   make test
   make install

You might have to edit Makefile.PL to get it to work for your system.
If so, please let me know.


INSTALLING OIS UNDER UBUNTU

To install OIS in Ubuntu Jaunty,

  sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 6FED7057

  sudo gedit /etc/apt/sources.list

and add these lines:

  deb http://ppa.launchpad.net/andrewfenn/ogredev/ubuntu jaunty main
  deb-src http://ppa.launchpad.net/andrewfenn/ogredev/ubuntu jaunty main 

  sudo apt-get install libois1 libois-dev

`pkg-config --modversion OIS` should be 1.2.0 .


COPYRIGHT AND LICENCE

Please report any bugs/suggestions to <slanning@cpan.org>

Copyright 2007, 2009 Scott Lanning. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

OIS itself is under the "zlib/libpng" license. See the ReadMe.txt file
in OIS's source distribution for more (and probably more accurate) information.
