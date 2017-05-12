#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Mojolicious::Plugin::SassRenderer' ) || print "Bail out!
";
}

diag( "Testing Mojolicious::Plugin::SassRenderer $Mojolicious::Plugin::SassRenderer::VERSION, Perl $], $^X" );
