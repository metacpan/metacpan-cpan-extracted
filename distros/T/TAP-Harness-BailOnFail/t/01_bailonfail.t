use strict;
use warnings;

use TAP::Harness::BailOnFail;
use Test::More;

my $harness = TAP::Harness::BailOnFail->new;
isa_ok $harness, 'TAP::Harness';

my @res;
$harness->callback(made_parser => sub {
    my $parser = shift;
    $parser->callback(test => sub {
        my $test = shift;
        $res[$test->is_ok]++;
    });
});

test_tap("t/tap/1.t");
is_deeply \@res, [1, 0], 'failure is first';

test_tap("t/tap/2.t");
is_deeply \@res, [1, 3];

test_tap("t/tap/3.t");
is_deeply \@res, [0, 5], 'no failures';

done_testing;

exit;


sub test_tap {
    my $tap = shift;
    @res = (0) x 2;
    eval { $harness->runtests($tap) };
}
