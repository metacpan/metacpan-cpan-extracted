use strict;
use warnings;

use Test::More tests => 92;

use RPC::ExtDirect::Test::Util qw/ cmp_json is_deep /;
use RPC::ExtDirect::Config;

use RPC::ExtDirect::Router;

# Test modules are simple
use RPC::ExtDirect::Test::Pkg::Qux;
use RPC::ExtDirect::Test::Pkg::Meta;

my $tests = eval do { local $/; <DATA>; }           ## no critic
    or die "Can't eval DATA: $@";

my %only_tests = map { $_ => 1 } @ARGV;

TEST:
for my $test ( @$tests ) {
    my $name   = $test->{name};
    my $debug  = $test->{debug};
    my $input  = $test->{input};
    my $expect = $test->{output};
    
    next TEST if %only_tests && !$only_tests{$name};

    my $config = RPC::ExtDirect::Config->new(
        debug_router => $debug,
    );

    my $router = RPC::ExtDirect::Router->new(
        config => $config,
    );

    my $result = eval { $router->route($input) };

    # Remove reference addresses. On different platforms
    # stringified reference has different length so we're
    # trying to compensate for that here.
    # Additionally, JSON error output may change (again) and
    # that will break this test (again), so we cheat instead.
    if ( $result->[2]->[0] =~ /HASH\(/ ) {
        s/HASH\([^\)]+\)[^"]+/HASH(blessed)'/g
            for ( $expect->[2]->[0], $result->[2]->[0] );

        $result->[1]->[3] = $expect->[1]->[3] = length $expect->[2]->[0];
    };

    my $want_response = (pop @$expect)->[0];
    my $have_response = (pop @$result)->[0];

    my ($want_json, $have_json);

    # It was a form request; extract JSON
    if ( $want_response =~ /<textarea>/i ) {
        ($want_json) = $want_response =~ /<textarea>(.*)<\/textarea>/i;
        ($have_json) = $have_response =~ /<textarea>(.*)<\/textarea>/i;
    }
    else {
        $want_json = $want_response;
        $have_json = $have_response;
    }

    is       $@,         '',      "$name eval $@";
    is ref   $result,    'ARRAY', "$name result ARRAY";
    is_deep  $result,    $expect, "$name result headers";
    cmp_json $have_json, $want_json, "$name result body";
};

__DATA__
#line 60
[
    { name   => 'Invalid result', debug => 1,
      input  => '{"type":"rpc","tid":1,"action":"Foo","method":"foo_blessed",'.
                ' "data":{}}',
      output => [
                    200,
                    [
                        'Content-Type', 'application/json',
                        'Content-Length', 222,
                    ],
                [
                q|{"action":"Foo","message":"encountered object |.
                q|'foo=HASH(0x10088fca0)', but neither allow_blessed|.
                q| nor convert_blessed settings are enabled","method"|.
                q|:"foo_blessed","tid":1,"type":"exception","where":|.
                q|"RPC::ExtDirect::Serializer"}|,
                ],
                ],
    },
    { name   => 'Invalid POST', debug => 1,
      input  => '{"something":"invalid":"here"}',
      output => [ 200,
                  [ 'Content-Type', 'application/json',
                    'Content-Length', 249,
                  ],
                  [ q|{"action":null,|.
                    q|"message":"ExtDirect error decoding POST data: |.
                    q|', or } expected while parsing object/hash, at |.
                    q|character offset 22 (before \":\"here\"}\")'",|.
                    q|"method":null,"tid":null,|.
                    q|"type":"exception",|.
                    q|"where":"RPC::ExtDirect::Serializer->decode_post"}|
                  ],
                ],
    },
    { name   => 'Valid POST, single request', debug => 1,
      input  => '{"type":"rpc","tid":1,"action":"Qux","method":"foo_foo",'.
                ' "data":["bar"]}',
      output => [ 200,
                  [ 'Content-Type', 'application/json',
                    'Content-Length', 78,
                  ],
                  [ q|{"action":"Qux","method":"foo_foo",|.
                  q|"result":"foo! 'bar'","tid":1,"type":"rpc"}| ],
                ],
    },
    { name   => 'Valid POST, multiple requests', debug => 1,
      input  => q|[{"tid":1,"action":"Qux","method":"foo_foo",|.
                q|  "data":["foo"],"type":"rpc"},|.
                q| {"tid":2,"action":"Qux","method":"foo_bar",|.
                q|  "data":["bar1","bar2"],"type":"rpc"},|.
                q| {"tid":3,"action":"Qux","method":"foo_baz",|.
                q|  "data":{"foo":"baz1","bar":"baz2","baz":"baz3"},|.
                q|          "type":"rpc"}]|,
      output => [ 200, 
                  [ 'Content-Type', 'application/json',
                    'Content-Length', 304,
                  ],
                  [
                  q|[{"action":"Qux","method":"foo_foo",|.
                  q|"result":"foo! 'foo'","tid":1,"type":"rpc"},|.
                  q|{"action":"Qux","method":"foo_bar",|.
                  q|"result":["foo! bar!","bar1","bar2"],"tid":2,|.
                  q|"type":"rpc"},|.
                  q|{"action":"Qux","method":"foo_baz",|.
                  q|"result":{"bar":"baz2","baz":"baz3","foo":"baz1",|.
                  q|"msg":"foo! bar! baz!"},"tid":3,"type":"rpc"}]|
                  ],
                ],
    },
    {
        name   => 'Valid POST with invalid metadata 1', debug => 1,
        input  => q|{"type":"rpc","tid":1,"action":"Meta",|.
                  q|"method":"arg0","data":null,|.
                  q|"metadata":[42]}|,
        output => [ 200,
                    [
                        'Content-Type', 'application/json',
                        'Content-Length', 213,
                    ],
                    [
                        q|{"action":"Meta",|.
                        q|"message":"ExtDirectMethodMeta.arg0requires|.
                        q|2metadatavalue(s)butonly1areprovided",|.
                        q|"method":"arg0","tid":1,"type":"exception",|.
                        q|"where":"RPC::ExtDirect::API::Method->check_method_metadata"}|,
                    ],
                  ],
            
    },
    {
        name   => 'Valid POST with metadata 1', debug => 1,
        input  => q|{"type":"rpc","tid":1,"action":"Meta",|.
                  q|"method":"arg0","data":null,|.
                  q|"metadata":[42,"foo"]}|,
        output => [ 200,
                    [
                        'Content-Type', 'application/json',
                        'Content-Length', 83,
                    ],
                    [
                        q|{"action":"Meta","method":"arg0",|.
                        q|"result":{"meta":[42,"foo"]},"tid":1,|.
                        q|"type":"rpc"}|,
                    ],
                  ],
            
    },
    {
        name   => 'Valid POST with metadata 2', debug => 1,
        input  => q|{"type":"rpc","tid":1,"action":"Meta",|.
                  q|"method":"arg1_last","data":["foo"],|.
                  q|"metadata":[42]}|,
        output => [ 200,
                    [
                        'Content-Type', 'application/json',
                        'Content-Length', 95,
                    ],
                    [
                        q|{"action":"Meta","method":"arg1_last",|.
                        q|"result":{"arg1":"foo","meta":[42]},|.
                        q|"tid":1,"type":"rpc"}|,
                    ],
                  ],
    },
    {
        name   => 'Valid POST with metadata 3', debug => 1,
        input  => q|{"type":"rpc","tid":1,"action":"Meta",|.
                  q|"method":"arg1_first","data":["foo"],|.
                  q|"metadata":[42,43]}|,
        output => [ 200,
                    [
                        'Content-Type', 'application/json',
                        'Content-Length', 99,
                    ],
                    [
                        q|{"action":"Meta","method":"arg1_first",|.
                        q|"result":{"arg1":"foo","meta":[42,43]},|.
                        q|"tid":1,"type":"rpc"}|,
                    ],
                  ],
    },
    {
        name   => 'Valid POST with metadata 4', debug => 1,
        input  => q|{"type":"rpc","tid":1,"action":"Meta",|.
                  q|"method":"arg2_last","data":[42,43],|.
                  q|"metadata":["foo","bar"]}|,
        output => [ 200,
                    [
                        'Content-Type', 'application/json',
                        'Content-Length', 105,
                    ],
                    [
                        q|{"action":"Meta","method":"arg2_last",|.
                        q|"result":{"arg1":42,"arg2":43,"meta":["foo"]},|.
                        q|"tid":1,"type":"rpc"}|,
                    ],
                  ],
    },
    {
        name   => 'Valid POST with metadata 5', debug => 1,
        input  => q|{"type":"rpc","tid":1,"action":"Meta",|.
                  q|"method":"arg2_middle","data":[44,45],|.
                  q|"metadata":["fred","bonzo","qux"]}|,
        output => [ 200,
                    [
                        'Content-Type', 'application/json',
                        'Content-Length', 116,
                    ],
                    [
                        q|{"action":"Meta","method":"arg2_middle",|.
                        q|"result":{"arg1":44,"arg2":45,"meta":|.
                        q|["fred","bonzo"]},"tid":1,"type":"rpc"}|,
                    ],
                  ],
    },
    {
        name   => 'Valid POST with metadata 6', debug => 1,
        input  => q|{"type":"rpc","tid":1,"action":"Meta",|.
                  q|"method":"named_default",|.
                  q|"data":{"foo":"bar","fred":"bonzo"},|.
                  q|"metadata":[42]}|,
        output => [ 200,
                    [
                        'Content-Type', 'application/json',
                        'Content-Length', 113,
                    ],
                    [
                        q|{"action":"Meta","method":"named_default",|.
                        q|"result":{"foo":"bar","fred":"bonzo",|.
                        q|"meta":[42]},"tid":1,"type":"rpc"}|,
                    ],
                  ],
    },
    {
        name   => 'Valid POST with metadata 7', debug => 1,
        input  => q|{"type":"rpc","tid":1,"action":"Meta",|.
                  q|"method":"named_arg",|.
                  q|"data":{"qux":"fred"},|.
                  q|"metadata":["blerg"]}|,
        output => [ 200,
                    [
                        'Content-Type', 'application/json',
                        'Content-Length', 100,
                    ],
                    [
                        q|{"action":"Meta","method":"named_arg",|.
                        q|"result":{"meta":["blerg"],"qux":"fred"},|.
                        q|"tid":1,"type":"rpc"}|,
                    ],
                  ],
    },
    {
        name   => 'Valid POST with metadata 8', debug => 1,
        input  => q|{"type":"rpc","tid":1,"action":"Meta",|.
                  q|"method":"named_arg",|.
                  q|"data":{"foo":"bar"},|.
                  q|"metadata":["blerg"]}|,
        output => [ 200,
                    [
                        'Content-Type', 'application/json',
                        'Content-Length', 87,
                    ],
                    [
                        q|{"action":"Meta","method":"named_arg",|.
                        q|"result":{"meta":["blerg"]},|.
                        q|"tid":1,"type":"rpc"}|,
                    ],
                  ],
    },
    {
        name   => 'Valid POST with metadata 9', debug => 1,
        input  => q|{"type":"rpc","tid":1,"action":"Meta",|.
                  q|"method":"named_strict",|.
                  q|"data":{"frob":"dux","frogg":"bonzo"},|.
                  q|"metadata":{"foo":{"bar":{"baz":42}}}}|,
        output => [ 200,
                    [
                        'Content-Type', 'application/json',
                        'Content-Length', 136,
                    ],
                    [
                        q|{"action":"Meta","method":"named_strict",|.
                        q|"result":{"frob":"dux","frogg":"bonzo",|.
                        q|"meta":{"foo":{"bar":{"baz":42}}}},|.
                        q|"tid":1,"type":"rpc"}|,
                    ],
                  ],
    },
    {
        name   => 'Valid POST with metadata 10', debug => 1,
        input  => q|{"type":"rpc","tid":1,"action":"Meta",|.
                  q|"method":"named_unstrict",|.
                  q|"data":{"qux":null},"metadata":{}}|,
        output => [ 200,
                    [
                        'Content-Type', 'application/json',
                        'Content-Length', 96,
                    ],
                    [
                        q|{"action":"Meta","method":"named_unstrict",|.
                        q|"result":{"meta":{},"qux":null},|.
                        q|"tid":1,"type":"rpc"}|,
                    ],
                  ],
    },
    {
        name   => 'Valid POST with ancillary properties', debug => 1,
        input  => q|{"type":"rpc","tid":1,"action":"Meta",|.
                  q|"method":"aux","data":null,"foo":"bar",|.
                  q|"token":"kaboom!"}|,
        output => [ 200,
                    [
                        'Content-Type', 'application/json',
                        'Content-Length', 102,
                    ],
                    [
                        q|{"action":"Meta","method":"aux",|.
                        q|"result":{"aux":{"foo":"bar","token":"kaboom!"}},|.
                        q|"tid":1,"type":"rpc"}|,
                    ],
                  ],
    },
    { name   => 'Invalid form request', debug => 1,
      input  => { extTID => 100, action => 'Bar', method => 'bar_baz',
                  type => 'rpc', data => undef, },
      output => [ 200, [ 'Content-Type', 'application/json',
                         'Content-Length', 208, ],
                  [
                  q|{"action":"Bar",|.
                  q|"message":"ExtDirect formHandler method |.
                  q|Bar.bar_baz should only be called with form submits",|.
                  q|"method":"bar_baz","tid":100,|.
                  q|"type":"exception",|.
                  q|"where":"RPC::ExtDirect::Request->check_arguments"}|,
                  ],
                ],
    },
    { name   => 'Form request, no upload', debug => 1,
      input  => { action => '/router_action', method => 'POST',
                  extAction => 'Bar', extMethod => 'bar_baz',
                  extTID => 123, field1 => 'foo', field2 => 'bar', },
      output => [ 200, [ 'Content-Type', 'application/json',
                         'Content-Length', 99 ],
                  [
                  q|{"action":"Bar","method":"bar_baz",|.
                  q|"result":{"field1":"foo","field2":"bar"},|.
                  q|"tid":123,"type":"rpc"}|,
                  ],
                ],
    },
    {
        name   => 'Form request with decode_params',
        input  => { action => '/router_action', method => 'POST',
                    extAction => 'Bar', extType => 'rpc', extTID => 432,
                    extAction => 'Bar', extMethod => 'bar_baz',
                    blerg => '["bar","baz"]',
                    frob => '{"throbbe":["vita","voom"]}', },
        output => [ 200, [ 'Content-Type', 'application/json',
                           'Content-Length', 132, ],
                    [
                        q|{"action":"Bar","method":"bar_baz","type":"rpc",|.
                        q|"result":{"blerg":"[\"bar\",\"baz\"]",|.
                        q|"frob":{"throbbe":["vita","voom"]}},|.
                        q|"tid":432}|,
                    ],
                  ],
    },
    {
        name   => 'Form request with ordered metadata', debug => 1,
        input  => {
                    action => '/router_action', method => 'POST',
                    extAction => 'Meta', extMethod => 'form_ordered',
                    extTID => 42, extType => 'rpc',
                    fred => 'frob', metadata => [42],
                  },
        output => [ 200,
                    [
                        'Content-Type', 'application/json',
                        'Content-Length', 104,
                    ],
                    [
                        q|{"action":"Meta","method":"form_ordered",|.
                        q|"result":{"fred":"frob","metadata":[42]},|.
                        q|"tid":42,"type":"rpc"}|,
                    ],
                  ],
    },
    {
        name   => 'Form request with named metadata', debug => 1,
        input  => {
                    action => '/router_action', method => 'POST',
                    extAction => 'Meta', extMethod => 'form_named',
                    extTID => 58, extType => 'rpc',
                    boogaloo => 1916, frogg => 'splurge',
                    metadata => { foo => 1, bar => 2, baz => 3 },
                  },
        output => [ 200,
                    [
                        'Content-Type', 'application/json',
                        'Content-Length', 137,
                    ],
                    [
                        q|{"action":"Meta","method":"form_named",|.
                        q|"result":{"_m":{"bar":2,"baz":3,"foo":1},|.
                        q|"boogaloo":1916,"frogg":"splurge"},|.
                        q|"tid":58,"type":"rpc"}|,
                    ],
                  ],
    },
    { name   => 'Form request, upload one file', debug => 1,
      input  => { action => '/router.cgi', method => 'POST',
                    extAction => 'Bar', extMethod => 'bar_baz',
                    extTID => 7, foo_field => 'foo', bar_field => 'bar',
                    extUpload => 'true',
                    _uploads => [{ basename => 'foo.txt',
                        type => 'text/plain', handle => {},     # dummy
                        filename => 'C:\Users\nohuhu\foo.txt',
                        path => '/tmp/cgi-upload/foo.txt', size => 123 }],
                },
      output => [ 200, [ 'Content-Type', 'text/html',
                         'Content-Length', 232, ],
                  [
                  q|<html><body><textarea>|.
                  q|{"action":"Bar","method":"bar_baz",|.
                  q|"result":{"bar_field":"bar",|.
                  q|"foo_field":"foo",|.
                  q|"upload_response":"The following files were |.
                  q|processed:\n|.
                  q|foo.txt text/plain 123\n"|.
                  q|},"tid":7,|.
                  q|"type":"rpc"}|.
                  q|</textarea></body></html>|,
                  ],
                ],
    },
    { name   => 'Form request, multiple uploads', debug => 1,
      input  => { action => '/router_action', method => 'POST',
                    extAction => 'Bar', extMethod => 'bar_baz',
                    extTID => 8, field => 'value', extUpload => 'true',
                    _uploads => [
                        { basename => 'bar.jpg', handle => {},
                          type => 'image/jpeg', filename => 'bar.jpg',
                          path => 'C:\Windows\tmp\bar.jpg', size => 123123, },
                        { basename => 'qux.png', handle => {},
                          type => 'image/png', filename => '/tmp/qux.png',
                          path => 'C:\Windows\tmp\qux.png', size => 54321, },
                        { basename => 'script.js', handle => undef,
                          type => 'application/javascript', size => 1000,
                          filename => '/Users/nohuhu/Documents/script.js',
                          path => 'C:\Windows\tmp\script.js', }, ],
                },
      output => [ 200, [ 'Content-Type', 'text/html',
                         'Content-Length', 279, ],
                  [
                  q|<html><body><textarea>|.
                  q|{"action":"Bar","method":"bar_baz",|.
                  q|"result":{|.
                  q|"field":"value",|.
                  q|"upload_response":"The following files were |.
                  q|processed:\n|.
                  q|bar.jpg image/jpeg 123123\n|.
                  q|qux.png image/png 54321\n|.
                  q|script.js application/javascript 1000\n"|.
                  q|},"tid":8,"type":"rpc"}|.
                  q|</textarea></body></html>|,
                  ],
                ],
    },
]
