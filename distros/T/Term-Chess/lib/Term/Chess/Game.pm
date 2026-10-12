package Term::Chess::Game;

use 5.014;
use strict;
use warnings;

use Carp ();
use Object::Proto::Sugar -types;

use Chess::Plisco qw(:all);
use Chess::Plisco::Engine::Position;
use Term::Chess::Error;

our $VERSION = '0.01';

my $P = 'Chess::Plisco::Engine::Position';
my $R = 'Term::Chess::Error';

my %REASON = (
    CP_GAME_STALEMATE()             => 'stalemate',
    CP_GAME_FIFTY_MOVES()           => 'fifty_moves',
    CP_GAME_INSUFFICIENT_MATERIAL() => 'insufficient_material',
);

has white => (is => 'ro', isa => Str, default => 'p1');

has status => (is => 'rw', isa => Str, default => 'active');

has _held_seed => (is => 'ro', init_arg => 'seed');

has _fen => (is => 'ro', init_arg => 'position');

has _pos => (is => 'rw', private => 1);

has _start_fen => (is => 'rw', private => 1);

has _first_halfmoves => (is => 'rw', private => 1);

has _signatures => (is => 'ro', isa => ArrayRef, default => [], private => 1);

has _log => (is => 'ro', isa => ArrayRef, default => [], private => 1);

has _san => (is => 'ro', isa => ArrayRef, default => [], private => 1);

has _result => (is => 'rw', private => 1);

sub BUILD {
    my ($self) = @_;

    my $seed = $self->_held_seed;
    Carp::croak('Term::Chess::Game: seed must be exactly thirty-two bytes')
        unless defined $seed && length($seed) == 32;

    my $white = $self->white;
    Carp::croak("Term::Chess::Game: white must be 'p1' or 'p2', not '$white'")
        unless $white eq 'p1' || $white eq 'p2';

    my $fen = $self->_fen;
    my $pos = eval { defined $fen ? $P->new($fen) : $P->new };
    if (!$pos) {
        my $why = $@;
        $why =~ s/\s+at \S+ line \d+\.?\s*\z//;
        Carp::croak("Term::Chess::Game: Plisco refused the position: $why");
    }

    $self->_pos($pos);
    $self->_start_fen($pos->toFEN);
    $self->_first_halfmoves($pos->halfmoves);
    push @{ $self->_signatures }, $pos->signature;
    $self->_result({ winner => undef, reason => undef });

    $self->_settle;
    return;
}

sub other { $_[0] eq 'p1' ? 'p2' : 'p1' }

sub position   { $_[0]->_pos }
sub signatures { [ @{ $_[0]->_signatures } ] }
sub log        { [ @{ $_[0]->_log } ] }

sub _seat_of   { $_[1] == CP_WHITE ? $_[0]->white : other($_[0]->white) }

sub black { other($_[0]->white) }

sub turn {
    my ($self) = @_;
    return undef unless $self->status eq 'active';
    return $self->_seat_of($self->_pos->turn);
}

sub side {
    my ($self) = @_;
    return $self->_pos->turn == CP_WHITE ? 'white' : 'black';
}

sub legal {
    my ($self) = @_;
    return [] unless $self->status eq 'active';
    my $pos = $self->_pos;
    return [ map { $pos->moveCoordinateNotation($_) } $pos->legalMoves ];
}

sub seed {
    my ($self) = @_;
    return undef unless $self->status eq 'finished';
    return $self->_held_seed;
}

sub san_log {
    my ($self) = @_;
    my @san = @{ $self->_san };
    return '' unless @san;

    my $ply    = $self->_first_halfmoves;
    my $number = int($ply / 2) + 1;
    my @out;
    if ($ply % 2) {
        push @out, "$number... " . shift @san;
        $number++;
    }
    while (@san) {
        my $pair = "$number. " . shift @san;
        $pair .= ' ' . shift @san if @san;
        push @out, $pair;
        $number++;
    }
    return join ' ', @out;
}

sub play {
    my ($self, $text) = @_;
    return $R->throw('game_over') unless $self->status eq 'active';
    return $R->throw('bad_move') unless defined $text && !ref $text;

    $text =~ s/\A\s+|\s+\z//g;
    my $pos = $self->_pos;

    my $uci;
    if ($text =~ /\A[a-h][1-8][a-h][1-8][qrbnQRBN]?\z/) {
        $uci = lc $text;
    }
    else {
        my $m = eval { $pos->parseMove($text) };
        return $R->throw('bad_move') unless $m;
        $uci = $pos->moveCoordinateNotation($m);
    }

    my $m = $self->_find($uci);
    return $m unless ref $m eq '';

    push @{ $self->_san }, $pos->SAN($m);
    push @{ $self->_log }, $uci;
    $pos->doMove($m);
    push @{ $self->_signatures }, $pos->signature;

    $self->_settle;
    return 0;
}

