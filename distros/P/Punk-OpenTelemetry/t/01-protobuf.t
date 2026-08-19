#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use OTelWire qw(pb_parse pb_field pb_fields pb_str pb_varint_of);
use Punk::OpenTelemetry;

*_varint      = \&Punk::OpenTelemetry::Encode::_varint;
*_varint_size = \&Punk::OpenTelemetry::Encode::_varint_size;
*_anyvalue    = \&Punk::OpenTelemetry::Encode::_anyvalue;
*pb           = \&Punk::OpenTelemetry::Encode::traces_protobuf;
*pb_size      = \&Punk::OpenTelemetry::Encode::traces_protobuf_size;

# The protobuf writer. Everything here is checked against either a published
# encoding or the independent reader in t/lib/OTelWire.pm, which was written
# from the wire spec and shares no code with the encoder - a reader built out
# of the encoder's own tables would agree with the encoder's own bugs.

# ---- varints: the one thing every level inherits ---------------------------
{
    my @vec = (
        [ 0,          '00'     ],
        [ 1,          '01'     ],
        [ 127,        '7f'     ],
        [ 128,        '8001'   ],
        [ 150,        '9601'   ],   # the canonical example from the spec
        [ 300,        'ac02'   ],
        [ 16383,      'ff7f'   ],
        [ 16384,      '808001' ],
        [ 2**31,      '8080808008' ],
    );
    for my $v (@vec) {
        my ($n, $hex) = @$v;
        is(unpack('H*', _varint($n)), $hex, "varint($n) is $hex");
        is(_varint_size($n), length($hex) / 2, "varint($n) size agrees");
    }
    is(unpack('H*', _varint(2**32 + 1)), unpack('H*', pb_varint_of(2**32 + 1)),
        'a value over 32 bits matches an independent encoder');
}

# ---- AnyValue over every Perl scalar shape ---------------------------------
# The oneof field numbers: 1 string, 2 bool, 3 int, 4 double, 5 array,
# 6 kvlist. An empty encoding means "nothing set", which is how a null
# attribute is spelled - and is NOT the same as an empty string.
{
    sub anyfield {
        my ($sv) = @_;
        my $m = pb_parse(_anyvalue($sv));
        my @f = sort { $a <=> $b } keys %$m;
        return @f ? $f[0] : undef;
    }

    is(anyfield(undef), undef, 'undef sets no AnyValue field at all');
    is(length(_anyvalue(undef)), 0, 'and encodes to zero bytes');

    is(anyfield('hello'), 1, 'a string is stringValue');
    is(anyfield(\1), 2, 'a \\1 ref is boolValue');
    is(anyfield(\0), 2, 'and so is \\0');
    is(anyfield(42), 3, 'an integer is intValue');
    is(anyfield(1.5), 4, 'a float is doubleValue');
    is(anyfield([1, 2]), 5, 'an arrayref is arrayValue');
    is(anyfield({ a => 1 }), 6, 'a hashref is kvlistValue');

    # a scalar that is both a number and a string is a STRING: it has been
    # used as text, and guessing it into an int turns an id into a number
    my $dual = "3"; my $ignore = $dual + 0;
    is(anyfield($dual), 1, 'a scalar with a string form stays a string');

    # the values themselves
    my $m = pb_parse(_anyvalue('hello'));
    is(pb_field($m, 1), 'hello', 'stringValue carries the string');
    $m = pb_parse(_anyvalue(300));
    is(pb_field($m, 3), 300, 'intValue carries the integer');
    $m = pb_parse(_anyvalue(\1));
    is(pb_field($m, 2), 1, 'boolValue true is 1');
    $m = pb_parse(_anyvalue(\0));
    is(pb_field($m, 2), 0, 'boolValue false is 0');
}

