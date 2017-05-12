use strict;
use warnings;

use RPC::ExtDirect::Test::Util;
use RPC::ExtDirect::Config;
use RPC::ExtDirect;

### Testing invalid inputs

use Test::More tests => 94;

use RPC::ExtDirect::Request;

use RPC::ExtDirect::Test::Pkg::Foo;
use RPC::ExtDirect::Test::Pkg::Bar;
use RPC::ExtDirect::Test::Pkg::Qux;
use RPC::ExtDirect::Test::Pkg::Hooks;
use RPC::ExtDirect::Test::Pkg::PollProvider;

my $tests = eval do { local $/; <DATA>; }       ## no critic
    or die "Can't eval test data: $@";

for my $test ( @$tests ) {

    # Unpack variables
    my ($name, $data, $expected_ran, $expected_result, $debug,
        $run_twice, $isa, $code, $exception)
        = @$test{ qw(name data ran_ok result debug run_twice isa code xcpt)
                };

    # Set debug flag according to the test
    $data->{config} = RPC::ExtDirect::Config->new( debug_request => $debug );
    $data->{api}    = RPC::ExtDirect->get_api();

    # Try to create object
    my $request = eval { RPC::ExtDirect::Request->new($data) };

    is     $@,       '', "$name new() eval $@";
    ok     $request,     "$name new() object created";
    ref_ok $request, $isa;

    # Try to run method
    my $ran_ok = eval { $request->run() };

    $exception ||= '';

    is_deep $@,      $exception,    "$name run() eval";
    is      $ran_ok, $expected_ran, "$name run() no error";

    # Try to run method second time, no result checks this time
    $ran_ok = eval { $request->run() } if $run_twice;

    # Try to get results
    my $result = eval { $request->result() };

    is $@, '', "$name result() eval $@";

    if ( $expected_result ) {
        is_deep $result, $expected_result, "$name result() deep";
    };

    ok $code->(), "$name custom check" if $code;
};

