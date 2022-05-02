package Lite::Route::QuxA;
use Mojo::Base 'Lite::Route::Qux';

sub route {
    my ($self, $qux) = @_;

    $qux->get('/a' => sub {
        shift->render(text => 'Qux::A');
    });
}

1;
