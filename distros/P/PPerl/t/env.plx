#!perl -w
use strict;
print map { "'$_' => '$ENV{$_}'\n" } sort keys %ENV;