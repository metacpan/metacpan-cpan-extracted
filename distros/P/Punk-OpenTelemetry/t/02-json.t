#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Punk::OpenTelemetry;

BEGIN {
    eval { require File::Raw::JSON; 1 }
        or plan skip_all => 'File::Raw::JSON required for OTLP/JSON';
}
File::Raw::JSON->import('file_json_decode');

*json = \&Punk::OpenTelemetry::Encode::traces_json;
*tree = \&Punk::OpenTelemetry::Encode::traces_json_tree;

# OTLP/JSON. Four rules separate JSON a collector accepts from JSON that only
# looks right, and each of them fails silently: the payload parses, is stored,
# and is empty or wrong. They are asserted against the tree the encoder builds
# rather than against a parsed string, so a failure names the field.

my $PAYLOAD = {
    resource_spans => [ {
        resource    => { attributes => { 'service.name' => 'maat' } },
        schema_url  => 'https://opentelemetry.io/schemas/1.30.0',
        scope_spans => [ {
            scope => { name => 'Punk::OpenTelemetry', version => '0.01' },
            spans => [ {
                trace_id  => '4bf92f3577b34da6a3ce929d0e0e4736',
                span_id   => '00f067aa0ba902b7',
                parent_span_id => 'aaaaaaaaaaaaaaaa',
                name      => 'GET /users/:id',
                kind      => 2,
                start_time_unix_nano => 1_700_000_000_123_456_789,
                end_time_unix_nano   => 1_700_000_000_987_654_321,
                attributes => {
                    'an.int'    => 42,
                    'a.string'  => 'text',
                    'a.true'    => \1,
                    'a.false'   => \0,
                    'a.double'  => 1.5,
                    'a.null'    => undef,
                    'an.array'  => [ 1, 'two' ],
                    'a.map'     => { inner => 'v' },
                },
                events => [ { name => 'e', time_unix_nano => 1_700_000_000_5 } ],
                links  => [ { trace_id => 'b' x 32, span_id => 'c' x 16 } ],
                status => { code => 2, message => 'upstream refused' },
            } ],
        } ],
    } ],
};

my $t  = tree($PAYLOAD);
my $rs = $t->{resourceSpans}[0];
my $sp = $rs->{scopeSpans}[0]{spans}[0];

# ---- rule 1: lowerCamelCase field names ------------------------------------
# snake_case keys parse as a message with every field absent: accepted,
# stored, empty.
{
    ok(exists $t->{resourceSpans},  'resourceSpans, not resource_spans');
    ok(exists $rs->{scopeSpans},    'scopeSpans');
    ok(exists $rs->{schemaUrl},     'schemaUrl');
    ok(exists $sp->{startTimeUnixNano}, 'startTimeUnixNano');
    ok(exists $sp->{endTimeUnixNano},   'endTimeUnixNano');
    ok(exists $sp->{traceId},       'traceId');
    ok(exists $sp->{spanId},        'spanId');
    ok(exists $sp->{parentSpanId},  'parentSpanId');
    ok(!exists $sp->{trace_id},     'and no snake_case key survives');
    ok(!exists $sp->{start_time_unix_nano}, 'nor for the timestamps');
}

# ---- rule 2: ids are hex, never base64 -------------------------------------
{
    is($sp->{traceId}, '4bf92f3577b34da6a3ce929d0e0e4736',
        'traceId is lowercase hex');
    is($sp->{spanId}, '00f067aa0ba902b7', 'spanId is lowercase hex');
    is(length $sp->{traceId}, 32, 'a 16-byte id is 32 hex characters');
    is(length $sp->{spanId},  16, 'an 8-byte id is 16 hex characters');
    like($sp->{traceId}, qr/^[0-9a-f]+$/, 'lowercase, and hex throughout');

    # given raw bytes in, hex out: the SDK holds bytes, a human writes hex,
    # and both have to arrive as the same string
    my $raw = { %$PAYLOAD };
    my $t2 = tree({ resource_spans => [ { scope_spans => [ { spans => [ {
        trace_id => pack('H*', '4bf92f3577b34da6a3ce929d0e0e4736'),
        span_id  => pack('H*', '00f067aa0ba902b7'),
    } ] } ] } ] });
    is($t2->{resourceSpans}[0]{scopeSpans}[0]{spans}[0]{traceId},
       '4bf92f3577b34da6a3ce929d0e0e4736',
       'raw bytes in give the same hex out');
}

