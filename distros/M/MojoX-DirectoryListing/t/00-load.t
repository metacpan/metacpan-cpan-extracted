#!perl -T
use 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'MojoX::DirectoryListing' ) || print "Bail out!\n";
}

diag( "Testing MojoX::DirectoryListing $MojoX::DirectoryListing::VERSION, Perl $], $^X" );


