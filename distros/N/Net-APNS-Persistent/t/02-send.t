use Test::More tests => 9;
use Test::Exception;

BEGIN { use_ok('Net::APNS::Persistent') };

SKIP: {
    if (!($ENV{APNS_TEST_DEVICETOKEN} && $ENV{APNS_TEST_CERT} && $ENV{APNS_TEST_KEY})) {
        # make sure cpan installers see this
        my $msg = "skipping - can't make connection without environment variables: APNS_TEST_DEVICETOKEN APNS_TEST_CERT, APNS_TEST_KEY and (if needed) APNS_TEST_KEY_PASSWD";
        diag $msg;
        skip $msg, 8;
    }

    my %args = (
        sandbox => 1,
        cert => $ENV{APNS_TEST_CERT},
        key => $ENV{APNS_TEST_KEY},
       );

    $args{passwd} = $ENV{APNS_TEST_KEY_PASSED}
      if $ENV{APNS_TEST_KEY_PASSWD};
    
    isa_ok(
        my $apns = Net::APNS::Persistent->new(\%args),
        'Net::APNS::Persistent',
        "created Net::APNS::Persistent object"
       );

    sleep 3;
    
    lives_ok {
        $apns->queue_notification(
            $ENV{APNS_TEST_DEVICETOKEN},
            {
                aps => {
                    alert => '02-send.t first',
                    sound => 'default',
                    badge => 1,
                },
            },
           ) } "queued single notification";

    lives_ok { $apns->send_queue } "sent";

    sleep 3;

    lives_ok {
        $apns->queue_notification(
            $ENV{APNS_TEST_DEVICETOKEN},
            {
                aps => {
                    alert => '02-send.t second',
                    sound => 'default',
                    badge => 1,
                },
            },
           );
        $apns->queue_notification(
            $ENV{APNS_TEST_DEVICETOKEN},
            {
                aps => {
                    alert => '02-send.t third',
                    sound => 'default',
                    badge => 1,
                },
            },
           );        
    } "queued multiple notifications";

    lives_ok { $apns->send_queue } "sent";

    sleep 3;

        lives_ok {
        $apns->queue_notification(
            $ENV{APNS_TEST_DEVICETOKEN},
            {
                aps => {
                    alert => {
                        body => '02-send.t fourth',
                        'action-loc-key' => undef,
                    },
                    sound => 'default',
                    badge => 1,
                },
                foo => 'bar',
            },
           ) } "queued single notification with only one button and custom data";

    lives_ok { $apns->send_queue } "sent";

    lives_ok { $apns->disconnect } "disconnected";
}
