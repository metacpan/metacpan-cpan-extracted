#!/usr/bin/env perl
use warnings;
use strict;
use Test::More tests => 3;
use FirePHP::Dispatcher;
use HTTP::Headers;
use PerlIO::via::ToFirePHP;
my $fire_php = FirePHP::Dispatcher->new(HTTP::Headers->new);
open my $fh, '>:via(ToFirePHP)', $fire_php or die "can't open: $!";

# Check whether whole lines are accumlated
print $fh 'First line part A ';
print $fh "First line part B\n";
print $fh "Second line\n";
close $fh or die "can't close: $!";
$fire_php->finalize;
is($fire_php->message_index, 2, 'Recorded two messages');
like(
    $fire_php->http_headers->header('x-wf-1-1-1-1'),
    qr/First line part A First line part B/,
    'first line found in headers'
);
like(
    $fire_php->http_headers->header('x-wf-1-1-1-2'),
    qr/Second line/,
    'second line found in headers'
);
