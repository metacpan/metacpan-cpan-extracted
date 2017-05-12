
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
# (bump VERSION)
perl Makefile.PL
git rm *Tables*tar.gz
make test
make manifest
make dist
mojo cpanify -u USER -p PASS *Tables*tar.gz
git add *Tables*tar.gz
git commit -m 'Build version X.YY'
# (git push)
```
