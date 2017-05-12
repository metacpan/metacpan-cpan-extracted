Run::Parts — run-parts in Perl
==============================

[![Travis CI Build Status](https://travis-ci.org/xtaran/run-parts.svg)](https://travis-ci.org/xtaran/run-parts)
[![Coverage Status](https://img.shields.io/coveralls/xtaran/run-parts.svg)](https://coveralls.io/r/xtaran/run-parts)

The [Perl module `Run::Parts`](https://metacpan.org/release/Run-Parts)
offers the functionality of Debian's `run-parts` tool in Perl.

`Run::Parts` runs all the executable files named within constraints
described in `run-parts(8)` and `Run::Parts::Perl`, found in the given
directory.  Other files and directories are silently ignored.

Additionally it can just print the names of the all matching files
(not limited to executables, but ignores blacklisted files like
e.g. backup files), but don't actually run them.

This is useful when functionality or configuration is split over
multiple files in one directory. A typical convention is that
the directory name ends in ".d". Common examples for such
splitted configuration directories:

    /etc/cron.d/
    /etc/apt/apt.conf.d/
    /etc/apt/sources.list.d/,
    /etc/aptitude-robot/pkglist.d/
    /etc/logrotate.d/
    /etc/rsyslog.d/

Example Code
------------

```perl
use Run::Parts;

my $rp  = Run::Parts->new('directory'); # chooses backend automatically
my $rpp = Run::Parts->new('directory', 'perl'); # pure perl backend
my $rpd = Run::Parts->new('directory', 'debian'); # uses /bin/run-parts

my @file_list        = $rp->list;
my @executables_list = $rpp->test;
my $commands_output  = $rpd->run;
...
```

Backends
--------

`Run::Parts` contains two backend implementations.
`Run::Parts::Debian` actually uses `/bin/run-parts` and
`Run::Parts::Perl` is a pure Perl implementation of a basic set of
`run-parts`' functionality.

`Run::Parts::Debian` may or may not work with RedHat's simplified
shell-script based reimplementation of Debian's `run-parts`.

By default `Run::Parts` uses `Run::Parts::Debian` if `/bin/run-parts`
exists, `Run::Parts::Perl` otherwise. But you can also choose any of
the backends explicitly.

Distribution and Download
-------------------------

* [Git repository on GitHub](https://github.com/xtaran/run-parts)
* On the Comprehensive Perl Archive Network (CPAN):
  * [Run-Parts on MetaCPAN](https://metacpan.org/release/Run-Parts)
  * [Run-Parts on search.cpan.org](http://search.cpan.org/dist/Run-Parts/)
* [librun-parts-perl in Debian](https://packages.debian.org/librun-parts-perl)
  [QA page](https://tracker.debian.org/pkg/librun-parts-perl)
* [librun-parts-perl in Ubuntu](http://packages.ubuntu.com/librun-parts-perl)
  [Launchpad page](https://launchpad.net/ubuntu/+source/librun-parts-perl)

Author, License and Copyright
-----------------------------

Copyright 2013-2014 Axel Beckert <abe@deuxchevaux.org>.

This program is free software; you can redistribute it and/or modify
it under the terms of either: the
[GNU General Public License](https://www.gnu.org/licenses/gpl) as
published by the [Free Software Foundation](https://www.fsf.org/),
either [version 1](https://www.gnu.org/licenses/old-licenses/gpl-1.0),
or (at your option)
[any later version](https://www.gnu.org/licenses/#GPL); or the
[Artistic License](http://dev.perl.org/licenses/artistic.html).

See http://dev.perl.org/licenses/ for more information.

Testing, Continuous Integration and Code Coverage
-------------------------------------------------

* [Travis CI Build Status](https://travis-ci.org/xtaran/run-parts)
  (after each `git push`)
* [Coveralls.io Statement Coverage Status](https://coveralls.io/r/xtaran/run-parts)
  (after each `git push`)
* [CPANTS Kwalitee](http://cpants.cpanauthors.org/dist/Run-Parts)
  (once after each upload to CPAN)
* [CPAN Testers Smoke Tests](http://www.cpantesters.org/distro/R/Run-Parts.html)
  (on many platforms and Perl versions after each upload to CPAN)
* [Piuparts](https://piuparts.debian.org/sid/source/libr/librun-parts-perl.html)
  (package installation, upgrading and removal testing; at least after
  each upload to Debian)
* [Debcheck](https://qa.debian.org/debcheck.php?dist=unstable&package=librun-parts-perl)
  (mostly dependency checking; at least after each upload to Debian)
* [Code Statistics on OpenHub (formerly Ohloh)](https://www.openhub.net/p/run-parts)
  (every few days)
* [Code Coverage of Run-Parts 0.08 at cpancover.com](http://cpancover.com/staging/Run-Parts-0.08/index.html)
