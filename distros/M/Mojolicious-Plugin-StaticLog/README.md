
[![Build Status](https://travis-ci.org/frank-carnovale/Mojolicious-Plugin-StaticLog.svg?branch=master)](https://travis-ci.org/frank-carnovale/Mojolicious-Plugin-StaticLog)

Mojolicious::Plugin::StaticLog
------------------------------

Punch static-file stats into the log.

Guide
-----
Guide information is embedded in the main POD text.

Building a distribution
-----------------------
```
rm *StaticLog*tar.gz
# bump VERSION in (source).pm
perl Makefile.PL
make test
make manifest
make dist
mojo cpanify -u USER -p PASS *StaticLog*tar.gz
```
