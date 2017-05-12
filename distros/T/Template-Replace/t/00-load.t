#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Template::Replace' ) || print "Bail out!
";
}

diag( "Testing Template::Replace $Template::Replace::VERSION, Perl $], $^X" );
