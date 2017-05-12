use strict;
use warnings;
use utf8;
use Test::More;
use Net::APNs::Extended;

my $apns = Net::APNs::Extended->new(cert => 'xxx');

subtest 'payload.aps must be hashref' =>sub {
    eval { $apns->_create_send_data('device_token', {}) };
    like $@, qr/aps parameter must be HASHREF/;
};

subtest 'success' => sub {
    my $chunk = $apns->_create_send_data('device_token' => {
        aps => { alert => 'メッセージ' },
    }, { identifier => 0, expiry => 0 });
    my ($command, $identifier, $expiry, $device_token, $json)
        = unpack 'c L N n/a* n/a*' => $chunk;

    is $command, 1;
    is $identifier, 0;
    is $expiry, 0;
    is $device_token, 'device_token';
    is_deeply $apns->json->decode($json), {
        aps => { alert => 'メッセージ' },
    };
};

subtest 'with extras' => sub {
    my $chunk = $apns->_create_send_data('device_token' => {
        aps => { alert => 'メッセージ' },
    }, { identifier => 12345, expiry => 56789 });
    my ($command, $identifier, $expiry, $device_token, $json)
        = unpack 'c L N n/a* n/a*' => $chunk;

    is $command, 1;
    is $identifier, 12345;
    is $expiry, 56789;
    is $device_token, 'device_token';
    is_deeply $apns->json->decode($json), {
        aps => { alert => 'メッセージ' },
    };
};

subtest 'trimed' => sub {
    my $chunk = $apns->_create_send_data('device_token' => {
        aps => { alert => 'メッセージ'x100 },
    }, { identifier => 12345, expiry => 56789 });
    my ($command, $identifier, $expiry, $device_token, $json)
        = unpack 'c L N n/a* n/a*' => $chunk;

    is $command, 1;
    is $identifier, 12345;
    is $expiry, 56789;
    is $device_token, 'device_token';
    is_deeply $apns->json->decode($json), {
        aps => { alert => 'メッセージメッセージメッセージメッセージメッセージメッセージメッセージメッセージメッセージメッセージメッセージメッセージメッセージメッセージメッセージメッセ' },
    };
};

subtest 'badge to numify' => sub {
    my $chunk = $apns->_create_send_data('device_token' => {
        aps => { alert => 'メッセージ', badge => '100' },
    }, { identifier => 12345, expiry => 56789 });
    my ($command, $identifier, $expiry, $device_token, $json)
        = unpack 'c L N n/a* n/a*' => $chunk;

    is $command, 1;
    is $identifier, 12345;
    is $expiry, 56789;
    is $device_token, 'device_token';
    is_deeply $apns->json->decode($json), {
        aps => { alert => 'メッセージ', badge => 100 },
    };
};

subtest 'trimd alter.body' => sub {
    my $chunk = $apns->_create_send_data('device_token' => {
        aps => { alert => { body => 'メッセージ'x100 }, badge => '100' },
    }, { identifier => 12345, expiry => 56789 });
    my ($command, $identifier, $expiry, $device_token, $json)
        = unpack 'c L N n/a* n/a*' => $chunk;

    is $command, 1;
    is $identifier, 12345;
    is $expiry, 56789;
    is $device_token, 'device_token';
    is_deeply $apns->json->decode($json), {
        aps => {
            alert => {
                body => 'メッセージメッセージメッセージメッセージメッセージメッセージメッセージメッセージメッセージメッセージメッセージメッセージメッセージメッセージメ',
            },
            badge => 100,
        },
    };
};

subtest 'command 0' => sub {
    $apns->command(0);
    my $chunk = $apns->_create_send_data('device_token' => {
        aps => { alert => 'メッセージ' },
    }, { identifier => 0, expiry => 0 });
    my ($command, $device_token, $json) = unpack 'c n/a* n/a*' => $chunk;

    is $command, 0;
    is $device_token, 'device_token';
    is_deeply $apns->json->decode($json), {
        aps => { alert => 'メッセージ' },
    };
};

done_testing;
