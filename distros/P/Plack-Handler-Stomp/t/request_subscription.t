#!perl
use lib 't/lib';
use Test::Routine;
use Test::Routine::Util;
use MyTesting;
use Net::Stomp::Frame;
use Test::Plack::Handler::Stomp;
with 'TestApp';

test 'a simple request' => sub {
    my ($self) = @_;

    my $t = Test::Plack::Handler::Stomp->new();

    $t->clear_frames_to_receive;
    $t->queue_frame_to_receive(Net::Stomp::Frame->new({
        command => 'MESSAGE',
        headers => {
            destination => '/queue/testing',
        },
        body => 'foo',
    }));
    $t->queue_frame_to_receive(Net::Stomp::Frame->new({
        command => 'MESSAGE',
        headers => {
            destination => '/queue/testing-wrong-on-purpose',
            subscription => '0',
        },
        body => 'foo',
    }));

    $t->set_arg(
        subscriptions => [
            {
                destination => '/queue/testing',
                path_info => '/my/path',
            },
        ],
    );

    $t->handler->run($self->psgi_test_app);

    my $req = $self->requests_received->[-1];
    is($req->{'jms.destination'},'/queue/testing','destination passed through');
    is($req->{PATH_INFO},'/my/path','path mapped');

    $t->handler->run($self->psgi_test_app);

    $req = $self->requests_received->[-1];
    is($req->{'jms.destination'},'/queue/testing-wrong-on-purpose','destination passed through');
    is($req->{PATH_INFO},'/my/path','path mapped');
};

run_me;
done_testing;
