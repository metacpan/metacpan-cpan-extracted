#!perl
use 5.014;
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Term::Chess;
use Term::Chess::Game;
use Term::Chess::Test::Handle;

my $FRAME = 11;

sub walk {
    my ($fen, $white, $seat, $before, $count) = @_;
    my @chars = (@$before, (("\e", '[', 'C') x $count), 'q');
    my $g = Term::Chess::Game->new(seed => 'o' x 32, white => $white, (defined $fen ? (position => $fen) : ()));
    my $out = Term::Chess::Test::Handle->recorder;
    my $t = Term::Chess->new(size => 1, out => $out->fh, game => $g, colour => 0, ascii => 1,
        picking => 1, rewind => 0, keysource => sub { shift @chars });
    is $t->pick_move($g, $seat), 'quit', 'the walk ended on q';
    my @lines = split /\n/, $out->text;
    my @seen;
    while (@lines >= $FRAME) {
        my @frame = splice @lines, 0, $FRAME;
        my ($row) = grep { index($frame[$_], '[') >= 0 } 0 .. 8;
        push @seen, defined $row ? [ $row, index($frame[$row], '[') ] : undef;
    }
    return ($t, $g, @seen);
}

sub reads_on {
    my ($name, @seen) = @_;
    my $lap = $#seen;
    is scalar(grep { !defined } @seen), 0, "$name: every frame has a cursor";
    my $back = 0;
    for my $i (1 .. $lap - 1) {
        my ($was, $now) = @seen[ $i - 1, $i ];
        $back++ unless $now->[0] > $was->[0] || ($now->[0] == $was->[0] && $now->[1] > $was->[1]);
    }
    is $back, 0, "$name: right goes on along the row and then to the row below, as the board is drawn";
    is_deeply $seen[$lap], $seen[0], "$name: and after the last it is back on the first";
    return;
}

subtest 'right visits the pieces in the order they are drawn' => sub {
    my ($t, $g, @seen) = walk(undef, 'p1', 'p1', [], 10);
    is scalar @{ $t->origins($g->position, 0) }, 10, 'ten pieces, ten presses';
    reads_on('white', @seen);
};

subtest 'and for the seat that is black, on the board turned round' => sub {
    my $fen = 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1';
    my ($t, $g, @seen) = walk($fen, 'p2', 'p1', [], 10);
    is scalar @{ $t->origins($g->position, 1) }, 10, 'ten pieces, ten presses';
    reads_on('black', @seen);
};

subtest 'right visits one piece\'s squares in the order they are drawn' => sub {
    my $fen = '4k3/8/8/8/3Q4/8/8/4K3 w - - 0 1';
    my $g = Term::Chess::Game->new(seed => 'o' x 32, white => 'p1', position => $fen);
    my $n = scalar @{ Term::Chess->new(size => 1, ascii => 1, colour => 0,
        out => Term::Chess::Test::Handle->recorder->fh)->targets($g->position, 'd4', 0) };
    cmp_ok $n, '>', 20, 'a queen in the middle has squares on every rank';
    my ($t, $h, @seen) = walk($fen, 'p1', 'p1', [ "\r" ], $n);
    shift @seen;
    reads_on('the queen', @seen);
};

done_testing;
