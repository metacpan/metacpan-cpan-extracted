package Mojolicious::Plugin::CanonicalURL::Tester::MyTextApp;
use Mojo::Base 'Mojolicious';

sub startup {
    my ($self) = @_;

    my $r = $self->routes;

    $r->get('/' => {text => 'index'});
    $r->get('/foo' => {text => 'foo'});
    $r->get('/bar' => {text => 'bar'});
    $r->get('/baz' => {text => 'baz'});
    $r->get('/qux' => {text => 'qux'});
    $r->get('/text' => {text => 'text'});
}

1;
