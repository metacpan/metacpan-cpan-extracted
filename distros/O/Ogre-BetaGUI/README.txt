BetaGUI for OGRE
================

This is a port from C++ to Perl of Robin "Betajaen" Southern's BetaGUI
library for OGRE 3D: http://www.ogre3d.org/wiki/index.php/BetaGUI .

Since it depends on OGRE, it's probably useless outside of applications
that use OGRE.

The idea is to provide a minimal GUI library with no external dependencies
(c.f. CEGUI, OpenGUI, etc.). My current interest in it, in particular,
is just to be able to have a mouse cursor in my OGRE examples,
but the rest of the library has also been ported so you can also
make basic dialogs with text input and buttons. The library's functionality
is intentionally very basic, but you can customize it somewhat by providing
your own media resources.

I was going to just bundle this in with the Perl Ogre module, but putting it
in a separate module allows people to download it only if they need it
(Perl Ogre is getting pretty big already, as it is...)


DEPENDENCIES

Required:

  Ogre

The BetaGUI library is meant to be used with OGRE applications and depends on
Ogre to render Overlays and do material management. In order to use this
module, you'll need to install the Ogre Perl module first.

Optional:

  OIS

BetaGUI doesn't actually get user input (mouse, keyboard) for you,
so you need a way to do that. OIS provides one way of obtaining user input.
If you have another way to do that (SDL, for example), you don't have
to install OIS.


INSTALLATION

To install this module, do the usual:

   perl Makefile.PL
   make
   make test
   make install


BUGS

Please report any bugs/suggestions to <slanning@cpan.org>.


COPYRIGHT AND LICENCE

Copyright 2007,2009 Scott Lanning. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, provided that in addition
you keep the original copyright header given below.

This is the copyright header of the original BetaGUI library:

/// Betajaen's GUI 016 Uncompressed
/// Written by Robin "Betajaen" Southern 07-Nov-2006, http://www.ogre3d.org/wiki/index.php/BetaGUI
/// This code is under the Whatevar! licence. Do what you want; but keep the original copyright header.
