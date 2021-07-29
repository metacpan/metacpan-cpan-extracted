package Lite::Route::Baz;
use Mojo::Base 'MojoX::Route';

sub under {
    my ($self, $r) = @_;

    $r->under('/baz');
}

1;
