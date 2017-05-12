#!/usr/bin/perl -w

use strict;
use Test;

# use a BEGIN block so we print our plan before MyModule is loaded

BEGIN { plan tests => 1 };

# Load BBS
use OurNet::BBSApp;

ok(1);
