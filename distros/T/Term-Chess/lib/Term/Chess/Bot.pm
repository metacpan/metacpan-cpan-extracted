package Term::Chess::Bot;

use 5.014;
use strict;
use warnings;

use Digest::SHA ();
use Time::HiRes ();
use Chess::Plisco::Engine::Tree;
use Chess::Plisco::Engine::TranspositionTable;
use Term::Chess::Watcher;

our $VERSION = '0.02';

our @LADDER = (2_000, 10_000, 10_000, 40_000);

our $LEVEL;

my $TT_MB = 1;

sub ladder { @LADDER }

sub level_for {
    my ($class, $seed) = @_;
    return $LEVEL if defined $LEVEL;
    my $n = unpack 'N', Digest::SHA::sha256("chess-level:$seed");
    return $LADDER[ $n % scalar @LADDER ];
}

sub choose {
    my ($class, $game, $seat) = @_;
    return undef unless $game->status eq 'active';
    return undef unless defined $game->turn && $game->turn eq $seat;

    my $budget   = $class->level_for($game->_held_seed);
    my $position = $game->position->copy;
    my @info;
    my $tree = Chess::Plisco::Engine::Tree->new(
        position   => $position,
        signatures => $game->signatures,
        tt         => Chess::Plisco::Engine::TranspositionTable->new($TT_MB),
        watcher    => Term::Chess::Watcher->new($budget),
        info       => sub { push @info, "@_" },
    );
    $tree->{max_nodes}   = $budget;
    $tree->{nodes_to_tc} = 1000;
    $tree->{start_time}  = [ Time::HiRes::gettimeofday() ];

    my ($move) = $tree->think;
    return undef unless $move;
    die "Term::Chess::Bot: the search failed: $info[-1]\n" if grep { /Error/ } @info;
    my $uci = $game->position->moveCoordinateNotation($move);
    return wantarray ? ($uci, $tree->{nodes}, $budget) : $uci;
}

sub hint {
    my ($class, $game, $seat) = @_;
    local $LEVEL = $LADDER[-1];
    return $class->choose($game, $seat);
}

1;

__END__

=head1 NAME

Term::Chess::Bot - the opponent: Plisco's search, bounded in nodes

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    my $uci = Term::Chess::Bot->choose($game, 'p2');    # 'g8f6', or undef
    my $try = Term::Chess::Bot->hint($game, 'p1');      # at the top rung

=head1 DESCRIPTION

A thin wrapper on L<Chess::Plisco::Engine::Tree> that answers
C<choose($game, $seat)> like every other bot in the house.

The budget is a B<node count drawn from the game's seed>, one rung per game,
from C<@LADDER>: 2,000, 10,000, 10,000 or 40,000 nodes. The middle rung is
there twice on purpose, so it is drawn twice as often. The budget is in nodes
and never in seconds, so the same position answers the same on a busy machine
as on an idle one, and a game replayed from its seed meets the same opponent.

Setting C<$Term::Chess::Bot::LEVEL> pins every game to one budget instead,
which is what a command-line option or a test wants.

A search that fails inside Plisco dies here rather than quietly playing the
first legal move, which is how every wiring fault in Plisco's tree otherwise
shows itself.

=head1 METHODS

=head2 ladder

The budgets, in rung order.

=head2 level_for

    my $nodes = Term::Chess::Bot->level_for($seed);

The budget for a seed: C<$LEVEL> if set, otherwise a rung drawn from the
seed.

=head2 choose

    my $uci = Term::Chess::Bot->choose($game, $seat);

The move the search prefers, as coordinates, or C<undef> when the game is
over or the seat is not on move. It does not play the move. In list context
it also returns the nodes the search visited and the budget it was given,
which is how a test sees that the budget is a budget.

=head2 hint

The same, always at the top rung whatever the game drew: somebody asking
for help is not asking for a beginner's answer.

=cut
