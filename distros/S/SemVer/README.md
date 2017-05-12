SemVer version 0.6.0
====================

This module subclasses [`version`] to create semantic versions, as defined by
the [Semantic Versioning 1.0.0 Specification]
The two salient points of the specification, for the purposes of version
formatting, are:

1. A normal version number MUST take the form X.Y.Z where X, Y, and Z are
   integers. X is the major version, Y is the minor version, and Z is the
   patch version. Each element MUST increase numerically by increments of one.
   For instance: `1.9.0 < 1.10.0 < 1.11.0`.

2. A pre-release version number MAY be denoted by appending an arbitrary
   string immediately following the patch version and a dash. The string MUST
   be comprised of only alphanumerics plus dash C<[0-9A-Za-z-]>. Pre-release
   versions satisfy but have a lower precedence than the associated normal
   version. Precedence SHOULD be determined by lexicographic ASCII sort order.
   For instance: `1.0.0-alpha1 < 1.0.0-beta1 < 1.0.0-beta2 < 1.0.0-rc1 < 1.0.0`.

[`version`]: http://search.cpan.org/perldoc?version
[Semantic Versioning 1.0.0 Specification]: http://semver.org/spec/v1.0.0.html

Installation
============

To install this module, type the following:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Dependencies
------------

SemVer requires version.

Copyright and License
---------------------

Copyright (c) 2010-2015 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
