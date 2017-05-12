package Foo;
use Moose;
with 'MooseX::Role::MissingMethodUtils';

sub method_missing {
    my ($self, $method_name, @params) = @_;

    if ( $method_name eq 'foobar' )
    {
        return 1 unless scalar @params;
    }

    if ( $method_name eq 'foobar2' )
    {
        return 1 if $params[0] eq 'test';
    }

    return;
}

sub responds_to {
    my ( $self, $method_name ) = @_;

    if ( $method_name eq 'foobar3' ) {
        return sub { return 'foobar_3' };
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
