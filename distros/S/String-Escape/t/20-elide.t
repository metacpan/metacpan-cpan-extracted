#!/usr/bin/perl

use strict;
use Test;
BEGIN { plan tests => 4, todo => [] }

use String::Escape qw( elide );

my ( $original, $altered, $comparison );

$original = "Now is the time for all good folk to party.";

ok( elide( $original, 10 ) eq 'Now is...');

ok( elide( $original, 15 ) eq 'Now is the...');

ok( elide( $original, 10, 0 ) eq 'Now is ...');

ok( elide( $original, 15, 0 ) eq 'Now is the t...');
