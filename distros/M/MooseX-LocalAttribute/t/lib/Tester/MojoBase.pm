package Tester::MojoBase;
use Mojo::Base -base;

has hashref => sub { return { key => 'value' } };
has string  => 'string';

sub change_hashref {
    my ( $self, $key, $val ) = @_;

    $self->hashref->{$key} = $val;
}

1;
