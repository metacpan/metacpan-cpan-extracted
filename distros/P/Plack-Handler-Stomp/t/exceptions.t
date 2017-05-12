#!perl
use lib 't/lib';
use Test::Routine;
use Test::Routine::Util;
use MyTesting;
use Net::Stomp::Frame;
use Test::Plack::Handler::Stomp;
with 'TestApp';

has t => (
    is => 'rw',
    default => sub { Test::Plack::Handler::Stomp->new() }
);

test 'unknown frames' => sub {
    my ($self) = @_;

    my $t=$self->t;

    $t->clear_frames_to_receive;
    $t->queue_frame_to_receive(Net::Stomp::Frame->new({
        command => 'WRONG',
        headers => { },
        body => 'boom',
    }));
    $t->set_arg(
        subscriptions => [
            {
                destination => '/queue/testing',
                path_info => '/my/path',
            },
        ],
        connect_retry_delay => 1,
    );

    my $exception = exception {
        $t->handler->run($self->psgi_test_app)
    };
    isa_ok($exception,'Plack::Handler::Stomp::Exceptions::UnknownFrame',
           'correct exception thrown');
    is($exception->frame->command,'WRONG',
       'frame reported');
};

test 'app error' => sub {
    my ($self) = @_;

    my $t=$self->t;

    $t->clear_calls_and_queues;
    $t->queue_frame_to_receive(Net::Stomp::Frame->new({
        command => 'MESSAGE',
        headers => {
            destination => '/queue/testing',
        },
        body => 'die now',
    }));

    my $exception = exception {
        $t->handler->run($self->psgi_test_app)
    };
    isa_ok($exception,'Plack::Handler::Stomp::Exceptions::AppError',
           'correct exception thrown');
    is($exception->previous_exception,"I died\n",
       'exception was saved');
    is($t->sent_frames_count,0,
       'the message was not ACKed');
};

run_me;
done_testing;
