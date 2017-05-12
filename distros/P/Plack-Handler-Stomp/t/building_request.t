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
            'message-id' => 123,
            'content-type' => 'json',
        },
        body => 'foo',
    }));

    $t->handler->run($self->psgi_test_app);

    my %expected = (
        # server
        SERVER_NAME => 'localhost',
        SERVER_PORT => 0,
        SERVER_PROTOCOL => 'STOMP',

        # client
        REQUEST_METHOD => 'POST',
        REQUEST_URI => '/queue/testing',
        SCRIPT_NAME => '',
        PATH_INFO => '/queue/testing',
        QUERY_STRING => '',

        # broker
        REMOTE_ADDR => 'localhost',

        # http
        HTTP_USER_AGENT => 'Net::Stomp',
        CONTENT_LENGTH => 3,
        CONTENT_TYPE => 'json',

        # psgi
        'psgi.version' => [1,0],
        'psgi.url_scheme' => 'http',
        'psgi.multithread' => 0,
        'psgi.multiprocess' => 0,
        'psgi.run_once' => 0,
        'psgi.nonblocking' => 0,
        'psgi.streaming' => 1,

        # stomp
        'jms.destination' => '/queue/testing',
        'jms.message-id' => 123,
        'jms.content-type' => 'json',

        # application
        'testapp.body' => 'foo',
    );

    is($self->requests_count,1,'one request handled');
    is_deeply($self->requests_received->[0],
              \%expected,
              'with expected content');

    is($t->sent_frames_count,1,'sent one frame');
    my $frame = $t->frames_sent->[0];
    is($frame->command,'ACK',q{it's an ack});
    is_deeply($frame->headers,
              { 'message-id' => 123 },
              'for the right message');
};

run_me;
done_testing;
