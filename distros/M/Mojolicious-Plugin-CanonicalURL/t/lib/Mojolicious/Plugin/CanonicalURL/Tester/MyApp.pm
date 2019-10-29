package Mojolicious::Plugin::CanonicalURL::Tester::MyApp;
use Mojo::Base 'Mojolicious';

sub startup {
    my ($self) = @_;

    my $r = $self->routes;

    $r->get('/' => sub { shift->render(text => 'index'); });
    $r->get('/foo' => sub { shift->render(text => 'foo'); });
    $r->get('/bar' => sub { shift->render(text => 'bar'); });
    $r->get('/baz' => sub { shift->render(text => 'baz'); });
    $r->get('/qux' => sub { shift->render(text => 'qux'); });
    $r->get('/text/' => {text => 'text'});
}

1;
