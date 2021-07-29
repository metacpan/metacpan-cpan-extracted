package Lite::Route::Baz::A;
use Mojo::Base 'MojoX::Route';

sub route {
    my ($self, $r) = @_;

    $r->get('/a' => sub {
        shift->render(text => 'Baz::A');
    });
}

1;
