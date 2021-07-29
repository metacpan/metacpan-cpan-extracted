package Lite::Route::Bar::Qux::B;
use Mojo::Base 'MojoX::Route';

sub route {
    my ($self, $r) = @_;

    $r->get('/b' => sub {
        shift->render(text => 'Bar::Qux::B');
    });
}

1;
