#!/usr/bin/perl

use strict;
use warnings;

BEGIN {push @main::loaded, __FILE__}

#warn "\n\n$ENV{QUERY_STRING}\n\n";

if ($ENV{QUERY_STRING}=~s/\Aone_piece,//) {
    print <<'EOF'.("huhu\n" x ($ENV{QUERY_STRING}||1));
Status: 404
X-my-header: fritz
Content-Type: my/text

EOF
} else {
    print <<'EOF';
Status: 200
X-my-header: fritz
Content-Type: my/text

EOF

    print "huhu\n" for (1..($ENV{QUERY_STRING}||1));
}
