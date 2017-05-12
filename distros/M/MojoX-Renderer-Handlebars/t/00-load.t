#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'MojoX::Renderer::Handlebars' ) || print "Bail out!\n";
    use_ok( 'Mojolicious::Plugin::HandlebarsRenderer' ) || print "Bail out!\n";
}

diag( "Testing MojoX::Renderer::Handlebars $MojoX::Renderer::Handlebars::VERSION, Perl $], $^X" );
diag( "Testing Mojolicious::Plugin::HandlebarsRenderer $Mojolicious::Plugin::HandlebarsRenderer::VERSION, Perl $], $^X" );
