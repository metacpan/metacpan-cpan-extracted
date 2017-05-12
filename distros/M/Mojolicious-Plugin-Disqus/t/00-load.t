#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Mojolicious::Plugin::Disqus' ) || print "Bail out!
";
}

diag( "Testing Mojolicious::Plugin::Disqus $Mojolicious::Plugin::Disqus::VERSION, Perl $], $^X" );
