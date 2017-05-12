use strict;
use warnings;
use Test::More;
use Test::Mock::Guard qw(mock_guard);
use Net::APNs::Extended;

my $apns = Net::APNs::Extended->new(cert => 'xxx');

subtest 'datum must be ARRAYREF' => sub {
    eval { $apns->send_multi };
    like $@, qr/Usage: \$apns->send_multi\(\\\@datum\)/;
};

subtest 'data must be ARRAYREF' => sub {
    eval { $apns->send_multi([ {} ]) };
    like $@, qr/Net::APNs::Extended: send data must be ARRAYREF/;
};

subtest 'device_token and payload must be specified' => sub {
    eval { $apns->send_multi([ [] ]) };
    like $@, qr/Net::APNs::Extended: send data require \$device_token and \\%payload/;
};

subtest 'success' => sub {
    my $recived_datum = [];
    my $guard = mock_guard $apns => {
        _create_send_data => sub {
            my ($self, $device_token, $payload, $extra) = @_;
            push @$recived_datum, [$device_token, $payload, $extra];
            return 'dummy';
        },
        _send => sub {
            my ($self, $data) = @_;
            is $data, 'dummy' x 2;
        }
    };
    my $datum = [
        [ 'device_tokenA', { aps => { alert => 'HelloA' } } ],
        [ 'device_tokenB', { aps => { alert => 'HelloB' } } ],
    ];
    $apns->send_multi($datum);

    is_deeply $recived_datum, [
        [
            'device_tokenA',
            { aps => { alert => 'HelloA' } },
            { identifier => 0, expiry => 0 },
        ],
        [
            'device_tokenB',
            { aps => { alert => 'HelloB' } },
            { identifier => 1, expiry => 0 },
        ],
    ];
};

subtest 'with extras' => sub {
    my $recived_datum = [];
    my $guard = mock_guard $apns => {
        _create_send_data => sub {
            my ($self, $device_token, $payload, $extra) = @_;
            push @$recived_datum, [$device_token, $payload, $extra];
            return 'dummy';
        },
        _send => sub {
            my ($self, $data) = @_;
            is $data, 'dummy' x 2;
        }
    };
    my $datum = [
        [
            'device_tokenA',
            { aps => { alert => 'HelloA' } },
            { identifier => 200, expiry => 500 },
        ],
        [ 
            'device_tokenB',
            { aps => { alert => 'HelloB' } },
            { identifier => 100, expiry => 300 },
        ],
    ];
    $apns->send_multi($datum);

    is_deeply $recived_datum, $datum;
};

done_testing;
