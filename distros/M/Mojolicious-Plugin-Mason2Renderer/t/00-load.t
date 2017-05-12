#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Mojolicious::Plugin::Mason2Renderer' ) || print "Bail out!
";
}

diag( "Testing Mojolicious::Plugin::Mason2Renderer $Mojolicious::Plugin::Mason2Renderer::VERSION, Perl $], $^X" );
