use strict;
use warnings;

use Test::More;
use Future;
use Mojo::WebSocketProxy::Backend::ConsumerGroups;
use Test::MockObject;
use Test::MockModule;
use Test::Fatal;

my $redis = Test::MockObject->new();
$redis->mock(_execute  => sub { pop->() });
$redis->mock(subscribe => sub { });
$redis->mock(on        => sub { });

my $cg_mock = Test::MockModule->new('Mojo::WebSocketProxy::Backend::ConsumerGroups');

my $timeouts_config = {
    general => 1,
    mt5     => 5,
    payment => 4
};

my $cg_backend = Mojo::WebSocketProxy::Backend::ConsumerGroups->new(
    redis                    => $redis,
    timeout                  => 1,
    queue_separation_enabled => 1,
    category_timeout_config  => $timeouts_config,
);

my $passed_timout;
$cg_mock->mock(
    request => sub {
        my ($self, $request_data, $category_name, $category_timeout) = @_;
        $passed_timout = $category_timeout;
        return Future->done();
    });

my $passed_deadline;
$cg_mock->mock(
    _prepare_request_data => sub {
        my ($self, $c, $req_storage, $category_deadline) = @_;
        $passed_deadline = $category_deadline;
        return {};
    });

#Controller Mock
my $c = Test::MockObject->new();
$c->mock(tx        => sub { 1 });
$c->mock(wsp_error => sub { my %e; @e{qw(type code msg)} = @_[1, 2, 3]; return \%e });

my $result;
$c->mock(send => sub { $result = $_[1]->{json} });

subtest 'RPC Timeout extension inactive' => sub {
    my $req_storage = {
        msg_type     => 'ping',
        method       => 'ping',
        category     => 'payment',
        stash_params => [],
        args         => {},
    };

    $passed_deadline = undef;
    $passed_timout   = undef;

    $cg_backend->call_rpc($c, $req_storage);

    is $passed_deadline, 4, 'Correct deadline set';
    is $passed_timout,   4, 'Correct timeout set';

};

subtest 'RPC Timeout extension active' => sub {
    my $req_storage = {
        rpc_timeout_extend_offset     => 10,
        rpc_timeout_extend_percentage => 25,
        msg_type                      => 'ping',
        method                        => 'ping',
        category                      => 'payment',
        stash_params                  => [],
        args                          => {},
    };

    my $expected_deadline = 4;
    my $expected_timeout  = 4 + 10 + 1;

    $passed_deadline = undef;
    $passed_timout   = undef;

    $cg_backend->call_rpc($c, $req_storage);

    is $passed_deadline, $expected_deadline, 'Correct deadline set';
    is $passed_timout,   $expected_timeout,  'Correct timeout set';

    $cg_mock->unmock_all();
};

$cg_mock->unmock_all();

done_testing();
