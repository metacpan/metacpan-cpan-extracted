#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Object::New' ) || print "Bail out!
";
}

diag( "Testing Object::New $Object::New::VERSION, Perl $], $^X" );
