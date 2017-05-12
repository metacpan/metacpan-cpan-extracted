package Net::Fluidinfo::Value::ListOfStrings;
use Moose;
extends 'Net::Fluidinfo::Value::Native';

sub to_json {
    my $self = shift;
    my @strings = map $self->json->encode("$_"), @{$self->value};
    '[' . join(',', @strings) . ']';
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
