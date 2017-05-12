package Net::Fluidinfo::Value::Boolean;
use Moose;
extends 'Net::Fluidinfo::Value::Native';

sub to_json {
    my $self = shift;
    $self->value ? 'true' : 'false';
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
