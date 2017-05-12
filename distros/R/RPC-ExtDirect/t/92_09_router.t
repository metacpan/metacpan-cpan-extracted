use strict;
use warnings;
no  warnings 'once';

use Test::More;

use RPC::ExtDirect::Test::Util;

if ( $ENV{REGRESSION_TESTS} ) {
    plan tests => 24;
}
else {
    plan skip_all => 'Regression tests are not enabled.';
}

# We will test deprecated API and don't want the warnings
# cluttering STDERR
$SIG{__WARN__} = sub {};

use RPC::ExtDirect::Router;

# Test modules are simple
use lib 't/lib2';
use RPC::ExtDirect::Test::Qux;

my $tests = eval do { local $/; <DATA>; }           ## no critic
    or die "Can't eval DATA: $@";

for my $test ( @$tests ) {
    my $name   = $test->{name};
    my $debug  = $test->{debug};
    my $input  = $test->{input};
    my $expect = $test->{output};

    local $RPC::ExtDirect::Router::DEBUG = $debug;

    my $result = eval { RPC::ExtDirect::Router->route($input) };

    # Remove whitespace
    s/\s//g for ( $expect->[2]->[0], $result->[2]->[0] );

    # Remove reference addresses. On different platforms
    # stringified reference has different length so we're
    # trying to compensate for it here
    # Additionally, JSON error output may change (again) and
    # that will break this test (again), so we cheat instead.
    if ( $result->[2]->[0] =~ /HASH\(/ ) {
        s/HASH\([^\)]+\)[^"]+/HASH(blessed)'/g
            for ( $expect->[2]->[0], $result->[2]->[0] );

        $result->[1]->[3] = $expect->[1]->[3] = length $expect->[2]->[0];
    };

    is      $@,      '',      "$name eval $@";
    is ref  $result, 'ARRAY', "$name result ARRAY";
    is_deep $result, $expect, "$name result deep";
};


__DATA__
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
