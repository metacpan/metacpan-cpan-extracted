#!perl
use lib 't/lib';
use Test::Routine;
use Test::Routine::Util;
use MyTesting;
use Net::Stomp::Frame;
use Test::Plack::Handler::Stomp;
with 'TestApp';

test 'a simple response' => sub {
    my ($self) = @_;

    my $t = Test::Plack::Handler::Stomp->new();

    $t->clear_frames_to_receive;
    $t->queue_frame_to_receive(Net::Stomp::Frame->new({
        command => 'MESSAGE',
        headers => {
            destination => '/queue/testing',
            subscription => 0,
            'message-id' => '1234',
        },
        body => 'please reply',
    }));

    $t->set_arg(
        subscriptions => [
            {
                destination => '/queue/testing',
            },
        ],
    );

    $t->handler->run($self->psgi_test_app);

    is($t->sent_frames_count,2,
       'ACK & reply');
    my ($reply,$ack) = @{$t->frames_sent};
    is($reply->command,'SEND',
       'reply is a send');
    is($reply->body,'hello',
       'reply has correct body');
    is($reply->headers->{destination},
       '/remote-temp-queue/reply_queue',
       'reply has correct destination');
    is($reply->headers->{foo},
       'something',
       'reply has correct headers');
    is($ack->command,'ACK',
       'ack is an ack');
    is($ack->headers->{'message-id'},'1234',
       'ack with correct message-id');
};

run_me;
done_testing;
