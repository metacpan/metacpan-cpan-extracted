#!/usr/bin/env perl

use Test::More tests => 5;
use Test::Exception;
use Carp;

use strict;
use warnings;
use SVG::Sparkline;


throws_ok { SVG::Sparkline->new( RangeBar => { } ) } qr/Missing required 'values'/, '\'values\' data is not supplied';

throws_ok { SVG::Sparkline->new( RangeBar => { values=>{} } ) } qr/'values' must be an array reference/, '\'values\' data is a hash.';

throws_ok { SVG::Sparkline->new( RangeBar => { values=>[] } ) } qr/No values for 'values' specified/, 'Empty \'values\' data array.';

throws_ok { SVG::Sparkline->new( RangeBar => { values=>'' } ) } qr/'values' must be an array reference/, 'Empty \'values\' data string.';

throws_ok { SVG::Sparkline->new( RangeBar => { values=>[ 1,2,3,4 ] } ) } qr/'values' must be an array of pairs/, 'Scalars in \'values\'';

