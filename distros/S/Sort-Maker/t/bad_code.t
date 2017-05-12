#!/usr/local/bin/perl -sw

use strict ;

use lib 't' ;
use lib '..' ;

use Test::More tests => 2 ;

use Sort::Maker qw( :all ) ;

my $err = make_sorter( 'plain', string => [] ) ;
ok( !$err, 'bad extraction code - array ref' ) ;

$err = make_sorter( 'GRT', number => \'foo' ) ;
ok( !$err, 'bad extraction code - scalar ref' ) ;


