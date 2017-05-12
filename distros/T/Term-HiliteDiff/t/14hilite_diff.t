#!perl
use strict;
use Test::More tests => 2;
use lib 't/lib';
use Test::IsEscapes qw( isq );
use Term::HiliteDiff qw( hilite_diff );

isq( hilite_diff( 'a b' ), "a b" );
isq( hilite_diff( 'a c' ), "a \e[7mc\e[0m" );
