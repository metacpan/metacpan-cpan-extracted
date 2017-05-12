use 5.006;
use strict;
use warnings;
use Test::More;
 
plan tests => 1;
 
BEGIN {
    use_ok( 'Net::Twitter::Loader' ) || print "Bail out!\n";
}
 
diag( "Testing Net::Twitter::Loader $Net::Twitter::Loader::VERSION, Perl $], $^X" );
