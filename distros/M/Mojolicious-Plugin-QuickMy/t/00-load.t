#!/usr/bin/env perl
 
use Test::More tests => 1;
 
BEGIN {
    use_ok( 'Mojolicious::Plugin::QuickMy' ) || print "Bail out!
";
}
 
diag( "Testing Mojolicious::Plugin::QuickMy $Mojolicious::Plugin::QuickMy::VERSION, Perl $], $^X" );