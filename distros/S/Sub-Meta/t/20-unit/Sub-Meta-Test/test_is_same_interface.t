use Test2::V0;

use Sub::Meta;
use Sub::Meta::Test qw(test_is_same_interface);

subtest 'Fail: test_is_same_interface' => sub {
    my $events = intercept {
        my $meta = Sub::Meta->new();
        my @tests = (
            hoge => 'message' => { },
        );
        test_is_same_interface($meta, @tests);
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
