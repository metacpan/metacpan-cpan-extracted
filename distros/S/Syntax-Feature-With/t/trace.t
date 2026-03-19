#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use Syntax::Feature::With qw(with);

use IO::Handle;
open my $err, '>', \my $stderr;

{
    local *STDERR = $err;

    my %h = ( a => 1 );
    my ($a);

    with -trace => \%h, sub { $a };
}

like($stderr, qr/entering with/, 'trace: entering message');
like($stderr, qr/leaving with/,  'trace: leaving message');
like($stderr, qr/depth=1/,       'trace: depth shown');

done_testing();

