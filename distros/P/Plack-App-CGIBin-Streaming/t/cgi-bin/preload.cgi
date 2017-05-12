#!/usr/bin/perl

use strict;
use warnings;

BEGIN {push @main::loaded, __FILE__}

local $"="\n";

print <<"EOF";
Status: 200
Content-Type: text/plain

@main::loaded
EOF
