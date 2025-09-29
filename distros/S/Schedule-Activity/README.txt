"Schedule::Activity" Version 0.1.0

Abstract:
---------
This package provides a mechanism to construct "random" schedules of events using a graph-based configuration of activities and actions.  Action scheduling allows cycles/recursion to meet activity schedule goals.

What's new in version 0.1.0:
--------------------------
* This is a "stable" version providing only core functionality
* Full support is available for higher-level activity scheduling
* Generic action graphs are supported
* Actions support string messages
* Actions support slack/buffer time configuration
* Scheduling algorithm should be relatively safe

Copyright & License:
--------------------
This package is Copyright (c) 2025--2035 by Brian Blackmore.  All rights reserved.

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
https://github.com/blb8/perl-schedule-activity
