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
use Term::Chess::Bot;
use Term::Chess::Test::Handle;

my $T = 'Term::Chess';
my $H = 'Term::Chess::Test::Handle';

sub game { Term::Chess::Game->new(seed => substr(($_[0] // 'terminal-test') . ('.' x 32), 0, 32), white => $_[1] // 'p1', (defined $_[2] ? (position => $_[2]) : ())) }

# THE WIDTH FUNCTION IS DUPLICATED HERE ON PURPOSE: a renderer and a measurer
# that share one function agree with each other even when both are wrong. The
# rule, written from scratch: a chess glyph is one column, ANSI paint is none,
# everything else is one.
sub width {
    my ($s) = @_;
    $s =~ s/\e\[[0-9;]*m//g;
    return length $s;
}

subtest 'the twelve glyphs are the codepoints the plan pinned' => sub {
    my %outline = (CP_KING, 0x2654, CP_QUEEN, 0x2655, CP_ROOK, 0x2656, CP_BISHOP, 0x2657, CP_KNIGHT, 0x2658, CP_PAWN, 0x2659);
    my %filled  = (CP_KING, 0x265A, CP_QUEEN, 0x265B, CP_ROOK, 0x265C, CP_BISHOP, 0x265D, CP_KNIGHT, 0x265E, CP_PAWN, 0x265F);
    local %ENV = %ENV;
    delete $ENV{NO_COLOR};
    my $plain = $T->new(size => 1, colour => 0);
    my $paint = $T->new(size => 1, colour => 1);
    for my $piece (sort keys %outline) {
        is ord($plain->glyph($piece, CP_WHITE)), $outline{$piece}, sprintf 'uncoloured white piece %d is U+%04X, the outline', $piece, $outline{$piece};
        is ord($plain->glyph($piece, CP_BLACK)), $filled{$piece},  sprintf 'uncoloured black piece %d is U+%04X, filled', $piece, $filled{$piece};
        is ord($paint->glyph($piece, CP_WHITE)), $filled{$piece},  'with colour on, white is the filled set';
        is ord($paint->glyph($piece, CP_BLACK)), $filled{$piece},  '  and so is black: the colour says the side';
    }
    my $ascii = $T->new(size => 1, ascii => 1);
    is join('', map { $ascii->glyph($_, CP_WHITE) } CP_KING, CP_QUEEN, CP_ROOK, CP_BISHOP, CP_KNIGHT, CP_PAWN), 'KQRBNP', 'ascii white is the FEN letters';
    is join('', map { $ascii->glyph($_, CP_BLACK) } CP_KING, CP_QUEEN, CP_ROOK, CP_BISHOP, CP_KNIGHT, CP_PAWN), 'kqrbnp', '  and black is lowercase';
    is $plain->glyph(0, CP_WHITE), '', 'no piece is no glyph';
};

subtest 'every row of the board is the same number of display columns' => sub {
    local %ENV = %ENV;
    delete $ENV{NO_COLOR};
    for my $mode ([ 'characters', { colour => 0 } ], [ 'ascii', { ascii => 1, colour => 0 } ], [ 'coloured', { colour => 1 } ]) {
        my ($name, $opt) = @$mode;
        my $t = $T->new(size => 1, %$opt);
        my @marked = (
            [ 'bare',        {} ],
            [ 'flipped',     { flip => 1 } ],
            [ 'cursor on a', { cursor => 'a1' } ],
            [ 'cursor on h', { cursor => 'h8' } ],
            [ 'held and to', { from => 'e2', cursor => 'e4', spots => [qw(e3 e4)] } ],
            [ 'a capture',   { from => 'a1', cursor => 'a8', spots => [qw(a8 h8)] } ],
            [ 'all flipped', { flip => 1, from => 'a1', cursor => 'h1', spots => [qw(h1 a8)] } ],
        );
        for my $case (@marked) {
            my ($what, $o) = @$case;
            my @lines = $t->board_lines(%$o);
            is scalar @lines, 9, "$name/$what: eight ranks and a legend";
            my %widths;
            $widths{ width($_) }++ for @lines;
            is scalar keys %widths, 1, "$name/$what: one width across all 9 rows (" . join(', ', sort keys %widths) . ')'
                or diag(join "\n", map { sprintf '%3d |%s|', width($_), $_ } @lines);
            is((keys %widths)[0], 27, "$name/$what: and it is 27 columns");
        }
    }
};

subtest 'a1 is dark, h1 is light, and there are 32 of each' => sub {
    my $t = $T->new(size => 1, colour => 0);
    is $t->light('a1'), 0, 'a1 is dark';
    is $t->light('h1'), 1, 'h1 is light';
    is $t->light('e4'), 1, 'e4 is light';
    is $t->light('d4'), 0, 'd4 is dark';
    is $t->light('a8'), 1, 'a8 is light';
    my %n;
    $n{ $t->light($_) }++ for map { my $f = $_; map { "$f$_" } 1 .. 8 } 'a' .. 'h';
    is_deeply \%n, { 0 => 32, 1 => 32 }, 'thirty-two of each';

    my $g = game(undef, 'p1', '4k3/8/8/8/8/8/8/4K3 w - - 0 1');
    my $board = join "\n", $T->new(size => 1, colour => 0, game => $g)->board_lines;
    my $light = () = $board =~ / \./g;
    my $dark  = () = $board =~ / :/g;
    is $light, 31, 'thirty-one empty light squares drawn as a dot (e8 is taken by a king)';
    is $dark, 31, 'thirty-one empty dark squares drawn as a colon (e1 is taken by the other)';
    like((split /\n/, $board)[7], qr/\A1   :  \.  :  \.  \x{2654}  \.  :  \. \z/, 'rank 1 starts dark on a1, and the king stands on light e1');
};

subtest 'the view flips for the second seat, files and all' => sub {
    my @up   = $T->new(size => 1, colour => 0)->board_lines;
    my @down = $T->new(size => 1, colour => 0)->board_lines(flip => 1);
    like $up[0],   qr/\A8 /, 'unflipped starts at rank 8';
    like $down[0], qr/\A1 /, 'flipped starts at rank 1';
    like $up[-1],   qr/a .*b .*c .*d .*e .*f .*g .*h/, 'the files run a to h';
    like $down[-1], qr/h .*g .*f .*e .*d .*c .*b .*a/, '  and h to a when flipped, so the player sees the board from their side';
    my $t = $T->new(size => 1, ascii => 1, colour => 0);
    like(($t->board_lines)[7],              qr/\A1   R  N  B  Q  K  B  N  R/, 'white from white: the king is right of the queen');
    like(($t->board_lines(flip => 1))[7],   qr/\A8   r  n  b  k  q  b  n  r/, 'black from black: rank 8 at the bottom with the king left of the queen');
};

subtest 'NO_COLOR beats an explicit request for colour' => sub {
    {
        local $ENV{NO_COLOR} = '1';
        is $T->new(size => 1, colour => 1)->colour, 0, 'NO_COLOR=1 wins over colour => 1';
    }
    {
        local $ENV{NO_COLOR} = '0';
        is $T->new(size => 1, colour => 1)->colour, 0, 'and so does NO_COLOR=0: presence is what counts';
        is $T->new->colour, 0, '  with no request either way';
    }
    {
        local %ENV = %ENV;
        delete $ENV{NO_COLOR};
        is $T->new(size => 1, colour => 1)->colour, 1, 'without it, colour => 1 is honoured';
        is $T->new(size => 1, colour => 0)->colour, 0, '  and colour => 0 is too';
        is $T->new->colour, 1, '  and no request means colour';
        like join('', $T->new(size => 1, colour => 1)->board_lines), qr/\e\[/, 'colour emits escapes';
        unlike join('', $T->new(size => 1, colour => 0)->board_lines), qr/\e\[/, 'and off emits none';
        my $t = $T->new(size => 1, colour => 1);
        $t->colour(0);
        is $t->colour, 0, 'colour can be turned off afterwards';
        $t->colour(1);
        is $t->colour, 1, '  and on again';
    }
};

subtest 'ascii is the FEN letters and nothing above U+007F' => sub {
    my @lines = $T->new(size => 1, ascii => 1, colour => 0)->board_lines;
    my $board = join "\n", @lines;
    unlike $board, qr/[^\x00-\x7F]/, 'nothing outside ASCII anywhere in it';
    like $lines[0], qr/r.*n.*b.*q.*k.*b.*n.*r/, 'rank 8 is black, lowercase';
    like $lines[7], qr/R.*N.*B.*Q.*K.*B.*N.*R/, 'rank 1 is white, uppercase';
    my $marked = join "\n", $T->new(size => 1, ascii => 1, colour => 0)->board_lines(from => 'a1', cursor => 'h8', spots => ['a8']);
    unlike $marked, qr/[^\x00-\x7F]/, 'and the marks are ASCII too';
    like $marked, qr/x/, '  the capture mark is an x';
    my @both = $T->new(size => 1, ascii => 1, colour => 0)->board_lines(from => 'e2', cursor => 'e2');
    like $both[6], qr/\[ P\]/, 'the cursor bracket wins over the held parenthesis on one square';
    unlike $both[6], qr/[()]/, '  and the parenthesis is not drawn at all';
};

subtest 'size: squares of 2, 4 or 6 columns and as many rows, the default 2' => sub {
    local %ENV = %ENV;
    delete $ENV{NO_COLOR};
    is $T->new(colour => 0)->size, 2, 'the default size is 2';
    ok !eval { $T->new(size => 4); 1 }, 'size 4 croaks';
    like $@, qr/size is 1, 2 or 3/, '  saying what it takes';
    ok !eval { $T->new(size => 'big'); 1 }, '  and so does a word';
    for my $size (1, 2, 3) {
        for my $mode ([ 'plain', { colour => 0 } ], [ 'coloured', { colour => 1 } ], [ 'ascii', { ascii => 1, colour => 0 } ]) {
            my ($name, $opt) = @$mode;
            my $t = $T->new(size => $size, %$opt);
            my @lines = $t->board_lines(from => 'd2', cursor => 'e2', spots => [qw(d4 e3)]);
            is scalar @lines, 8 * $size + 1, "size $size $name: eight ranks of $size rows and a legend";
            my %w;
            $w{ width($_) }++ for @lines;
            is_deeply [ keys %w ], [ 16 * $size + 11 ], "  every row is @{[ 16 * $size + 11 ]} columns";
            my @labelled = grep { /\A\d / } @lines;
            is scalar @labelled, 8, '  eight rows carry a rank label';
            is((grep { /\A  / } @lines[0 .. $#lines - 1]), 8 * ($size - 1), '  and the rest of the square rows are blank-labelled');
            my $glyph_row = int($size / 2);
            like $lines[$glyph_row], qr/\A8 /, "  the glyph row of a square is row $glyph_row of it";
            my $legend = $lines[-1];
            my $plain = $lines[$glyph_row];
            $plain =~ s/\e\[[0-9;]*m//g;
            my $glyph = $name eq 'ascii' ? 'r' : $t->glyph(CP_ROOK, CP_BLACK);
            is index($legend, 'a'), index($plain, $glyph), '  the file letter sits under the glyph';
        }
    }
};

subtest 'with colour on the gaps and margins are painted and an empty square is blank' => sub {
    local %ENV = %ENV;
    delete $ENV{NO_COLOR};
    for my $size (1, 2) {
        my $t = $T->new(size => $size, colour => 1);
        my @lines = $t->board_lines(cursor => 'a1', from => 'h8', spots => ['h1']);
        for my $i (0 .. $#lines - 1) {
            my $row = substr $lines[$i], 2;
            like $row, qr/\A(?:\e\[[0-9;]*m[^\e]*\e\[0m)+\z/, "size $size row $i is painted spans end to end, the gaps and margins included"
                or last;
        }
        my $row = $lines[ 7 * $size + int($size / 2) ];
        $row =~ s/\e\[[0-9;]*m//g;
        like $row, qr/\A1 \[/, '  the cursor mark on a1 is in the painted left margin';
        my $empty = $lines[ 2 * $size + int($size / 2) ];
        $empty =~ s/\e\[[0-9;]*m//g;
        unlike $empty, qr/[.:]/, '  an empty rank has no dots or colons: the colour is the shade';
        like $empty, qr/\A6 \s+\z/, '  it is blank';
        my $first = $lines[0];
        my ($light_paint) = $first =~ /\e\[(48;5;\d+)m/;
        ok $light_paint, '  the top-left square a8 is painted';
        is $light_paint, '48;5;180', '  light, since a8 is light';
    }
    my $plain = $T->new(size => 2, colour => 0);
    my @lines = $plain->board_lines;
    like $lines[2 * 2 + 1], qr/\A6    \.    :    \.    :    \.    :    \.    :\s*\z/, 'without colour the dots and colons return';
};

subtest 'a game played through a pair of handles' => sub {
    my $in  = $H->reader('board', 'legal', 'fen', 'log', 'help', 'wibble', 'e2e5', 'e2e4', 'log', 'quit');
    my $out = $H->recorder;
    my $g = game();
    my $t = $T->new(size => 1, in => $in->fh, out => $out->fh, game => $g, colour => 0, level => 2_000, seat => 'p1');
    my $status = $t->start;
    my $text = $out->text;
    is $status, 0, 'quitting is not a loss, so the status is 0';
    like $text, qr/a move is coordinates like e2e4/, 'it said how to type a move';
    like $text, qr/white to move> /, 'the prompt names the colour';
    like $text, qr/20 moves: /, 'legal listed the twenty';
    like $text, qr{rnbqkbnr/pppppppp}, 'fen printed a FEN';
    like $text, qr/no moves yet/, 'log before a move says so';
    like $text, qr/or standard notation like Nf3/, 'help printed the help';
    like $text, qr/no: that is not a move \(bad_move\)/, 'the nonsense was refused with its code';
    like $text, qr/no: that piece cannot move there \(not_legal\)/, 'and the impossible move too';
    like $text, qr/the bot plays \S+ \([a-h][1-8][a-h][1-8]\)/, 'the bot announced its move in SAN with the coordinates';
    like $text, qr/white to move> 1\. e4 \S+$/m, 'log after the moves is numbered SAN, on the prompt line since a pipe types no newline';
    is $g->log->[0], 'e2e4', 'the typed move was played';
    is scalar @{ $g->log }, 2, 'and the bot answered it';
};

subtest 'on a terminal the screen is cleared before each new position' => sub {
    my $out = $H->recorder;
    my $g = game();
    my $t = $T->new(size => 1, in => $H->reader('e2e4', 'quit')->fh, out => $out->fh, game => $g, colour => 0, ascii => 1, level => 2_000, seat => 'p1', rewind => 1);
    is $t->start, 0, 'a move and a quit';
    my $text = $out->text;
    my @clears = $text =~ /(\e\[H\e\[2J)/g;
    is scalar @clears, 2, 'two clears: after the typed move and after the bot\'s';
    like $text, qr/\e\[H\e\[2Jthe bot plays \S+ \([a-h][1-8][a-h][1-8]\)\n8 /, 'the announcement is printed straight after the clear, above the board';
    my $piped = $H->recorder;
    my $p = $T->new(size => 1, in => $H->reader('e2e4', 'quit')->fh, out => $piped->fh, game => game(), colour => 0, ascii => 1, level => 2_000, seat => 'p1');
    $p->start;
    unlike $piped->text, qr/\e\[H\e\[2J/, 'under a pipe nothing is cleared';
    like $piped->text, qr/the bot plays/, '  and the announcement is still there';
    my $picked = $H->recorder;
    my @keys = ("\r", "\r", 'q');
    my $k = $T->new(size => 1, out => $picked->fh, game => game(), colour => 0, ascii => 1, level => 2_000, seat => 'p1', picking => 1, rewind => 1, keysource => sub { shift @keys });
    $k->start;
    my @pc = $picked->text =~ /(\e\[H\e\[2J)/g;
    is scalar @pc, 2, 'with the picker: a clear after the bot\'s move and one for the final board';
    like $picked->text, qr/\e\[H\e\[2Jthe bot plays [^\n]+\n8 /, '  the bot\'s announcement sits above the picker\'s next frame';
};

subtest 'SAN is typed too, and resign ends it' => sub {
    my $in  = $H->reader('Nf3', 'resign');
    my $out = $H->recorder;
    my $g = game();
    my $t = $T->new(size => 1, in => $in->fh, out => $out->fh, game => $g, colour => 0, level => 2_000, seat => 'p1');
    is $t->start, 1, 'resigning is a loss';
    is $g->log->[0], 'g1f3', 'Nf3 went in as coordinates';
    like $out->text, qr/you lost: resignation/, 'and the verdict says why';
    is_deeply $g->result, { winner => 'p2', reason => 'resignation' }, 'the game agrees';
};

subtest 'you won, you lost, drawn' => sub {
    my $out = $H->recorder;
    my $g = game(undef, 'p1', '6k1/5ppp/8/8/8/8/5PPP/R5K1 w - - 0 1');
    my $t = $T->new(size => 1, in => $H->reader('a1a8')->fh, out => $out->fh, game => $g, colour => 0, seat => 'p1');
    is $t->start, 0, 'mating is status 0';
    like $out->text, qr/you won: checkmate/, '  and says you won';

    $out = $H->recorder;
    $g = game(undef, 'p1', '6k1/5ppp/8/8/8/8/5PPP/R5K1 w - - 0 1');
    $t = $T->new(size => 1, in => $H->reader('quit')->fh, out => $out->fh, game => $g, colour => 0, level => 2_000, seat => 'p2');
    is $t->start, 1, 'being mated by the bot is status 1';
    like $out->text, qr/the bot plays Ra8# \(a1a8\), checkmate/, '  the announcement says checkmate';
    like $out->text, qr/you lost: checkmate/, '  and so does the verdict';

    $out = $H->recorder;
    $g = game(undef, 'p1', '7k/8/6K1/5Q2/8/8/8/8 w - - 0 1');
    $t = $T->new(size => 1, in => $H->reader('f5f7')->fh, out => $out->fh, game => $g, colour => 0, seat => 'p1');
    is $t->start, 0, 'a draw is status 0';
    like $out->text, qr/drawn: stalemate/, '  and says drawn';

    $out = $H->recorder;
    $g = game(undef, 'p1', '4k3/8/8/8/8/8/3b4/4KN2 w - - 0 1');
    $t = $T->new(size => 1, in => $H->reader('f1d2')->fh, out => $out->fh, game => $g, colour => 0, seat => 'p1');
    is $t->start, 0, 'insufficient material is a draw';
    like $out->text, qr/drawn: neither side can mate/, '  in words';

    $out = $H->recorder;
    $g = game(undef, 'p1', '7k/5Q2/6K1/8/8/8/8/8 b - - 0 1');
    $t = $T->new(size => 1, in => $H->reader('quit')->fh, out => $out->fh, game => $g, colour => 0, seat => 'p1');
    is $t->start, 0, 'a game already over returns at once';
    like $out->text, qr/drawn: stalemate/, '  with its verdict';
};

subtest 'the announcement reads the move from Plisco' => sub {
    my $t = $T->new(size => 1, colour => 0, out => $H->recorder->fh);
    my $g = game(undef, 'p1', 'r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3');
    is $t->describe($g, 'f3e5', 'the bot plays'), 'the bot plays Nxe5 (f3e5), taking the pawn', 'a capture names the piece taken';
    is $t->describe($g, 'f1b5', 'try'), 'try Bb5 (f1b5)', 'a quiet move is the SAN and the coordinates';
    my $ep = game(undef, 'p1', '4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1');
    is $t->describe($ep, 'e5d6', 'you play'), 'you play exd6 (e5d6), taking the pawn', 'en passant takes a pawn';
    my $ch = game(undef, 'p1', '4k3/8/8/8/8/8/8/R3K3 w - - 0 1');
    is $t->describe($ch, 'a1a8', 'the bot plays'), 'the bot plays Ra8+ (a1a8), check', 'a check says so';
    is $t->describe($ch, 'nonsense', 'the bot plays'), 'the bot plays nonsense', 'a move Plisco cannot read is echoed as it is';
    is $t->piece_name(CP_KNIGHT, CP_BLACK), 'black knight', 'piece_name';
    is $t->piece_name(0), 'nothing', '  and nothing';
};

subtest 'a move the bot offers and the game refuses stops the game' => sub {
    no warnings 'redefine';
    local *Term::Chess::Bot::choose = sub { 'a1a1' };
    my $out = $H->recorder;
    my $g   = game(undef, 'p2');
    my $t   = $T->new(size => 1, in => $H->reader('quit')->fh, out => $out->fh, game => $g, colour => 0, picking => 0, seat => 'p1');
    is $g->turn, 'p2', 'the bot is to move, so the bot branch runs first';
    ok $g->play('a1a1'), '  and a1a1 really is a move the game refuses';
    my $status = eval {
        local $SIG{ALRM} = sub { die "start did not return\n" };
        alarm 10;
        my $s = $t->start;
        alarm 0;
        $s;
    };
    alarm 0;
    is $@, '', 'start returned rather than spinning';
    ok defined $status, '  with a status';
    like $out->text, qr/the bot offered a move the game refused: not_legal/, '  and said what happened';
};

subtest 'hint, and the bot plays from the seat it is given' => sub {
    my $in  = $H->reader('hint', 'quit');
    my $out = $H->recorder;
    my $g = game(undef, 'p1', '6k1/5ppp/8/8/8/8/5PPP/R5K1 w - - 0 1');
    my $t = $T->new(size => 1, in => $in->fh, out => $out->fh, game => $g, colour => 0, seat => 'p1');
    is $t->start, 0, 'quit after a hint';
    like $out->text, qr/try Ra8# \(a1a8\), checkmate/, 'the hint is the mate';
    is scalar @{ $g->log }, 0, '  and was not played';
};

subtest 'start builds a game when given none, and returns rather than exits' => sub {
    my $out = $H->recorder;
    my $t = $T->new(size => 1, in => $H->reader('quit')->fh, out => $out->fh, colour => 0, level => 2_000);
    my $status = $t->start;
    ok defined $status, 'it returned';
    is $status, 0, '  with a status';
    ok $t->game, '  and made a game';
    is $t->game->white, 'p1', '  with p1 as white';
};

subtest 'the level is handed to the bot' => sub {
    my $seen;
    no warnings 'redefine';
    local *Term::Chess::Bot::choose = sub { $seen = $Term::Chess::Bot::LEVEL; 'e7e5' };
    my $g = game(undef, 'p1');
    my $t = $T->new(size => 1, in => $H->reader('e2e4', 'quit')->fh, out => $H->recorder->fh, game => $g, colour => 0, level => 12_345, seat => 'p1');
    $t->start;
    is $seen, 12_345, 'LEVEL was the sitting\'s level while the bot chose';
    is $Term::Chess::Bot::LEVEL, undef, '  and is unset again afterwards';
};

subtest 'in and out are read-write properties, and the layer is pushed once' => sub {
    my $t = $T->new(size => 1, colour => 0);
    my $rec = $H->recorder;
    $t->out($rec->fh);
    is $t->out, $rec->fh, 'out took a new handle';
    my @layers = PerlIO::get_layers($rec->fh);
    ok((grep { /encoding/i } @layers), '  with an encoding layer');
    $t->out($rec->fh);
    is_deeply [ PerlIO::get_layers($rec->fh) ], \@layers, '  and setting it again adds none';
    $t->draw;
    like $rec->decoded, qr/\x{2656}/, '  and the board went to it, as characters';
    my $rdr = $H->reader('quit');
    $t->in($rdr->fh);
    is $t->in, $rdr->fh, 'in took one too';
    my $a = $T->new(size => 1, ascii => 1);
    my $plain = $H->recorder;
    $a->out($plain->fh);
    is scalar(grep { /utf8|encoding/i } PerlIO::get_layers($plain->fh)), 0, 'ascii pushes no layer';
};

subtest 'picking and rewind follow the handles when unset' => sub {
    my $t = $T->new(size => 1, in => $H->reader()->fh, out => $H->recorder->fh, colour => 0);
    is $t->picking, 0, 'no tty, no picker';
    is $t->rewind, 0, 'no tty, no rewind';
    is $t->keys_available, 0, 'no keys';
    $t->keysource(sub { undef });
    is $t->keys_available, 1, 'a keysource is keys';
    is $t->picking, 1, '  and so a picker';
    $t->picking(0);
    is $t->picking, 0, 'unless told otherwise';
    ok $t->enter_raw, 'enter_raw with a keysource';
    is $t->raw, 1, '  sets raw';
    $t->leave_raw;
    is $t->raw, 0, '  and leave_raw clears it';
    is $t->enter_raw, $t, 'enter_raw returns the terminal';
    $t->rewind(1);
    is $t->rewind, 1, 'rewind can be forced';
};

subtest 'the key reader' => sub {
    my @chars;
    my $t = $T->new(size => 1, colour => 0, out => $H->recorder->fh, keysource => sub { shift @chars });
    @chars = ("\e", '[', 'A');
    is $t->read_key, 'up', 'an arrow';
    @chars = ("\r");
    is $t->read_key, 'enter', 'enter';
    @chars = (' ');
    is $t->read_key, ' ', 'a space comes back as itself';
    @chars = ("\e", 'x');
    is $t->read_key, 'escape', 'escape then a letter is escape';
    is $t->read_key, 'x', '  and the letter is still there';
    @chars = ("\e", '[', '5', '~');
    is $t->read_key, 'page_up', 'a tilde sequence';
    @chars = ("\x03");
    is $t->read_key, 'interrupt', 'control-c';
    @chars = ();
    is $t->read_key, undef, 'nothing is undef';
};

done_testing;
