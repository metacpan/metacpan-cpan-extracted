package Lite::Route::Baz::A;
use Mojo::Base 'MojoX::Route';

sub under {
    my ($self, $baz) = @_;
    
    $baz->under('/a');
}

sub route {
    my ($self, $a, $baz) = @_;

    $baz->get('/a' => sub {
        shift->render(text => 'Baz::A');
    });
    
    $a->get('/new' => sub {
        shift->render(text => 'Baz::A->new');
    })
}

1;
