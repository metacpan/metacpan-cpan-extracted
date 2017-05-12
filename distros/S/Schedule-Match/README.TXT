
WHAT IS IT
==========

This library will allow you to handle schedules in extended
crontab(5) format. This library mainly provides following
methods:

  1. Method to find the time which given schedule will be executed

  2. Method to detect crash between two schedule. This can be done
     with or without the consideration of each schedule's duration

  3. Other utility functions related to time handling (leap year
     checking, etc).

If you're planning to manage pattern-based (i.e., crontab(5)-like
defined) schedule, then this library should be useful.

HOW TO INSTALL
==============

Just type:

    perl Makefile.PL
    make
    make test
    make install

and you should be all set.

REQUIREMENT
===========

This module requires Time::Local.

HOW TO USE
==========

For the usage, please consult POD document embedded in the library.
Also,

    perldoc Schedule::Match

should show you the document if installed correctly.
