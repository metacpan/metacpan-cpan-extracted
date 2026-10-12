#!perl
use 5.014;
use strict;
use warnings;
use Test::More;
use Time::HiRes ();

use Term::Chess::Game;
use Term::Chess::Bot;
use Term::Chess::Watcher;

my $G = 'Term::Chess::Game';
my $B = 'Term::Chess::Bot';
my $SEED = "\x01" x 32;

sub game { $G->new(seed => $_[0] // $SEED, white => 'p1') }
sub from { $G->new(seed => $SEED, white => 'p1', position => $_[0]) }

subtest 'the bot does not play the first legal move' => sub {
    local $Term::Chess::Bot::LEVEL = 2_000;
    my $g = from('6k1/5ppp/8/8/8/8/5PPP/R5K1 w - - 0 1');
    my $first = $g->legal->[0];
    isnt $first, 'a1a8', "the first legal move ($first) is not the mate, so a fallback would show";
    is $B->choose($g, 'p1'), 'a1a8', 'the bot mates';
    is $B->choose($g, 'p2'), undef, 'and has nothing for the seat not on move';
    ok((grep { $_ eq 'a1a8' } @{ $g->legal }), 'and did not play it: the game is as it was');
    is scalar @{ $g->log }, 0, 'with nothing in the log';
    $g->play('a1a8');
    is $B->choose($g, 'p2'), undef, 'nothing once the game is over';
};

subtest 'the budget is a budget' => sub {
    for my $budget (Term::Chess::Bot->ladder, 0) {
        local $Term::Chess::Bot::LEVEL = $budget;
        my $g = game();
        my ($uci, $nodes, $given) = $B->choose($g, 'p1');
        ok((grep { $_ eq $uci } @{ $g->legal }), "$budget: a legal move");
        is $given, $budget, 'at the budget asked for';
        cmp_ok $nodes, '<=', $budget + 1000, "and $nodes nodes is within one interval of it";
    }
};

subtest 'the watcher' => sub {
    my $w = Term::Chess::Watcher->new(500);
    is $w->budget, 500, 'knows its budget';
    my %tree = (nodes => 499);
    $w->check(\%tree);
    ok !$tree{stop_requested}, 'does not stop short of it';
    $tree{nodes} = 500;
    $w->check(\%tree);
    ok $tree{stop_requested}, 'stops at it';
    $w->check({});
    pass 'and a tree with no node count yet is not an error';
};

subtest 'the seed draws the rung' => sub {
    my %seen;
    my %again;
    for my $n (1 .. 64) {
        my $seed = substr(sprintf('seed-%03d', $n) . ('.' x 32), 0, 32);
        my $level = $B->level_for($seed);
        $seen{$level}++;
        $again{$seed} = $level;
    }
    is_deeply [ sort { $a <=> $b } keys %seen ], [ 2_000, 10_000, 40_000 ], 'every budget on the ladder is drawn';
    cmp_ok $seen{10_000}, '>', $seen{2_000}, 'the doubled rung is drawn more often than the lowest';
    for my $seed (sort keys %again) {
        last unless is $B->level_for($seed), $again{$seed}, 'the same seed draws the same rung';
    }
    {
        local $Term::Chess::Bot::LEVEL = 7_000;
        is $B->level_for('any seed'), 7_000, 'LEVEL pins it';
    }
    is_deeply [ $B->ladder ], [ 2_000, 10_000, 10_000, 40_000 ], 'the ladder is the four rungs';
    is $B->level_for("\x01" x 32), 10_000, 'the test seed draws the middle rung, as it did when this was written';
    is $B->level_for(substr('seed-001' . ('.' x 32), 0, 32)), 40_000, 'and seed-001 the top one';
};

subtest 'hint answers at the top rung' => sub {
    my $seed = 'a seed that draws the lowest rung...';
    for my $n (1 .. 200) {
        my $try = substr("low-$n" . ('.' x 32), 0, 32);
        if ($B->level_for($try) == 2_000) { $seed = $try; last }
    }
    is $B->level_for($seed), 2_000, 'a seed that draws the lowest rung';
    my $g = game($seed);
    my (undef, undef, $chosen) = $B->choose($g, 'p1');
    is $chosen, 2_000, 'choose uses it';
    my (undef, undef, $hinted) = $B->hint($g, 'p1');
    is $hinted, 40_000, 'hint uses the top rung';
    is $B->level_for($seed), 2_000, 'and leaves LEVEL as it was';
    is $B->hint($g, 'p2'), undef, 'and has no hint for the seat not on move';
};

subtest 'the worst single move at the top rung, in milliseconds' => sub {
    local $Term::Chess::Bot::LEVEL = 40_000;
    my %pos = (
        opening    => undef,
        middlegame => 'r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4',
        endgame    => '8/8/4k3/8/8/4K3/4P3/8 w - - 0 1',
    );
    my $worst = 0;
    for my $name (sort keys %pos) {
        my $g = $pos{$name} ? from($pos{$name}) : game();
        my $t0 = Time::HiRes::time();
        my $uci = $B->choose($g, 'p1');
        my $ms = (Time::HiRes::time() - $t0) * 1000;
        $worst = $ms if $ms > $worst;
        ok((grep { $_ eq $uci } @{ $g->legal }), sprintf '%s: a legal move in %.0f ms', $name, $ms);
    }
    diag sprintf 'worst case %.0f ms at 40,000 nodes', $worst;
    cmp_ok $worst, '<', 3000, 'and under three seconds';
};

done_testing;
