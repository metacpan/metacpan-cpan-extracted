#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Module::Starter::Protobuf' ) || print "Bail out!\n";
}

diag( "Testing Module::Starter::Protobuf $Module::Starter::Protobuf::VERSION, Perl $], $^X" );
