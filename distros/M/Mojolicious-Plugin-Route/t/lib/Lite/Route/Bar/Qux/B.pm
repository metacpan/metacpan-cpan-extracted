package Lite::Route::Bar::Qux::B;
use Mojo::Base 'MojoX::Route';

sub route {
    my ($self, $qux, $r) = @_;

    $qux->get('/b' => sub {
        shift->render(text => 'Bar::Qux::B');
    });
    
    $r->get('/b' => sub {
        shift->render(text => 'B');
    });
}

1;
