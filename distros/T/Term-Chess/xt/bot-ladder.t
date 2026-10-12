#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

use Term::Chess::Game;
use Term::Chess::Bot;

# Each rung against the one below, colours alternated. Slow: the top pair is
# twenty games at up to 40,000 nodes a move. RELEASE_TESTING or TC_LADDER
# turns it on; TC_LADDER_GAMES sets the games a pair (default 20).

plan skip_all => 'set RELEASE_TESTING or TC_LADDER to play the ladder'
    unless $ENV{RELEASE_TESTING} || $ENV{TC_LADDER};

my $GAMES = $ENV{TC_LADDER_GAMES} || 20;
my $CAP   = 300;

my @rungs = do { my %seen; grep { !$seen{$_}++ } Term::Chess::Bot->ladder };

sub play_one {
    my ($white_budget, $black_budget, $n) = @_;
    my $seed = substr("ladder-$white_budget-$black_budget-$n" . ('.' x 32), 0, 32);
    my $g = Term::Chess::Game->new(seed => $seed, white => 'p1');
    my %budget = (p1 => $white_budget, p2 => $black_budget);
    my $plies = 0;
    while ($g->status eq 'active' && $plies < $CAP) {
        my $seat = $g->turn;
        local $Term::Chess::Bot::LEVEL = $budget{$seat};
        my $uci = Term::Chess::Bot->choose($g, $seat);
        die "no move for $seat" unless defined $uci;
        my $why = $g->play($uci);
        die "the game refused the bot's $uci: " . $why->code if $why;
        $plies++;
    }
    return $g->status eq 'active' ? undef : $g->winner;
}

for my $i (1 .. $#rungs) {
    my ($low, $high) = @rungs[ $i - 1, $i ];
    my %points = (low => 0, high => 0);
    my %tally  = (high => 0, low => 0, draw => 0);
    for my $n (1 .. $GAMES) {
        my $high_is_white = $n % 2;
        my $winner = $high_is_white ? play_one($high, $low, $n) : play_one($low, $high, $n);
        my $who = !defined $winner ? 'draw'
                : ($winner eq 'p1') == !!$high_is_white ? 'high' : 'low';
        $tally{$who}++;
        if ($who eq 'draw') { $points{low} += 0.5; $points{high} += 0.5 }
        else                { $points{$who} += 1 }
    }
    diag sprintf '%d against %d nodes: %d won, %d lost, %d drawn for the higher rung',
        $high, $low, $tally{high}, $tally{low}, $tally{draw};
    cmp_ok $points{high}, '>=', $points{low}, "$high nodes does not lose the pair against $low";
}

done_testing;
