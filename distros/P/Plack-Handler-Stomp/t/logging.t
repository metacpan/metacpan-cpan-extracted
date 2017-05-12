#!perl
use lib 't/lib';
use Test::Routine;
use Test::Routine::Util;
use MyTesting;
use Net::Stomp::Frame;
use Test::Plack::Handler::Stomp;
with 'TestApp';

test 'custom logger' => sub {
    my ($self) = @_;

    my $t = Test::Plack::Handler::Stomp->new();

    $t->clear_frames_to_receive;
    $t->queue_frame_to_receive(Net::Stomp::Frame->new({
        command => 'MESSAGE',
        headers => {
            destination => '/queue/testing',
            subscription => 0,
        },
        body => 'error please',
    }));
    $t->queue_frame_to_receive(Net::Stomp::Frame->new({
        command => 'RECEIPT',
        headers => {
            'receipt-id' => 1234,
        },
        body => '',
    }));
    $t->queue_frame_to_receive(Net::Stomp::Frame->new({
        command => 'ERROR',
        headers => {
            message => 'testing error',
        },
        body => '',
    }));

    $t->set_arg(
        subscriptions => [
            {
                destination => '/queue/testing',
            },
        ],
    );

    $t->handler->run($self->psgi_test_app);
    my $msg = $t->log_messages->[-1];
    is_deeply($msg,
              ['error','your error'],
              'app error logged');

    $t->handler->run($self->psgi_test_app);
    $msg = $t->log_messages->[-1];
    is_deeply($msg,
              ['debug','ignored RECEIPT frame for 1234'],
              'receipt debug logged');

    $t->handler->run($self->psgi_test_app);
    $msg = $t->log_messages->[-1];
    is_deeply($msg,
              ['warn','testing error'],
              'STOMP ERROR frame logged');
};

run_me;
done_testing;