__DATA__
#line 66
[
    # Null input, debug off
    {
        name   => 'Failure 1, debug off', debug  => 0, ran_ok => '',
        data   => { action  => 'Nonexistent', method => 'nonexistent',
                    type    => 'rpc',         tid    => 123,
                    data    => [], },
        isa    => 'RPC::ExtDirect::Exception',
        result => { type    => 'exception',
                    action  => 'Nonexistent',
                    method  => 'nonexistent',
                    tid     => 123,
                    where   => 'ExtDirect',
                    message => 'An error has occured while processing '.
                               'request', },
    },
    # Action not found, debug off
    {
        name   => 'Failure 2, debug off', debug  => 0, ran_ok => '',
        data   => { action  => 'Nonexistent', method => 'nonexistent',
                    type    => 'rpc',         tid    => 111,
                    data    => [], },
        isa    => 'RPC::ExtDirect::Exception',
        result => { type    => 'exception',
                    action  => 'Nonexistent',
                    method  => 'nonexistent',
                    tid     => 111,
                    where   => 'ExtDirect',
                    message => 'An error has occured while processing '.
                               'request', },
    },
    # Invalid input 1, debug on
    {
        name   => 'Invalid input 1, debug on', debug => 1, ran_ok => '',
        data   => { action  => '', method => 'foo', type => 'rpc',
                    tid     => 1, data => [], },
        isa    => 'RPC::ExtDirect::Exception',
        result => { type    => 'exception',
                    action  => undef,
                    method  => undef,
                    tid     => undef,
                    where   => 'RPC::ExtDirect::Request->new',
                    message => 'ExtDirect action (class name) required' },
    },
    # Invalid input 2, debug on
    {
        name   => 'Invalid input 2, debug on', debug => 1, ran_ok => '',
        data   => { action  => 'Some', method => '', type => 'rpc',
                    tid     => 2, data => [], },
        isa    => 'RPC::ExtDirect::Exception',
        result => { type    => 'exception',
                    action  => undef,
                    method  => undef,
                    tid     => undef,
                    where   => 'RPC::ExtDirect::Request->new',
                    message => 'ExtDirect method name required' },
    },
    # Action not found, debug on
    {
        name   => 'Action not found, debug on', debug  => 1, ran_ok => '',
        data   => { action  => 'None',          method => 'nonexistent',
                    type    => 'rpc',           tid    => 111,
                    data    => [], },
        isa    => 'RPC::ExtDirect::Exception',
        result => { type    => 'exception',
                    action  => 'None',
                    method  => 'nonexistent',
                    tid     => 111,
                    where   => 'RPC::ExtDirect::Request->new',
                    message => 'ExtDirect action or method not found' },
    },
    # Not enough arguments
    {
        name   => 'Not enough args, debug on', debug => 1, ran_ok => '',
        data   => { action  => 'Qux', method => 'bar_foo', tid    => 222,
                    type    => 'rpc', data   => [ 1, 2, 3 ], },
        isa    => 'RPC::ExtDirect::Exception',
        result => { type    => 'exception',
                    action  => 'Qux',
                    method  => 'bar_foo',
                    tid     => 222,
                    where   => 'RPC::ExtDirect::API::Method->'.
                               'check_method_arguments',
                    message => 'ExtDirect Method Qux.bar_foo '.
                               'requires 4 argument(s) but only 3 '.
                               'are provided', },
    },
    # Tried to run method twice
    {
        name   => 'Try to run twice, debug on', debug => 1, ran_ok => 1,
        data   => { action  => 'Qux', method => 'foo_foo', tid => 333,
                    type    => 'rpc', data   => [ 123 ], },
        isa    => 'RPC::ExtDirect::Request',
        run_twice => 1,
        result => { type    => 'exception',
                    action  => 'Qux',
                    method  => 'foo_foo',
                    tid     => 333,
                    where   => 'RPC::ExtDirect::Request->run',
                    message => "ExtDirect request can't run more than once per batch"
                  },
    },
    # Method call failed
    {
        name   => 'Method failed, debug on', debug => 1, ran_ok => '',
        data   => { action  => 'Qux', method => 'bar_foo', tid => 444,
                    type    => 'rpc', data => [ 1, 2, 3, 4 ], },
        isa    => 'RPC::ExtDirect::Request',
        result => { type    => 'exception',
                    action  => 'Qux',
                    method  => 'bar_foo',
                    tid     => 444,
                    where   => 'RPC::ExtDirect::Test::Pkg::Qux->bar_foo',
                    message => "bar foo!", },
    },
    # Form handler called directly
    {
        name   => 'Form handler called directly', debug => 1, ran_ok => '',
        data   => { action => 'Bar', method => 'bar_baz', tid => 555,
                    type => 'rpc', data => {}, },
        isa    => 'RPC::ExtDirect::Exception',
        result => { type    => 'exception',
                    action  => 'Bar',
                    method  => 'bar_baz',
                    tid     => 555,
                    where   => 'RPC::ExtDirect::Request->check_arguments',
                    message => "ExtDirect formHandler method ".
                               "Bar.bar_baz should only be called ".
                               "with form submits", },
    },
    # Poll handler called directly
    {
        name   => 'Poll handler called directly', debug => 1, ran_ok => '',
        data   => { action => 'PollProvider', method => 'foo', tid => 666,
                    type => 'rpc', data => [], },
        isa    => 'RPC::ExtDirect::Exception',
        result => { type    => 'exception',
                    action  => 'PollProvider',
                    method  => 'foo',
                    tid     => 666,
                    where   => 'RPC::ExtDirect::Request->check_arguments',
                    message => "ExtDirect pollHandler method ".
                               "PollProvider.foo should not ".
                               "be called directly", },
    },

    # Nonexistent before hook
    {
        name   => 'Nonexistent before hook', debug => 1, ran_ok => '',
        data   => { action => 'Hooks', method => 'foo_foo', tid => 777,
                    type => 'rpc', data => [1], },
        isa    => 'RPC::ExtDirect::Request',
        result => { type    => 'exception',
                    action  => 'Hooks',
                    method  => 'foo_foo',
                    tid     => 777,
                    where   => 'RPC::ExtDirect::Test::Pkg::Hooks->foo_foo',
                    message => 'Undefined subroutine '.
                               '&RPC::ExtDirect::Test::Pkg::Hooks::'.
                               'nonexistent_before_hook called',
                  },
        code   => sub { !$RPC::ExtDirect::Test::Pkg::Hooks::foo_foo_called },
    },

    # Before hook unset (NONE)
    {
        name   => 'Before hook unset (NONE)', debug => 1, ran_ok => 1,
        data   => { action => 'Hooks', method => 'foo_bar', tid => 888,
                    type => 'rpc', data => [ 1, 2, ], },
        isa    => 'RPC::ExtDirect::Request',
        result => { type => 'rpc', action => 'Hooks', method => 'foo_bar',
                    tid => 888, result => 1 },
        code   => sub { $RPC::ExtDirect::Test::Pkg::Hooks::foo_bar_called },
    },

    # After hook
    {
        name   => 'After hook', debug => 1, ran_ok => 1,
        data   => { action => 'Hooks', method => 'foo_baz',
                    tid => 999, type => 'rpc',
                    data => { foo => 111, bar => 222, baz => 333 }, },
        isa    => 'RPC::ExtDirect::Request',
        result => { type   => 'rpc', tid => 999,
                    action => 'Hooks', method => 'foo_baz',
                    result => { msg  => 'foo! bar! baz!',
                                foo => 111, bar => 222, baz => 333 }, },
        code   => sub { !!$RPC::ExtDirect::Test::Pkg::Hooks::foo_baz_called },
    },
]

