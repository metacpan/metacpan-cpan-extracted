#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Template::Plugin::GoogleLaTeX' ) || print "Bail out!
";
}

diag( "Testing Template::Plugin::GoogleLaTeX $Template::Plugin::GoogleLaTeX::VERSION, Perl $], $^X" );
