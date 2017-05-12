#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Template::Flute::PDF' ) || print "Bail out!
";
}

diag( "Testing Template::Flute::PDF $Template::Flute::PDF::VERSION, Perl $], $^X" );
