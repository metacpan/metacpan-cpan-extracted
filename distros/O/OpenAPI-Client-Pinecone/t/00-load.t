#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'OpenAPI::Client::Pinecone' ) || print "Bail out!\n";
}

diag( "Testing OpenAPI::Client::Pinecone $OpenAPI::Client::Pinecone::VERSION, Perl $], $^X" );
