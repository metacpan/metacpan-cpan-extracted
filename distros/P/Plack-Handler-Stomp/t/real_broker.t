#!perl
use lib 't/lib';
use Test::Routine;
use Test::Routine::Util;
use MyTesting;
use JSON::XS;
use Net::Stomp::MooseHelpers::ReadTrace;
with 'RunTestApp';

test 'talk to the app' => sub {
    my ($self) = @_;

    my $child = $self->child;
    my $conn = $self->server_conn;
    my $reply_to = $self->reply_to;

    my @cases = (
        {
            destination => '/queue/plack-handler-stomp-test',
            JMSType => 'anything',
            custom_header => '3',
            path_info => '/queue/plack-handler-stomp-test',
        },
        {
            destination => '/topic/plack-handler-stomp-test',
            JMSType => 'test_foo',
            custom_header => '3',
            path_info => '/topic/ch1',
        },
        {
            destination => '/topic/plack-handler-stomp-test',
            JMSType => 'anything',
            custom_header => '1',
            path_info => '/topic/ch1',
        },
        {
            destination => '/topic/plack-handler-stomp-test',
            JMSType => 'test_bar',
            custom_header => '3',
            path_info => '/topic/ch2',
        },
        {
            destination => '/topic/plack-handler-stomp-test',
            JMSType => 'anything',
            custom_header => '2',
            path_info => '/topic/ch2',
        },
    );

    subtest 'send & reply' => sub {
        for my $case (@cases) {
            my $message = {
                payload => { foo => 1, bar => 2 },
                reply_to => $reply_to,
                type => 'testaction',
            };

            $conn->send( {
                destination => $case->{destination},
                body => JSON::XS::encode_json($message),
                JMSType => $case->{JMSType},
                custom_header => $case->{custom_header},
            } );

            my $reply_frame = $conn->receive_frame();
            ok($reply_frame, 'got a reply');

            my $response = JSON::XS::decode_json($reply_frame->body);
            ok($response, 'response ok');
            ok($response->{path_info} eq $case->{path_info}, 'worked');
        }
    };

    subtest 'tracing' => sub {
        my $reader = Net::Stomp::MooseHelpers::ReadTrace->new({
            trace_basedir => $self->trace_dir,
        });
        my @frames = $reader->sorted_frames();

        my @case_comparers = map {
            my %h=%$_;
            $h{type}=delete $h{JMSType};
            my $pi=delete $h{path_info};

            (
                methods(command=>'MESSAGE',
                        headers=>superhashof(\%h),
                    ),
                methods(command=>'SEND',
                        headers=>{
                            destination=>re(qr{^/remote-temp-queue/}),
                        },
                        body => re(qr{"path_info":"\Q$pi\E"}),
                    ),
                methods(command=>'ACK'),
            )
        } @cases;

        cmp_deeply(\@frames,
                   [
                       methods(command=>'CONNECT'),
                       methods(command=>'CONNECTED'),
                       (methods(command=>'SUBSCRIBE')) x 3,
                       @case_comparers,
                   ],
                   'tracing works'
               );
    };

    # we send the "exit now" command on the topic, so we're sure we
    # won't find it on the next run
    #
    # BrokerTestApp exits without ACK-ing the message, so it would
    # remain on the queue, ready to stop the application the next time
    # we try to run the test
    $conn->send( {
        destination => '/topic/plack-handler-stomp-test',
        body => JSON::XS::encode_json({exit_now=>1}),
        JMSType => 'test_foo',
    } );

};

run_me;
done_testing;
