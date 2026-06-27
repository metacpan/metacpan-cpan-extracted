#!/usr/bin/env perl
use strict;
use warnings;

print "Content-Type: text/plain\r\n\r\n";
print "SCRIPT_NAME=$ENV{SCRIPT_NAME};PATH_INFO=$ENV{PATH_INFO}";
