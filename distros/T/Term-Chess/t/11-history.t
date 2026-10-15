#!perl
use 5.014;
use strict;
use warnings;

BEGIN {
    if (($ENV{PERL_PERTURB_KEYS} // '') ne '0' || ($ENV{PERL_HASH_SEED} // '') ne '0') {
        local $ENV{PERL_HASH_SEED} = 0;
        local $ENV{PERL_PERTURB_KEYS} = 0;
        my $status = system $^X, (map { "-I$_" } grep { !ref } @INC), $0, @ARGV;
        die "t/11-history.t: rerunning with Plisco's root moves in a fixed hash order failed: $!\n"
            if $status == -1;
        exit($status >> 8 || ($status ? 255 : 0));
    }
}

use Test::More;
use lib 't/lib';

use Term::Chess;
use Term::Chess::Game;
use Term::Chess::Test::Handle;

my $T = 'Term::Chess';
my $G = 'Term::Chess::Game';
my $H = 'Term::Chess::Test::Handle';

sub game { $G->new(seed => 'h' x 32, white => 'p1', @_) }

sub keysource {
    my @queue = map {
        ref $_       ? $_
      : $_ eq 'home' ? ("\e", '[', 'H')
      : $_ eq 'enter' ? ("\r")
      :                split //, $_
    } @_;
    return sub {
        (shift @queue)->() while @queue && ref $queue[0];
        return shift @queue;
    };
}

sub picker {
    my ($g, $seat, @keys) = @_;
    my $out = $H->recorder;
    my $t = $T->new(size => 1, out => $out->fh, game => $g, colour => 0, ascii => 1,
        picking => 1, rewind => 0, level => 300, seat => $seat);
    $t->keysource(keysource(@keys));
    return ($t, $out);
}

subtest 'u takes back your move and the bot\'s reply, r plays them again' => sub {
    my $g = game();
    my $first = $g->to_text;
    my ($t, $out);
    my ($second, $after_u, $after_r, $log_u, $log_r);
    ($t, $out) = picker($g, 'p1',
        'enter', 'enter',
        sub { $second = $t->game->to_text },
        'u',
        sub { $after_u = $t->game->to_text; $log_u = scalar @{ $t->game->log } },
        'r',
        sub { $after_r = $t->game->to_text; $log_r = scalar @{ $t->game->log } },
        'q');
    is $t->start, 0, 'it played, went back and forward, and quit';
    is scalar @{ $G->from_text($second)->log }, 2, 'at the second turn your move and the bot\'s reply are played';
    is $after_u, $first, 'u: the game is the one kept at your first turn';
    is $log_u, 0, '  with the bot\'s reply gone too';
    is $after_r, $second, 'r: the game is the one kept at your second turn';
    is $log_r, 2, '  both moves back';
    is $t->game->to_text, $second, 'and the game left behind is the redone one';
    like $out->text, qr/taken back/, 'u says so';
    like $out->text, qr/played again/, 'r says so';
};

subtest 'a new move after u throws the redo away' => sub {
    my $g = game();
    my ($t, $out);
    my ($can_redo, $after_move);
    ($t, $out) = picker($g, 'p1',
        'enter', 'enter', 'u',
        sub { $can_redo = $t->history->can_redo },
        'home', 'enter', 'enter',
        sub { $after_move = $t->history->can_redo },
        'r', 'q');
    $t->start;
    is $can_redo, 1, 'after u there is a turn to play again';
    is $after_move, 0, 'after a new move there is none';
    like $out->text, qr/nothing to play again/, 'and r says so';
    is scalar @{ $t->game->log }, 2, '  and the game is the new move and its reply';
};

subtest 'u and r at the start say so and change nothing' => sub {
    my $g = game();
    my $text = $g->to_text;
    my ($t, $out) = picker($g, 'p1', 'u', 'r', 'q');
    is $t->start, 0, 'it quit';
    like $out->text, qr/nothing to take back/, 'u says there is nothing to take back';
    like $out->text, qr/nothing to play again/, 'r says there is nothing to play again';
    is $t->game, $g, 'the game is the same object';
    is $t->game->to_text, $text, '  unchanged';
};

subtest 'the bot\'s opening is never a step' => sub {
    my $g = game();
    my ($t, $out);
    my ($log_u, $opening);
    ($t, $out) = picker($g, 'p2',
        sub { $opening = $t->game->to_text },
        'enter', 'enter', 'u',
        sub { $log_u = scalar @{ $t->game->log } },
        'u', 'q');
    $t->start;
    is $log_u, 1, 'u goes back to your first turn, after the bot\'s opening';
    is $t->game->to_text, $opening, '  which is the game as you first had it';
    like $out->text, qr/nothing to take back/, 'and a second u has nothing to take back';
};

subtest 'typed undo and redo' => sub {
    my $out = $H->recorder;
    my $t = $T->new(size => 1, in => $H->reader('undo', 'e2e4', 'undo', 'redo', 'undo', 'quit')->fh,
        out => $out->fh, game => game(), colour => 0, ascii => 1, level => 300, seat => 'p1', picking => 0);
    is $t->start, 0, 'it quit';
    my $text = $out->text;
    like $text, qr/nothing to take back/, 'undo at the start says so';
    like $text, qr/taken back.*played again.*taken back/s, 'undo, redo, undo';
    is scalar @{ $t->game->log }, 0, 'and the game is back at the start';
};

subtest 'help lists undo and redo, and ? lists u and r' => sub {
    my $out = $H->recorder;
    my $t = $T->new(size => 1, in => $H->reader('help', 'quit')->fh, out => $out->fh,
        game => game(), colour => 0, ascii => 1, seat => 'p1', picking => 0);
    $t->start;
    like $out->text, qr/^undo    /m, 'help has undo';
    like $out->text, qr/^redo    /m, '  and redo';
    my ($p, $pout) = picker(game(), 'p1', '?', 'q');
    $p->start;
    like $pout->text, qr/^u       /m, '? has u';
    like $pout->text, qr/^r       /m, '  and r';
};

subtest 'on a terminal a swap clears and draws the whole board' => sub {
    my $out = $H->recorder;
    my $t = $T->new(size => 1, in => $H->reader('e2e4', 'undo', 'quit')->fh, out => $out->fh,
        game => game(), colour => 0, ascii => 1, level => 300, seat => 'p1', picking => 0, rewind => 1);
    $t->start;
    like $out->text, qr/\e\[H\e\[2Jtaken back\n8 /, 'the screen is cleared, the note said, and the board drawn below it';
    my $opening = join "\n", $T->new(size => 1, colour => 0, ascii => 1, out => $H->recorder->fh)
        ->board_lines(position => game()->position);
    like $out->text, qr/taken back\n\Q$opening\E\n/, '  and it is the opening';
};

subtest 'in the promotion question r is still the rook, and elsewhere it is redo' => sub {
    my $g = game(position => '4k3/P7/8/8/8/8/8/4K3 w - - 0 1');
    my ($t) = picker($g, 'p1', 'enter', 'enter', 'r');
    is $t->pick_move($g, 'p1'), 'a7a8r', 'r answers the question with a rook';
    ($t) = picker($g, 'p1', 'r');
    is $t->pick_move($g, 'p1'), 'redo', 'r on its own is redo';
    ($t) = picker($g, 'p1', 'u');
    is $t->pick_move($g, 'p1'), 'undo', 'u is undo';
};

subtest 'a game that ends keeps its last move' => sub {
    my $g = game(position => '6k1/5ppp/8/8/8/8/5PPP/R5K1 w - - 0 1');
    my $before = $g->to_text;
    my $t = $T->new(size => 1, in => $H->reader('a1a8')->fh, out => $H->recorder->fh,
        game => $g, colour => 0, seat => 'p1', picking => 0);
    is $t->start, 0, 'mate';
    is $t->history->text, $g->to_text, 'the finished game is kept';
    my $back = $t->history->undo;
    is $back->to_text, $before, 'and an undo takes back the mating move';
    is $back->status, 'active', '  so the game is in hand again';
};

done_testing;
