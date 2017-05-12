# Dynamically defined Hooks with eager and lazy code resolution

use strict;
use warnings;

use Test::More tests => 2;
use RPC::ExtDirect::Test::Util;

our $WAS_THERE;

sub global_after {
    $WAS_THERE = 1;
}

use RPC::ExtDirect::API;

use lib 't/lib';
use test::hooks;

my $api = RPC::ExtDirect::API->new_from_hashref(
    api_href => {
        before => 'test::hooks::global_before',
        after  => \&global_after,

        Foo => {
            methods => {
                foo_zero => { len => 0 },
            },
        }
    }
);

my $method_ref = $api->get_method_by_name('Foo', 'foo_zero');

$api->before->run(
    api        => $api,
    method_ref => $method_ref,
);

ok $test::hooks::WAS_THERE, "Before hook resolved";

$api->after->run(
    api        => $api,
    method_ref => $method_ref,
);

ok $::WAS_THERE, "After hook resolved";

