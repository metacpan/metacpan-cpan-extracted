package Net::Fluidinfo::Value::Null;
use Moose;
extends 'Net::Fluidinfo::Value::Native';

sub value {
    undef;
}

sub to_json {
    'null';
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
