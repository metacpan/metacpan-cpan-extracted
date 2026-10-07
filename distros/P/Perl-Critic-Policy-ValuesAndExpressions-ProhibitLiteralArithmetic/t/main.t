#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use re '/aa';

use 5.014;

=head1 NAME

t/main.t - which expressions the policy reads as arithmetic on literals, and
which it leaves alone

=head1 DESCRIPTION

Tables of snippets that must be reported, with how many times, and a table of
snippets that must not be.

The edges are precedence and associativity: an operator whose operands are
both literals once perl has decided what each operand is, against one whose
operand reaches a variable through an operator that binds more tightly.  The
other edges are the operators that are not arithmetic, signs, notations of a
number, and version strings.

=cut

use Test::More;

use Perl::Critic;

# Loaded so that a syntax error in it is a compile failure here rather than
# Perl::Critic reporting no such policy.  Named as a string below, which is
# what ProhibitUnusedImports cannot see.
use Perl::Critic::Policy::ValuesAndExpressions::ProhibitLiteralArithmetic;    ## no critic (ProhibitUnusedImports)

# -profile => q{} because Perl::Critic otherwise walks up from cwd looking for a
# .perlcriticrc, finds this dist's own, and runs every policy in it against
# these snippets.  The anchored long name because -single-policy is a pattern.
my $POLICY = '^Perl::Critic::Policy::ValuesAndExpressions::ProhibitLiteralArithmetic$';

my $critic = Perl::Critic->new( -profile => q{}, '-single-policy' => $POLICY, -severity => 1 );

my $check_table = sub {
    my ( $label, %cases ) = @_;
    foreach my $case ( sort keys %cases ) {
        my ( $expected, $source ) = @{ $cases{$case} };
        is( scalar $critic->critique( \$source ), $expected, "$label: $case" ) or diag $source;
    }
    return;
};

$check_table->(
    'reported',
    'a product'                   => [ 1, q{my $mb = 1024 * 1024;} ],
    'a chain, once'               => [ 1, q{my $gb = 1024 * 1024 * 1024;} ],
    'a power'                     => [ 1, q{my $gb = 1024 ** 3;} ],
    'a shift'                     => [ 1, q{my $mask = 1 << 20;} ],
    'a sum'                       => [ 1, q{my $n = 2 + 3;} ],
    'a difference'                => [ 1, q{my $n = 3 - 2;} ],
    'a difference with no spaces' => [ 1, q{my $n = 3-2;} ],
    'a quotient and a remainder'  => [ 2, q{my $n = 9 / 3; my $m = 9 % 4;} ],
    'mixed operators, once'       => [ 1, q{my $n = 2 + 3 * 4;} ],
    'a constant'                  => [ 1, q{use constant TIMEOUT => 5 * 60;} ],
    'returned'                    => [ 1, q{return 60 * 60 * 24;} ],
    'an argument'                 => [ 1, q{f( 2 * 3, $x );} ],
    'a subscript'                 => [ 1, q{my $y = $x[ 1 + 1 ];} ],
    'inside parentheses'          => [ 1, q{my $n = ( 2 + 3 ) * $x;} ],
    'two expressions'             => [ 2, q{my $a = 2 * 3; my $b = 4 * 5;} ],
    'hex, separators, exponents'  => [ 1, q{my $n = 0x10 * 1_000 + 1e3;} ],
    'a negative literal'          => [ 1, q{my $n = -1 * 2;} ],
    'a negated operand'           => [ 1, q{my $n = 2 * -3;} ],
    'a sign apart from its digit' => [ 1, q{my $n = 5 - - 3;} ],
);

# What perl computes first decides whether a literal value is computed at all.
$check_table->(
    'reported, by precedence',
    'tighter than the + before it'  => [ 1, q{my $n = $y + 2 * 3;} ],
    'tighter than the + after it'   => [ 1, q{my $n = 2 * 3 + $y;} ],
    'tighter than a concatenation'  => [ 1, q{my $s = $y . 2 * 3;} ],
    'the right of a left-assoc run' => [ 1, q{my $n = $y * 2 + 3 * 4;} ],
    'left-assoc, from the left'     => [ 1, q{my $n = 2 - 3 - $y;} ],
    'right-assoc, from the right'   => [ 1, q{my $n = $y ** 2 ** 3;} ],
    'a shift of a sum'              => [ 1, q{my $n = $y << 2 + 3;} ],
    'a sum, then shifted'           => [ 1, q{my $n = 2 + 3 << $y;} ],
    'beside a comparison'           => [ 1, q{return 1 if $y > 2 * 3;} ],
    'beside a logical operator'     => [ 1, q{my $n = $y || 2 * 3;} ],
);

$check_table->(
    'allowed',
    'a variable'                     => [ 0, q{my $v = 1024 * $size;} ],
    'a variable first'               => [ 0, q{my $v = $size * 1024;} ],
    'the product binds first'        => [ 0, q{my $n = $y * 2 + 3;} ],
    'left-assoc, from the variable'  => [ 0, q{my $n = $y - 2 - 3;} ],
    'right-assoc, toward a variable' => [ 0, q{my $n = 2 ** 3 ** $y;} ],
    'a sum that binds before shift'  => [ 0, q{my $n = $y + 2 << 3;} ],
    'a range'                        => [ 0, q{my @r = 1 .. 10;} ],
    'repetition'                     => [ 0, q{my $s = '-' x 72;} ],
    'a repeated number'              => [ 0, q{my $s = 3 x 2;} ],
    'concatenation'                  => [ 0, q{my $s = 1 . 2;} ],
    'a negative literal alone'       => [ 0, q{my $n = -1;} ],
    'a number alone'                 => [ 0, q{my $n = 1_073_741_824;} ],
    'a comparison of literals'       => [ 0, q{return 1 if 2 > 1;} ],
    'a version string'               => [ 0, q{my $v = v5.14;} ],
    'a perl version'                 => [ 0, q{use 5.014;} ],
    'a number in a string'           => [ 0, q{my $s = '1024 * 1024';} ],
    'a call'                         => [ 0, q{my $n = f(2) * 3;} ],
);

done_testing;
