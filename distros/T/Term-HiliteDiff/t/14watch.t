#!perl
use strict;
use Test::More tests => 2;
use lib 't/lib';
use Test::IsEscapes qw( isq );
use Term::HiliteDiff qw( watch );

isq( watch( 'a b' ), "\e[sa b\e[K" );
isq( watch( 'a c' ), "\e[ua \e[7mc\e[0m\e[K" );
