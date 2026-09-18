package Perl::Critic::Policy::ValuesAndExpressions::ProhibitDefinedBeforeLength;
$Perl::Critic::Policy::ValuesAndExpressions::ProhibitDefinedBeforeLength::VERSION = '0.001';
# ABSTRACT: Test the value, not its length, and shape it before measuring it.

use strict;
use warnings FATAL => 'all';

use 5.014;

use re '/aa';

use Readonly;

use Perl::Critic::Utils qw{ :severities is_hash_key is_method_call };
use parent              qw{Perl::Critic::Policy};



Readonly::Scalar my $PAIR_DESC => 'defined before length on the same value';
Readonly::Scalar my $PAIR_EXPL => 'In a boolean context use the value alone; where the length matters, shape the value first ($x //= q{})';
Readonly::Scalar my $BARE_DESC => 'length in a boolean context';
Readonly::Scalar my $BARE_EXPL => 'The value alone is false for undef and the empty string, and needs no call';

# The operators that join the two halves of a pair, positive and negated.
Readonly::Hash my %AND => map { $_ => 1 } qw{&& and};
Readonly::Hash my %OR  => map { $_ => 1 } qw{|| or};
Readonly::Hash my %NOT => map { $_ => 1 } ( q{!}, 'not' );

# The operators a condition is built from.  A length joined to others by these
# is still a condition if the whole chain is one.
Readonly::Hash my %LOGICAL => map { $_ => 1 } ( qw{&& || // and or xor not}, q{!} );

# What makes the rest of a statement its condition.
Readonly::Hash my %MODIFIER => map { $_ => 1 } qw{if unless while until};

# The list functions whose block is a test of each element.
Readonly::Hash my %TESTS_EACH => map { $_ => 1 } qw{grep first any all none notall};

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_LOW }
sub default_themes       { return qw{troglodyne performance maintenance} }
sub applies_to           { return 'PPI::Token::Word' }

sub violates {
    my ( $self, $elem, undef ) = @_;

    return () if is_hash_key($elem) || is_method_call($elem);

    if ( $elem->content eq 'defined' ) {
        return () unless _pair($elem);
        return $self->violation( $PAIR_DESC, $PAIR_EXPL, $elem );
    }

    return () unless $elem->content eq 'length';
    return () if _second_half_of_a_pair($elem);

    my ( undef, $after ) = _operand($elem);
    return () unless _is_boolean( $elem, $after );
    return $self->violation( $BARE_DESC, $BARE_EXPL, $elem );
}

# The length a defined is paired with, or nothing: `defined $x && length $x`,
# or its negation `!defined $x || !length $x`, on the same operand.
sub _pair {
    my ($defined) = @_;

    my $negated = _is_not( $defined->sprevious_sibling );

    my ( $operand, $after ) = _operand($defined);
    return unless $after && $after->isa('PPI::Token::Operator');
    return unless $negated ? $OR{ $after->content } : $AND{ $after->content };

    my $length = $after->snext_sibling;
    if ($negated) {
        return unless _is_not($length);
        $length = $length->snext_sibling;
    }
    return unless $length && $length->isa('PPI::Token::Word') && $length->content eq 'length';

    my ($measured) = _operand($length);
    return unless $measured eq $operand;
    return $length;
}

# Reported already, as the pair.
sub _second_half_of_a_pair {
    my ($length) = @_;

    my $sibling = $length->sprevious_sibling;
    while ($sibling) {
        if ( $sibling->isa('PPI::Token::Word') && $sibling->content eq 'defined' ) {
            my $paired = _pair($sibling);
            return 1 if $paired && $paired == $length;
        }
        $sibling = $sibling->sprevious_sibling;
    }
    return 0;
}

# Whether the value of a term is only tested for truth.  $start is the term's
# first element and $after the first sibling past it.
sub _is_boolean {
    my ( $start, $after ) = @_;

    my $before = $start->sprevious_sibling;
    return 1 if _is_not($before);

    # What the term is used for, from what is right beside it: `?` tests it,
    # and any other operator that is not logical uses its value.
    if ( $after && $after->isa('PPI::Token::Operator') ) {
        return 1 if $after->content eq q{?};
        return 0 unless $LOGICAL{ $after->content };
    }
    return 0 if $before && $before->isa('PPI::Token::Operator') && !$LOGICAL{ $before->content };

    # Then along the chain of logical operators it is part of.
    my $left = $before;
    while ($left) {
        return 1 if $left->isa('PPI::Token::Word')     && $MODIFIER{ $left->content };
        return 0 if $left->isa('PPI::Token::Word')     && $left->content eq 'return';
        return 0 if $left->isa('PPI::Token::Operator') && !$LOGICAL{ $left->content };
        $left = $left->sprevious_sibling;
    }

    my $right = $after;
    while ($right) {
        return 1 if $right->isa('PPI::Token::Operator') && $right->content eq q{?};
        last     if $right->isa('PPI::Token::Operator') && $right->content =~ m/\A(?:,|=>|:)\z/;
        last     if $right->isa('PPI::Token::Word')     && $MODIFIER{ $right->content };
        $right = $right->snext_sibling;
    }

    return _is_boolean_place($start);
}

# The chain reached the edge of its statement, so the statement's place decides.
sub _is_boolean_place {
    my ($start) = @_;

    my $statement = $start->parent     or return 0;
    my $holder    = $statement->parent or return 0;

    return 1 if $holder->isa('PPI::Structure::Condition');

    # Parenthesised: the list is the term, one level out -- unless it is the
    # argument list of a call.
    if ( $holder->isa('PPI::Structure::List') ) {
        my $before = $holder->sprevious_sibling;
        return 0 if $before && $before->isa('PPI::Token::Word');
        return _is_boolean( $holder, $holder->snext_sibling );
    }

    # The last statement of a grep block is its test.
    if ( $holder->isa('PPI::Structure::Block') ) {
        my $call = $holder->sprevious_sibling;
        return 0 unless $call && $call->isa('PPI::Token::Word') && $TESTS_EACH{ $call->content };
        my @statements = $holder->schildren;
        return $statements[-1] == $statement ? 1 : 0;
    }

    return 0;
}

# The operand of a named unary op, as text with the whitespace taken out, and
# the first sibling after it.  defined($x) is the list's contents; defined $x
# runs until an operator other than -> or anything that cannot be part of a
# term.  No operand at all is $_, as perl reads it.
sub _operand {
    my ($op) = @_;

    my $next = $op->snext_sibling;

    if ( $next && $next->isa('PPI::Structure::List') ) {
        my $inside = join( q{}, map { $_->content } $next->schildren );
        return ( _squash( length $inside ? $inside : '$_' ), $next->snext_sibling );
    }

    my @term;
    while ( $next && _continues_term( $next, \@term ) ) {
        push( @term, $next );
        $next = $next->snext_sibling;
    }

    my $text = join( q{}, map { $_->content } @term );
    return ( _squash( length $text ? $text : '$_' ), $next );
}

# A term is a variable, a quoted string or a call, then any run of subscripts,
# derefs, and method calls with their arguments.  A word is part of it only as
# a function or method name.
sub _continues_term {
    my ( $elem, $term ) = @_;

    my $last = $term->[-1];
    return _starts_term($elem) unless $last;

    return 1 if $elem->isa('PPI::Structure::Subscript');
    return 1 if $elem->isa('PPI::Token::Operator') && $elem->content eq '->';
    return 1 if $last->isa('PPI::Token::Cast')     && ( $elem->isa('PPI::Token::Symbol') || $elem->isa('PPI::Structure::Block') );

    my $after_arrow = $last->isa('PPI::Token::Operator') && $last->content eq '->';
    return 1 if $after_arrow                   && ( $elem->isa('PPI::Token::Word') || $elem->isa('PPI::Structure::List') );
    return 1 if $last->isa('PPI::Token::Word') && $elem->isa('PPI::Structure::List');

    return 0;
}

sub _starts_term {
    my ($elem) = @_;

    return 1 if $elem->isa('PPI::Token::Symbol') || $elem->isa('PPI::Token::Magic') || $elem->isa('PPI::Token::Cast');
    return 1 if $elem->isa('PPI::Token::Quote');
    return 1 if $elem->isa('PPI::Token::Word') && !$MODIFIER{ $elem->content } && $elem->content !~ m/\A(?:for|foreach|x)\z/;
    return 0;
}

sub _is_not {
    my ($elem) = @_;
    return $elem && $elem->isa('PPI::Token::Operator') && $NOT{ $elem->content };
}

sub _squash {
    my ($text) = @_;
    $text =~ s/\s+//g;
    return $text;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitDefinedBeforeLength - Test the value, not its length, and shape it before measuring it.

=head1 VERSION

version 0.001

=head1 Perl::Critic::Policy::ValuesAndExpressions::ProhibitDefinedBeforeLength

Asking whether a value is defined and then whether it has a length is two
operations where one does the job, and in a boolean context neither is needed:

    return unless defined $uri && length $uri;      # what you see - violates
    return unless length $uri;                      # what it means - still violates
    return unless $uri;                             # what should actually be done

When the length itself matters, shape the value before the comparison rather
than guarding the comparison:

    return if defined $uri && length $uri > 2048;   # we care about the length - violates
    $uri //= q{};                                   # shape the data first
    return if length $uri > 2048;                   # correct solution

Under C<use warnings FATAL =E<gt> 'all'>, C<length(undef) E<gt> 2048> dies.
That is working as designed: you should validate/coerce your inputs type before
you start blithely shoving them into conditionals past which they subtly pollute
your program.

In a boolean context, the value alone is false for undef, the empty string and
C<"0">.  C<length> is true for C<"0">, and that difference is the reason the
pattern spread.  It catches as many bugs as it causes:

    my $a = read_value_from_file(...);
    my $b = read_value_from_file(...);    # guess what read() returns? not integers!
    if (length($a)) { print $a }          # hey this is great, maybe saved a print op.
    if (length($b)) { return 5 / $b }     # Now I've got a divide by zero bug.

so the policy asks for the cheaper test, since
there is no avoiding awareness of this distinction in perl.

Where C<"0"> is a value you actually want the length of, say so with a C<## no critic> and a reason.

The saving is largest in a loop, where the redundant ops run per element:

    grep { defined $_ && length $_ } @list;         # 3 calls
    grep { length } @list;                          # one call
    grep { $_ } @list;                              # no calls!

=head2 PROHIBITED

Anywhere:

    defined $x && length $x
    defined($x) and length($x)
    defined $h->{key} && length $h->{key}
    defined && length                               # both of $_
    defined $x && length $x > 3                     # shape $x first

    !defined $x || !length $x                       # the negation
    not defined $x or not length $x

In a boolean context -- the condition of C<if>, C<unless>, C<while> or
C<until>, a statement modifier, the operand of C<!> or C<not>, the condition of
C<?:>, or the block of C<grep>, C<first>, C<any>, C<all>, C<none> or C<notall>:

    length $x                                       # waste of time in boolean context
    !length $x

=head2 ALLOWED

    $x                                              # in a boolean context
    defined $x && length $y                         # two different values
    defined $x && $x ne q{}
    length $x > 3                                   # the length is used
    my $size = length $x;                           # not a boolean context

C<defined $x && $x ne q{}> is a different way to write the test, and is not
reported.

=head2 CAVEATS

Assigning the result of C<length> and using it later will not be checked.

A C<length> that is the operand of C<&&> or C<||> in an assignment or a
C<return>, such as C<return length $x && $y>, is a value rather than a
condition, and is not reported either.

=head1 CONFIGURATION

None.

=head2 METHODS

What L<Perl::Critic::Policy> asks of a policy, answered here rather than called
from anywhere.

=head3 supported_parameters

None.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/perl-critic-policy-prohibitdefinedbeforelength/issues>

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