sub _find {
    my ($self, $uci) = @_;
    my $pos = $self->_pos;
    my @legal = $pos->legalMoves;
    for my $m (@legal) {
        return $m if $pos->moveCoordinateNotation($m) eq $uci;
    }

    my ($from, $to) = (substr($uci, 0, 2), substr($uci, 2, 2));
    my ($piece, $colour) = $pos->pieceAtSquare($from);
    return $R->throw('no_piece') unless $piece;
    return $R->throw('not_your_turn') unless $colour == $pos->turn;

    return $R->throw('bad_promotion')
        if grep { substr($pos->moveCoordinateNotation($_), 0, 4) eq "$from$to" } @legal;

    my @coords = map { $pos->moveCoordinateNotation($_) } @legal;
    return $R->throw('in_check', legal => \@coords)
        if grep { $pos->moveCoordinateNotation($_) eq $uci } $pos->pseudoLegalMoves;
    return $R->throw('not_legal', legal => \@coords);
}

sub _settle {
    my ($self) = @_;
    my $pos   = $self->_pos;
    my $state = $pos->gameOver;

    if ($state & CP_GAME_OVER) {
        if ($state & CP_GAME_WHITE_WINS) {
            return $self->_finish($self->white, 'checkmate');
        }
        if ($state & CP_GAME_BLACK_WINS) {
            return $self->_finish($self->black, 'checkmate');
        }
        for my $flag (CP_GAME_STALEMATE, CP_GAME_FIFTY_MOVES, CP_GAME_INSUFFICIENT_MATERIAL) {
            return $self->_finish(undef, $REASON{$flag}) if $state & $flag;
        }
        return $self->_finish(undef, 'over');
    }

    my $now  = $self->_signatures->[-1];
    my $seen = grep { $_ == $now } @{ $self->_signatures };
    return $self->_finish(undef, 'repetition') if $seen >= 3;
    return;
}

sub _finish {
    my ($self, $winner, $reason) = @_;
    $self->status('finished');
    $self->_result({ winner => $winner, reason => $reason });
    return;
}

sub resign {
    my ($self, $seat) = @_;
    return $R->throw('game_over') unless $self->status eq 'active';
    return $R->throw('bad_move')
        unless defined $seat && ($seat eq 'p1' || $seat eq 'p2');
    $self->_finish(other($seat), 'resignation');
    return 0;
}

sub result {
    my ($self) = @_;
    return { %{ $self->_result } };
}

sub winner { $_[0]->result->{winner} }

sub bot { require Term::Chess::Bot; 'Term::Chess::Bot' }

sub replay {
    my ($proto, @rest) = @_;

    if (ref $proto) {
        my $moves = ref $rest[0] eq 'ARRAY' ? $rest[0] : [ grep { defined } @rest ];
        return $proto->_replayed($moves);
    }

    return undef if @rest % 2;
    my %o = @rest;
    my $self = $proto->new(%o);
    return $self->_walk($o{moves} || []);
}

sub _replayed {
    my ($self, $moves) = @_;
    my $fresh = (ref $self)->new(
        seed     => $self->_held_seed,
        white    => $self->white,
        position => $self->_start_fen,
    );
    return $fresh->_walk($moves);
}

sub _walk {
    my ($self, $moves) = @_;
    for my $i (0 .. $#$moves) {
        my $why = $self->play($moves->[$i]);
        return wantarray ? ($self, $why, $i) : undef if $why;
    }
    return wantarray ? ($self, 0, scalar @$moves) : $self;
}

1;

__END__

=head1 NAME

Term::Chess::Game - a game of chess over a Chess::Plisco position

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Term::Chess::Game;

    my $g = Term::Chess::Game->new(seed => $thirty_two_bytes, white => 'p1');
    $g->turn;                     # 'p1'
    $g->legal;                    # [ 'a2a3', 'a2a4', ... ] as coordinates
    my $why = $g->play('e4');     # 0, or a Term::Chess::Error
    $g->play('e7e5');
    $g->san_log;                  # '1. e4 e5'
    $g->status;                   # 'active' | 'finished'
    $g->result;                   # { winner, reason }

    my ($replayed, $why, $at) = Term::Chess::Game->replay(
        seed => $seed, white => 'p1', moves => $g->log);

