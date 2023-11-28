#!/usr/bin/env perl

use Test2::Require::Module 'Google::ProtocolBuffers::Dynamic';
use Test2::V0 -target => 'OpenTelemetry::Proto';
use JSON::PP;

my $resource = OpenTelemetry::Proto::Resource::V1::Resource->new_and_check({
    attributes => [
        {
            key   => 'int',
            value => { int_value => 123 },
        },
        {
            key   => 'string',
            value => { string_value => 'foo' },
        },
        {
            key   => 'empty',
            value => {},
        },
    ],
    dropped_attributes_count => 12,
});

is $resource, object {
    prop isa => 'OpenTelemetry::Proto::Resource::V1::Resource';
}, 'Construct resource object';

is decode_json( $resource->encode_json ), {
    attributes => [
        {
            key   => 'int',
            value => { intValue => 123 },
        },
        {
            key   => 'string',
            value => { stringValue => 'foo' },
        },
        {
            key   => 'empty',
            value => {},
        },
    ],
    droppedAttributesCount => 12,
}, 'JSON roundtrip';

done_testing;
