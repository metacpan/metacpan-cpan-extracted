#!/usr/bin/env perl

use Test::More;
use Test::Mojo;

use File::Basename;
use File::Spec;
use Mojolicious::Lite;
use MojoX::Renderer::HTC;

my $renderer = MojoX::Renderer::HTC->build( default_escape => 'HTML', path => File::Spec->catdir( dirname(__FILE__), 'renderer_t' ) );
app->renderer->add_handler( tmpl => $renderer );

my $plain_renderer = MojoX::Renderer::HTC->build( path => File::Spec->catdir( dirname(__FILE__), 'renderer_t' ));
app->renderer->add_handler( htc => $plain_renderer );

get '/' => sub {
    shift->render( 'index', test => '<test>', handler => 'tmpl' );
};

get '/plain' => sub {
    shift->render( test => '<test>', handler => 'htc' );
};

my $t = Test::Mojo->new();

$t->get_ok( '/' )->status_is( 200 )->content_is( "&lt;test&gt;\n" );
$t->get_ok( '/plain' )->status_is( 200 )->content_is( "<test>\n" );

done_testing();
