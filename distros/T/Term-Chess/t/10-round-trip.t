#!perl
use 5.014;
use strict;
use warnings;

BEGIN {
    if (($ENV{PERL_PERTURB_KEYS} // '') ne '0' || ($ENV{PERL_HASH_SEED} // '') ne '0') {
        local $ENV{PERL_HASH_SEED} = 0;
        local $ENV{PERL_PERTURB_KEYS} = 0;
        my $status = system $^X, (map { "-I$_" } grep { !ref } @INC), $0, @ARGV;
        die "t/10-round-trip.t: rerunning with Plisco's root moves in a fixed hash order failed: $!\n"
            if $status == -1;
        exit($status >> 8 || ($status ? 255 : 0));
    }
}

use Test::More;

use Term::Chess::Game;
use Term::Chess::Bot;

my $G = 'Term::Chess::Game';
my $B = 'Term::Chess::Bot';
my $SEED = join '', map { chr } 0 .. 31;

$Term::Chess::Bot::LEVEL = 300;

sub game { $G->new(seed => $SEED, white => 'p1', @_) }

sub played {
    my $g = game();
    for my $m (@_) {
        my $why = $g->play($m);
        die "the line refused $m: " . $why->code . "\n" if $why;
    }
    return $g;
}

sub bot_moves {
    my ($g) = @_;
    my @moves;
    for (1 .. 3) {
        my $m = $g->status eq 'active' ? $B->choose($g, $g->turn) : undef;
        push @moves, $m // '-';
        last unless defined $m;
        $g->play($m);
    }
    return \@moves;
}

sub round_trip {
    my ($name, $g) = @_;
    subtest $name => sub {
        my $text = $g->to_text;
        ok defined $text && !ref $text, 'to_text is a string';

        my $back = $G->from_text($text);
        isa_ok $back, $G;
        is $back->to_text, $text, 'save(load(save)) is save';
        is_deeply $back->legal, $g->legal, 'the same legal moves';
        is $back->status, $g->status, 'the same status';
        is_deeply $back->result, $g->result, 'the same result';
        is_deeply $back->signatures, $g->signatures, 'the same signatures';
        is $back->san_log, $g->san_log, 'the same SAN log';
        is $back->position->toFEN, $g->position->toFEN, 'the same position';

        my $other = $G->from_text($text);
        if ($other->status eq 'active') {
            $other->play($other->legal->[0]);
            is $g->to_text, $text, 'playing on the rebuilt game leaves the original alone';
        }
        else {
            $other->status('active');
            is $g->status, $back->status, 'changing the rebuilt game leaves the original alone';
        }

        is_deeply bot_moves($back), bot_moves($g), 'the next three bot moves are the same';
    };
}

round_trip('at the start', game());

round_trip('after three moves', played(qw(e2e4 e7e5 g1f3)));

round_trip('after a capture', played(qw(e2e4 d7d5 e4d5)));

round_trip('from a position, black to move',
    game(position => 'r3k2r/8/8/8/8/8/8/R3K2R b KQkq - 4 20'));

round_trip('one move short of a threefold repetition',
    played(qw(g1f3 g8f6 f3g1 f6g8 g1f3 g8f6 f3g1)));

{
    my $g = played(qw(g1f3 g8f6 f3g1 f6g8 g1f3 g8f6 f3g1 f6g8));
    is $g->result->{reason}, 'repetition', 'a threefold repetition ends the line';
    round_trip('after a threefold repetition', $g);
}

{
    my $g = played(qw(e2e4 e7e5));
    $g->resign('p2');
    round_trip('after a resignation', $g);
    like $g->to_text, qr/^resigned p2$/m, 'the text names the seat that resigned';
}

{
    my $g = played(qw(d2d4));
    $g->status('finished');
    round_trip('after the caller ends it', $g);
}

{
    my $g = game();
    while ($g->status eq 'active' && @{ $g->log } < 400) {
        $g->play($B->choose($g, $g->turn));
    }
    my @log = @{ $g->log };
    cmp_ok scalar @log, '>', 4, 'the bot plays a game of ' . scalar(@log) . ' moves';
    my $late = $G->replay(seed => $SEED, white => 'p1', moves => [ @log[0 .. $#log - 3] ]);
    round_trip('late in a game the bot played', $late);
    round_trip('at the end of a game the bot played', $g);
}

subtest 'a malformed string is refused with a sentence' => sub {
    my $good = played(qw(e2e4 e7e5))->to_text;
    my @bad = (
        [ undef,                                        qr/given nothing/ ],
        [ [],                                           qr/given a reference/ ],
        [ '',                                           qr/not a saved game of chess/ ],
        [ "draughts 1\n",                               qr/not a saved game of chess/ ],
        [ $good =~ s/^white .*\n//mr,                   qr/no white line/ ],
        [ $good . "moves e2e4\n",                       qr/gives moves twice/ ],
        [ $good . "colour blue\n",                      qr/does not know: 'colour blue'/ ],
        [ $good =~ s/^seed \w+/seed 1234/mr,            qr/sixty-four hex digits/ ],
        [ $good =~ s/^white p1/white p3/mr,             qr/white must be 'p1' or 'p2'/ ],
        [ $good =~ s/^start .*/start nonsense/mr,       qr/Plisco refused the position/ ],
        [ $good =~ s/^moves .*/moves e2e4 e2e4/mr,      qr/saved move 2, e2e4, was refused: no_piece/ ],
        [ $good =~ s/^resigned -/resigned p9/mr,        qr/resignation must be/ ],
        [ $good =~ s/^status active/status over/mr,     qr/status must be/ ],
    );
    for my $case (@bad) {
        my ($text, $why) = @$case;
        my $ok = eval { $G->from_text($text); 1 };
        ok !$ok, 'refused: ' . (defined $text && !ref $text ? (split /\n/, $text)[0] // '(empty)' : 'not a string');
        like $@, qr/\ATerm::Chess::Game: .*$why/s, '  with the sentence';
    }
};

done_testing;
