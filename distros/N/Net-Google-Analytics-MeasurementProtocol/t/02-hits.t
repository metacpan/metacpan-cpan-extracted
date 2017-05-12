use strict;
use warnings;
use Test::More;
use Net::Google::Analytics::MeasurementProtocol;

diag 'these tests require a working Internet connection.';
unless ($ENV{ONLINE_TESTS}) {
    plan skip_all => 'Online tests disabled. Please set ONLINE_TESTS=1 in the environment';
    exit;
}

my $has_json = eval "use JSON; 1;";
if ($has_json) {
    diag 'JSON looks installed. Good. Tests will be more accurate :)';
}
else {
    diag q(JSON looks missing. We'll make due with regexes);
}

test_pageview();

my $has_lwp = eval {
    require LWP::UserAgent;
    require LWP::Protocol::https;
    1;
};

SKIP: {
    skip 'LWP::Protocol::https is likely not installed', 2, unless $has_lwp;
    test_pageview( LWP::UserAgent->new );
};

sub test_pageview {
    my $ua_object = shift;
    diag 'Using ' . ( $ua_object ? 'LWP::UserAgent' : 'Furl' );

    my $ga = Net::Google::Analytics::MeasurementProtocol->new(
        tid   => 'UA-1234-5',
        debug => 1,
        $ua_object ? ( ua_object => $ua_object ) : (),
    );


    my $res = $ga->send( 'pageview', {
        dh => 'www.colab55.com',
        dp => '/pop',
        dt => '/pop',
    });

    if ($has_json) {
        my $json = JSON::decode_json( $res->decoded_content );
        ok exists $json->{hitParsingResult}[0]{valid}, 'valid response fields';
        is "$json->{hitParsingResult}[0]{valid}", 0, 'invalid response is invalid';
    }
    else {
        like $res->decoded_content, qr/"valid": false/s, 'invalid response is invalid';
    }

}

my $ga = Net::Google::Analytics::MeasurementProtocol->new(
    tid => 'UA-12345678-9',
    debug       => 1,
);

my $res = $ga->send( 'pageview', {
    dh => 'www.colab55.com',
    dp => '/pop',
});

if ($has_json) {
    my $json = JSON::decode_json( $res->decoded_content );
    ok exists $json->{hitParsingResult}[0]{valid}, 'valid response fields (2)';
    is "$json->{hitParsingResult}[0]{valid}", 1, 'valid response is valid';
}
else {
    like $res->decoded_content, qr/"valid": true/s, 'valid response is valid';
}

# enhanced ecommerce event
$res = $ga->send( 'event', {
    ec => 'Ecommerce',
    ea => 'Refund',
    pa => 'refund',
    ti => 'X-1234',
});

if ($has_json) {
    my $json = JSON::decode_json( $res->decoded_content );
    ok exists $json->{hitParsingResult}[0]{valid}, 'valid response fields for event';
    is "$json->{hitParsingResult}[0]{valid}", 1, 'valid event response is valid';
}
else {
    like $res->decoded_content, qr/"valid": true/s, 'valid event response is valid';
}

done_testing;
