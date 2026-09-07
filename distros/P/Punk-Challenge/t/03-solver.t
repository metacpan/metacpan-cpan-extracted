#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Punk::Challenge::Token ();
use Punk::Challenge::Solver ();

my $T = Punk::Challenge::Token::;
my %cfg = ( secret => 'k', bits => 8 );
my $S = '192.0.2.0/24';

# Eight bits: 256 hashes on average. Nothing here asserts on time.

my $puzzle = $T->issue(\%cfg, $S);
my $sol = Punk::Challenge::Solver::solve($puzzle);
like($sol, qr/^\Q$puzzle\E\.\d+\z/, 'the solution is the puzzle, a dot, a nonce');
is(scalar $T->verify(\%cfg, $S, $sol), 8, 'and it verifies');
is(scalar $T->verify(\%cfg, $S, $sol, undef, bits => 9), undef, 'nine bits rejects it');

{
    my ($nonce) = $sol =~ /\.(\d+)\z/;
    my $d = Punk::Challenge::Token::_sha256($sol);
    cmp_ok(Punk::Challenge::Token::_zero_bits($d), '>=', 8, 'the hash has at least eight zero bits');
    for my $n (0 .. $nonce - 1) {
        my $dd = Punk::Challenge::Token::_sha256("$puzzle.$n");
        if (Punk::Challenge::Token::_zero_bits($dd) >= 8) {
            fail("nonce $n would have solved it before $nonce");
            last;
        }
    }
    pass('and no smaller nonce does: it is the first');
}

# Two puzzles at one difficulty have their own solutions.
{
    my $p2 = $T->issue(\%cfg, $S);
    my $s2 = Punk::Challenge::Solver::solve($p2);
    is(scalar $T->verify(\%cfg, $S, $s2), 8, 'a second puzzle solves');
    my ($n1) = $sol =~ /\.(\d+)\z/;
    is(scalar $T->verify(\%cfg, $S, "$p2.$n1"), undef,
        '  and the first nonce does not satisfy it unless by chance')
        if Punk::Challenge::Token::_zero_bits(Punk::Challenge::Token::_sha256("$p2.$n1")) < 8;
}

# The difficulty comes from the puzzle.
{
    my $p1 = $T->issue(\%cfg, $S, bits => 1);
    my $s1 = Punk::Challenge::Solver::solve($p1);
    is(scalar $T->verify(\%cfg, $S, $s1, undef, bits => 1), 1, 'one bit solves and verifies');
    my $p12 = $T->issue(\%cfg, $S, bits => 12);
    my $s12 = Punk::Challenge::Solver::solve($p12);
    is(scalar $T->verify(\%cfg, $S, $s12, undef, bits => 12), 12, 'twelve bits solves and verifies');
}

# max bounds the search.
{
    my $p = $T->issue(\%cfg, $S, bits => 16);
    is(Punk::Challenge::Solver::solve($p, max => 1), undef, 'one nonce at sixteen bits is not enough')
        if Punk::Challenge::Token::_zero_bits(Punk::Challenge::Token::_sha256("$p.0")) < 16;
    ok(defined Punk::Challenge::Solver::solve($puzzle, max => 1_000_000),
        'a million is plenty for eight');
}

# Not a puzzle.
{
    local $@;
    eval { Punk::Challenge::Solver::solve('hello') };
    like($@, qr/not a puzzle: 'hello'/, 'a string that is not a puzzle croaks');
    eval { Punk::Challenge::Solver::solve("$puzzle.5") };
    like($@, qr/not a puzzle/, 'a solution is not a puzzle');
    (my $p23 = $puzzle) =~ s/^(v1\.\d+\.)8\./${1}23./;
    eval { Punk::Challenge::Solver::solve($p23) };
    like($@, qr/not a puzzle/, 'twenty-three bits is refused, not attempted');
    eval { Punk::Challenge::Solver::solve(undef) };
    like($@, qr/not a puzzle/, 'undef is not a puzzle');
    eval { Punk::Challenge::Solver::solve($puzzle, mx => 1) };
    like($@, qr/unknown option 'mx' \(known: max\)/, 'an unknown option croaks');
}

done_testing;
