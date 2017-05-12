use strict;
use warnings;
use Test::More;
use Test::Mock::Guard qw(mock_guard);
use Net::APNs::Extended;

my $apns = Net::APNs::Extended->new(cert => 'xxx');

subtest 'basic' => sub {
    my $guard = mock_guard $apns => {
        _read => sub {
            pack 'C C L', 8, 8, 12345;
        },
        disconnect => 1,
    };
    my $error = $apns->retrieve_error;
    is_deeply $error, {
        command    => 8,
        status     => 8,
        identifier => 12345,
    };
    is $guard->call_count($apns, 'disconnect'), 1;
};

subtest 'no data' => sub {
    my $guard = mock_guard $apns => {
        _read      => undef,
        disconnect => 1,
    };
    my $error = $apns->retrieve_error;
    is $error, undef;
    is $guard->call_count($apns, 'disconnect'), 0;
};

subtest 'connection closed' => sub {
    my $guard = mock_guard $apns => {
        _read      => '',
        disconnect => 1,
    };
    my $error = $apns->retrieve_error;
    is $error, '';
    is $guard->call_count($apns, 'disconnect'), 1;
};

done_testing;
