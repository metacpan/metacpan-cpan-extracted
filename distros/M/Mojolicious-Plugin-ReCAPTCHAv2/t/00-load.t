#!perl -T
# vim:syntax=perl:tabstop=4:number:noexpandtab:

use Test::More tests => 1;

BEGIN {
	use_ok('Mojolicious::Plugin::ReCAPTCHAv2') || print "Bail out!";
}

diag( "Testing Mojolicious::Plugin::ReCAPTCHAv2 $Mojolicious::Plugin::ReCAPTCHAv2::VERSION, Perl $], $^X" );
