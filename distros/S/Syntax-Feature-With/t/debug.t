#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use Syntax::Feature::With qw(with);

# Capture STDERR
use IO::Handle;
open my $err, '>', \my $stderr;

{
    local *STDERR = $err;

    my %h = ( a => 1, 'foo-bar' => 2 );
    my ($a);

    with -debug => \%h, sub { $a };

    like($stderr, qr/Aliased: \$a/, 'debug: aliased message appears');
    like($stderr, qr/invalid identifier/, 'debug: invalid identifier message appears');
}

done_testing();

