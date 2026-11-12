"Pod::Literate" Version 0.0.3

Abstract:
---------
This package provides a POD format mechanism that supports naming and referencing code embedded in Perl POD, automatically extracting and arranging that code into files, and generating associate literate programming documentation from that specification.

What's new in version 0.0.3:
----------------------------
* Switch to literate:command target=filename
* Verify inline references
* Reject :literate format request
* Additional build specifications

Copyright & License:
--------------------
This package is Copyright (c) 2026--2033 by Brian Blackmore.  All rights reserved.

This library is free software; you can redistribute it and/or modify it under the terms of the GNU Library General Public License Version 3 as published by the Free Software Foundation.

Installation:
-------------
perl ./Build.PL
Build build
Build install
Build test

Author:
---------------
Brian Blackmore <BBLACKM@cpan.org>
https://github.com/blb8/perl-pod-literate
