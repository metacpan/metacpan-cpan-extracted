use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;
use Log::Any::Adapter qw(TAP);

use Ryu;

subtest 'drain from one source then another' => sub {
    my $sink = new_ok('Ryu::Sink');
    my $rslt = $sink->source->as_list;
    my @expected = 1..20;
    my @pending = @expected;
    while(my @batch = splice @pending, 0, 2) {
        $sink->source->pause('overflow');
        my $src = new_ok('Ryu::Source');
        my $f = $src->count->as_last;
        $sink->drain_from($src->buffer(
            low => 3,
            high => 8,
        ));
        $src->emit($_) for @batch;
        $src->finish;
        await $src->completed;
        my $count = await $f;
        note explain $count;
        ok(!$rslt->is_ready, 'sink is not yet finished after source drain');
        $sink->source->resume('overflow');
    }
    $sink->source->finish;
    ok($rslt->is_ready, 'sink is now finished');
    cmp_deeply([ $rslt->get ], \@expected, 'items match');
    done_testing;
};

done_testing;
