#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

sub diag {
    print STDERR @_;
    print STDERR "\n";
}

if ( not exists $ENV{STERILIZE_ENV} ) {
    diag('STERILIZE_ENV unset');
    exit 0;
}
if ( $ENV{STERILIZE_ENV} < 1 ) {
    diag('STERLIZIE_ENV < 1, Not Sterilizing');
    exit 0;
}
if ( not exists $ENV{TRAVIS} ) {
    diag('Is not running under travis!');
    exit 1;
}
for my $i (@INC) {
    next if $i !~ /site/;
    next if $i eq '.';
    diag( 'Sterilizing files in ' . $i );
    system( 'find', $i, '-type', 'f', '-delete' );
    diag( 'Sterilizing dirs in ' . $i );
    system( 'find', $i, '-depth', '-type', 'd', '-delete' );
}

