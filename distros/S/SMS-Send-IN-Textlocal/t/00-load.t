#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'SMS::Send::IN::Textlocal' ) || print "Bail out!\n";
}

diag( "Testing SMS::Send::IN::Textlocal $SMS::Send::IN::Textlocal::VERSION, Perl $], $^X" );
