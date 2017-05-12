#!/usr/bin/env perl

use Test::More tests => 5;
use Test::Exception;
use Carp;

use strict;
use warnings;
use SVG::Sparkline;

throws_ok { SVG::Sparkline->new( Area => { } ) } qr/Missing required 'values'/, 'values is not an array';

throws_ok { SVG::Sparkline->new( Area => { values=>''} ) } qr/'values' must be an array reference/, 'values is not an array';

throws_ok { SVG::Sparkline->new( Area => { values=>[] } ) } qr/No values for 'values' specified/, 'values is empty';

throws_ok { SVG::Sparkline->new( Area => { values=>[[0,1], [1,2], 3, [4,5]] } ) } qr/not a pair/, 'value is not an array ref';

throws_ok { SVG::Sparkline->new( Area => { values=>[[0,1], [1,2], [3], [4,5]] } ) } qr/not a pair/, 'value is not a pair';

