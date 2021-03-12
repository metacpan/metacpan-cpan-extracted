#!/usr/bin/env perl

use strict;
use warnings;

use File::Temp;

use Test::More;
use Test::FailWarnings;

my $dir = File::Temp::tempdir( CLEANUP => 1 );

use constant E_UP => do {
    my $v = "é";
    utf8::upgrade($v);
    $v;
};

chdir $dir;

open my $wfh, '>', 'é';

my $destroyed;

do {
    use Sys::Binmode;

    open my $rfh, '<', E_UP or do {
        diag "open failed: $!";
    };
    ok( fileno($rfh), 'open() with upgraded string' );
};

chdir '/';

done_testing;

1;
