#!/usr/bin/env perl

# Do not use 'use 5.14.0', since we want to run under say 5.10.1.

use strict;
use warnings;

# ---------------------

my($re) = qr//;

print "Stringified re: $re \n";
