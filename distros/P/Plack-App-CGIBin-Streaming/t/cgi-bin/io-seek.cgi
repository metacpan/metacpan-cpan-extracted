#!/usr/bin/perl

use strict;
use warnings;

BEGIN {push @main::loaded, __FILE__}

print <<'EOF';
Status: 200
Content-Type: text/plain

EOF

my $r=Plack::App::CGIBin::Streaming->request;

unless ($r->env->{'psgix.input.buffered'}) {
    print "n/a\n";
    exit 0;
}

$/=\20;
for my $pos (split /,/, $ENV{QUERY_STRING}) {
    seek STDIN, 20*($pos-1), 0;
    print scalar readline STDIN;
}
