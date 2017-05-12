package Net::Fluidinfo::Value::Integer;
use Moose;
extends 'Net::Fluidinfo::Value::Native';

# A Perl integer is a JSON integer. Sanitize with int().
sub to_json {
    my $self = shift;
    no warnings; # the value may not be an integer indeed
    int $self->value;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