# ---- rule 3: 64-bit integers are strings -----------------------------------
# A nanosecond timestamp is ~1.7e18 and loses its last two digits as an IEEE
# double. Not a portability nicety: the timestamp is wrong.
{
    is(ref \$sp->{startTimeUnixNano}, 'SCALAR', 'startTimeUnixNano is a scalar');
    is($sp->{startTimeUnixNano}, '1700000000123456789',
        'and carries every digit');
    is($sp->{endTimeUnixNano}, '1700000000987654321', 'so does the end time');

    my $enc = json($PAYLOAD);
    like($enc, qr/"startTimeUnixNano":"1700000000123456789"/,
        'and it is QUOTED in the JSON, not a number');
    unlike($enc, qr/"startTimeUnixNano":1700000000123456789/,
        'never emitted as a bare number');

    my $back = file_json_decode($enc);
    is($back->{resourceSpans}[0]{scopeSpans}[0]{spans}[0]{startTimeUnixNano},
       '1700000000123456789',
       'and survives a decode with every digit intact');
}

# ---- rule 4: enums are names -----------------------------------------------
{
    is($sp->{kind}, 'SPAN_KIND_SERVER', 'kind is the enum NAME');
    is($sp->{status}{code}, 'STATUS_CODE_ERROR', 'status code is the name');

    for my $c ([0,'SPAN_KIND_UNSPECIFIED'],[1,'SPAN_KIND_INTERNAL'],
               [2,'SPAN_KIND_SERVER'],[3,'SPAN_KIND_CLIENT'],
               [4,'SPAN_KIND_PRODUCER'],[5,'SPAN_KIND_CONSUMER']) {
        my $tt = tree({ resource_spans => [ { scope_spans => [ {
            spans => [ { kind => $c->[0] } ] } ] } ] });
        is($tt->{resourceSpans}[0]{scopeSpans}[0]{spans}[0]{kind}, $c->[1],
            "kind $c->[0] is $c->[1]");
    }
    for my $c ([0,'STATUS_CODE_UNSET'],[1,'STATUS_CODE_OK'],
               [2,'STATUS_CODE_ERROR']) {
        my $tt = tree({ resource_spans => [ { scope_spans => [ {
            spans => [ { status => { code => $c->[0] } } ] } ] } ] });
        is($tt->{resourceSpans}[0]{scopeSpans}[0]{spans}[0]{status}{code},
            $c->[1], "status $c->[0] is $c->[1]");
    }
}

# ---- AnyValue rendering ----------------------------------------------------
{
    my %a = map { $_->{key} => $_->{value} } @{ $sp->{attributes} };

    is($a{'a.string'}{stringValue}, 'text', 'a string is stringValue');
    is($a{'an.int'}{intValue}, '42',
        'an int is intValue AND a string: it is an int64 in the schema');
    is($a{'a.double'}{doubleValue}, 1.5, 'a double stays a JSON number');
    is_deeply($a{'a.null'}, {}, 'undef is an empty value, not an empty string');

    is(ref $a{'a.true'}{boolValue}, 'SCALAR', 'a bool is the JSON-bool ref');
    is(${ $a{'a.true'}{boolValue} }, 1, 'true');
    is(${ $a{'a.false'}{boolValue} }, 0, 'false');
    like(json($PAYLOAD), qr/"boolValue":true/, 'and serialises as true');
    like(json($PAYLOAD), qr/"boolValue":false/, 'and as false');

    is(scalar @{ $a{'an.array'}{arrayValue}{values} }, 2, 'an array has values');
    is($a{'an.array'}{arrayValue}{values}[0]{intValue}, '1', 'the int in it');
    is($a{'an.array'}{arrayValue}{values}[1]{stringValue}, 'two', 'the string');
    is($a{'a.map'}{kvlistValue}{values}[0]{key}, 'inner', 'a map has a key');
    is($a{'a.map'}{kvlistValue}{values}[0]{value}{stringValue}, 'v', 'and value');
}

