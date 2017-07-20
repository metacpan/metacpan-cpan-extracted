package PawsX::DynamoDB::DocumentClient::QueryOrScan;

use strict;
use 5.008_005;

use PawsX::DynamoDB::DocumentClient::Util qw(
    make_arg_transformer
    unmarshal_attribute_map
);
use PerlX::Maybe;

sub to_marshall { ['ExpressionAttributeValues', 'ExclusiveStartKey'] }

sub transform_output {
    my ($class, $output) = @_;
    return {
        count => $output->Count,
        items => _unmarshall_items($output->Items),
        maybe last_evaluated_key => _unmarshall_key($output->LastEvaluatedKey),
    };
}

sub _unmarshall_items {
    my ($items) = @_;
    return [ map { unmarshal_attribute_map($_) } @$items ];
}

sub _unmarshall_key {
    my ($key) = @_;
    return undef unless $key && %{ $key->Map };
    return unmarshal_attribute_map($key);
}

1;
__END__
