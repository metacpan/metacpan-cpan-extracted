#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Mojolicious::Plugin::MozPersona' ) || print "Bail out!";
}

diag( "Testing Mojolicious::Plugin::MozPersona $Mojolicious::Plugin::MozPersona::VERSION, Perl $], $^X" );
