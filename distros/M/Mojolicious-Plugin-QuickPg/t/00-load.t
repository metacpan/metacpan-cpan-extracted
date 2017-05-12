#!/usr/bin/env perl
 
use Test::More tests => 1;
 
BEGIN {
    use_ok( 'Mojolicious::Plugin::QuickPg' ) || print "Bail out!
";
}
 
diag( "Testing Mojolicious::Plugin::QuickPg $Mojolicious::Plugin::QuickPg::VERSION, Perl $], $^X" );