#!/usr/bin/perl
use blib;
use SOM ':types', ':class', ':dsom', ':environment';

# This should not be needed, but it misbehaves itself otherwise if WPDServer
#   is messed up...
# Misbehaves even with this:
# RestartWPDServer(0);

Ensure_SOMDD_Down(100, 1);