# ---- refs protobuf cannot represent ----------------------------------------
{
    my $code = pb_parse(_anyvalue(sub { 1 }));
    is((sort keys %$code)[0], 1, 'a coderef becomes a string');
    like(pb_field($code, 1), qr/^CODE\(0x/, 'namely its stringification');

    my $rx = pb_parse(_anyvalue(qr/abc/));
    like(pb_field($rx, 1), qr/abc/, 'a regexp becomes its stringification');

    {
        package OTOver;
        use overload '""' => sub { 'I am a value' }, fallback => 1;
        sub new { bless {}, shift }
    }
    my $ov = pb_parse(_anyvalue(OTOver->new));
    is(pb_field($ov, 1), 'I am a value',
        'an object with an overloaded "" uses it');
}

# ---- nested values ----------------------------------------------------------
{
    my $m = pb_parse(_anyvalue([ 'a', 7 ]));
    my $arr = pb_parse(pb_field($m, 5));
    my @vals = pb_fields($arr, 1);
    is(scalar @vals, 2, 'arrayValue holds both entries');
    is(pb_field(pb_parse($vals[0]), 1), 'a', 'the first is the string');
    is(pb_field(pb_parse($vals[1]), 3), 7,   'the second is the int');

    $m = pb_parse(_anyvalue({ k => 'v' }));
    my $kvl = pb_parse(pb_field($m, 6));
    my $kv  = pb_parse((pb_fields($kvl, 1))[0]);
    is(pb_field($kv, 1), 'k', 'kvlist entry carries its key');
    is(pb_field(pb_parse(pb_field($kv, 2)), 1), 'v', 'and its value');
}

# ---- the trace tree ---------------------------------------------------------
my $PAYLOAD = {
    resource_spans => [ {
        resource    => { attributes => { 'service.name' => 'maat' } },
        schema_url  => 'https://opentelemetry.io/schemas/1.30.0',
        scope_spans => [ {
            scope => { name => 'Punk::OpenTelemetry', version => '0.01' },
            spans => [ {
                trace_id  => '4bf92f3577b34da6a3ce929d0e0e4736',
                span_id   => '00f067aa0ba902b7',
                name      => 'GET /users/:id',
                kind      => 2,                       # SERVER
                start_time_unix_nano => 1_700_000_000_000_000_000,
                end_time_unix_nano   => 1_700_000_000_123_000_000,
                attributes => {
                    'http.route'                => '/users/:id',
                    'http.response.status_code' => 200,
                },
                events => [ { name => 'cache miss',
                              time_unix_nano => 1_700_000_000_050_000_000 } ],
                status => { code => 1 },              # OK
            } ],
        } ],
    } ],
};

{
    my $bytes = pb($PAYLOAD);
    ok(length($bytes) > 0, 'the payload encodes to bytes');
    is(length($bytes), pb_size($PAYLOAD),
        'the measuring pass and the writing pass agree exactly');

    my $req = pb_parse($bytes);
    my $rs  = pb_parse(pb_field($req, 1));            # ResourceSpans
    is(pb_field($rs, 3), 'https://opentelemetry.io/schemas/1.30.0',
        'the schema url survives');

    my $res = pb_parse(pb_field($rs, 1));             # Resource
    my $kv  = pb_parse((pb_fields($res, 1))[0]);      # KeyValue
    is(pb_field($kv, 1), 'service.name', 'the resource attribute key');
    is(pb_field(pb_parse(pb_field($kv, 2)), 1), 'maat', 'and its value');

    my $ss = pb_parse(pb_field($rs, 2));              # ScopeSpans
    my $sc = pb_parse(pb_field($ss, 1));              # Scope
    is(pb_field($sc, 1), 'Punk::OpenTelemetry', 'the scope name');
    is(pb_field($sc, 2), '0.01', 'and its version');

    my $sp = pb_parse(pb_field($ss, 2));              # Span
    is(unpack('H*', pb_field($sp, 1)), '4bf92f3577b34da6a3ce929d0e0e4736',
        'the trace id is 16 raw bytes, decoded from the hex given');
    is(length(pb_field($sp, 1)), 16, 'exactly 16 bytes, not 32');
    is(unpack('H*', pb_field($sp, 2)), '00f067aa0ba902b7', 'the span id');
    is(length(pb_field($sp, 2)), 8, 'exactly 8 bytes');
    is(pb_field($sp, 5), 'GET /users/:id', 'the span name');
    is(pb_field($sp, 6), 2, 'the kind');
    is(pb_str(pb_field($sp, 7)), 1_700_000_000_000_000_000, 'the start time');
    is(pb_str(pb_field($sp, 8)), 1_700_000_000_123_000_000, 'the end time');

    my @attrs = pb_fields($sp, 9);
    is(scalar @attrs, 2, 'both span attributes are present');
    # sorted by key, so http.response.status_code comes before http.route
    my $a0 = pb_parse($attrs[0]);
    is(pb_field($a0, 1), 'http.response.status_code',
        'attributes are sorted by key, so the bytes are reproducible');
    is(pb_field(pb_parse(pb_field($a0, 2)), 3), 200,
        'a numeric attribute encodes as an int');

    my $ev = pb_parse(pb_field($sp, 11));
    is(pb_field($ev, 2), 'cache miss', 'the event name');
    is(pb_str(pb_field($ev, 1)), 1_700_000_000_050_000_000, 'the event time');

    my $st = pb_parse(pb_field($sp, 15));
    is(pb_field($st, 3), 1, 'the status code');
}

# ---- reproducibility --------------------------------------------------------
{
    is(pb($PAYLOAD), pb($PAYLOAD),
        'encoding the same payload twice gives identical bytes');
}

# ---- proto3 default omission -----------------------------------------------
# A field at its default is not written. That is not an optimisation: an
# UNSET status must be absent, or every uninstrumented span claims an opinion
# it does not have.
{
    my $bare = { resource_spans => [ {
        scope_spans => [ { spans => [ {
            trace_id => '0' x 32, span_id => '0' x 16,
            name => 'x', kind => 0, status => { code => 0 },
        } ] } ] } ] };
    my $req = pb_parse(pb($bare));
    my $sp  = pb_parse(pb_field(pb_parse(pb_field(pb_parse(pb_field($req,1)),2)),2));
    ok(!exists $sp->{6},  'SpanKind UNSPECIFIED is omitted');
    ok(!exists $sp->{15}, 'a wholly UNSET status is omitted');
    ok(!exists $sp->{4},  'an absent parent_span_id is omitted');
}

# ---- ids: bytes or hex, and nothing else ------------------------------------
{
    my $raw = pack 'H*', '4bf92f3577b34da6a3ce929d0e0e4736';
    my $p = { resource_spans => [ { scope_spans => [ { spans => [
        { trace_id => $raw, span_id => pack('H*','00f067aa0ba902b7'), name => 'y' }
    ] } ] } ] };
    my $req = pb_parse(pb($p));
    my $sp  = pb_parse(pb_field(pb_parse(pb_field(pb_parse(pb_field($req,1)),2)),2));
    is(pb_field($sp, 1), $raw, 'a 16-byte binary trace id is taken as-is');

    # a wrong-length id is omitted rather than truncated or padded: a
    # valid-looking id of the wrong value joins to nothing and is worse than
    # an absent one, which is at least visible
    $p->{resource_spans}[0]{scope_spans}[0]{spans}[0]{trace_id} = 'too short';
    $req = pb_parse(pb($p));
    $sp  = pb_parse(pb_field(pb_parse(pb_field(pb_parse(pb_field($req,1)),2)),2));
    ok(!exists $sp->{1}, 'a wrong-length trace id is omitted, not mangled');
}

done_testing;
