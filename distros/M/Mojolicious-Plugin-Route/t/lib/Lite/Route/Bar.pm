package Lite::Route::Bar;
use Mojo::Base 'MojoX::Route';

sub any {
    my ($self, $r) = @_;

    $r->any(['GET'] => '/bar');
}

1;
