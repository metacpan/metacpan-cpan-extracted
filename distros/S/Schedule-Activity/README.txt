"Schedule::Activity" Version 0.1.7

Abstract:
---------
This package provides a mechanism to construct "random" schedules of events using a graph-based configuration of activities and actions.  Action scheduling allows cycles/recursion to meet activity schedule goals.

What's new in version 0.1.7:
--------------------------
* Schedule::Activity supports an object call interface.
* buildSchedule will be deprecated in 0.2.0.
* Scheduling to maximum buffer, the single-node case, is now fully passed through filters.
* Tension settings added for slack/buffer (undocumented, internal only)

What's new in version 0.1.6:
--------------------------
* Node filtering is now supported in scheduling configurations.

What's new in version 0.1.5:
--------------------------
* Attributes use rolling averages for efficiency.
* The 0.1.4 update fixed attribute historic entry, but it never really worked "properly" and has been removed as it is not needed in the scheduler.

What's new in version 0.1.4:
--------------------------
* Attributes can log historic changes, but they no longer update the 'value', which should always be the most recent logged value.

What's new in version 0.1.3:
--------------------------
* Attribute precedence when both action nodes and messages contain attribute operators

What's new in version 0.1.2:
--------------------------
* Named message support

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
