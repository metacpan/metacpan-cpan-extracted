package Net::Fluidinfo::Value::Float;
use Moose;
extends 'Net::Fluidinfo::Value::Native';

# This serializer tries to send the best representation of the value, and let's
# Perl choose whether that's scientific notation or not.
#
# Fluidinfo handles integers and floats differently, care in serialisation is needed.
# For example if you tag object X with tag T and serialised value "5", then X won't
# be returned in a query for objects tagged with T with value less than "10.0".
# Reason is Fluidinfo interprets the type of the value serialised as "5" to be integer,
# and it won't pick it as float unless you serialise it explicitly as such: "5.0".
sub to_json {
    my $self  = shift;
    no warnings; # value may not be a number
    my $float = 0 + $self->value; # ensure we get a number
    my $e     = sprintf "%g", $float;
    index($e, 'e') != -1 ? $e : index($float, '.') != -1 ? "$float" : "$float.0";
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
