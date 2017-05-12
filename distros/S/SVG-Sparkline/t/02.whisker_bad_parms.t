#!/usr/bin/env perl

use Test::More tests => 5;
use Test::Exception;
use Carp;

use strict;
use warnings;
use SVG::Sparkline;


throws_ok { SVG::Sparkline->new( Whisker => { } ) } qr/Missing required 'values'/, '\'values\' is missing.';

throws_ok { SVG::Sparkline->new( Whisker => { values=>{} } ) } qr/Unrecognized type of/, '\'values\' data is a hash.';

throws_ok { SVG::Sparkline->new( Whisker => { values=>[] } ) } qr/No values specified/, 'Empty \'values\' data array.';

throws_ok { SVG::Sparkline->new( Whisker => { values=>'' } ) } qr/No values specified/, 'Empty \'values\' data string.';

throws_ok { SVG::Sparkline->new( Whisker => { values=>'+-*' } ) } qr/Unrecognized character/, 'Bad data string.';

