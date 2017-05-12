#!/usr/bin/perl

use strict;
use warnings;

BEGIN {push @main::loaded, __FILE__}

print <<'EOF';
Status: 200
Content-Type: text/plain

EOF

binmode STDIN, $ENV{QUERY_STRING} if $ENV{QUERY_STRING};

$/=\100;
while (defined(my $chunk=<STDIN>)) {
    print $chunk;
}
