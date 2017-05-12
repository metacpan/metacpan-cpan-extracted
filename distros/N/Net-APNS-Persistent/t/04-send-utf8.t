use Test::More tests => 7;
use Test::Exception;
use Encode;
use FindBin;

use utf8;

BEGIN { use_ok('Net::APNS::Persistent') };

SKIP: {
    if (!($ENV{APNS_TEST_DEVICETOKEN} && $ENV{APNS_TEST_CERT} && $ENV{APNS_TEST_KEY})) {
        # make sure cpan installers see this
        my $msg = "skipping - can't make connection without environment variables: APNS_TEST_DEVICETOKEN APNS_TEST_CERT, APNS_TEST_KEY and (if needed) APNS_TEST_KEY_PASSWD";
        diag $msg;
        skip $msg, 6;
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

    sleep 5;
    
    lives_ok {
        $apns->queue_notification(
            $ENV{APNS_TEST_DEVICETOKEN},
            {
                aps => {
                    alert => "caf\xc3\xa9",
                    sound => 'default',
                    badge => 1,
                },
            },
           );
    } "queued single large utf8 notification";

    lives_ok { $apns->send_queue } "sent";

    sleep 5;
    
    my $utf8_text = "";
    open my $utf8_text_fh, '<', $FindBin::Bin . '/utf8-Demosthenes.txt'
      or die "unable to open utf8-Demosthenes.txt: $!";

    binmode $utf8_text_fh;

    while (<$utf8_text_fh>) {
        $utf8_text .= $_;
    }

    lives_ok {
        $apns->queue_notification(
            $ENV{APNS_TEST_DEVICETOKEN},
            {
                aps => {
                    alert => $utf8_text,
                    sound => 'default',
                    badge => 1,
                },
            },
           );
    } "queued single large utf8 notification";

    lives_ok { $apns->send_queue } "sent";

    lives_ok { $apns->disconnect } "disconnected";
}
