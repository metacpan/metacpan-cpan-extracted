use strict;
use warnings;

use Test::More;

use RPC::ExtDirect::Test::Util;

if ( $ENV{REGRESSION_TESTS} ) {
    plan tests => 2;
}
else {
    plan skip_all => 'Regression tests are not enabled.';
}

# We will test deprecated API and don't want the warnings
# cluttering STDERR
$SIG{__WARN__} = sub {};

# Test modules are so simple they can't be broken
use lib 't/lib2';
use RPC::ExtDirect::Test::Foo;
use RPC::ExtDirect::Test::Bar;
use RPC::ExtDirect::Test::Qux;
use RPC::ExtDirect::Test::PollProvider;

use RPC::ExtDirect::API     namespace    => 'myApp.Server',
                            router_path  => '/router.cgi',
                            poll_path    => '/poll.cgi',
                            remoting_var => 'Ext.app.REMOTE_CALL_API',
                            polling_var  => 'Ext.app.REMOTE_EVENT_API',
                            auto_connect => 'HELL YEAH!';

local $RPC::ExtDirect::API::DEBUG = 1;

my $expected = q~
Ext.app.REMOTE_CALL_API = {
    "actions":{
        "Bar":[
                { "len":5, "name":"bar_bar" },
                { "formHandler":true, "name":"bar_baz" },
                { "len":4, "name":"bar_foo" }
              ],
        "Foo":[
                { "len":2, "name":"foo_bar" },
                { "name":"foo_baz", "params":["foo","bar","baz"] },
                { "name":"foo_blessed", "params":[], "strict":false },
                { "len":1, "name":"foo_foo" },
                { "len":0, "name":"foo_zero" }
              ],
        "Qux":[
                { "len":5, "name":"bar_bar" },
                { "formHandler":true, "name":"bar_baz" },
                { "len":4, "name":"bar_foo" },
                { "len":2, "name":"foo_bar" },
                { "name":"foo_baz", "params":["foo","bar","baz"] },
                { "len":1, "name":"foo_foo" }
              ]
    },
    "namespace":"myApp.Server",
    "type":"remoting",
    "url":"/router.cgi"
};
Ext.direct.Manager.addProvider(Ext.app.REMOTE_CALL_API);
Ext.app.REMOTE_EVENT_API = {
    "type":"polling",
    "url":"/poll.cgi"
};
Ext.direct.Manager.addProvider(Ext.app.REMOTE_EVENT_API);
~;

my $remoting_api = eval { RPC::ExtDirect::API->get_remoting_api() };

is      $@,            '',        "remoting_api() 3 eval $@";
cmp_api $remoting_api, $expected, "remoting_api() 3 result";
