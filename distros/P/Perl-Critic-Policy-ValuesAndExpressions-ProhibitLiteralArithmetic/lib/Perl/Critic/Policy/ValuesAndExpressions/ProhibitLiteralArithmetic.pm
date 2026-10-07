package Perl::Critic::Policy::ValuesAndExpressions::ProhibitLiteralArithmetic 0.001;

# ABSTRACT: Write a number as the number it is, not as arithmetic on other numbers.

use strict;
use warnings FATAL => 'all';

use 5.014;

use re '/aa';

use Readonly;

use Perl::Critic::Utils qw{ :severities };
use parent              qw{Perl::Critic::Policy};


Readonly::Scalar my $DESC => q{Arithmetic on literal numbers};
Readonly::Scalar my $EXPL => q{Write the value it computes, with digit separators where they help};

# How tightly each operator binds, as perlop lists it: a higher number binds
# more tightly.  ** is the one that is right associative.
Readonly::Hash my %PRECEDENCE => (
    q{**} => 4,
    q{*}  => 3,
    q{/}  => 3,
    q{%}  => 3,
    q{x}  => 3,
    q{+}  => 2,
    q{-}  => 2,
    q{.}  => 2,
    q{<<} => 1,
    q{>>} => 1,
);
Readonly::Hash my %RIGHT_ASSOCIATIVE => ( q{**} => 1 );

# The operators that are arithmetic.  x and . bind like * and +, so they are in
# the table above, but they make strings.
Readonly::Hash my %ARITHMETIC => map { $_ => 1 } qw{ ** * / % + - << >> };

# Signs that PPI leaves as an operator before a number, as in "5 - - 3".
Readonly::Hash my %SIGN => map { $_ => 1 } qw{ + - };


sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_LOW }
sub default_themes       { return qw{ maintenance } }
sub applies_to           { return 'PPI::Token::Number' }

# A number, and not a version string.
my $is_number = sub {
    my ($elem) = @_;
    return $elem && $elem->isa('PPI::Token::Number') && !$elem->isa('PPI::Token::Number::Version');
};

my $is_operator = sub {
    my ( $elem, $table ) = @_;
    return $elem && $elem->isa('PPI::Token::Operator') && $table->{ $elem->content };
};

# The next significant element in the direction that $step names,
# sprevious_sibling or snext_sibling, past any signs.  A sign is a + or a - with
# nothing before it that could be its left operand.
my $step_past_signs = sub {
    my ( $elem, $step ) = @_;
    my $found = $elem->$step;
    while ( $is_operator->( $found, \%SIGN ) ) {
        my $before = $found->sprevious_sibling;
        last if $before && !$before->isa('PPI::Token::Operator');
        $found = $found->$step;
    }
    return $found;
};

# Whether the operand of $op on one side reaches past the run: every operator
# between them, and the one at the edge, binds tightly enough to take $op's
# operand into its own expression.
my $reaches = sub {
    my ( $op, $right, @between ) = @_;
    my $mine = $PRECEDENCE{$op};
    foreach my $other (@between) {
        my $theirs = $PRECEDENCE{$other} // return 0;
        return 0 if $theirs < $mine;
        return 0 if $theirs == $mine && ( $right ? !$RIGHT_ASSOCIATIVE{$op} : $RIGHT_ASSOCIATIVE{$op} );
    }
    return 1;
};


sub violates {
    my ( $self, $elem, undef ) = @_;
    return unless $is_number->($elem);

    # One violation for each expression, from its first number.  A number that
    # an arithmetic operator joins to a literal before it is not first.
    my $before = $step_past_signs->( $elem, 'sprevious_sibling' );
    return if $is_operator->( $before, \%ARITHMETIC ) && $is_number->( $step_past_signs->( $before, 'sprevious_sibling' ) );

    # The run of literals that arithmetic joins, and the operators at its edges.
    my @operators;
    my $last = $elem;
    while ( my $op = $last->snext_sibling ) {
        last unless $is_operator->( $op, \%ARITHMETIC );
        my $number = $step_past_signs->( $op, 'snext_sibling' );
        last unless $is_number->($number);
        push @operators, $op->content;
        $last = $number;
    }
    return unless @operators;

    my $after = $last->snext_sibling;
    my $left  = $is_operator->( $before, \%PRECEDENCE ) ? $before->content : undef;
    my $right = $is_operator->( $after,  \%PRECEDENCE ) ? $after->content  : undef;

    # An operator in the run makes a literal value when neither of its operands
    # reaches past the run to the operand beyond an edge operator.
    foreach my $i ( 0 .. $#operators ) {
        my $op = $operators[$i];
        next if defined $left  && $reaches->( $op, 0, @operators[ 0 .. $i - 1 ],           $left );
        next if defined $right && $reaches->( $op, 1, @operators[ $i + 1 .. $#operators ], $right );
        return $self->violation( $DESC, $EXPL, $elem );
    }
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitLiteralArithmetic - Write a number as the number it is, not as arithmetic on other numbers.

=head1 VERSION

version 0.001

=head1 Perl::Critic::Policy::ValuesAndExpressions::ProhibitLiteralArithmetic

Arithmetic whose operands are all literal numbers computes, every time it runs,
a value that never changes.  The reader then has to do the arithmetic to learn
what the value is.  Write the value, with digit separators where they help:

    my $GB = 1024 * 1024 * 1024;         # reported
    my $GB = 1024 ** 3;                  # reported
    my $GB = 1_073_741_824;              # what to write

=head2 PROHIBITED

    my $day = 60 * 60 * 24;
    my $mask = 1 << 20;
    use constant TIMEOUT => 5 * 60;
    my $x = $y + 2 * 3;                  # 2 * 3 is computed before the +
    my $x = 2 * 3 + $y;                  # and so is this one
    my $x = $y ** 2 ** 3;                # ** is right associative: 2 ** 3 first

=head2 ALLOWED

    my $x = $y * 2 + 3;                  # $y * 2 first, then + 3
    my $x = $y - 2 - 3;                  # ($y - 2) - 3
    my $x = 2 ** 3 ** $y;                # 2 ** (3 ** $y)
    my @r = 1 .. 10;                     # a range, not arithmetic
    my $s = '-' x 72;                    # repetition, not arithmetic
    my $n = -1;                          # a negative literal
    my $v = 1024 * $size;                # a variable is not a literal

=head1 WHAT COUNTS

An expression is reported when an operator in it has a literal number on each
side, after perl's precedence and associativity decide what each side is.  The
operators are C<**>, C<*>, C</>, C<%>, C<+>, C<->, C<<< << >>> and C<<< >> >>>.
A literal is a number in any notation that PPI reads as one, decimal, hex,
octal, binary or exponent, with or without its sign.  A version string such as
C<v5.14> is not a number here.

One expression is one violation, at its first number, however many operators
it has.

=head1 CAVEATS

PPI gives a statement as a list of tokens, not as a tree.  So the policy applies
perl's precedence to that list itself, and it knows the binary operators of
L<perlop> that can sit beside a number.  An operator it does not know is taken
to bind more loosely than any of these, which is true of every one that is
left: the comparisons, the logical operators, the ternary, assignment and the
comma.

Parentheses are a structure of their own in PPI.  C<(2 + 3) * 4> is reported at
C<2 + 3>, inside them, and not as the whole expression.  Whoever writes out
that value writes out the whole of it anyway.

=head2 METHODS

=head3 supported_parameters

=head3 default_severity

=head3 default_themes

=head3 applies_to

=head3 violates

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/perl-critic-policy-prohibitliteralarithmetic/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
