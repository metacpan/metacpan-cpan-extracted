use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;
use Log::Any::Adapter qw(TAP);

use Ryu;

subtest 'single source drain' => sub {
    my $sink = new_ok('Ryu::Sink');
    my $rslt = $sink->source->as_list;
    my $src = new_ok('Ryu::Source');
    $sink->drain_from($src);
    my @expected = qw(a b c);
    $src->emit($_) for @expected;
    $src->finish;
    ok(!$rslt->is_ready, 'sink is not yet finished after source drain');
    $sink->source->finish;
    ok($rslt->is_ready, 'sink is now finished');
    cmp_deeply([ $rslt->get ], \@expected, 'items match');
    done_testing;
};

subtest 'drain from one source then another' => sub {
    my $sink = new_ok('Ryu::Sink');
    my $rslt = $sink->source->as_list;
    my @expected = qw(a b c);
    my @pending = @expected;
    while(my @batch = splice @pending, 0, 2) {
        my $src = new_ok('Ryu::Source');
        $sink->drain_from($src);
        $src->emit($_) for @batch;
        $src->finish;
        ok(!$rslt->is_ready, 'sink is not yet finished after source drain');
    }
    $sink->source->finish;
    ok($rslt->is_ready, 'sink is now finished');
    cmp_deeply([ $rslt->get ], \@expected, 'items match');
    done_testing;
};

subtest 'two sources with interleaved emission should maintain order' => sub {
    my $sink = new_ok('Ryu::Sink', [ label => 'main sink' ]);
    my $rslt = $sink->source->as_list;
    my @pending = qw(a b c d e f);
    my @src = map { new_ok('Ryu::Source', [ label => 'source ' . $_ ]) } 1..2;
    my @expected = map { $_->as_list } @src;
    for my $src (@src) {
        $src->each(sub { note sprintf 'Emit %s for %s', $_, $src->describe });
    }
    $sink->drain_from($_) for @src;
    while(my @batch = splice @pending, 0, 2) {
        # Rotate our sources
        my $src = shift @src;
        push @src, $src;

        $src->emit($_) for @batch;
        ok(!$rslt->is_ready, 'sink is not yet finished after source drain');
    }
    $_->finish for @src;
    ok(!$rslt->is_ready, 'sink is not yet finished after all draining sources are finished');
    $sink->source->finish;
    ok($rslt->is_ready, 'sink is now finished');
    ok(Future->needs_all(@expected)->is_ready, 'sources all generated lists as expected');
    cmp_deeply([ $rslt->get ], [ map { $_->get } @expected ], 'items match') or note explain [ $rslt->get ];
    done_testing;
};

subtest 'drain from regular source and arrayref' => sub {
    my $sink = new_ok('Ryu::Sink');
    my $rslt = $sink->source->as_list;
    my $src = new_ok('Ryu::Source');
    $sink->drain_from($src);
    $sink->drain_from([ qw(d e f) ]);
    $src->emit($_) for qw(a b c);
    $src->finish;
    ok(!$rslt->is_ready, 'sink is not yet finished after source drain');
    $sink->source->finish;
    ok($rslt->is_ready, 'sink is now finished');
    cmp_deeply([ $rslt->get ], [ qw(a b c d e f) ], 'items match');
    done_testing;
};

done_testing;
__END__
# This test may not be what we wanted - we should be able to drain from sources at any time,
# but also don't expect a source to keep all its items around just because something else may
# want to connect at some point.
subtest 'multi-source drain' => sub {
    my $sink = new_ok('Ryu::Sink');
    $sink->source->each(sub {
        note 'had ' . $_;
    });
    my $rslt = $sink->source->as_list;
    my @src = map { new_ok('Ryu::Source') } 1..3;
    my @expected = map { $_->as_list } @src;
    my @buffered = map { $_->buffer } @src;
    my $id = 0;
    for my $idx (0..$#src) {
        note 'Emit for all ' . (0 + @src) . ' remaining sources';
        $_->emit($id++) for @src;
        my $src = $src[$idx];
        note 'Drain from ' . $src->describe;
        $sink->drain_from($buffered[$idx]);
    }
    note 'Finish sources';
    $_->finish for @src;
    $sink->source->finish;
    ok($rslt->is_ready, 'sink is now finished');
    ok(Future->needs_all(@expected)->is_ready, 'all expected lists have returned');
    cmp_deeply([ $rslt->get ], [ map { $_->get } @expected ], 'items match');
    done_testing;
};