=head1 DESCRIPTION

A game between two seats, C<p1> and C<p2>, over one
L<Chess::Plisco::Engine::Position>. Plisco holds the position, generates the
legal moves and judges checkmate, stalemate, the fifty-move rule and
insufficient material; this class knows which seat is which colour, what a
move is called, why a move that is not on Plisco's list was refused, when the
same position has come round three times, and how to replay a log. No rule of
chess is written here.

The seat named C<white> plays White and moves first.

=head2 A move is coordinates in, coordinates stored, SAN beside

C<play> takes coordinates (C<e2e4>, C<e7e8q>) or standard algebraic notation
(C<Nf3>, C<exd5>, C<O-O>, C<a8=Q>). Whatever was typed, the log holds the
coordinates, because SAN depends on the position and is ambiguous to read
back years later; C<san_log> gives the same moves as numbered SAN for a
person.

=head2 A refusal is returned, never thrown

C<play> returns C<0> when the move was played and a L<Term::Chess::Error>
when it was not. Plisco itself dies on a string it cannot read; that die is
caught here and becomes C<bad_move>, so a caller never needs an C<eval>.

A move that parses but is not on the legal list is named from the near
misses: an empty from-square is C<no_piece>; a piece of the other colour is
C<not_your_turn>; a pawn move to the last rank with no piece named, or the
wrong one, is C<bad_promotion>; a move the piece can make that only the king
forbids is C<in_check>; everything else is C<not_legal>. The last two carry
the legal list.

=head2 How a game ends

After every move Plisco is asked whether the game is over: checkmate wins
for the seat holding the mating colour; stalemate, fifty moves without a
capture or a pawn move, and insufficient material are draws. Then the
position's signature is counted through every signature since the start,
and a third occurrence is a draw by repetition. A seat may also C<resign>.
A game built from a position that is already over is finished at once.

=head1 METHODS

=head2 new

    Term::Chess::Game->new(seed => $bytes, white => 'p1', position => $fen);

C<seed> is exactly thirty-two bytes and is what the bot draws its rung from;
anything else is a programmer error and croaks. C<white> is the seat that
plays White, C<p1> by default. C<position> is a FEN to start from instead
of the opening; one Plisco refuses croaks with Plisco's reason.

=head2 white

=head2 black

The seat playing each colour.

=head2 status

C<active> or C<finished>.

=head2 turn

The seat to move, or C<undef> once the game is finished.

=head2 side

C<white> or C<black>: the colour to move.

=head2 legal

The legal moves as coordinates, in the order Plisco yields them. Empty once
finished.

=head2 play

    my $why = $g->play('Nf3');

C<0>, or a L<Term::Chess::Error>.

=head2 resign

    $g->resign('p1');

Finishes the game for the other seat with the reason C<resignation>.
Returns C<0>, or C<game_over> if it was already finished.

=head2 log

The moves played, as coordinates, a copy.

=head2 san_log

The same moves as numbered SAN: C<1. e4 e5 2. Nf3>. A game that began
with Black to move starts C<1... e5>.

=head2 result

    { winner => 'p2', reason => 'checkmate' }

C<winner> is a seat, or C<undef> for a draw or while the game is active.
C<reason> is one of C<checkmate>, C<stalemate>, C<fifty_moves>,
C<insufficient_material>, C<repetition>, C<resignation>, or C<undef> while
active.

=head2 winner

The seat that won, or C<undef>.

=head2 position

The L<Chess::Plisco::Engine::Position> itself, for drawing and for the bot.
It is the live object: a caller that moves on it has moved in the game.

=head2 signatures

A copy of the position's signature at the start and after every move, in
order. The bot's search takes this list so it can see a repetition coming.

=head2 seed

The seed, but only once the game is finished; C<undef> while it is active.

=head2 bot

The name of the bot class, loaded on demand.

=head2 replay

    my ($game, $why, $at) = Term::Chess::Game->replay(
        seed => $seed, white => 'p1', position => $fen, moves => \@coordinates);

    my ($again, $why, $at) = $game->replay(\@coordinates);

Builds a fresh game and plays the moves into it. In list context returns the
game, the first refusal or C<0>, and the index of the move that was refused
(or the count of moves when none was). In scalar context returns the game,
or C<undef> if any move was refused. The instance form replays from this
game's own seed, colours and starting position.

=head2 other

    Term::Chess::Game::other('p1');    # 'p2'

The other seat. A function, not a method.

=cut
