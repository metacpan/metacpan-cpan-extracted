use strict;
use warnings;

use Test::More tests => 64;

use RPC::ExtDirect::Test::Util;
use RPC::ExtDirect::Config;
use RPC::ExtDirect;

use RPC::ExtDirect::Serializer;

# Test modules are simple and effective
use RPC::ExtDirect::Test::Pkg::Qux;

my $tests = eval do { local $/; <DATA>; }       ## no critic
    or die "Can't eval DATA: $@";

for my $test ( @$tests ) {
    my $name    = $test->{name};
    my $debug   = $test->{debug};
    my $method  = $test->{method};
    my $data    = $test->{data};
    my $expect  = $test->{result};
    my $run_exp = $test->{run};

    my $api    = RPC::ExtDirect->get_api;
    my $config = RPC::ExtDirect::Config->new(
        debug_request     => $debug,
        debug_deserialize => $debug,
    );

    my $serializer = RPC::ExtDirect::Serializer->new(
        api    => $api,
        config => $config,
    );

    my $requests = eval {
        $serializer->$method(
            data => $data
        )
    };

    is     $@, '',               "$name $method() requests eval $@";
    ok ref $requests eq 'ARRAY', "$name $method requests is ARRAY";

    if ( 'ARRAY' ne ref $requests ) {
        print "requests not ARRAY\n";
        exit 1;
    };

    my $runs    = eval { [ map { $_->run()    } @$requests ] };

    is      $@, '',               "$name $method() runs eval $@";
    ok ref  $runs eq 'ARRAY',     "$name $method() runs is ARRAY";
    is_deep $runs, $run_exp,   "$name $method() runs deep";

    my $results = eval { [ map { $_->result() } @$requests ] };

    is      $@, '',              "$name $method() results eval $@";
    ok ref  $results eq 'ARRAY', "$name $method() results is ARRAY";
    is_deep $results, $expect,   "$name $method() results deep";
};

