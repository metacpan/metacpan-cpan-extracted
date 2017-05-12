# Statically (compile time) defined Hooks with lazy code resolution

use strict;
use warnings;

use Test::More tests => 2;
use RPC::ExtDirect::Test::Util;

use RPC::ExtDirect::Test::Pkg::Foo;
use RPC::ExtDirect::Test::Pkg::Bar;

our $WAS_THERE;

sub global_after {
    $WAS_THERE = 1;
}

use RPC::ExtDirect;
use RPC::ExtDirect::API
        before  => 'test::hooks::global_before',
        after   => \&global_after;

use lib 't/lib';
use test::hooks;

my $api        = RPC::ExtDirect->get_api();
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

