use strict;
use warnings;
use Test::More;
use Test::Mock::Guard qw(mock_guard);
use Net::APNs::Extended;

my $apns = Net::APNs::Extended->new(cert => 'xxx');

subtest 'device_token and payload must be specified' => sub {
    eval { $apns->send };
    like $@, qr/Usage: \$apns->send\(\$device_token, \\%payload \[, \\%extra \]\)/;
};

subtest 'payload must be hashref' => sub {
    eval { $apns->send('device_token', []) };
    like $@, qr/Usage: \$apns->send\(\$device_token, \\%payload \[, \\%extra \]\)/;
};

subtest 'success' => sub {
    my $guard = mock_guard $apns => {
        _create_send_data => sub {
            my ($self, $device_token, $payload, $extra) = @_;
            is $device_token, 'device_token';
            is_deeply $payload, {
                aps => { alert => 'Hello' },
            };
            is_deeply $extra, {
                identifier => 0,
                expiry     => 0,
            };
            return 'dummy';
        },
        _send => sub {
            my ($self, $data) = @_;
            is $data, 'dummy';
            return 1;
        },
    };
    ok $apns->send('device_token', {
        aps => { alert => 'Hello' },
    });
};

subtest 'with extra' => sub {
    my $guard = mock_guard $apns => {
        _create_send_data => sub {
            my ($self, $device_token, $payload, $extra) = @_;
            is $device_token, 'device_token';
            is_deeply $payload, {
                aps => { alert => 'Hello' },
            };
            is_deeply $extra, {
                identifier => 12345,
                expiry     => 56789,
            };
            return 'dummy';
        },
        _send => sub {
            my ($self, $data) = @_;
            is $data, 'dummy';
            return 1;
        },
    };
    ok $apns->send('device_token', {
        aps => { alert => 'Hello' },
    }, { identifier => 12345, expiry => 56789 });
};

done_testing;
