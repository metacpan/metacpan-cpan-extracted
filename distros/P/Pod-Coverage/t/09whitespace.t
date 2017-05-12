#!/usr/bin/perl -w
use strict;
use Test::More tests => 3;
use lib 't/lib';

BEGIN {
    use_ok( 'Pod::Coverage' );
}

my $obj = new Pod::Coverage package => 'Empty', nonwhitespace => 1;
isa_ok( $obj, 'Pod::Coverage' );
is($obj->coverage, 0.5, "Noticed empty pod section");