__DATA__
#line 65
[
    { name   => 'Invalid post data, debug off', debug => 0,
      method => 'decode_post',
      data   => '{"action":"foo" "method":"bar","tid":1}',
      run    => [ '' ],
      result => [ { type  => 'exception', action => undef,
                    tid   => undef,       method => undef,
                    where => 'ExtDirect',
              message => 'An error has occured while processing request' }, ],
    },
    { name   => 'Invalid post data, debug on', debug => 1,
      method => 'decode_post',
      data   => '{"action":"foo" "method":"bar","tid":1}',
      run    => [ '' ],
      result => [ { type  => 'exception', action => undef,
                    tid   => undef,       method => undef,
              where => 'RPC::ExtDirect::Serializer->decode_post',
              message => q!ExtDirect error decoding POST data: '!.
                         q!, or } expected while parsing object/hash!.
                         q!, at character offset 16 (before !.
                         q!""method":"bar","tid"...")'! } ],
    },
    { name   => 'Valid post data, single OK request', debug => 1,
      method => 'decode_post',
      data   => '{"tid":1,"action":"Qux","method":"foo_foo",'.
                '"data":["bar"],"type":"rpc"}',
      run    => [ 1 ],
      result => [ { type => 'rpc', tid => 1, action => 'Qux',
                    method => 'foo_foo', result => "foo! 'bar'", },
                ],
    },
    { name   => 'Valid post data, multiple OK requests', debug => 1,
      method => 'decode_post',
      data   => '[{"tid":1,"action":"Qux","method":"foo_foo",'.
                '  "data":["foo"],"type":"rpc"},'.
                ' {"tid":2,"action":"Qux","method":"foo_bar",'.
                '  "data":["bar1","bar2"],"type":"rpc"},'.
                ' {"tid":3,"action":"Qux","method":"foo_baz",'.
                '  "data":{"foo":"baz1","bar":"baz2","baz":"baz3"},'.
                '  "type":"rpc"}]',
      run    => [ 1, 1, 1 ],
      result => [ { type   => 'rpc', tid => 1, action => 'Qux',
                    method => 'foo_foo', result => "foo! 'foo'", },
                  { type   => 'rpc', tid => 2, action => 'Qux',
                    method => 'foo_bar',
                    result => [ 'foo! bar!', 'bar1', 'bar2' ], },
                  { type   => 'rpc', tid => 3, action => 'Qux',
                    method => 'foo_baz',
                    result => { msg  => 'foo! bar! baz!',
                                foo => 'baz1', bar => 'baz2',
                                baz => 'baz3' }, },
                ],
    },
    { name   => 'Valid post data, OK/NOK requests', debug => 0,
      method => 'decode_post',
      data   => '[{"tid":1,"action":"Qux","method":"foo_foo",'.
                '  "data":["foo"],"type":"rpc"},'.
                ' {"tid":2,"action":"Qux","method":"foo_barq",'.
                '  "data":["bar1","bar2"],"type":"rpc"},'.
                ' {"tid":3,"action":"Qux","method":"foo_baz",'.
                '  "data":{"foo":"baz1","bar":"baz2","baz":"baz3"},'.
                '  "type":"rpc"}]',
      run    => [ 1, '', 1 ],
      result => [ { type   => 'rpc', tid => 1, action => 'Qux',
                    method => 'foo_foo', result => "foo! 'foo'", },
                  { type   => 'exception', where => 'ExtDirect', tid => 2,
                    action  => 'Qux',      method => 'foo_barq',
                    message => 'An error has occured while processing request',
                  },
                  { type   => 'rpc', tid => 3, action => 'Qux',
                    method => 'foo_baz', 
                    result => { msg  => 'foo! bar! baz!',
                                foo => 'baz1', bar => 'baz2', 
                                baz => 'baz3' }, },
                ],
    },
    # Form handler call, no upload
    {
        name   => 'Form call, no uploads', debug => 1,
        method => 'decode_form',
        data   => { action => '/something.cgi', method => 'POST',
                    extAction => 'Bar', extMethod => 'bar_baz',
                    extTID => 6, field1 => 'foo', field2 => 'bar', },
        run    => [ 1 ],
        result => [{ type => 'rpc', tid => 6, action => 'Bar',
                    method => 'bar_baz',
                    result => { field1 => 'foo', field2 => 'bar', }, }],
    },
    # Form handler call, one file "upload"
    {
        name   => 'Form call, one upload', debug => 1,
        method => 'decode_form',
        data   => { action => '/router.cgi', method => 'POST',
                    extAction => 'Bar', extMethod => 'bar_baz',
                    extTID => 7, foo_field => 'foo', bar_field => 'bar',
                    extUpload => 'true',
                    _uploads => [{ basename => 'foo.txt',
                        type => 'text/plain', handle => {},     # dummy
                        filename => 'C:\Users\nohuhu\foo.txt',
                        path => '/tmp/cgi-upload/foo.txt', size => 123 }],
                  },
        run    => [ 1 ],
        result => [{ type => 'rpc', tid => 7, action => 'Bar',
                    method => 'bar_baz',
                    result => { foo_field => 'foo', bar_field => 'bar',
                                upload_response =>
                                "The following files were processed:\n".
                                "foo.txt text/plain 123\n",
                              },
                  }],
    },
    # Form handler call, multiple uploads
    {
        name   => 'Form call, multi uploads', debug => 1,
        method => 'decode_form',
        data   => { action => '/router_action', method => 'POST',
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
        run => [ 1 ],
        result => [{
            type => 'rpc', tid => 8, action => 'Bar', method => 'bar_baz',
            result => { field => 'value', upload_response =>
                        "The following files were processed:\n".
                        "bar.jpg image/jpeg 123123\n".
                        "qux.png image/png 54321\n".
                        "script.js application/javascript 1000\n",
            },
        }],
    },
]