# ---- the two encoders agree about what a value IS ---------------------------
# One classifier, two renderings. If these ever disagree, a value arrives as
# an int over one transport and a string over the other, and nobody finds out
# until a dashboard filter stops matching.
{
    my @cases = (
        [ 42,      'intValue'    ],
        [ 'text',  'stringValue' ],
        [ 1.5,     'doubleValue' ],
        [ \1,      'boolValue'   ],
        [ [1],     'arrayValue'  ],
        [ {a=>1},  'kvlistValue' ],
        [ sub {1}, 'stringValue' ],   # a coderef stringifies in BOTH
        [ qr/x/,   'stringValue' ],
    );
    # protobuf oneof field number -> the JSON key it must correspond to
    my %pb_to_json = (1 => 'stringValue', 2 => 'boolValue', 3 => 'intValue',
                      4 => 'doubleValue', 5 => 'arrayValue', 6 => 'kvlistValue');
    require OTelWire;
    for my $c (@cases) {
        my ($val, $want) = @$c;
        my $m = OTelWire::pb_parse(
            Punk::OpenTelemetry::Encode::_anyvalue($val));
        my ($field) = sort { $a <=> $b } keys %$m;
        my $tt = tree({ resource_spans => [ { scope_spans => [ { spans => [
            { attributes => { k => $val } } ] } ] } ] });
        my $jkey = (keys %{ $tt->{resourceSpans}[0]{scopeSpans}[0]{spans}[0]
                              {attributes}[0]{value} })[0];
        is($jkey, $want, "JSON renders it as $want");
        is($pb_to_json{$field}, $want,
            "and protobuf agrees: field $field is the same type");
    }

    # a scalar with both a string and a numeric form is a string in both
    my $dual = "3"; my $ignore = $dual + 0;
    my $m = OTelWire::pb_parse(Punk::OpenTelemetry::Encode::_anyvalue($dual));
    is((sort { $a <=> $b } keys %$m)[0], 1, 'protobuf: a dual scalar is a string');
    my $tt = tree({ resource_spans => [ { scope_spans => [ { spans => [
        { attributes => { k => $dual } } ] } ] } ] });
    ok(exists $tt->{resourceSpans}[0]{scopeSpans}[0]{spans}[0]
                {attributes}[0]{value}{stringValue},
        'and JSON agrees');
}

# ---- structure -------------------------------------------------------------
{
    is($rs->{resource}{attributes}[0]{key}, 'service.name', 'resource attrs');
    is($rs->{schemaUrl}, 'https://opentelemetry.io/schemas/1.30.0', 'schemaUrl');
    is($rs->{scopeSpans}[0]{scope}{name}, 'Punk::OpenTelemetry', 'scope name');
    is($sp->{events}[0]{name}, 'e', 'the event');
    is($sp->{links}[0]{traceId}, 'b' x 32, 'the link trace id, in hex');
    is($sp->{status}{message}, 'upstream refused', 'the status message');
    is($sp->{name}, 'GET /users/:id', 'the span name');

    # attributes are sorted, same as the protobuf side, so the bytes are
    # reproducible on both transports
    my @keys = map { $_->{key} } @{ $sp->{attributes} };
    is_deeply(\@keys, [ sort @keys ], 'attributes are sorted by key');
}

# ---- it is valid JSON ------------------------------------------------------
{
    my $enc = json($PAYLOAD);
    my $back = eval { file_json_decode($enc) };
    ok($back, 'the output decodes as JSON') or diag $@;
    is(ref $back->{resourceSpans}, 'ARRAY', 'with the expected top-level shape');
    is(json($PAYLOAD), json($PAYLOAD), 'and is reproducible');
}

done_testing;
