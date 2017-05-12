#!/usr/bin/perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Mojolicious::Plugin::Bcrypt' ) || print "Bail out!
";
}

diag( "Testing Mojolicious::Plugin::Bcrypt $Mojolicious::Plugin::Bcrypt::VERSION, Perl $], $^X" );
