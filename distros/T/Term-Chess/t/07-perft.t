#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

use Chess::Plisco;

diag "Chess::Plisco $Chess::Plisco::VERSION from $INC{'Chess/Plisco.pm'}";

my %canary = (
    'the opening' => ['rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1', 8_902],
    'kiwipete'    => ['r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1', 97_862],
);

plan tests => scalar keys %canary;

for my $name (sort keys %canary) {
    my ($fen, $want) = @{ $canary{$name} };
    is(Chess::Plisco->new($fen)->perft(3), $want,
        "$name to depth 3 is $want: the Plisco under us is the one this dist was tested against");
}
