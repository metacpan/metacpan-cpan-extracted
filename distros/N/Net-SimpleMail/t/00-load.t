#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::SimpleMail' ) || print "Bail out!\n";
}

diag( "Testing Net::SimpleMail $Net::SimpleMail::VERSION, Perl $], $^X" );
