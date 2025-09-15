"Schedule::Easing" Version 0.1.4

Abstract:
---------
This packages provides a method for filtering existing, ongoing events with a throttling-like mechanism that slowly increases the percentage of messages transmitted over time.  For log messages of warnings or errors that are typically ignored, for example, organizations may wish to begin acting on those messages, but transmitting all such messages to recipients immediately would be considered an "unmanagable flood" and users will likely ignore every message as spam.  Instead, messages can be transmitted at low rates initially, providing an opportunity for users to respond and fix underlying issues.  Over the chosen schedule, eventually all messages will be transmitted and cleanup will have concluded.

What's new in version 0.1.4:
--------------------------
* Initial support for relaxing configurations (begin>final).
* schedule-easing.pl uses a stream handler in all modes to improve performance (since 0.1.3)
* schedule-easing.pl timestamps mode is supported (since 0.1.3)
* schedule-easing.pl fully supports warnings and check modes (since 0.1.2)

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
https://github.com/blb8/perl-schedule-easing
