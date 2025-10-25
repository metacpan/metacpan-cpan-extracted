"Schedule::Activity" Version 0.1.8

Abstract:
---------
This package provides a mechanism to construct "random" schedules of events using a graph-based configuration of activities and actions.  Action scheduling allows cycles/recursion to meet activity schedule goals.

What's new in version 0.1.8:
--------------------------
* Commandline tool:  schedule-activity.pl
* Configuration tension for slack/buffer in action scheduling
* Compile-time safety checks

What's new in version 0.1.7:
--------------------------
* Schedule::Activity supports an object call interface.
* buildSchedule will be deprecated in 0.2.0.
* Scheduling to maximum buffer, the single-node case, is now fully passed through filters.
* Tension settings added for slack/buffer (undocumented, internal only)

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
