#!/usr/bin/perl

use strict;
use warnings;

BEGIN {push @main::loaded, __FILE__}

my $r=Plack::App::CGIBin::Streaming->request;
undef $r->parse_headers;

$r->suppress_flush=undef
    if $ENV{QUERY_STRING} eq 'dont_suppress';

$|=1;

print "x";
print "x";
print "x";
$r->print_content('||');
$r->flush;
print "x";
print "x";
print "x";
