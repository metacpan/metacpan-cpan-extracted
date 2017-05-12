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
                    alert => "03-send-large.t first
Beware the Jubjub bird, and shun
  The frumious Bandersnatch!'
He took his vorpal sword in hand:
  Long time the manxome foe he sought --
So rested he by the Tumtum tree,
  And stood awhile in thought.
And, as in uffish thought he stood,
  The Jabberwock, with eyes of flame,
Came whiffling through the tulgey wood,
  And burbled as it came!
One, two! One, two! And through and through
  The vorpal blade went snicker-snack!
He left it dead, and with its head
  He went galumphing back.
'And, has thou slain the Jabberwock?
  Come to my arms, my beamish boy!
O frabjous day! Callooh! Callay!'
  He chortled in his joy.",
                    sound => 'default',
                    badge => 1,
                },
            },
           ) } "queued single large notification";

    lives_ok { $apns->send_queue } "sent";

    sleep 3;

    lives_ok {
        $apns->queue_notification(
            $ENV{APNS_TEST_DEVICETOKEN},
            {
                aps => {
                    alert => '02-send.t second
There was movement at the station, for the word had passed around
That the colt from old Regret had got away,
And had joined the wild bush horses - he was worth a thousand pound,
So all the cracks had gathered to the fray.
All the tried and noted riders from the stations near and far
Had mustered at the homestead overnight,
For the bushmen love hard riding where the wild bush horses are,
And the stock-horse snuffs the battle with delight.',
                    sound => 'default',
                    badge => 1,
                },
            },
           );
        $apns->queue_notification(
            $ENV{APNS_TEST_DEVICETOKEN},
            {
                aps => {
                    alert => "02-send.t third
       Blessed are the poor in spirit, 
For theirs is the kingdom of heaven. 
       Blessed are those who mourn, 
For they shall be comforted. 
       Blessed are the meek, 
For they shall inherit the earth. 
       Blessed are those who hunger and thirst for righteousness, 
For they shall be filled. 
       Blessed are the merciful, 
For they shall obtain mercy. 
       Blessed are the pure in heart, 
For they shall see God. 
       Blessed are the peacemakers, 
For they shall be called sons of God. 
       Blessed are those who are persecuted for righteousness' sake, 
For theirs is the kingdom of heaven.",
                    sound => 'default',
                    badge => 1,
                },
            },
           );        
    } "queued multiple large notifications";

    lives_ok { $apns->send_queue } "sent";

    sleep 5;

    lives_ok {
        $apns->queue_notification(
            $ENV{APNS_TEST_DEVICETOKEN},
            {
                aps => {
                    alert => "02-send.t fourth",
                    sound => 'default',
                    badge => 1,
                },
            },
           );        
    } "queued single notification again, just to make sure we haven't messed up the byte order";

    lives_ok { $apns->send_queue } "sent";


    lives_ok { $apns->disconnect } "disconnected";
}
