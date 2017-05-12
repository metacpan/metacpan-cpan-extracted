#!/usr/bin/env perl

#
# Testing private method.
# This method is not part of the public interface, and therefore may change at
# any time. It's functionality and existence are not guaranteed.
#

use Test::More tests => 6;
use Carp;

use strict;
use warnings;
use SVG::Sparkline::Whisker;

is( SVG::Sparkline::Whisker::_clean_path( 'M0,1v5m3,-5v-5m3,5,v-5' ),
    'M0,1v5m3,-5v-5m3,5,v-5',
    'Simple path, no changes'
);

is( SVG::Sparkline::Whisker::_clean_path( 'M0,1v5m3,-5m3,0v-5' ),
    'M0,1v5m6,-5v-5',
    'Double m, consolidated'
);

is( SVG::Sparkline::Whisker::_clean_path( 'M0,1v5m3,-5m3,0m3,0v-5' ),
    'M0,1v5m9,-5v-5',
    'Triple m, consolidated'
);

is( SVG::Sparkline::Whisker::_clean_path( 'M0,1v5m3,-5v-5m3,5v-5m0,0' ),
    'M0,1v5m3,-5v-5m3,5v-5',
    'Zero m, Removed'
);

is( SVG::Sparkline::Whisker::_clean_path( 'M0,1v5m3,-5v-5m3,5,v-5m3,0' ),
    'M0,1v5m3,-5v-5m3,5,v-5',
    'Remove trailing move'
);

is( SVG::Sparkline::Whisker::_clean_path( 'M0,1m3,0v5m3,-5v-5m3,5,v-5m3,0' ),
    'M3,1v5m3,-5v-5m3,5,v-5',
    'Consolidate initial moves'
);

