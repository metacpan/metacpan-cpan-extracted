#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('Mojolicious::Plugin::CountryDropDown') || print "Bail out!";
}

diag( "Testing Mojolicious::Plugin::CountryDropDown $Mojolicious::Plugin::CountryDropDown::VERSION, Perl $], $^X" );
