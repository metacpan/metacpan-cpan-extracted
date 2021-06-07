use strict;
use warnings;

use Myriad;
use Myriad::Commands;
use Test::More;
use Test::Fatal;
use Test::MockModule;
use Test::MockObject;
use Future::AsyncAwait;
use IO::Async::Test;

sub loop_notifiers {
    my $loop = shift;

    my @current_notifiers = $loop->notifiers;
    my %loaded_in_loop = map { ref()  => 1 } @current_notifiers;
    return \%loaded_in_loop;
}

my $command_module = Test::MockModule->new('Myriad::Commands');
my $command = 'test';
my $command_is_called = 0;
$command_module->mock($command, async sub { my ($self, $param) = @_; $command_is_called = $param; });

my $myriad = new_ok('Myriad');
my $metaclass = Object::Pad::MOP::Class->for_class('Myriad');
my $loop = $myriad->loop;
testing_loop($loop);

subtest "class methods and proper initialization" => sub {
    can_ok($myriad, qw(configure_from_argv loop registry redis rpc_client rpc http subscription storage add_service service_by_name ryu shutdown run));


    my $command_param = 'Testing';
    wait_for_future($myriad->configure_from_argv('-l', 'debug', '--subscription_transport', 'memory', '--rpc_transport', 'memory', '--storage_transport', 'memory', $command, $command_param))->get;

    # Check configure_from_argv init objects
    my $loop = $metaclass->get_slot('$loop')->value($myriad);
    isa_ok($loop, 'IO::Async::Loop', 'Loop is set');
    isa_ok($myriad->config, 'Myriad::Config', 'Config is set');

    # Logging setup
    is($myriad->config->log_level, 'debug', 'Log level matching');
    isa_ok(@{$myriad->config->log_level->{subscriptions}}[0], 'CODE', 'Logging has been setup');

    # Tracing setup
    isa_ok($metaclass->get_slot('$tracing')->value($myriad), 'Net::Async::OpenTracing', 'Tracing is set');
    my $shutdown_tasks = $metaclass->get_slot('$shutdown_tasks')->value($myriad);
    isa_ok($shutdown_tasks->[-1], 'CODE', 'Added to shutdown tasks');
    is(@$shutdown_tasks, 1, 'One added shutdown task');

    my $current_notifiers = loop_notifiers($myriad->loop);
    ok($current_notifiers->{'Net::Async::OpenTracing'}, 'Tracing is added to  loop');

    # Since we passing test command
    # No Service, or plugin is setup.

    # Command
    isa_ok($metaclass->get_slot('$commands')->value($myriad), 'Myriad::Commands', 'Command is set');
    like($command_is_called, qr/$command_param/, 'Test Command has been found and called');

};

subtest "Myriad attributes setting tests" => sub {

    # RPC
    my $rpc = $myriad->rpc;
    isa_ok($metaclass->get_slot('$rpc')->value($myriad), 'Myriad::RPC::Implementation::Memory', 'Myriad RPC is set');
    my $current_notifiers = loop_notifiers($myriad->loop);
    ok($current_notifiers->{'Myriad::RPC::Implementation::Memory'}, 'RPC is added to loop');
    my $shutdown_tasks = $metaclass->get_slot('$shutdown_tasks')->value($myriad);
    isa_ok($shutdown_tasks->[-1], 'CODE', 'Added to shutdown tasks');
    is(@$shutdown_tasks, 2, 'Two added shutdown tasks');

    # RPC Client
    my $rpc_client = $myriad->rpc_client;
    isa_ok($rpc_client, 'Myriad::RPC::Client::Implementation::Memory', 'Myriad RPC Client is set');
    $current_notifiers = loop_notifiers($myriad->loop);
    ok($current_notifiers->{'Myriad::RPC::Client::Implementation::Memory'}, 'RPC Cleint is added to loop');

    # HTTP
    my $http = $myriad->http;
    isa_ok($metaclass->get_slot('$http')->value($myriad), 'Myriad::Transport::HTTP', 'Myriad HTTP is set');
    $current_notifiers = loop_notifiers($myriad->loop);
    ok($current_notifiers->{'Myriad::Transport::HTTP'}, 'HTTP is added to loop');

    # Subscription
    my $subscription = $myriad->subscription;
    isa_ok($metaclass->get_slot('$subscription')->value($myriad), 'Myriad::Subscription::Implementation::Memory', 'Myriad Subscription is set');
    $current_notifiers = loop_notifiers($myriad->loop);
    ok($current_notifiers->{'Myriad::Subscription::Implementation::Memory'}, 'Subscription is added to loop');

    # Storage
    my $storage = $myriad->storage;
    isa_ok($metaclass->get_slot('$storage')->value($myriad), 'Myriad::Storage::Implementation::Memory', 'Myriad Storage is set');

    # Registry and ryu
    isa_ok($myriad->registry, 'Myriad::Registry', 'Myriad::Registry is set');
    my $ryu = $myriad->ryu;
    isa_ok($metaclass->get_slot('$ryu')->value($myriad), 'Ryu::Async', 'Myriad Ryu is set');
    $current_notifiers = loop_notifiers($myriad->loop);
    ok($current_notifiers->{'Ryu::Async'}, 'Ryu is added to loop');

};

subtest  "Run and shutdown behaviour" => sub {

    like(exception {
        wait_for_future($myriad->shutdown)->get
    }, qr/attempting to shut down before we have started,/, 'can not shutdown as nothing started yet.');

    my $shutdown_task_called = 0;
    my $shutdown_test = async sub { pass('Shutdown task has been called'); $shutdown_task_called++; return; };
    my $service_mock = Test::MockObject->new();
    $service_mock->mock( 'shutdown', $shutdown_test );

    $metaclass->get_slot('$shutdown_tasks')->value($myriad) = [$shutdown_test];
    $metaclass->get_slot('$services')->value($myriad) = { testing_service => $service_mock };

    wait_for_future(Future->needs_all(
        $loop->delay_future(after => 0)->on_ready(sub {
            is(exception {
                wait_for_future($myriad->shutdown)->get
            }, undef, 'can shut down without exceptions arising');
        }),
        $myriad->run,
    ))->get;

    is($shutdown_task_called, 2, 'both shutdown operations has been called successfully');

};
done_testing;
