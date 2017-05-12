#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Mojolicious::Plugin::Mason1Renderer' ) || print "Bail out!
";
}

diag( "Testing Mojolicious::Plugin::Mason1Renderer $Mojolicious::Plugin::Mason1Renderer::VERSION, Perl $], $^X" );
