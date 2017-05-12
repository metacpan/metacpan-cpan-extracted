#!/usr/bin/perl

use strict;
use warnings;
use utf8;

BEGIN {push @main::loaded, __FILE__}

print <<'EOF';
Status: 200
Content-Type: text/plain

EOF

my $string="äö"x2;

print $string;

binmode STDOUT, ':utf8';

print $string;

binmode STDOUT, $ENV{QUERY_STRING};

print $string;

binmode STDOUT, ':encoding(utf8)';

print $string;

binmode STDOUT, $ENV{QUERY_STRING};

print $string;
