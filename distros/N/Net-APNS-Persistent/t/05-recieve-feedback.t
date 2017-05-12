use Test::More tests => 7;
use Test::Exception;

BEGIN { use_ok('Net::APNS::Feedback') };

my $feedback;

SKIP: {
    if (!($ENV{APNS_TEST_CERT} && $ENV{APNS_TEST_KEY})) {
        # make sure cpan installers see this
        my $msg = "skipping - can't make connection without environment variables: APNS_TEST_CERT, APNS_TEST_KEY and (if needed) APNS_TEST_KEY_PASSWD";
        diag $msg;
        skip $msg, 3;
    }

    my %args = (
        sandbox => 1,
        cert => $ENV{APNS_TEST_CERT},
        key => $ENV{APNS_TEST_KEY},
       );

    $args{passwd} = $ENV{APNS_TEST_KEY_PASSED}
      if $ENV{APNS_TEST_KEY_PASSWD};
    
    isa_ok(
        my $apns = Net::APNS::Feedback->new(\%args),
        'Net::APNS::Feedback',
        "created Net::APNS::Feedback object"
       );
    
    lives_ok { $feedback = $apns->retrieve_feedback } 'retrieved any pending feedback data';

    is( ref($feedback), 'ARRAY', 'array ref returned' );
}

SKIP: {
    if (! $feedback || ! @{$feedback} ) {
        # make sure cpan installers see this
        my $msg = "skipping structure tests - no feedback data retrieved";
        diag $msg;
        skip $msg, 3;
    }

    ok(
        ! scalar( grep { ref $_ ne 'HASH' } @{$feedback} ),
        'all entries are hashrefs'
       );
    
    ok(
        ! scalar( grep { $_->{time_t} !~ /^[0-9]{9}[0-9]+$/ } @{$feedback} ),
        'all entries have time_t that looks like an epoc time'
       );
    
    ok(
        ! scalar( grep { $_->{token} !~ /^[0-9a-f]{64}$/i } @{$feedback} ),
        'all entries have a token that looks like 32 byte hex'
       );
}
