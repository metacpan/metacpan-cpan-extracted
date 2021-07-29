package Lite::Route::Foo;
use Mojo::Base 'MojoX::Route';

sub route {
    my ($self, $r) = @_;

    $r->get('/foo' => sub {
        shift->render(text => 'Foo');
    });
}

1;
