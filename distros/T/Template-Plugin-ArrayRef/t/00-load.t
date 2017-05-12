#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Template::Plugin::ArrayRef' ) || print "Bail out!\n";
}

diag( "Testing Template::Plugin::ArrayRef $Template::Plugin::ArrayRef::VERSION, Perl $], $^X" );
