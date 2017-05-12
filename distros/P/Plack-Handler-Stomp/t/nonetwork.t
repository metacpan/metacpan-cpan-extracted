#!perl
use lib 't/lib';
use Test::Routine;
use Test::Routine::Util;
use MyTesting;
use JSON::XS;
use Net::Stomp::MooseHelpers::ReadTrace;
use File::ChangeNotify;
with 'RunTestAppNoNet';
use Data::Printer;

test 'talk to the app' => sub {
    my ($self) = @_;

    my $trace_dir = $self->trace_dir;

    my $reader = Net::Stomp::MooseHelpers::ReadTrace->new({
        trace_basedir => $trace_dir,
    });

    # we have to call this *before* creating the child (and thus the
    # File::ChangeNotify object), otherwise
    # Plack::Handler::Stomp::NoNetwork believes that its directories
    # are going away and complains
    $reader->clear_destination();

    my $child = $self->child;
    my $prod = $self->producer;
    my $reply_to = '/remote-temp-queue/foo';

    my @cases = (
        {
            destination => '/queue/plack-handler-stomp-test',
            JMSType => 'anything',
            custom_header => '3',
            path_info => '/queue/plack-handler-stomp-test',
        },
        {
            destination => '/topic/plack-handler-stomp-test-1',
            JMSType => 'test_foo',
            custom_header => '3',
            path_info => '/topic/ch1',
        },
        {
            destination => '/topic/plack-handler-stomp-test-1',
            JMSType => 'anything',
            custom_header => '1',
            path_info => '/topic/ch1',
        },
        {
            destination => '/topic/plack-handler-stomp-test-2',
            JMSType => 'test_bar',
            custom_header => '3',
            path_info => '/topic/ch2',
        },
        {
            destination => '/topic/plack-handler-stomp-test-2',
            JMSType => 'anything',
            custom_header => '2',
            path_info => '/topic/ch2',
        },
    );

    subtest 'send & reply' => sub {
        for my $case (@cases) {
            my $message = {
                payload => { foo => 1, bar => 2 },
                reply_to => 'foo',
                type => 'testaction',
            };

            # same as above, clear before creating the watcher
            $reader->clear_destination($reply_to);

            my $dir = $reader->trace_subdir_for_destination($reply_to);

            my $watcher = File::ChangeNotify->instantiate_watcher(
                directories => [ $dir->stringify ],
                filter => qr{^\d+\.\d+-send-},
            );

            $prod->send(
                $case->{destination},
                {
                    type => $case->{JMSType},
                    custom_header => $case->{custom_header},
                },
                JSON::XS::encode_json($message),
            );

            $watcher->wait_for_events;

            my ($reply_frame,@rest) = $reader->sorted_frames($reply_to);
            ok($reply_frame, 'got a reply');
            ok(!@rest,'and only one');

            my $response = JSON::XS::decode_json($reply_frame->body);
            ok($response, 'response ok');
            ok($response->{path_info} eq $case->{path_info}, 'worked');
        }
    };

    subtest 'subscriptions' => sub {
        my $watcher = File::ChangeNotify->instantiate_watcher(
            directories => [ $trace_dir ],
            filter => qr{^\d+\.\d+-send-},
        );

        $prod->send(
            '/queue/not-subscribed',
            {
                type => 'whatever',
            },
            'does not matter'
        );

        sleep(1);

        # the mess with forward and backward slashes is necessary:
        # sometimes, under Win32, we get filenames with mixed slashes,
        # so we have to accept whatever looks vaguely right. Might
        # break on VMS, though...
        my $sent_dir = $reader->trace_subdir_for_destination('/queue/not-subscribed')->absolute;
        my $sent_dir_re = join '[/\\\\]', map {quotemeta}
            $sent_dir->volume,$sent_dir->dir_list(1);
        my $sent_file_re = join '[/\\\\]', (map {quotemeta}
            $sent_dir->volume,$sent_dir->dir_list(1)),
                '\d+\.\d+-send-';
        my (@events) = $watcher->wait_for_events;

        cmp_deeply(
            \@events,
            [
                methods(type => 'create',
                        path => re(qr{$sent_dir_re})),
                methods(type => 'create',
                        path => re(qr{$sent_file_re})),
            ],
            'one message sent by us, none by the consumer'
        ) or note p @events;

    };

    $prod->send(
        '/topic/plack-handler-stomp-test',
        {
            type => 'test_foo',
        },
        JSON::XS::encode_json({exit_now=>1}),
    );
};

run_me;

done_testing;
