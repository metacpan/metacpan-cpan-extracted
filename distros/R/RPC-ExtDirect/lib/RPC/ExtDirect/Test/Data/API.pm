# This does not need to be indexed by PAUSE
package
     RPC::ExtDirect::Test::Data::API;

use strict;
use warnings;

# This aref contains definitions/data for API tests
my $tests = [{
    name => 'API 1',
    
    config => {
        api_path => '/api',
        debug => 1,
        no_polling => 1,
        router_path => '/extdirectrouter',
        poll_path => '/events',
    },
    
    input => {
        method => 'GET',
        url => '/api',
        cgi_url => '/api1',
        
        content => undef,
    },
    
    # Expected test output
    output => {
        status => 200,
        content_type => qr|^application/javascript\b|,
        content_length => 1312,
        comparator => 'cmp_api',
        content => q~
            Ext.app.REMOTING_API = {
                "actions": {
                "Bar": [
                            { "len":5, "name":"bar_bar" },
                            { "formHandler":true, "name":"bar_baz" },
                            { "len":4, "name":"bar_foo" }
                       ],
                "Foo": [
                            { "len":2, "name":"foo_bar" },
                            { "name":"foo_baz", "params":["foo","bar","baz"] },
                            { "len":1, "name":"foo_foo" },
                            { "len":0, "name":"foo_zero" },
                            { "name":"foo_blessed", "params":[], "strict":false }
                       ],
                "Meta": [
                        { "name":"arg0", "len":0, "metadata":{ "len":2 } },
                        { "name":"arg1_last", "len":1, "metadata":{ "len":1 } },
                        { "name":"arg1_first", "len":1, "metadata":{ "len":2 } },
                        { "name":"arg2_last", "len":2, "metadata":{ "len":1 } },
                        { "name":"arg2_middle", "len":2, "metadata":{ "len":2 } },
                        { "name":"form_named", "formHandler": true,
                          "metadata": { "params": [], "strict": false } },
                        { "name": "form_ordered", "formHandler": true,
                          "metadata": { "len": 1 } },
                        { "name":"named_default", "params": [], "strict":false,
                          "metadata": { "len": 1 } },
                        { "name":"named_arg", "params": [], "strict":false,
                          "metadata": { "len": 1 } },
                        { "name":"named_strict", "params": [], "strict":false,
                          "metadata": { "params": ["foo"] } },
                        { "name":"named_unstrict", "params": [], "strict":false,
                          "metadata": { "params": [], "strict": false } },
                        { "name":"aux", "len":0 }
                ],
                "Qux": [
                            { "len":5, "name":"bar_bar" },
                            { "formHandler":true, "name":"bar_baz" },
                            { "len":4, "name":"bar_foo" },
                            { "len":2, "name":"foo_bar" },
                            { "name":"foo_baz", "params":["foo","bar","baz"] },
                            { "len":1, "name":"foo_foo" }
                       ]
                },
                "type":"remoting",
                "url":"/extdirectrouter"
            };
        ~,
    },
}, {
    name => 'API 2',
    
    config => {
        api_path => '/api',
        namespace => 'myApp.ns',
        auto_connect => 1,
        router_path => '/router.cgi',
        debug => 1,
        remoting_var => 'Ext.app.REMOTE_CALL',
        no_polling => 1,
        poll_path => '/events',
    },
    
    input => {
        method => 'GET',
        url => '/api',
        cgi_url => '/api2',
        
        content => undef,
    },
    
    output => {
        status => 200,
        content_type => qr|^application/javascript\b|,
        content_length => 1382,
        comparator => 'cmp_api',
        content => q~
            Ext.app.REMOTE_CALL = {
                "actions": {
                "Bar": [
                            { "len":5, "name":"bar_bar" },
                            { "formHandler":true, "name":"bar_baz" },
                            { "len":4, "name":"bar_foo" }
                       ],
                "Foo": [
                            { "len":2, "name":"foo_bar" },
                            { "name":"foo_baz", "params":["foo","bar","baz"] },
                            { "len":1, "name":"foo_foo" },
                            { "len":0, "name":"foo_zero" },
                            { "name":"foo_blessed", "params":[], "strict":false }
                       ],
                "Meta": [
                        { "name":"arg0", "len":0, "metadata":{ "len":2 } },
                        { "name":"arg1_last", "len":1, "metadata":{ "len":1 } },
                        { "name":"arg1_first", "len":1, "metadata":{ "len":2 } },
                        { "name":"arg2_last", "len":2, "metadata":{ "len":1 } },
                        { "name":"arg2_middle", "len":2, "metadata":{ "len":2 } },
                        { "name":"form_named", "formHandler": true,
                          "metadata": { "params": [], "strict": false } },
                        { "name": "form_ordered", "formHandler": true,
                          "metadata": { "len": 1 } },
                        { "name":"named_default", "params": [], "strict":false,
                          "metadata": { "len": 1 } },
                        { "name":"named_arg", "params": [], "strict":false,
                          "metadata": { "len": 1 } },
                        { "name":"named_strict", "params": [], "strict":false,
                          "metadata": { "params": ["foo"] } },
                        { "name":"named_unstrict", "params": [], "strict":false,
                          "metadata": { "params": [], "strict": false } },
                        { "name":"aux", "len":0 }
                ],
                "Qux": [
                            { "len":5, "name":"bar_bar" },
                            { "formHandler":true, "name":"bar_baz" },
                            { "len":4, "name":"bar_foo" },
                            { "len":2, "name":"foo_bar" },
                            { "name":"foo_baz", "params":["foo","bar","baz"] },
                            { "len":1, "name":"foo_foo" }
                       ]
                },
                "namespace":"myApp.ns",
                "type":"remoting",
                "url":"/router.cgi"
            };
            Ext.direct.Manager.addProvider(Ext.app.REMOTE_CALL);
        ~,
    },
}, {
    name => 'API 3',
    
    config => {
        remoting_var => 'Ext.app.CALL',
        debug => 1,
        polling_var => 'Ext.app.POLL',
        auto_connect => !1,
        router_path => '/cgi-bin/router.cgi',
        poll_path => '/cgi-bin/events.cgi',
        namespace => 'Namespace',
        api_path => '/api',
        no_polling => !1,
    },
    
    input => {
        method => 'GET',
        url => '/api',
        cgi_url => '/api3',
        
        content => undef,
    },
    
    output => {
        status => 200,
        content_type => qr|^application/javascript\b|,
        content_length => 1394,
        comparator => 'cmp_api',
        content => q~
            Ext.app.CALL = {
                "actions": {
                "Bar": [
                            { "len":5, "name":"bar_bar" },
                            { "formHandler":true, "name":"bar_baz" },
                            { "len":4, "name":"bar_foo" }
                       ],
                "Foo": [
                            { "len":2, "name":"foo_bar" },
                            { "name":"foo_baz", "params":["foo","bar","baz"] },
                            { "len":1, "name":"foo_foo" },
                            { "len":0, "name":"foo_zero" },
                            { "name":"foo_blessed", "params":[], "strict":false }
                       ],
                "Meta": [
                        { "name":"arg0", "len":0, "metadata":{ "len":2 } },
                        { "name":"arg1_last", "len":1, "metadata":{ "len":1 } },
                        { "name":"arg1_first", "len":1, "metadata":{ "len":2 } },
                        { "name":"arg2_last", "len":2, "metadata":{ "len":1 } },
                        { "name":"arg2_middle", "len":2, "metadata":{ "len":2 } },
                        { "name":"form_named", "formHandler": true,
                          "metadata": { "params": [], "strict": false } },
                        { "name": "form_ordered", "formHandler": true,
                          "metadata": { "len": 1 } },
                        { "name":"named_default", "params": [], "strict":false,
                          "metadata": { "len": 1 } },
                        { "name":"named_arg", "params": [], "strict":false,
                          "metadata": { "len": 1 } },
                        { "name":"named_strict", "params": [], "strict":false,
                          "metadata": { "params": ["foo"] } },
                        { "name":"named_unstrict", "params": [], "strict":false,
                          "metadata": { "params": [], "strict": false } },
                        { "name":"aux", "len":0 }
                ],
                "Qux": [
                            { "len":5, "name":"bar_bar" },
                            { "formHandler":true, "name":"bar_baz" },
                            { "len":4, "name":"bar_foo" },
                            { "len":2, "name":"foo_bar" },
                            { "name":"foo_baz", "params":["foo","bar","baz"] },
                            { "len":1, "name":"foo_foo" }
                       ]
                },
                "namespace":"Namespace",
                "type":"remoting",
                "url":"/cgi-bin/router.cgi"
            };
            Ext.app.POLL = {
                "type":"polling",
                "url":"/cgi-bin/events.cgi"
            };
        ~,
    },
}];

sub get_tests { return $tests };

1;
