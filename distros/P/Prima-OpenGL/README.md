Prima extension for OpenGL
==========================

Works on win32, cygwin, and x11

Dependencies
------------

Ubuntu: apt-get install libgl-dev

Strawberry perl, if freeglut is not included (5.38): http://prima.eu.org/download/freeglut-win64.zip

Optional dependencies
---------------------

cpan OpenGL::Modern

Howto
-----

    perl Makefile.PL
    make
    make test
    make install
    perl examples/icosahedron.pl

Where
-----

http://github.com/dk/Prima-OpenGL

Author
------

Dmitry Karasik, 2024
