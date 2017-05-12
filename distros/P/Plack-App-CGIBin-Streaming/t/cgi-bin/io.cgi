#!/usr/bin/perl

use strict;
use warnings;

BEGIN {push @main::loaded, __FILE__}

print <<'EOF';
Status: 200
Content-Type: text/plain

blah blah
EOF

my $r=Plack::App::CGIBin::Streaming->request;
my $st1=$r->status_written;

my $len=0;
{
    local $/=\100;
    while (defined(my $chunk=<STDIN>)) {
        $len+=length $chunk;
        print $chunk;
    }
}

my $st2=$r->status_written;

print ("\n\nlength: $len\nmethod: $ENV{REQUEST_METHOD}\n".
       "st1: $st1\nst2: $st2\n");
