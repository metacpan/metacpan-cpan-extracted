#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Plack::Middleware::Debug::Dancer::TemplateTimer' ) || print "Bail out!\n";
}

diag( "Testing Plack::Middleware::Debug::Dancer::TemplateTimer $Plack::Middleware::Debug::Dancer::TemplateTimer::VERSION, Perl $], $^X" );
