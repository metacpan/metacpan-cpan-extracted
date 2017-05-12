#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'MooseX::Getopt::Usage' ) || print "Bail out!
";
    use_ok( 'MooseX::Getopt::Usage::Formatter' );
}

diag( "Testing MooseX::Getopt::Usage $MooseX::Getopt::Usage::VERSION, Perl $], $^X" );
