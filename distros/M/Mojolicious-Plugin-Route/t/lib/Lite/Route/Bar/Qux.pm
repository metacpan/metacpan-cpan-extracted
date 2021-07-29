package Lite::Route::Bar::Qux;
use Mojo::Base 'MojoX::Route';

sub any {
    my ($self, $r) = @_;

    $r->any(['GET'] => '/qux');
}

1;
