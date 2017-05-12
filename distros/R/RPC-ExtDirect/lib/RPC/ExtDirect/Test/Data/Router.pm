# This does not need to be indexed by PAUSE
package
    RPC::ExtDirect::Test::Data::Router;

use strict;
use warnings;

# This aref contains definitions/data for Router tests
my $tests = [{
    name => 'Invalid raw POST',
    
    config => {
        api_path => '/api',
        router_path => '/router',
        poll_path => '/events',
        debug => 1,
    },
    
    input => {
        method => 'POST',
        url => '/router',
        cgi_url => '/router1',
    
        content => {
            type => 'raw_post',
            arg => [
                'http://localhost/router',
                '{"something":"invalid":"here"}',
            ],
        },
    },
    
    output => {
        status => 200,
        content_type => qr|^application/json\b|,
        content_length => 249,
        comparator => 'cmp_json',
        content => 
            q|{"action":null,"message":"ExtDirect error decoding POST data: |.
            q|            ', or } expected while parsing object/hash,|.
            q|             at character offset 22 (before \":\"here\"}\")'",|.
            q| "method":null, "tid": null, "type":"exception",|.
            q| "where":"RPC::ExtDirect::Serializer->decode_post"}|,
    },
}, {
    name => 'Valid raw POST, single request',
    
    config => {
        api_path => '/api',
        router_path => '/router',
        poll_path => '/events',
        debug => 1,
    },
    
    input => {
        method => 'POST',
        url => '/router',
        cgi_url  => '/router1',
    
        content => {
            type => 'raw_post',
            arg  => [
                'http://localhost/router',
                q|{"type":"rpc","tid":1,"action":"Foo",|.
                q| "method":"foo_foo","data":["bar"]}|,
            ],
        },
    },
    
    output => {
        status => 200,
        content_type => qr|^application/json\b|,
        content_length => 78,
        comparator => 'cmp_json',
        content => 
            q|{"action":"Foo","method":"foo_foo",|.
            q|"result":"foo! 'bar'","tid":1,"type":"rpc"}|,
    },
}, {
    name => 'Valid raw POST, multiple requests',
    
    config => {
        api_path => '/api',
        router_path => '/router',
        poll_path => '/events',
        debug => 1,
    },
    
    input => {
        method => 'POST',
        url => '/router',
        cgi_url  => '/router1',
    
        content => {
            type => 'raw_post',
            arg  => [
                'http://localhost/router',
                q|[{"tid":1,"action":"Qux","method":"foo_foo",|.
                q|  "data":["foo"],"type":"rpc"},|.
                q| {"tid":2,"action":"Qux","method":"foo_bar",|.
                q|  "data":["bar1","bar2"],"type":"rpc"},|.
                q| {"tid":3,"action":"Qux","method":"foo_baz",|.
                q|  "data":{"foo":"baz1","bar":"baz2",|.
                q|  "baz":"baz3"},"type":"rpc"}]|,
            ],
        },
    },
    
    output => {
        status => 200,
        content_type => qr|^application/json\b|,
        content_length => 304,
        comparator => 'cmp_str',
        content => 
            q|[{"action":"Qux","method":"foo_foo",|.
            q|"result":"foo! 'foo'","tid":1,"type":"rpc"},|.
            q|{"action":"Qux","method":"foo_bar",|.
            q|"result":["foo! bar!","bar1","bar2"],"tid":2,"type":"rpc"},|.
            q|{"action":"Qux","method":"foo_baz",|.
            q|"result":{"bar":"baz2","baz":"baz3","foo":"baz1",|.
            q|"msg":"foo! bar! baz!"},"tid":3,"type":"rpc"}]|,
    },
}, {
    name => 'Valid POST with invalid metadata 1',
    
    config => {
        api_path => '/api',
        router_path => '/router',
        poll_path => '/events',
        debug => 1,
    },
    
    input => {
        method => 'POST',
        url => '/router',
        cgi_url => '/router4',
        
        content => {
            type => 'raw_post',
            arg => [
                'http://localhost/router',
                q|{"type":"rpc","tid":1,"action":"Meta",|.
                q|"method":"arg0","data":null,|.
                q|"metadata":[42]}|,
            ],
        },
    },
    
    output => {
        status => 200,
        content_type => qr|^application/json\b|,
        content_length => 213,
        comparator => 'cmp_str',
        content =>
            q|{"action":"Meta",|.
            q|"message":"ExtDirectMethodMeta.arg0requires|.
            q|2metadatavalue(s)butonly1areprovided",|.
            q|"method":"arg0","tid":1,"type":"exception",|.
            q|"where":"RPC::ExtDirect::API::Method->check_method_metadata"}|,
    },
}, {
    name => 'Valid POST with metadata 1',
    
    config => {
        api_path => '/api',
        router_path => '/router',
        poll_path => '/events',
        debug => 1,
    },
    
    input => {
        method => 'POST',
        url => '/router',
        cgi_url => '/router4',
        
        content => {
            type => 'raw_post',
            arg => [
                'http://localhost/router',
                q|{"type":"rpc","tid":1,"action":"Meta",|.
                q|"method":"arg0","data":null,|.
                q|"metadata":[42,"foo"]}|,
            ],
        },
    },
    
    output => {
        status => 200,
        content_type => qr|^application/json\b|,
        content_length => 83,
        comparator => 'cmp_str',
        content =>
            q|{"action":"Meta","method":"arg0",|.
            q|"result":{"meta":[42,"foo"]},"tid":1,|.
            q|"type":"rpc"}|,
    },
}, {
    name => 'Valid POST with metadata 2',
    
    config => {
        api_path => '/api',
        router_path => '/router',
        poll_path => '/events',
        debug => 1,
    },
    
    input => {
        method => 'POST',
        url => '/router',
        cgi_url => '/router4',
        
        content => {
            type => 'raw_post',
            arg => [
                'http://localhost/router',
                q|{"type":"rpc","tid":1,"action":"Meta",|.
                q|"method":"arg1_last","data":["foo"],|.
                q|"metadata":[42]}|,
            ],
        },
    },
    
    output => {
        status => 200,
        content_type => qr|^application/json\b|,
        content_length => 95,
        comparator => 'cmp_str',
        content =>
            q|{"action":"Meta","method":"arg1_last",|.
            q|"result":{"arg1":"foo","meta":[42]},|.
            q|"tid":1,"type":"rpc"}|,
    },
}, {
    name => 'Valid POST with metadata 3',
    
    config => {
        api_path => '/api',
        router_path => '/router',
        poll_path => '/events',
        debug => 1,
    },
    
    input => {
        method => 'POST',
        url => '/router',
        cgi_url => '/router4',
        
        content => {
            type => 'raw_post',
            arg => [
                'http://localhost/router',
                q|{"type":"rpc","tid":1,"action":"Meta",|.
                q|"method":"arg1_first","data":["foo"],|.
                q|"metadata":[42,43]}|,
            ],
        },
    },
    
    output => {
        status => 200,
        content_type => qr|^application/json\b|,
        content_length => 99,
        comparator => 'cmp_str',
        content =>
            q|{"action":"Meta","method":"arg1_first",|.
            q|"result":{"arg1":"foo","meta":[42,43]},|.
            q|"tid":1,"type":"rpc"}|,
    },
}, {
    name => 'Valid POST with metadata 4',
    
    config => {
        api_path => '/api',
        router_path => '/router',
        poll_path => '/events',
        debug => 1,
    },
    
    input => {
        method => 'POST',
        url => '/router',
        cgi_url => '/router4',
        
        content => {
            type => 'raw_post',
            arg => [
                'http://localhost/router',
                q|{"type":"rpc","tid":1,"action":"Meta",|.
                q|"method":"arg2_last","data":[42,43],|.
                q|"metadata":["foo","bar"]}|,
            ],
        },
    },
    
    output => {
        status => 200,
        content_type => qr|^application/json\b|,
        content_length => 105,
        comparator => 'cmp_str',
        content =>
            q|{"action":"Meta","method":"arg2_last",|.
            q|"result":{"arg1":42,"arg2":43,"meta":["foo"]},|.
            q|"tid":1,"type":"rpc"}|,
    },
}, {
    name => 'Valid POST with metadata 5',
    
    config => {
        api_path => '/api',
        router_path => '/router',
        poll_path => '/events',
        debug => 1,
    },
    
    input => {
        method => 'POST',
        url => '/router',
        cgi_url => '/router4',
        
        content => {
            type => 'raw_post',
            arg => [
                'http://localhost/router',
                q|{"type":"rpc","tid":1,"action":"Meta",|.
                q|"method":"arg2_middle","data":[44,45],|.
                q|"metadata":["fred","bonzo","qux"]}|,
            ],
        },
    },
    
    output => {
        status => 200,
        content_type => qr|^application/json\b|,
        content_length => 116,
        comparator => 'cmp_str',
        content =>
            q|{"action":"Meta","method":"arg2_middle",|.
            q|"result":{"arg1":44,"arg2":45,"meta":|.
            q|["fred","bonzo"]},"tid":1,"type":"rpc"}|,
    },
}, {
    name => 'Valid POST with metadata 6',
    
    config => {
        api_path => '/api',
        router_path => '/router',
        poll_path => '/events',
        debug => 1,
    },
    
    input => {
        method => 'POST',
        url => '/router',
        cgi_url => '/router4',
        
        content => {
            type => 'raw_post',
            arg => [
                'http://localhost/router',
                q|{"type":"rpc","tid":1,"action":"Meta",|.
                q|"method":"named_default",|.
                q|"data":{"foo":"bar","fred":"bonzo"},|.
                q|"metadata":[42]}|,
            ],
        },
    },
    
    output => {
        status => 200,
        content_type => qr|^application/json\b|,
        content_length => 113,
        comparator => 'cmp_str',
        content =>
            q|{"action":"Meta","method":"named_default",|.
            q|"result":{"foo":"bar","fred":"bonzo",|.
            q|"meta":[42]},"tid":1,"type":"rpc"}|,
    },
}, {
    name => 'Valid POST with metadata 7',
    
    config => {
        api_path => '/api',
        router_path => '/router',
        poll_path => '/events',
        debug => 1,
    },
    
    input => {
        method => 'POST',
        url => '/router',
        cgi_url => '/router4',
        
        content => {
            type => 'raw_post',
            arg => [
                'http://localhost/router',
                q|{"type":"rpc","tid":1,"action":"Meta",|.
                q|"method":"named_arg",|.
                q|"data":{"qux":"fred"},|.
                q|"metadata":["blerg"]}|,                
            ],
        },
    },
    
    output => {
        status => 200,
        content_type => qr|^application/json\b|,
        content_length => 100,
        comparator => 'cmp_str',
        content =>
            q|{"action":"Meta","method":"named_arg",|.
            q|"result":{"meta":["blerg"],"qux":"fred"},|.
            q|"tid":1,"type":"rpc"}|,
    },
}, {
    name => 'Valid POST with metadata 8',
    
    config => {
        api_path => '/api',
        router_path => '/router',
        poll_path => '/events',
        debug => 1,
    },
    
    input => {
        method => 'POST',
        url => '/router',
        cgi_url => '/router4',
        
        content => {
            type => 'raw_post',
            arg => [
                'http://localhost/router',
                q|{"type":"rpc","tid":1,"action":"Meta",|.
                q|"method":"named_arg",|.
                q|"data":{"foo":"bar"},|.
                q|"metadata":["blerg"]}|,
            ],
        },
    },
    
    output => {
        status => 200,
        content_type => qr|^application/json\b|,
        content_length => 87,
        comparator => 'cmp_str',
        content =>
            q|{"action":"Meta","method":"named_arg",|.
            q|"result":{"meta":["blerg"]},|.
            q|"tid":1,"type":"rpc"}|,
    },
}, {
    name => 'Valid POST with metadata 9',
    
    config => {
        api_path => '/api',
        router_path => '/router',
        poll_path => '/events',
        debug => 1,
    },
    
    input => {
        method => 'POST',
        url => '/router',
        cgi_url => '/router4',
        
        content => {
            type => 'raw_post',
            arg => [
                'http://localhost/router',
                q|{"type":"rpc","tid":1,"action":"Meta",|.
                q|"method":"named_strict",|.
                q|"data":{"frob":"dux","frogg":"bonzo"},|.
                q|"metadata":{"foo":{"bar":{"baz":42}}}}|,
            ],
        },
    },
    
    output => {
        status => 200,
        content_type => qr|^application/json\b|,
        content_length => 136,
        comparator => 'cmp_str',
        content =>
            q|{"action":"Meta","method":"named_strict",|.
            q|"result":{"frob":"dux","frogg":"bonzo",|.
            q|"meta":{"foo":{"bar":{"baz":42}}}},|.
            q|"tid":1,"type":"rpc"}|,
    },
}, {
    name => 'Valid POST with metadata 10',
    
    config => {
        api_path => '/api',
        router_path => '/router',
        poll_path => '/events',
        debug => 1,
    },
    
    input => {
        method => 'POST',
        url => '/router',
        cgi_url => '/router4',
        
        content => {
            type => 'raw_post',
            arg => [
                'http://localhost/router',
                q|{"type":"rpc","tid":1,"action":"Meta",|.
                q|"method":"named_unstrict",|.
                q|"data":{"qux":null},"metadata":{}}|,
            ],
        },
    },
    
    output => {
        status => 200,
        content_type => qr|^application/json\b|,
        content_length => 96,
        comparator => 'cmp_str',
        content =>
            q|{"action":"Meta","method":"named_unstrict",|.
            q|"result":{"meta":{},"qux":null},|.
            q|"tid":1,"type":"rpc"}|,
    },
}, {
    name => 'Valid POST with ancillary properties',
    
    config => {
        api_path => '/api',
        router_path => '/router',
        poll_path => '/events',
        debug => 1,
    },
    
    input => {
        method => 'POST',
        url => '/router',
        cgi_url => '/router4',
        
        content => {
            type => 'raw_post',
            arg => [
                'http://localhost/router',
                q|{"type":"rpc","tid":1,"action":"Meta",|.
                q|"method":"aux","data":null,"foo":"bar",|.
                q|"token":"kaboom!"}|,
            ],
        },
    },
    
    output => {
        status => 200,
        content_type => qr|^application/json\b|,
        content_length => 102,
        comparator => 'cmp_str',
        content =>
            q|{"action":"Meta","method":"aux",|.
            q|"result":{"aux":{"foo":"bar","token":"kaboom!"}},|.
            q|"tid":1,"type":"rpc"}|,
    },
}, {
    name => 'Form request, no uploads',
    
    config => {
        api_path => '/api',
        router_path => '/router',
        poll_path => '/events',
        debug => 1,
    },
    
    input => {
        method => 'POST',
        url => '/router',
        cgi_url => '/router1',
    
        content => {
            type => 'form_post',
            arg  => [
                'http://localhost/router',
                action => '/router.cgi',
                method => 'POST',
                extAction => 'Bar',
                extMethod => 'bar_baz',
                extTID => 123,
                field1 => 'foo',
                field2 => 'bar',
                extType => 'rpc',
            ],
        },
    },
    
    output => {
        status => 200,
        content_type => qr|^application/json\b|,
        content_length => 99,
        comparator => 'cmp_str',
        content =>
            q|{"action":"Bar","method":"bar_baz",|.
            q|"result":{"field1":"foo","field2":"bar"},|.
            q|"tid":123,"type":"rpc"}|,
    },
}, {
    name => 'Form request with ordered metadata',
    
    config => {
        api_path => '/api',
        router_path => '/router',
        poll_path => '/events',
        debug => 1,
    },
    
    input => {
        method => 'POST',
        url => '/router',
        cgi_url => '/router4',
    
        content => {
            type => 'form_post',
            arg  => [
                'http://localhost/router',
                action => '/router.cgi',
                method => 'POST',
                extAction => 'Meta',
                extMethod => 'form_ordered',
                extType => 'rpc',
                extTID => 42,
                fred => 'frob',
                
                # Client sends JSON encoded metadata with forms
                metadata => '[42]',
            ],
        },
    },
    
    output => {
        status => 200,
        content_type => qr|^application/json\b|,
        content_length => 104,
        comparator => 'cmp_str',
        content =>
            q|{"action":"Meta","method":"form_ordered",|.
            q|"result":{"fred":"frob","metadata":[42]},|.
            q|"tid":42,"type":"rpc"}|,
    },
}, {
    name => 'Form request with named metadata',
    
    config => {
        api_path => '/api',
        router_path => '/router',
        poll_path => '/events',
        debug => 1,
    },
    
    input => {
        method => 'POST',
        url => '/router',
        cgi_url => '/router4',
    
        content => {
            type => 'form_post',
            arg  => [
                'http://localhost/router',
                action => '/router.cgi',
                method => 'POST',
                extAction => 'Meta',
                extMethod => 'form_named',
                extType => 'rpc',
                extTID => 58,
                frogg => 'splurge',
                boogaloo => 1916,

                # Client sends JSON encoded metadata with forms
                metadata => '{"foo":1,"bar":2,"baz":3}',
            ],
        },
    },
    
    output => {
        status => 200,
        content_type => qr|^application/json\b|,
        content_length => 139,
        comparator => 'cmp_str',
        
        # Note that we send a number in boogaloo field above
        # but expect a string in return. This is due to the nature
        # of form POST submits; in either URL encoding or form-multipart
        # the data is sent as 
        content =>
            q|{"action":"Meta","method":"form_named",|.
            q|"result":{"_m":{"bar":2,"baz":3,"foo":1},|.
            q|"boogaloo":"1916","frogg":"splurge"},|.
            q|"tid":58,"type":"rpc"}|,
    },
}, {
    name => 'Form request with named metadata, multipart encoded',
    
    config => {
        api_path => '/api',
        router_path => '/router',
        poll_path => '/events',
        debug => 1,
    },
    
    input => {
        method => 'POST',
        url => '/router',
        cgi_url => '/router4',
    
        content => {
            type => 'form_upload',
            arg  => [
                'http://localhost/router',
                [],
                action => '/router.cgi',
                method => 'POST',
                extAction => 'Meta',
                extMethod => 'form_named',
                extType => 'rpc',
                extUpload => 'true',
                extTID => 63,
                frogg => 'splurge',
                boogaloo => 1916,

                # Client sends JSON encoded metadata with forms
                metadata => '{"foo":1,"bar":2,"baz":3}',
            ],
        },
    },
    
    output => {
        status => 200,
        content_type => qr|^text/html\b|,
        content_length => 186,
        comparator => 'cmp_str',
        content =>
            q|<html><body><textarea>|.
            q|{"action":"Meta","method":"form_named",|.
            q|"result":{"_m":{"bar":2,"baz":3,"foo":1},|.
            q|"boogaloo":"1916","frogg":"splurge"},|.
            q|"tid":63,"type":"rpc"}|.
            q|</textarea></body></html>|,
    },
}, {
    name => 'Form request, one upload',
    
    config => {
        api_path => '/api',
        router_path => '/router',
        poll_path => '/events',
        debug => 1,
    },
    
    input => {
        method => 'POST',
        url => '/router',
        cgi_url => '/router2',
    
        content => {
            type => 'form_upload',
            arg  => [
                'http://localhost/router',
                ['qux.txt'],
                action => '/router.cgi',
                method => 'POST',
                extAction => 'JuiceBar',
                extMethod => 'bar_baz',
                extTID => 7,
                extType => 'rpc',
                foo_field => 'foo',
                bar_field => 'bar',
                extUpload => 'true',
            ],
        },
    },
    
    output => {
        status => 200,
        content_type => qr|^text/html\b|,
        content_length => 253,
        comparator => 'cmp_str',
        content =>
            q|<html><body><textarea>|.
            q|{"action":"JuiceBar","method":"bar_baz",|.
            q|"result":{"bar_field":"bar",|.
            q|"foo_field":"foo",|.
            q|"upload_response":"The following files were |.
            q|processed:\n|.
            q|qux.txt application/octet-stream 31 ok\n"|.
            q|},"tid":7,|.
            q|"type":"rpc"}|.
            q|</textarea></body></html>|,
    },
}, {
    name => 'Form request, multiple uploads',
    
    config => {
        api_path => '/api',
        router_path => '/router',
        poll_path => '/events',
        debug => 1,
    },
    
    input => {
        method => 'POST',
        cgi_url => '/router2',
        url => '/router',
    
        content => {
            type => 'form_upload',
            arg  => [
                'http://localhost/router',
                ['foo.jpg', 'bar.png', 'script.js'],
                action => '/router.cgi',
                method => 'POST',
                extAction => 'JuiceBar',
                extMethod => 'bar_baz',
                extTID => 8,
                field => 'value',
                extUpload => 'true',
                extType => 'rpc',
            ],
        },
    },
    
    output => {
        status => 200,
        content_type => qr|^text/html\b|,
        content_length => 321,
        comparator => 'cmp_str',
        content =>
            q|<html><body><textarea>|.
            q|{"action":"JuiceBar","method":"bar_baz",|.
            q|"result":{|.
            q|"field":"value",|.
            q|"upload_response":"The following files were |.
            q|processed:\n|.
            q|foo.jpg application/octet-stream 16159 ok\n|.
            q|bar.png application/octet-stream 20693 ok\n|.
            q|script.js application/octet-stream 80 ok\n"|.
            q|},"tid":8,"type":"rpc"}|.
            q|</textarea></body></html>|,
    },
}];

sub get_tests { return $tests };

1;
