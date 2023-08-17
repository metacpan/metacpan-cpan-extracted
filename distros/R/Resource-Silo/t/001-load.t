#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

eval {
    require Resource::Silo;
    Resource::Silo->import();
    resource( foo => sub { 1 } );
    is silo()->foo, 1, "dumb resource defn worked";
    diag( "Testing Resource::Silo $Resource::Silo::VERSION, Perl $], $^X" );
    done_testing;
    1;
} || do {
    diag "Resource::Silo import failed: $@";
    print "Bail out!\n";
    exit 1;
};

