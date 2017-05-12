#!/usr/bin/perl -w

use strict;
use Test;

# use a BEGIN block so we print our plan before MyModule is loaded

BEGIN { plan tests => 1 };

# Load BBS
use Slash::OurNet;

ok(1);
