package Orochi::Injection::Setter;
use Moose;
use namespace::clean -except => qw(meta);

extends 'Orochi::Injection::Constructor';

has setter_params => (
    is => 'ro',
    isa => 'HashRef',
    required => 1
);

sub post_expand {
    my ($self, $c, $object) = @_;

    my $params = $self->setter_params;
    $self->expand_all_injections( $c, $params );

    while (my ($attr, $value) = each %$params ) {
        if (Orochi::DEBUG()) {
            print STDERR " + Setting $attr to $value on $object\n";
        }
        $object->$attr($value);
    }
    $object;
};


__PACKAGE__->meta->make_immutable();

1;