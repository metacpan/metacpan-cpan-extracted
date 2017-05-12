#!/usr/bin/env perl

use Test::More tests => 4;
use Test::Exception;
use Carp;

use strict;
use warnings;
use SVG::Sparkline;


throws_ok { SVG::Sparkline->new( Bar => { } ) } qr/Missing required 'values'/, '\'values\' data is not supplied';

throws_ok { SVG::Sparkline->new( Bar => { values=>{} } ) } qr/'values' must be an array reference/, '\'values\' data is a hash.';

throws_ok { SVG::Sparkline->new( Bar => { values=>[] } ) } qr/No values for 'values' specified/, 'Empty \'values\' data array.';

throws_ok { SVG::Sparkline->new( Bar => { values=>'' } ) } qr/'values' must be an array reference/, 'Empty \'values\' data string.';

