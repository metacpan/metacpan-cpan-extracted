#!/usr/bin/perl -w
use strict;
use Test::More tests => 4;
use lib 't/lib';

BEGIN {
    use_ok( 'Pod::Coverage' );
    use_ok( 'Pod::Coverage::ExportOnly' );
}

my $obj = new Pod::Coverage package => 'Tie';
isa_ok( $obj, 'Pod::Coverage' );
is($obj->coverage, 1, "yay, skipped TIE* and friends");
