
[![Build Status](https://travis-ci.org/frank-carnovale/Mojolicious-Plugin-Tables.svg?branch=master)](https://travis-ci.org/frank-carnovale/Mojolicious-Plugin-Tables)

Mojolicious::Plugin::Tables
---------------------------

The "Tables" Framework is now a Mojolicious Plugin.

Guide
-----
Guide information is embedded in the main POD text.

Running the Test application
----------------------------

The test scripts run a minimal app called 'blah',
against a sample SQLite database.

To actually run the same test web app, do this:
```
EXAMPLEDB=t/example.db t/blah/script/blah daemon
```
and browse to localhost:3000.

Building a distribution
-----------------------
```
 # (first ensure new work committed, then..)

 rm *Tables*tar.gz

 # (bump VERSION in lib/Mojolicious/Plugin/Tables.pm)
 git add            lib/Mojolicious/Plugin/Tables.pm
 git commit -m 'Build version X.YY'
 git log >CHANGES
 git add CHANGES
 git commit -m 'Built version X.YY'
 # (git push)

 perl Makefile.PL 
 make test
 make manifest
 make dist

 mojo cpanify -u USER -p PASS *Tables*tar.gz
```
