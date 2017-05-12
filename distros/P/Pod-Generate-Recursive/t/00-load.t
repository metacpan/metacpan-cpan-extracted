#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan skip_all => "These tests are for authors only!" 
    unless $ENV{AUTHOR_TESTING} or $ENV{RELEASE_TESTING};

use_ok( 'Pod::Generate::Recursive' ) || print "Bail out!\n";

diag( "Testing Pod::Generate::Recursive $Pod::Generate::Recursive::VERSION, Perl $], $^X" );

done_testing();
