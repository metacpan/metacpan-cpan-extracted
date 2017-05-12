#!perl

use Mojo::Base -strict;
use lib qw(lib);

use Test::More tests => 6;
use Test::Mojo;

{
    package MyApp;
    use Mojo::Base 'Mojolicious';

    sub startup {
        my ($self) = @_;
        $self->log->level( $ENV{MOJO_LOG_LEVEL} = 'warn' );
        $self->plugin('ContextResources');

        $self->routes->get("/stylesheet")->to('foo#unknow1');
        $self->routes->get("/javascript")->to('foo#unknow2');
    }
    1;
}

{
    package MyApp::Controller::Foo;
    use Mojo::Base 'Mojolicious::Controller';

    sub unknow1 {
        my ($self) = @_;
        my $url = $self->url_context_stylesheet // '';
        return $self->render(text => "$url");
    }
    sub unknow2 {
        my ($self) = @_;
        my $url = $self->url_context_javascript // '';
        return $self->render(text => "$url");
    }

    1;
}

my $t = Test::Mojo->new('MyApp');
$t  ->get_ok('/stylesheet')
    ->status_is(200)
    ->content_is('')
;

$t  ->get_ok('/javascript')
    ->status_is(200)
    ->content_is('')
;
