#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Mojolicious::Plugin::Captcha::reCAPTCHA' ) || print "Bail out!";
}

diag( "Testing Mojolicious::Plugin::Captcha::reCAPTCHA $Mojolicious::Plugin::Captcha::reCAPTCHA::VERSION, Perl $], $^X" );
