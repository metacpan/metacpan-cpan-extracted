use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use Scalar::Util qw(refaddr);
use PAGI::SSE;

# Characterizes the real PAGI::SSE caching contract: you get the SAME object
# back from the scope cache as long as you hold a strong reference to it. The
# cache is intentionally weak (to avoid a scope<->sse reference cycle), so it is
# NOT a guaranteed singleton across the loss of all strong refs — the POD must
# describe it as "cached while referenced", not "singleton".

subtest 'same object returned while a strong reference is held' => sub {
    my $scope = { type => 'sse', path => '/events', headers => [] };
    my $send  = sub { Future->done };
    my $recv  = sub { Future->new };

    my $sse = PAGI::SSE->new($scope, $recv, $send);   # strong ref kept in $sse
    $sse->start->get;

    my $again = PAGI::SSE->new($scope, $recv, $send);
    is refaddr($again), refaddr($sse), 'cache returns the same object';
    ok $again->is_started, 'so its state (is_started) is preserved';
};

done_testing;
