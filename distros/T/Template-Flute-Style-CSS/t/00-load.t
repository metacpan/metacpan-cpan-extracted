#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Template::Flute::Style::CSS' ) || print "Bail out!
";
}

diag( "Testing Template::Flute::Style::CSS $Template::Flute::Style::CSS::VERSION, Perl $], $^X" );
