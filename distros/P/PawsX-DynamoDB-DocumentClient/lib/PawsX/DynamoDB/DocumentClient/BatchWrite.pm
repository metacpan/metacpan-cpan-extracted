package PawsX::DynamoDB::DocumentClient::BatchWrite;

use strict;
use 5.008_005;

use Net::Amazon::DynamoDB::Marshaler;
use PawsX::DynamoDB::DocumentClient::Util qw(
    make_assert_arrayref
    make_assert_hashref
    unmarshal_attribute_map
);

my $METHOD_NAME = 'batch_write()';
my $ASSERT_HASHREF = make_assert_hashref($METHOD_NAME);
my $ASSERT_ARRAYREF = make_assert_arrayref($METHOD_NAME);

sub transform_arguments {
    my $class = shift;
    my %args = @_;
    return (
        %args,
        RequestItems => _marshall_request_items($args{RequestItems}),
    );
}

sub transform_output {
    my ($class, $output) = @_;
    my $tables = $output->UnprocessedItems->Map;
    return undef unless %$tables;
    return {
        map { $_ => _unmarshall_requests($tables->{$_}) }
        keys %$tables
    };
}

sub run_service_command {
    my ($class, $service, %args) = @_;
    return $service->BatchWriteItem(%args);
}

sub _marshall_request_items {
    my ($tables) = @_;
    $ASSERT_HASHREF->('RequestItems', $tables);
    return {
        map { $_ => _marshall_request_items_list($tables->{$_}) }
        keys %$tables
    };
}

sub _marshall_request_items_list {
    my ($requests) = @_;
    $ASSERT_ARRAYREF->('RequestItems value', $requests);
    return [ map { _marshall_request($_) } @$requests ];
}

sub _marshall_request {
    my ($request) = @_;
    $ASSERT_HASHREF->('write request', $request);
    my $put_request = $request->{PutRequest};
    my $delete_request = $request->{DeleteRequest};

    die "$METHOD_NAME: write request missing PutRequest or DeleteRequest"
        unless ($put_request || $delete_request);

    return _marshall_put_request($put_request) if $put_request;
    return _marshall_delete_request($delete_request);
}

sub _marshall_put_request {
    my ($val) = @_;
    $ASSERT_HASHREF->('PutRequest', $val);
    my $item = $val->{Item};
    die "$METHOD_NAME: PutRequest must contain Item" unless $item;
    $ASSERT_HASHREF->(q|PutRequest's Item|, $item);
    return {
        PutRequest => {
            Item => dynamodb_marshal($item),
        },
    };
}

sub _marshall_delete_request {
    my ($val) = @_;
    $ASSERT_HASHREF->(q|DeleteRequest|, $val);
    my $key = $val->{Key};
    die "$METHOD_NAME: DeleteRequest must contain Key" unless $key;
    $ASSERT_HASHREF->(q|DeleteRequest's Key|, $key);
    return {
        DeleteRequest => {
            Key => dynamodb_marshal($key),
        },
    };
}

sub _unmarshall_requests {
    my ($requests) = @_;
    return [ map { _unmarshall_request($_) } @$requests ];
}

sub _unmarshall_request {
    my ($request) = @_;
    return $request->PutRequest
        ? _unmarshall_put_request($request->PutRequest)
        : _unmarshall_delete_request($request->DeleteRequest);
}

sub _unmarshall_put_request {
    my ($request) = @_;
    return {
        PutRequest => {
            Item => unmarshal_attribute_map($request->Item),
        },
    };
}

sub _unmarshall_delete_request {
    my ($request) = @_;
    return {
        DeleteRequest => {
            Key => unmarshal_attribute_map($request->Key),
        },
    };
}

1;
__END__
