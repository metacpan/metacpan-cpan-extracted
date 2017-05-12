package TestDynamoDB;
# ABSTRACT: mocked version of Amazon::DynamoDB

use Amazon::DynamoDB::Types;
use Clone 'clone';
use Future;
use Kavorka qw(-default classmethod);
use Moose;
use MooseX::ClassAttribute;
use Type::Registry;
use namespace::autoclean;

BEGIN {
    my $reg = "Type::Registry"->for_me;
    $reg->add_types(-Standard);
    $reg->add_types("Amazon::DynamoDB::Types");
};

class_has '_tables' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub {{}},
    traits  => ['Hash'],
    handles   => {
        delete_table      => 'delete',
        delete_all_tables => 'clear',
        _get_table        => 'get',
        _set_table        => 'set',
    },
);

classmethod create_table (Str :$table_name!, Str :$key_name!) {
    $class->_set_table($table_name, { key_name => $key_name, entries => {} });
}

method put_item (ConditionalOperatorType :$ConditionalOperator,
                 Str :$ConditionExpression,
                 ItemType :$Item!,
                 ExpectedType :$Expected,
                 ExpressionAttributeValuesType :$ExpressionAttributeValues,
                 ReturnConsumedCapacityType :$ReturnConsumedCapacity,
                 ReturnItemCollectionMetricsType :$ReturnItemCollectionMetrics,
                 ReturnValuesType :$ReturnValues,
                 TableNameType :$TableName!) {
    my $table = $self->_get_table($TableName);
    my $key_name = $table->{key_name};
    my $key = $Item->{$key_name} or die "$key_name missing";
    $table->{entries}{$key} = clone($Item);
    return Future->done;
}

method get_item(CodeRef $code,
                AttributesToGetType :$AttributesToGet,
                StringBooleanType :$ConsistentRead,
                KeyType :$Key!,
                ReturnConsumedCapacityType :$ReturnConsumedCapacity,
                TableNameType :$TableName!) {
    my $table = $self->_get_table($TableName);
    my $key_name = $table->{key_name};
    my $key_value = $Key->{$key_name};
    my $item = $table->{entries}{$key_value};
    return Future->done($code->($item));
}

__PACKAGE__->meta()->make_immutable();

1;
__END__
