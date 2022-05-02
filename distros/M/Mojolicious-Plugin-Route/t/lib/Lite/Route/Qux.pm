package Lite::Route::Qux;
use Mojo::Base 'MojoX::Route';

sub under {
    my ($self, $r) = @_;

    $r->under('/qux');
}

1;
