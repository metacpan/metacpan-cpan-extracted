use Test2::V0;

use Sub::Meta;
use Sub::Meta::Test qw(test_error_message);

subtest 'Fail: test_error_message' => sub {
    my $events = intercept {
        my $meta = Sub::Meta->new();
        my @tests = (
            hoge => { }, qr//,
        );
        test_error_message($meta, @tests);
    };

    is $events, array {
        event 'Subtest';
        event 'Diag';
        end;
    };

    my ($subtest) = @$events;
    my $summary = $subtest->subevents->[0]->summary;
    like $summary, qr/Plan is 0 assertions/;
};

done_testing;
