use Test::More tests => 7;
use Test::Exception;

BEGIN { use_ok('Net::APNS::Persistent') };

SKIP: {
    if (!($ENV{APNS_TEST_CERT} && $ENV{APNS_TEST_KEY})) {
        # make sure cpan installers see this
        my $msg = "skipping - can't make connection without environment variables: APNS_TEST_CERT, APNS_TEST_KEY and (if needed) APNS_TEST_KEY_PASSWD";
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
    
    my $conn;
    lives_ok { $conn = $apns->_connection } "obtained connection";
    is(ref($conn), 'ARRAY', 'connection data is arrayref');
    is(scalar(@{$conn}), 3, 'connection data contains 3 elements');
    is(ref($conn->[0]), 'GLOB', 'first connection bit looks like a socket');
    
    # how to test the opaque pointers?
    
    lives_ok { $apns->disconnect } "disconnected";
}
