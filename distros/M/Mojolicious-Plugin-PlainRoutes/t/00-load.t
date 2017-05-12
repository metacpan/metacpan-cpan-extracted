#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('Mojolicious::Plugin::PlainRoutes') || print "Bail out!\n";
}

diag(
	"Testing Mojolicious::Plugin::PlainRoutes "
	. " $Mojolicious::Plugin::PlainRoutes::VERSION, Perl $], $^X"
);
