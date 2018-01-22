#!perl -T
use strict;
use warnings;
use Test::More;

plan tests => 4;

BEGIN {
    use_ok( 'Mojolicious::Plugin::SessionStorage' ) || print "Bail out!\n";
    use_ok( 'Mojolicious::Sessions::Storage' ) || print "Bail out!\n";
    use_ok( 'Mojolicious::Service::SesssionFile' ) || print "Bail out!\n";
    use_ok( 'Mojolicious::Sessions::Storage::Memory' ) || print "Bail out!\n";
}

diag( "Testing Mojolicious::Plugin::SessionStorage $Mojolicious::Plugin::SessionStorage::VERSION, Perl $], $^X" );
