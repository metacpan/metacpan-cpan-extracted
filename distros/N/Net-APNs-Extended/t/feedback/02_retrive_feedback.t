use strict;
use warnings;
use Test::More;
use Test::Mock::Guard qw(mock_guard);
use Net::APNs::Extended::Feedback;

my $apns = Net::APNs::Extended::Feedback->new(cert => 'xxx');

subtest 'basic' => sub {
    my $time = time;
    my $guard = mock_guard $apns => {
        _read => sub {
            my $data;
            for my $feedback (
                [$time, ('0123456789'x3).10],
                [$time + 1, ('0123456789'x3).20]
            ) {
                $data .= pack 'N n/a*' => @$feedback;
            }
            return $data;
        },
    };
    my $feedbacks = $apns->retrieve_feedback;
    is_deeply $feedbacks, [
        {
            time_t    => $time,
            token_bin => '01234567890123456789012345678910',
            token_hex => unpack 'H*' => '01234567890123456789012345678910',
        },
        {
            time_t    => $time + 1,
            token_bin => '01234567890123456789012345678920',
            token_hex => unpack 'H*' => '01234567890123456789012345678920',
        },
    ];
};

done_testing;
