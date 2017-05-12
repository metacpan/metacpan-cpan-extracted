# Test Ext.Direct API declaration handling

use strict;
use warnings;

use RPC::ExtDirect::Config;

use Test::More tests => 93;

use RPC::ExtDirect::Test::Util;

BEGIN { use_ok 'RPC::ExtDirect::Client::API' };

my $source_js = <<'END_JS';
REMOTING_API = {
    "actions":{
        "Bar":[
                { "len":5, "name":"bar_bar" },
                { "formHandler":true, "name":"bar_baz" },
                { "len":4, "name":"bar_foo" }
              ],
        "Foo":[
                { "len":2, "name":"foo_bar" },
                { "name":"foo_baz", "params":["foo","bar","baz"] },
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
    "type":"remoting",
    "url":"/extdirectrouter"
};
Ext.direct.Manager.addProvider(REMOTING_API);
POLLING_API = {
    "type":"polling",
    "url":"/extdirectevents"
};
Ext.direct.Manager.addProvider(POLLING_API);
END_JS

my $config = RPC::ExtDirect::Config->new(
    remoting_var => 'REMOTING_API',
);

my $aclass = 'RPC::ExtDirect::Client::API';

my $api = eval {
    $aclass->new_from_js(
        config => $config,
        js     => $source_js,
    )
};

is     $@,   '',      "Constructor eval $@";
ok     $api,          'Got object';
ref_ok $api, $aclass, 'Right object, too,';

is $api->type, 'remoting',         'Type';
is $api->url,  '/extdirectrouter', 'URL';

my @tests = (
    { name    => 'Bar',
      methods => [
        { name => 'bar_bar', len => 5, is_named => !1, is_ordered => 1,
          formHandler => undef, params => undef, },
        { name => 'bar_baz', len => undef, is_named => !1, is_ordered => !1,
          formHandler => 1, params => undef, },
        { name => 'bar_foo', len => 4, is_named => !1, is_ordered => 1,
          formHandler => undef, params => undef, },
      ],
    },
    { name    => 'Foo',
      methods => [
        { name => 'foo_bar', len => 2, is_named => !1, is_ordered => 1,
          formHandler => undef, params => undef, },
        { name => 'foo_baz', len => undef, is_named => 1, is_ordered => !1,
          formHandler => undef, params => [ 'foo', 'bar', 'baz' ],
        },
        { name => 'foo_foo', len => 1, is_named => !1, is_ordered => 1,
          formHandler => undef, params => undef, },
        { name => 'foo_zero', len => 0, is_named => !1, is_ordered => 1,
          formHandler => undef, params => undef, },
      ],
    },
    { name    => 'Qux',
      methods => [
        { name => 'bar_bar', len => 5, is_named => !1, is_ordered => 1,
          formHandler => undef, params => undef, },
        { name => 'bar_baz', len => undef, is_named => !1, is_ordered => !1,
          formHandler => 1, params => undef, },
        { name => 'bar_foo', len => 4, is_named => !1, is_ordered => 1,
          formHandler => undef, params => undef, },
        { name => 'foo_bar', len => 2, is_named => !1, is_ordered => 1,
          formHandler => undef, params => undef, },
        { name => 'foo_baz', len => undef, is_named => 1, is_ordered => !1,
          formHandler => undef, params => [ 'foo', 'bar', 'baz' ],
        },
        { name => 'foo_foo', len => 1, is_named => !1, is_ordered => 1,
          formHandler => undef, params => undef, },
      ],
    },
);

my $sort_actions = sub { $a->name cmp $b->name };

# Test all actions at once

my @actions = sort $sort_actions $api->actions;

for my $action ( @actions ) {
    my $test = shift @tests;

    my $aname = $action->name;
    
    is $aname, $test->{name}, "Action $aname name";

    my @methods = @{ $test->{methods} };

    for my $method ( @methods ) {
        my $mname = $method->{name};

        while ( my ( $meth, $exp ) = each %$method ) {
            if ( $meth eq 'params' ) {
                is_deep $action->method($mname)->$meth, $exp,
                        "Action $aname method $mname: $meth";
            }
            else {
                is $action->method($mname)->$meth, $exp,
                   "Action $aname method $mname: $meth";
            };
        };
    };
};

# Test returning a sliced set of actions

@actions = sort $sort_actions $api->actions('Qux', 'Foo');

is scalar @actions,   2,     'Number of sliced actions';
is $actions[0]->name, 'Foo', 'First sliced action name';
is $actions[1]->name, 'Qux', 'Second sliced action name';

# Test returning a single action in scalar context

my $action = $api->actions('Bar');

my $act_class = 'RPC::ExtDirect::API::Action';

ok     $action,                   'Got single action object';
ref_ok $action,       $act_class, 'Right single action object class, too,';
is     $action->name, 'Bar',      'Single action name';

