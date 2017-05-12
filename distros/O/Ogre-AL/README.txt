OgreAL Perl bindings
====================

This distribution provides Perl bindings for the OgreAL C++ 3D audio library
by Casey Borders. See http://ogreal.sourceforge.net/ or search for
OgreAL on the OGRE 3D wiki http://www.ogre3d.org/wiki/index.php .

OgreAL integrates the OpenAL audio library with OGRE 3D. That lets you
attach a sound to a node in a 3D scene, so that the sound seems to be
coming from a certain place within the scene, which could be interesting
in games for example.

I was going to just bundle this in with the Perl Ogre module, but putting it
in a separate module allows people to download it only if they need it
(Perl Ogre is getting pretty big already, as it is...)


DEPENDENCIES

Required:

  Ogre - the Perl module

  OgreAL - latest version from svn
  libopenal - latest version

There are installation notes below.


Optional Perl modules for the examples:

  OIS
  Ogre::BetaGUI

OIS provides a way of obtaining user input. If you have another way to do
that (SDL, for example), or your application doesn't accept user input,
then you don't have to install OIS.

Ogre::BetaGUI allows you to make a simple graphical user interface
with a mouse cursor, windows, buttons, text boxes, and labels.

These are required for running the examples, but otherwise
it's up to you.


INSTALLATION

Ideally, you should be able to do this to install this Perl module, Ogre::AL.

1) install Ogre and OIS Perl modules
   That will include installing the corresponding C++ libraries.

2) install latest OgreAL :

   svn co https://ogreal.svn.sourceforge.net/svnroot/ogreal/trunk/OgreAL-Eihort
   cd OgreAL-Eihort/
   ./bootstrap
   ./configure
   make
   sudo make install

3) install this module:

   perl Makefile.PL
   make
   make test
   make install

As of today, with r130 from subversion, the above will not quite work.
If it doesn't, there hasn't been a patch yet,
then see http://www.ogre3d.org/addonforums/viewtopic.php?f=10&t=9703&p=64280#p64280
and apply this patch

   cp ogreal-r130.diff /tmp/
   patch -p0 < /tmp/ogreal-r130.diff

to the OgreAL sources before running `make`.


BUGS

No doubt... Please report any bugs/suggestions to <slanning@cpan.org>.


COPYRIGHT AND LICENCE

Copyright 2007, 2009, Scott Lanning. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


OgreAL is copyright Casey Borders and is currently (4 Oct 2009)
distributed under the LGPL license. See the OgreAL distribution
for more details.
