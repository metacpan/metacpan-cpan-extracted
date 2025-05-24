#!/usr/bin/env perl -T
use Carp::Always;
use Test::More;
use strict;

require_ok 'Net::RDAP::JSON';

my $test = <<"END";
{
    "string": "This is a test",
    "integer": 42,
    "float": 3.14159265359,
    "bool": false,
    "null": null,
    "array": ["a", "b", "c", "d", "e"]
}
END

my $json = Net::RDAP::JSON::decode_json($test);

is(ref($json), 'HASH');
is(ref($json->{array}), 'ARRAY');

my $encoded = Net::RDAP::JSON::encode_json($json);
ok(length($encoded) > 0);

done_testing;
