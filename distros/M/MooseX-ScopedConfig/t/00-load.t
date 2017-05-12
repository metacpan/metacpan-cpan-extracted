#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'MooseX::ScopedConfig' ) || print "Bail out!\n";
}

diag( "Testing MooseX::ScopedConfig $MooseX::ScopedConfig::VERSION, Perl $], $^X" );
