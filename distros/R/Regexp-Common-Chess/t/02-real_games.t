#!/usr/bin/perl
# Copyright (c) 2011 - Olof Johansson <olof@cpan.org>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use warnings;
use strict;
use Test::More;
use Regexp::Common qw/Chess/;

my $re = $RE{Chess}{SAN};

my %games = (
	'deep blue vs kasparov 1997, game 1' => [qw/
		e4 c5 c3 d5 exd5 Qxd5 d4 Nf6 Nf3 Bg4
		Be2 e6 h3 Bh5 O-O Nc6 Be3 cxd4 cxd4
		Bb4 a3 Ba5 Nc3 Qd6 Nb5 Qe7 Ne5 Bxe2
		Qxe2 O-O Rac1 Rac8 Bg5 Bb6 Bxf6 gxf6
		Nc4 Rfd8 Nxb6 axb6 Rfd1 f5 Qe3 Qf6 d5
		Rxd5 Rxd5 exd5 b3 Kh8 Qxb6 Rg8 Qc5 d4
		Nd6 f4 Nxb7 Ne5 Qd5 f3 g3 Nd3 Rc7 Re8
		Nd6 Re1+ Kh2 Nxf2 Nxf7+ Kg7 Ng5+ Kh6
		Rxh7+
	/], # 0-1
	'botvinnik vs capablanca 1938' => [qw/
		d4 Nf6 c4 e6 Nc3 Bb4 e3 d5 a3 Bxc3+ 
		bxc3 c5 cxd5 exd5 Bd3 O-O Ne2 b6 O-O
		Ba6 Bxa6 Nxa6 Bb2 Qd7 a4 Rfe8 Qd3 c4 
		Qc2 Nb8 Rae1 Nc6 Ng3 Na5 f3 Nb3 e4 
		Qxa4 e5 Nd7 Qf2 g6 f4 f5 exf6 Nxf6 f5
		Rxe1 Rxe1 Re8 Re6 Rxe6 fxe6 Kg7 Qf4 
		Qe8 Qe5 Qe7 Ba3 Qxa3 Nh5+ gxh5 Qg5+
		Kf8 Qxf6+ Kg8 e7 Qc1+ Kf2 Qc2+ Kg3 
		Qd3+ Kh4 Qe4+ Kxh5 Qe2+ Kh4 Qe4+ g4
		Qe1+ Kh5
	/], # 1-0
);

my $tests;
$tests += @{$games{$_}} for (keys %games);
plan tests => $tests;

for my $game (keys %games) {
	my $moves = 0;
	for(@{$games{$game}}) {
		my $color = $moves & 1 ? 'black' : 'white';
		my $move = int($moves / 2 + 1);
		
		ok(/^$re$/, "$game: $move (${color}'s move): $_");
		++$moves;
	}
}

