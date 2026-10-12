#!perl
use 5.014;
use strict;
use warnings;
use utf8;
use Test::More;
use lib 't/lib';

use Chess::Plisco qw(:all);
use Term::Chess;
use Term::Chess::Game;
use Term::Chess::Test::Handle;

my $T = 'Term::Chess';
my $H = 'Term::Chess::Test::Handle';

# ONE CHARACTER PER CALL, which is what the key reader asks for and what makes
# an escape sequence testable: an arrow is three reads.
sub keysource {
    my @chars;
    for my $k (@_) {
        push @chars,
            $k eq 'up'     ? ("\e", '[', 'A')
          : $k eq 'down'   ? ("\e", '[', 'B')
          : $k eq 'right'  ? ("\e", '[', 'C')
          : $k eq 'left'   ? ("\e", '[', 'D')
          : $k eq 'home'   ? ("\e", '[', 'H')
          : $k eq 'end'    ? ("\e", '[', 'F')
          : $k eq 'enter'  ? ("\r")
          : $k eq 'tab'    ? ("\t")
          : $k eq 'escape' ? ("\e")
          : $k eq 'bs'     ? ("\x7f")
          :                  split //, $k;
    }
    return sub { shift @chars };
}

sub picker {
    my ($fen, $white, @keys) = @_;
    my $g = Term::Chess::Game->new(seed => 'p' x 32, white => $white // 'p1', (defined $fen ? (position => $fen) : ()));
    my $out = $H->recorder;
    my $t = $T->new(size => 1, out => $out->fh, game => $g, colour => 0, ascii => 1, picking => 1, rewind => 0, keysource => keysource(@keys));
    return ($t, $g, $out);
}

subtest 'attacked, pinned: it reports the attacks of the side NOT on move' => sub {
    my $w = Term::Chess::Game->new(seed => 'a' x 32, position => '4k3/8/8/8/8/8/4r3/4K3 w - - 0 1')->position;
    ok $w->attacked($w->squareToShift('e1')), 'white to move: the white king on e1 is attacked by the black rook';
    ok !$w->attacked($w->squareToShift('e2')), '  the rook itself is not reported, though the white king attacks it';
    ok $w->attacked($w->squareToShift('d2')), '  d2 is, along the rook\'s rank';
    my $b = Term::Chess::Game->new(seed => 'a' x 32, position => '4k3/8/8/8/8/8/8/4KR2 b - - 0 1')->position;
    ok $b->attacked($b->squareToShift('f8')), 'black to move: f8 is attacked by the white rook';
    ok !$b->attacked($b->squareToShift('e8')), '  e8 is not';
    ok $b->attacked($b->squareToShift('e1')), '  and a square with a white piece on it still counts as attacked by white';
};

subtest 'the cursor stops only where a move is, and never on a dead piece' => sub {
    my ($t, $g) = picker(undef, 'p1');
    my $pos = $g->position;
    my $from = $t->origins($pos, 0);
    my %legal_from = map { $pos->shiftToSquare($pos->moveFrom($_)) => 1 } $pos->legalMoves;
    is_deeply [ sort @$from ], [ sort keys %legal_from ], 'the origins are exactly the from-squares of the legal moves';
    is scalar @$from, 10, '  ten pieces have a move from the opening: eight pawns and two knights';
    is_deeply $from, [qw(b1 g1 a2 b2 c2 d2 e2 f2 g2 h2)], '  in the drawn order: rank 2 above rank 1 is NOT drawn order, so the knights come after the pawns'
        if 0;
    is_deeply $from, [qw(a2 b2 c2 d2 e2 f2 g2 h2 b1 g1)], '  in the drawn order: rank 2 first, then rank 1, left to right';

    my ($boxed) = picker('4k3/8/8/8/8/8/PPP5/RN2K3 w - - 0 1', 'p1');
    my %open = map { $_ => 1 } @{ $boxed->origins($boxed->game->position, 0) };
    ok !$open{a1}, 'a rook boxed in by its own pawn and knight is not an origin';
    ok $open{a2}, '  while the pawn in front of it is';
    ok $open{b1}, '  and so is the knight';
    is_deeply [ sort keys %open ], [qw(a2 b1 b2 c2 e1)], '  and those are the five';

    my ($pinned) = picker('4r1k1/8/8/8/8/8/4N3/4K3 w - - 0 1', 'p1');
    my %pin = map { $_ => 1 } @{ $pinned->origins($pinned->game->position, 0) };
    ok !$pin{e2}, 'a knight pinned to its king by a rook is not an origin, though it has pseudo-legal moves';
    ok $pin{e1}, '  while the king is';
    is_deeply [ sort keys %pin ], ['e1'], '  and nothing else';

    my %in = map { $_ => 1 } @$from;
    for my $key (qw(right left up down tab home end)) {
        my $at = 0;
        for (1 .. scalar(@$from) + 2) {
            $at = $t->step($from, $at, $key, 0);
            ok $in{ $from->[$at] }, "$key stayed on a square that has a move" or last;
        }
    }
};

subtest 'targets are one piece\'s squares, with a promotion square once' => sub {
    my ($t, $g) = picker(undef, 'p1');
    is_deeply $t->targets($g->position, 'e2', 0), [qw(e4 e3)], 'the e-pawn: e4 above e3 in the drawn order';
    is_deeply $t->targets($g->position, 'g1', 0), [qw(f3 h3)], 'the knight: f3 then h3';
    my ($p, $pg) = picker('4k3/P7/8/8/8/8/8/4K3 w - - 0 1', 'p1');
    is_deeply $p->targets($pg->position, 'a7', 0), ['a8'], 'four promotions are one square';
    is scalar($p->moves_between($pg->position, 'a7', 'a8')), 4, '  and moves_between has the four';
    is scalar($p->moves_between($pg->position, 'a7', 'b8')), 0, '  and none for a square it cannot reach';
};

subtest 'up and down change rank, left and right ring, and the flip turns them over' => sub {
    my ($t) = picker(undef, 'p1');
    my @sq = qw(a8 e8 c5 h5 e1);
    is $t->step(\@sq, 0, 'down', 0), 2, 'down from a8 takes the nearer rank 5';
    is $t->step(\@sq, 1, 'down', 0), 2, '  and from e8 the closer file of the two';
    is $t->step(\@sq, 3, 'down', 0), 4, 'down from h5 reaches rank 1';
    is $t->step(\@sq, 4, 'up', 0), 2, 'up from e1 takes the closer file of the two';
    is $t->step(\@sq, 0, 'up', 0), 0, 'up from the top row stays';
    is $t->step(\@sq, 4, 'down', 0), 4, 'and down from the bottom row stays';
    is $t->step(\@sq, 4, 'down', 1), 2, 'flipped, down from e1 goes to rank 5';
    is $t->step(\@sq, 4, 'up', 1), 4, '  and up from it has nowhere to go';
    is $t->step(\@sq, 0, 'up', 1), 2, 'flipped, up from a8 goes to rank 5';
    is $t->step(\@sq, 0, 'left', 0), 4, 'left from the first wraps to the last';
    is $t->step(\@sq, 4, 'right', 0), 0, 'and right from the last back to the first';
    is $t->step(\@sq, 2, 'tab', 0), 3, 'tab is right';
    is $t->step(\@sq, 2, 'home', 0), 0, 'home is the first';
    is $t->step(\@sq, 2, 'end', 0), 4, 'and end the last';

    my ($b, $bg) = picker(undef, 'p2');
    $bg->play('e2e4');
    is_deeply $b->origins($bg->position, 1), [qw(h7 g7 f7 e7 d7 c7 b7 a7 g8 b8)], 'for the seat that is black the drawn order is rank 7 first and h before a';
    is_deeply $b->targets($bg->position, 'e7', 1), [qw(e5 e6)], '  and e5 is drawn above e6';
};

subtest 'two phases: a piece, then a square, and escape puts it back' => sub {
    my ($t, $g, $out) = picker(undef, 'p1', 'home', 'enter', 'enter');
    is $t->pick_move($g, 'p1'), 'a2a4', 'the first origin is the a-pawn and its first square is a4';
    my $text = $out->text;
    like $text, qr/\( P\)/, 'the held piece is drawn in parentheses';
    like $text, qr/\[ \+\]/, '  and the square under the cursor in brackets';
    like $text, qr/a4: a quiet move/, 'the caption described the move';
    like $text, qr/the white pawn on a2, 2 moves/, '  and the piece before it';
    is scalar @{ $g->log }, 0, 'pick_move did not play it';

    my ($t2, $g2) = picker(undef, 'p1', 'home', 'enter', 'escape', 'right', 'enter', 'enter');
    is $t2->pick_move($g2, 'p1'), 'b2b4', 'escape let the first piece go and right moved to the b-pawn';
    my ($t3, $g3) = picker(undef, 'p1', 'home', 'enter', 'bs', 'right', 'enter', 'down', 'enter');
    is $t3->pick_move($g3, 'p1'), 'b2b3', 'backspace does the same, and down moves to the nearer square';

    my ($t4, $g4) = picker(undef, 'p1', 'q');
    is $t4->pick_move($g4, 'p1'), 'quit', 'q quits while choosing a piece';
    my ($t5, $g5) = picker(undef, 'p1', 'enter', 'q');
    is $t5->pick_move($g5, 'p1'), 'quit', '  and while choosing a square';
    my ($t6, $g6) = picker(undef, 'p1');
    is $t6->pick_move($g6, 'p1'), 'quit', '  and running out of keys is a quit';
};

subtest 'space does what enter does, in all three phases' => sub {
    my ($t, $g) = picker(undef, 'p1', 'home', ' ', ' ');
    is $t->pick_move($g, 'p1'), 'a2a4', 'space took the piece and played the square';
    my ($m, $g2) = picker(undef, 'p1', 'home', ' ', 'enter');
    is $m->pick_move($g2, 'p1'), 'a2a4', 'space then enter';
    my ($o, $g3) = picker(undef, 'p1', 'home', 'enter', ' ');
    is $o->pick_move($g3, 'p1'), 'a2a4', 'enter then space';
    my ($p, $pg) = picker('4k3/P7/8/8/8/8/8/4K3 w - - 0 1', 'p1', 'home', ' ', ' ', ' ');
    is $p->pick_move($pg, 'p1'), 'a7a8q', 'and space answers the promotion question with the queen';
    my ($s, $sg, $out) = picker(undef, 'p1', 'q');
    $s->pick_move($sg, 'p1');
    like $out->text, qr/enter or space/, 'the line under the board offers both';
};

subtest 'the promotion question' => sub {
    my $fen = '4k3/P7/8/8/8/8/8/4K3 w - - 0 1';
    my ($t, $g, $out) = picker($fen, 'p1', 'home', 'enter', 'enter', 'n');
    is $t->pick_move($g, 'p1'), 'a7a8n', 'n makes a knight';
    like $out->text, qr/queen, rook, bishop or knight\? \(q r b n, enter is queen\)/, 'the question was asked';
    like $out->text, qr/a8: a quiet move, and promotes/, '  after a caption that said the move promotes';
    my ($q, $qg) = picker($fen, 'p1', 'home', 'enter', 'enter', 'enter');
    is $q->pick_move($qg, 'p1'), 'a7a8q', 'enter is the queen';
    my ($r, $rg) = picker($fen, 'p1', 'home', 'enter', 'enter', 'escape', 'enter', 'r');
    is $r->pick_move($rg, 'p1'), 'a7a8r', 'escape goes back to the squares with the pawn still held, and enter asks again';
    my ($z, $zg) = picker($fen, 'p1', 'home', 'enter', 'enter', 'z', 'x', 'b');
    is $z->pick_move($zg, 'p1'), 'a7a8b', 'a wrong key leaves the question standing';
    my ($qq, $qqg) = picker($fen, 'p1', 'home', 'enter', 'enter', 'q');
    is $qq->pick_move($qqg, 'p1'), 'a7a8q', 'q in the question is the queen and not a quit';
    my ($k, $kg) = picker($fen, 'p1', 'end', 'enter', 'enter');
    like $k->pick_move($kg, 'p1'), qr/\Ae1[a-h][1-8]\z/, 'the king, the last origin, is not asked';
};

subtest 'en passant is marked where the pawn stands, castling says so' => sub {
    my ($t, $g, $out) = picker('4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1', 'p1', 'home', 'enter', 'q');
    is_deeply $t->victims($g->position, 'e5'), { d5 => 1 }, 'the victim of e5xd6 stands on d5';
    is_deeply $t->victims($g->position, 'e1'), {}, '  and the king has none';
    $t->pick_move($g, 'p1');
    my @lines = split /\n/, $out->text;
    my ($rank5) = grep { /\A5 / } reverse @lines;
    like $rank5, qr/x p\( P\)/, 'd5 has the capture mark on its left; its right gap is the held pawn\'s parenthesis, since adjacent squares share a gap';
    my ($rank6) = grep { /\A6 / } reverse @lines;
    unlike $rank6, qr/x/, '  and d6, the destination, has none';
    like $rank6, qr/\+/, '  it is drawn as a square to go to';
    like $out->text, qr/d6: takes the pawn en passant/, 'the caption says en passant' if $out->text =~ /d6:/;

    my ($c, $cg, $cout) = picker('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1', 'p1');
    is $c->move_line($cg->position, 'e1', 'g1'), 'g1: castles', 'the caption for e1g1 is castles';
    is $c->move_line($cg->position, 'e1', 'c1'), 'c1: castles', '  and for e1c1';
    is $c->move_line($cg->position, 'e1', 'f1'), 'f1: a quiet move', '  and a step is a step';
    ok((grep { $_ eq 'g1' } @{ $c->targets($cg->position, 'e1', 0) }), 'g1 is a target of the king');
};

subtest 'the caption is Plisco\'s vocabulary and not arithmetic' => sub {
    my ($t) = picker(undef, 'p1');
    my $pos = sub { Term::Chess::Game->new(seed => 'c' x 32, position => $_[0])->position };
    is $t->move_line($pos->('6k1/5ppp/8/8/8/8/5PPP/R5K1 w - - 0 1'), 'a1', 'a8'), 'a8: a quiet move, and it is mate', 'mate';
    is $t->move_line($pos->('4k3/8/8/8/8/8/8/R3K3 w - - 0 1'), 'a1', 'a8'), 'a8: a quiet move, and it checks', 'check';
    is $t->move_line($pos->('r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3'), 'f3', 'e5'), 'e5: takes the black pawn, but it loses material', 'a capture names its prey, and the knight on c6 makes it a bad one';
    is $t->move_line($pos->('4k3/8/8/3p4/4P3/8/8/4K3 w - - 0 1'), 'e4', 'd5'), 'd5: takes the black pawn', 'a free pawn is just taken';
    is $t->move_line($pos->('4k3/8/2p5/3p4/8/8/6Q1/4K3 w - - 0 1'), 'g2', 'd5'), 'd5: takes the black pawn, but it loses material', 'a defended pawn taken by the queen loses material, from SEE';
    is $t->move_line($pos->('4k3/8/8/3p4/8/8/6Q1/4K3 w - - 0 1'), 'g2', 'd5'), 'd5: takes the black pawn', 'a free one taken by the queen does not lose material';
    is $t->move_line($pos->('3rk3/8/8/8/8/8/8/3RK3 w - - 0 1'), 'd1', 'd8'), 'd8: takes the black rook, and it checks', 'an even exchange, rook for rook, is not called a loss: SEE is exactly zero there';
    is $t->move_line($pos->('4k3/P7/8/8/8/8/8/4K3 w - - 0 1'), 'a7', 'a8'), 'a8: a quiet move, and promotes, and it checks', 'a promotion says so, and the queen checks';
    is $t->move_line($pos->('4k3/8/8/8/8/8/8/4K3 w - - 0 1'), 'e1', 'e3'), 'e3: not a move', 'a square the piece cannot reach';
    is $t->piece_line($pos->('4k3/8/8/8/8/8/4r3/4K3 w - - 0 1'), 'e1', 0), 'the white king on e1, 3 moves, and it is attacked', 'the piece line says attacked';
    like $t->piece_line($pos->('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'), 'g1', 0), qr/\Athe white knight on g1, 2 moves\z/, '  and not when it is not';
    like $t->piece_line($pos->('4k3/P7/8/8/8/8/8/4K3 w - - 0 1'), 'a7', 0), qr/\Athe white pawn on a7, 1 move\z/, '  one move, singular';
};

subtest 'the picker draws the board, and start does not draw it again' => sub {
    my $out = $H->recorder;
    my $g = Term::Chess::Game->new(seed => 'd' x 32, white => 'p1');
    my $t = $T->new(size => 1, out => $out->fh, game => $g, colour => 0, ascii => 1, picking => 1, rewind => 0, level => 2_000, seat => 'p1', keysource => keysource('enter', 'enter', 'q'));
    is $t->start, 0, 'it played a move and left';
    is scalar @{ $g->log }, 2, '  and the move and the bot\'s reply were played';
    my @lines = split /\n/, $out->text;
    my (@bare, @marked);
    for my $i (0 .. $#lines) {
        next unless $lines[$i] =~ /\A8 /;
        my $board = join "\n", @lines[ $i .. ($i + 8 > $#lines ? $#lines : $i + 8) ];
        $board =~ /[\[\(]/ ? push(@marked, $i) : push(@bare, $i);
    }
    cmp_ok scalar @marked, '>', 0, 'the picker drew boards with the cursor on them';
    is scalar @bare, 1, 'and exactly one board has no cursor: the final position' or diag('bare boards at lines: ' . join ', ', @bare);
    cmp_ok $bare[0], '>', $marked[-1], '  which comes after the last picker frame';
    like $out->text, qr/arrows to choose a move/, 'and start said arrows, not typing';
};

subtest 'the picker for the seat that is black sees its own side at the bottom' => sub {
    my ($t, $g, $out) = picker(undef, 'p2', 'home', 'enter', 'enter');
    $g->play('e2e4');
    is $t->pick_move($g, 'p1'), 'h7h5', 'home for black is the h-pawn, top left when flipped, and its first square is h5';
    like((split /\n/, $out->text)[0], qr/\A1 /, 'the first rank drawn is rank 1');
};

subtest 'a capture is a frame, not a colour, and the keys are listed' => sub {
    my ($t, $g, $out) = picker('4k3/8/8/n7/8/8/8/R3K3 w - - 0 1', 'p1', 'home', 'enter', 'down', '?', 'l', 'f', 'g', 'h', 'q');
    local $ENV{NO_COLOR} = 1;
    is $t->pick_move($g, 'p1'), 'quit', 'quit at the end';
    my $text = $out->text;
    like $text, qr/x nx/, 'the black knight on a5 is framed with x in the gap on each side, as the cursor is with brackets';
    unlike $text, qr/\e\[/, '  with no escape in the whole transcript';
    like $text, qr/arrows  move the cursor/, '? listed the keys';
    like $text, qr/\d+ moves: /, 'l listed the moves';
    like $text, qr{4k3/8/8/n7/8/8/8/R3K3 w}, 'f printed the FEN';
    like $text, qr/no moves yet/, 'g printed the log';
    like $text, qr/try \S+ \(a1[a-h][1-8]|e1[a-h][1-8]\)/, 'h printed a hint';
};

done_testing;
