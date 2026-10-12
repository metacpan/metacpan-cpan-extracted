#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

use Term::Chess::Game;
use Term::Chess::Error;

my $G = 'Term::Chess::Game';
my $SEED = "\x01" x 32;

sub game { $G->new(seed => $SEED, white => $_[0] // 'p1') }
sub from { my ($fen, $white) = @_; $G->new(seed => $SEED, white => $white // 'p1', position => $fen) }
sub piece_at { my ($g, $sq) = @_; my ($p, $c) = $g->position->pieceAtSquare($sq); return $p ? ($c == 0 ? 'w' : 'b') . $p : '' }

subtest 'the seats and the seed' => sub {
    my $g = game();
    is $g->turn, 'p1', 'the seat named white moves first';
    is $g->white, 'p1', 'and is white';
    is $g->black, 'p2', 'the other seat is black';
    is $g->side, 'white', 'white to move';
    is $g->status, 'active', 'the game is on';
    is $g->seed, undef, 'the seed is kept back while the game is active';
    is_deeply $g->result, { winner => undef, reason => undef }, 'no result yet';

    my $other = game('p2');
    is $other->turn, 'p2', 'white => p2 moves first as p2';
    is $other->black, 'p1', 'and p1 is black';

    ok !eval { $G->new(seed => 'short'); 1 }, 'a seed that is not 32 bytes croaks';
    like $@, qr/thirty-two bytes/, 'saying so';
    ok !eval { $G->new(seed => $SEED, white => 'p3'); 1 }, 'a seat that is not p1 or p2 croaks';
    ok !eval { from('not a fen'); 1 }, 'a FEN Plisco refuses croaks';
    like $@, qr/Plisco refused the position/, 'with Plisco named';
    is scalar @{ game()->signatures }, 1, 'the starting position is the first signature';
};

subtest 'a quiet move' => sub {
    my $g = game();
    is $g->play('e2e4'), 0, 'e2e4 is played';
    is_deeply $g->log, ['e2e4'], 'and logged as coordinates';
    is $g->san_log, '1. e4', 'and as numbered SAN';
    is $g->turn, 'p2', 'the turn passes';
    is $g->side, 'black', 'to black';
    is piece_at($g, 'e4'), 'w1', 'the pawn is on e4';
    is piece_at($g, 'e2'), '', 'and no longer on e2';
    is scalar @{ $g->signatures }, 2, 'a second signature';
    isnt $g->signatures->[1], $g->signatures->[0], 'which differs from the first';
    my @legal = @{ $g->legal };
    is scalar @legal, 20, 'black has twenty replies';
    ok((grep { $_ eq 'e7e5' } @legal), 'one of them e7e5');
    like $legal[0], qr/\A[a-h][1-8][a-h][1-8]\z/, 'each as coordinates';
};

subtest 'SAN in, coordinates stored' => sub {
    my $g = game();
    is $g->play('e4'), 0, 'e4';
    is $g->play('e5'), 0, 'e5';
    is $g->play('Nf3'), 0, 'Nf3';
    is $g->play('Nc6'), 0, 'Nc6';
    is $g->play('d4'), 0, 'd4';
    is $g->play('exd4'), 0, 'exd4, a capture in SAN';
    is_deeply $g->log, [qw(e2e4 e7e5 g1f3 b8c6 d2d4 e5d4)], 'the log is coordinates throughout';
    is $g->san_log, '1. e4 e5 2. Nf3 Nc6 3. d4 exd4', 'the SAN log is numbered pairs';

    my $c = from('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1');
    is $c->play('O-O'), 0, 'O-O';
    is_deeply $c->log, ['e1g1'], 'stored as the king move';
    is $c->play(' O-O-O '), 0, 'spaces round a move are read too';
    is_deeply $c->log, [qw(e1g1 e8c8)], 'both as coordinates';

    my $p = from('4k3/P7/8/8/8/8/8/4K3 w - - 0 1');
    is $p->play('a8=Q'), 0, 'a8=Q';
    is_deeply $p->log, ['a7a8q'], 'stored with the piece letter';
    is $p->san_log, '1. a8=Q+', 'and the SAN carries the check';
};

subtest 'every code has a fixture' => sub {
    my %case = (
        not_your_turn => [game(), 'e7e5'],
        no_piece      => [game(), 'e3e4'],
        not_legal     => [game(), 'e2e5'],
        bad_move      => [game(), 'wibble'],
        in_check      => [from('4k3/8/8/8/7q/5P2/P7/4K3 w - - 0 1'), 'a2a3'],
        bad_promotion => [from('4k3/P7/8/8/8/8/8/4K3 w - - 0 1'), 'a7a8'],
    );
    for my $code (sort keys %case) {
        my ($g, $text) = @{ $case{$code} };
        my $why = $g->play($text);
        ok ref $why, "$code: '$text' is refused";
        is $why->code, $code, "with the code $code";
        is $why->message, Term::Chess::Error->message_for($code), 'and its sentence';
        ok $why->$code, 'and the flag set';
        is $g->turn, $g->white, 'and the turn did not pass';
    }

    my $g = from('4k3/8/8/8/7q/5P2/P7/4K3 w - - 0 1');
    my $why = $g->play('a2a3');
    ok((grep { $_ eq 'e1d1' } @{ $why->legal }), 'in_check carries the legal list, with the way out');
    my $nl = game()->play('e2e5');
    is scalar @{ $nl->legal }, 20, 'not_legal carries the twenty legal moves';

    for my $text ('a8', 'zz', '', 'Qxh9', 'a7a8x', 'e9') {
        my $r = game()->play($text);
        ok ref $r && $r->code eq 'bad_move', "'$text' is bad_move and nothing dies";
    }
    ok game()->play(undef)->bad_move, 'undef is bad_move';
    ok game()->play([])->bad_move, 'a reference is bad_move';

    my $pr = from('4k3/P7/8/8/8/8/8/4K3 w - - 0 1');
    is $pr->play('a7a8x')->code, 'bad_move', 'a promotion to a piece that is not one is bad_move';
    is $pr->play('a7a8k')->code, 'bad_move', 'and so is a king';
    is $pr->play('a7a8Q'), 0, 'an uppercase piece letter is read';
};

subtest 'castling, en passant, promotion' => sub {
    my $c = from('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1');
    is $c->play('e1g1'), 0, 'white castles short';
    is piece_at($c, 'f1'), 'w4', 'the rook came to f1';
    is piece_at($c, 'h1'), '', 'from h1';
    is $c->play('e8c8'), 0, 'black castles long';
    is piece_at($c, 'd8'), 'b4', 'the rook came to d8';

    my $e = from('4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1');
    is $e->play('e5d6'), 0, 'en passant';
    is piece_at($e, 'd5'), '', 'the pawn taken is gone from d5, which is not the destination';
    is piece_at($e, 'd6'), 'w1', 'and the taker stands on d6';
    is $e->san_log, '1. exd6', 'in SAN';

    for my $letter (qw(q r b n)) {
        my $p = from('4k3/P7/8/8/8/8/8/4K3 w - - 0 1');
        is $p->play("a7a8$letter"), 0, "promotes to $letter";
        my %kind = (q => 5, r => 4, b => 3, n => 2);
        is piece_at($p, 'a8'), 'w' . $kind{$letter}, 'and that piece stands on a8';
    }
};

subtest 'the endings' => sub {
    my $m = game();
    $m->play($_) for qw(f2f3 e7e5 g2g4 d8h4);
    is $m->status, 'finished', 'the fool is mated';
    is_deeply $m->result, { winner => 'p2', reason => 'checkmate' }, 'and the black seat wins by checkmate';
    is $m->winner, 'p2', 'winner says so';
    is $m->turn, undef, 'nobody is on turn';
    is_deeply $m->legal, [], 'and there are no legal moves';
    is $m->play('e1f2')->code, 'game_over', 'a move now is game_over';
    is $m->seed, $SEED, 'the seed is given up once finished';

    my $w = game('p2');
    $w->play($_) for qw(f2f3 e7e5 g2g4 d8h4);
    is $w->winner, 'p1', 'with the colours the other way, the seat that is black wins';

    my $wm = from('6k1/5ppp/8/8/8/8/5PPP/R5K1 w - - 0 1');
    is $wm->play('a1a8'), 0, 'the rook mates on the back rank';
    is_deeply $wm->result, { winner => 'p1', reason => 'checkmate' }, 'and the white seat wins by checkmate';
    is from('6k1/5ppp/8/8/8/8/5PPP/R5K1 w - - 0 1', 'p2')->play('a1a8') || 0, 0, 'played with white as p2 too';
    my $wm2 = from('6k1/5ppp/8/8/8/8/5PPP/R5K1 w - - 0 1', 'p2');
    $wm2->play('a1a8');
    is $wm2->winner, 'p2', 'and then the winner is p2';

    my $s = from('7k/8/6K1/5Q2/8/8/8/8 w - - 0 1');
    is $s->play('f5f7'), 0, 'the queen steps to f7';
    is_deeply $s->result, { winner => undef, reason => 'stalemate' }, 'stalemate';

    my $f = from('4k3/8/8/8/8/8/8/R3K3 w - - 99 60');
    is $f->play('a1b1'), 0, 'a quiet move with the clock at 99';
    is_deeply $f->result, { winner => undef, reason => 'fifty_moves' }, 'fifty moves';

    my $i = from('4k3/8/8/8/8/8/3b4/4KN2 w - - 0 1');
    is $i->status, 'active', 'knight against bishop is still a game';
    is $i->play('f1d2'), 0, 'the knight takes the bishop';
    is_deeply $i->result, { winner => undef, reason => 'insufficient_material' }, 'insufficient material';

    my $already = from('7k/5Q2/6K1/8/8/8/8/8 b - - 0 1');
    is $already->status, 'finished', 'a position that is already stalemate is finished at once';
    is $already->result->{reason}, 'stalemate', 'as a stalemate';

    my $r = game();
    for (1 .. 2) { $r->play($_) for qw(g1f3 g8f6 f3g1 f6g8) }
    is $r->status, 'finished', 'the knights out and back twice is three times the opening';
    is_deeply $r->result, { winner => undef, reason => 'repetition' }, 'repetition';
    my $almost = game();
    $almost->play($_) for qw(g1f3 g8f6 f3g1 f6g8);
    is $almost->status, 'active', 'twice is not three times';

    my $q = game();
    is $q->resign('p1'), 0, 'p1 resigns';
    is_deeply $q->result, { winner => 'p2', reason => 'resignation' }, 'and p2 wins by resignation';
    is $q->resign('p2')->code, 'game_over', 'a second resignation is game_over';
    is game()->resign('p3')->code, 'bad_move', 'a seat that is not one is bad_move';
};

subtest 'replay' => sub {
    my $g = game();
    $g->play($_) for qw(e2e4 e7e5 g1f3 b8c6 f1b5 a7a6);
    my ($again, $why, $at) = $G->replay(seed => $SEED, white => 'p1', moves => $g->log);
    is $why, 0, 'a log replays';
    is $at, 6, 'all six moves';
    is $again->position->toFEN, $g->position->toFEN, 'to the same position';
    is $again->san_log, $g->san_log, 'with the same SAN';

    my ($inst) = $g->replay($g->log);
    is $inst->position->toFEN, $g->position->toFEN, 'the instance form too';
    my $scalar = $g->replay([ @{ $g->log }[0 .. 1] ]);
    ok ref $scalar, 'in scalar context, the game';
    is scalar @{ $scalar->log }, 2, 'two moves in';

    my @tampered = @{ $g->log };
    $tampered[3] = 'b8a6';
    $tampered[4] = 'e4e5';
    my ($broken, $bad, $i) = $G->replay(seed => $SEED, white => 'p1', moves => \@tampered);
    is $bad->code, 'not_legal', 'a tampered log is refused';
    is $i, 4, 'at the move that could not be played';
    is scalar @{ $broken->log }, 4, 'with the moves before it played';
    is $G->replay(seed => $SEED, moves => \@tampered), undef, 'and undef in scalar context';
    is $G->replay('odd'), undef, 'an odd list is undef';

    my $m = game();
    $m->play($_) for qw(f2f3 e7e5 g2g4 d8h4);
    my ($done) = $m->replay($m->log);
    is $done->status, 'finished', 'a finished game replays to finished';
    is_deeply $done->result, $m->result, 'with the same result';

    my $fen = from('4k3/8/8/8/8/8/8/R3K3 b - - 3 12');
    $fen->play('e8d8');
    $fen->play('e1d1');
    $fen->play('d8c8');
    is $fen->san_log, '12... Kd8 13. Kd1 Kc8', 'a game that began with black to move numbers from the FEN';
    my ($f2) = $fen->replay($fen->log);
    is $f2->san_log, $fen->san_log, 'and replays from its own starting position';
};

subtest 'copies are copies' => sub {
    my $g = game();
    push @{ $g->signatures }, 0;
    is scalar @{ $g->signatures }, 1, 'pushing to signatures changes nothing';
    push @{ $g->log }, 'x';
    is_deeply $g->log, [], 'pushing to the log changes nothing';
    my $r = $g->result;
    $r->{winner} = 'p1';
    is $g->winner, undef, 'writing to a result changes nothing';
};

subtest 'the error class' => sub {
    is_deeply [ Term::Chess::Error->flags ],
        [qw(bad_move game_over not_your_turn no_piece bad_promotion in_check not_legal)],
        'seven flags in order';
    ok(Term::Chess::Error->known('in_check'), 'in_check is known');
    ok(!Term::Chess::Error->known('generals_face'), 'and a xiangqi flag is not');
    my $e = Term::Chess::Error->throw('not_legal', legal => ['e2e4']);
    ok($e, 'a refusal is true');
    is $e->code, 'not_legal', 'code';
    is $e->stringify, $e->message, 'stringify is the message';
    is_deeply $e->legal, ['e2e4'], 'legal carried';
    ok !eval { Term::Chess::Error->throw('no_such'); 1 }, 'an unknown flag dies';
    isnt "$e", $e->message, 'and there is no string overload';
};

done_testing;
