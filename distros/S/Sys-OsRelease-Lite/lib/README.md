# Sys::OsRelease::Lite lib directory

Sys::OsRelease::Lite imports and filters source code from Sys::OsRelease in order to use the same source code for maintainability.

The following files in this directory are not present in the git repository but are added to the distribution tree via a filter script via [Makefile.PL](../Makefile.PL) . The filter changes occurrences of Sys::OsRelease to Sys::OsRelease::Lite in lines of code but not in POD documentation in the same-named files in the main source tree for Sys::OsRelease.

* Sys/OsRelease/Lite.pm
  * built from ../build\_tools/input/Lite.pm, which is a symlink in the git repo to ../../../main/lib/Sys/OsRelease.pm
