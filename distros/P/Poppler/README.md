Poppler
=======

Perl bindings to the poppler-glib PDF rendering library

INSTALLATION
------------

To install this module type the following:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install


DEPENDENCIES
------------

This module requires these C libraries:

  * glib

  * cairo

  * poppler-glib

and these Perl modules:

  * Glib::Object::Introspection

  * Cairo (for rendering to cairo context)

  * URI (for convering to/from URIs expected by poppler)

COPYRIGHT AND LICENCE
---------------------

Copyright (C) 2016 by Jeremy Volkening (jdv@base2bio.com)

Copyright (C) 2009-2015 by c9s

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.
