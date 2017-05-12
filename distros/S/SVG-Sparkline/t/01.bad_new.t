#!/usr/bin/env perl

use Test::More tests => 19;
use Test::Exception;
use Carp;

use strict;
use warnings;
use SVG::Sparkline;

throws_ok { SVG::Sparkline->new(); } qr/No Sparkline type specified/, 'no parameters';
throws_ok { SVG::Sparkline->new( 'xyzzy' ); } qr/Unrecognized Sparkline type/, 'unrecognized type';
throws_ok { SVG::Sparkline->new( 'Whisker' ); } qr/Missing arguments hash/, 'Missing args';
throws_ok { SVG::Sparkline->new( 'Whisker', '' ); } qr/hash reference/, 'Not a hash reference';

throws_ok { SVG::Sparkline->new( Whisker => { values=>[1], height=>0 } ); } qr/positive numeric/, 'Bad height: 0';
throws_ok { SVG::Sparkline->new( Whisker => { values=>[1], height=>-2 } ); } qr/positive numeric/, 'Bad height: negative';

throws_ok { SVG::Sparkline->new( Whisker => { values=>[1], width=>0 } ); } qr/positive numeric/, 'Bad width: 0';
throws_ok { SVG::Sparkline->new( Whisker => { values=>[1], width=>-2 } ); } qr/positive numeric/, 'Bad width: negative';

throws_ok { SVG::Sparkline->new( Whisker => { values=>[1], xscale=>0 } ); } qr/positive numeric/, 'Bad xscale: 0';
throws_ok { SVG::Sparkline->new( Whisker => { values=>[1], xscale=>-2 } ); } qr/positive numeric/, 'Bad xscale: negative';

throws_ok { SVG::Sparkline->new( Whisker => { values=>[1], padx=>-2 } ); } qr/non-negative numeric/, 'Bad padx: negative';
throws_ok { SVG::Sparkline->new( Whisker => { values=>[1], pady=>-2 } ); } qr/non-negative numeric/, 'Bad pady: negative';

throws_ok { SVG::Sparkline->new( Whisker => { values => [1], color => '12345' } ); } qr/not a valid color/, 'bad color';
throws_ok { SVG::Sparkline->new( Whisker => { values => [1], bgcolor => '12345' } ); } qr/not a valid color/, 'bad bgcolor';

throws_ok { SVG::Sparkline->new( Whisker => { values => [1], mark => '12345' } ); } qr/array reference/, 'bad mark: not an array';
throws_ok { SVG::Sparkline->new( Whisker => { values => [1], mark => [1] } ); } qr/even number of/, 'bad mark: not pairs';

throws_ok {
    SVG::Sparkline->new( Whisker => { values => [1], mark => [ -1=>'red' ] } );
} qr/not a valid mark index/, 'bad mark index: -1';
throws_ok {
    SVG::Sparkline->new( Whisker => { values => [1], mark => [ middle=>'red' ] } );
} qr/not a valid mark index/, 'bad mark index: bad string';
throws_ok {
    SVG::Sparkline->new( Whisker => { values => [1], mark => [ 1=>'12345' ] } );
} qr/not a valid mark color/, 'bad mark color';

