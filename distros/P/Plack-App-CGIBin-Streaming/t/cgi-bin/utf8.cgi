#!/usr/bin/perl

use strict;
use warnings;
use utf8;                       # this makes $output a character string
                                # instead of an octet string

BEGIN {push @main::loaded, __FILE__}

my $cs='iso-8859-1';
if ($ENV{QUERY_STRING} eq 'u') {
    $ENV{QUERY_STRING}='utf-8';
    binmode STDOUT, ':utf8';
}

my $output=<<"EOF";
Content-Type: text/plain; charset=$cs

äö
EOF

print $output."is_utf8: ".utf8::is_utf8($output)."\n";
