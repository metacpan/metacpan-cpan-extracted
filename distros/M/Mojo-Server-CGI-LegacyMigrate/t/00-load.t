#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mojo::Server::CGI::LegacyMigrate' ) || print "Bail out!\n";
}

diag( "Testing Mojo::Server::CGI::LegacyMigrate $Mojo::Server::CGI::LegacyMigrate::VERSION, Perl $], $^X" );
