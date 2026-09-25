package Perl::Critic::Policy::Variables::ProhibitUselessVarClearing 0.001;

# ABSTRACT: Do not empty a lexical that nothing reads again before it goes out of scope.

use strict;
use warnings FATAL => 'all';

use 5.014;

use re '/aa';

use List::Util qw{any};
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use parent              qw{Perl::Critic::Policy};



Readonly::Scalar my $DESC => 'variable cleared that nothing reads again';
Readonly::Scalar my $EXPL => 'It goes out of scope at the end of its block, and perl frees it then';

# The compound statements that run their block more than once.
Readonly::Hash my %LOOP => map { $_ => 1 } qw{for foreach while until};

# Tokens whose text can name a variable without being a Symbol token.
Readonly::Array my @TEXTUAL => qw{PPI::Token::Quote PPI::Token::QuoteLike PPI::Token::Regexp PPI::Token::HereDoc PPI::Token::ArrayIndex};

sub supported_parameters { return () }


sub default_severity { return $SEVERITY_LOW }


sub default_themes { return qw{maintenance} }


sub applies_to { return 'PPI::Statement' }


sub violates {
    my ( $self, $elem ) = @_;

    my $symbol = _cleared_symbol($elem)             or return;
    my $scope  = _declaring_block( $elem, $symbol ) or return;
    return if _runs_again( $elem, $scope );
    return if _escapes( $scope, $symbol );
    return if _read_after( $elem, $scope, $symbol );

    return $self->violation( $DESC, $EXPL, $elem );
}

# The variable that $statement empties, such as '%h', or nothing when the
# statement does anything else.
sub _cleared_symbol {
    my ($statement) = @_;
    return if ref $statement ne 'PPI::Statement';

    my @parts = $statement->schildren;
    pop @parts if @parts && $parts[-1]->isa('PPI::Token::Structure') && $parts[-1]->content eq q{;};

    # An assignment to the whole variable of an empty list, of undef, or, for a
    # scalar, of a new empty hash or array.
    if ( @parts == 3 && $parts[0]->isa('PPI::Token::Symbol') && $parts[1]->isa('PPI::Token::Operator') && $parts[1]->content eq q{=} ) {
        my $value = $parts[2];
        my $empty = $value->isa('PPI::Structure::List') && !$value->schildren;
        my $undef = $value->isa('PPI::Token::Word')     && $value->content eq 'undef';
        my $fresh = $value->isa('PPI::Structure::Constructor') && !$value->schildren && $parts[0]->raw_type eq q{$};
        return $parts[0]->symbol if $empty || $undef || $fresh;
        return;
    }

    # A call to undef on the whole variable, with parens or without.
    return if @parts != 2 || !$parts[0]->isa('PPI::Token::Word') || $parts[0]->content ne 'undef';
    my $target = $parts[1];
    if ( $target->isa('PPI::Structure::List') ) {
        my @inside = $target->schildren;
        return if @inside != 1;
        my @tokens = $inside[0]->schildren;
        return if @tokens != 1;
        $target = $tokens[0];
    }
    return $target->isa('PPI::Token::Symbol') ? $target->symbol : undef;
}

# The block, or the document, whose own statements declare $symbol with my
# before the one that holds $elem.
sub _declaring_block {
    my ( $elem, $symbol ) = @_;

    my $node = $elem;
    while ( my $parent = $node->parent ) {
        if ( $parent->isa('PPI::Structure::Block') || $parent->isa('PPI::Document') ) {
            foreach my $child ( $parent->schildren ) {
                last           if $child == $node;
                return $parent if _declares( $child, $symbol );
            }
        }
        $node = $parent;
    }
    return;
}

sub _declares {
    my ( $statement, $symbol ) = @_;
    return if !$statement->isa('PPI::Statement::Variable') || $statement->type ne 'my';
    return grep { $_ eq $symbol } $statement->variables;
}

# Whether a block between $elem and $scope can run more than once, or later
# than the statements after it: a loop, a sub, or the block of map, grep, sort,
# do or eval.
sub _runs_again {
    my ( $elem, $scope ) = @_;

    my $node = $elem->parent;
    while ( $node && $node != $scope ) {
        if ( $node->isa('PPI::Structure::Block') ) {
            my $owner = $node->parent;
            return 1 if !$owner->isa('PPI::Statement::Compound');
            my $bare = ( $owner->schildren )[0] == $node;
            return 1 if !$bare && $LOOP{ $owner->type // q{} };
        }
        $node = $node->parent;
    }
    return 0;
}

# Whether anything other than the statements after it can reach $symbol: a
# reference taken with \, or a sub that mentions it.
sub _escapes {
    my ( $scope, $symbol ) = @_;

    my $symbols = $scope->find( sub { $_[1]->isa('PPI::Token::Symbol') && $_[1]->symbol eq $symbol } ) || [];
    foreach my $token (@$symbols) {
        my $before = $token->sprevious_sibling;
        return 1 if $before && $before->isa('PPI::Token::Cast') && $before->content eq q{\\};
        return 1 if _inside_sub( $token, $scope );
    }
    return 0;
}

sub _inside_sub {
    my ( $token, $scope ) = @_;

    my $node = $token->parent;
    while ( $node && $node != $scope ) {
        return 1 if $node->isa('PPI::Statement::Sub');
        if ( $node->isa('PPI::Structure::Block') ) {
            my $before = $node->sprevious_sibling;
            return 1 if $before && $before->isa('PPI::Token::Word') && $before->content eq 'sub';
        }
        $node = $node->parent;
    }
    return 0;
}

# Whether anything in $scope after $elem mentions $symbol.
sub _read_after {
    my ( $elem, $scope, $symbol ) = @_;

    my $end     = $elem->last_token->location or return 1;
    my ($name)  = $symbol =~ m/\A[\$\@%](.+)\z/xs;
    my $in_text = qr/(?:[\$\@]|\$\#)\{?\Q$name\E\b/xs;

    my $later = $scope->find(
        sub {
            my $token = $_[1];
            my $at    = $token->location or return 0;
            return 0 if $at->[0] < $end->[0] || ( $at->[0] == $end->[0] && $at->[1] <= $end->[1] );
            return 1 if $token->isa('PPI::Token::Symbol') && $token->symbol eq $symbol;
            return 0 if !any { $token->isa($_) } @TEXTUAL;
            my $text = $token->isa('PPI::Token::HereDoc') ? join( q{}, $token->heredoc ) : $token->content;
            return $text =~ $in_text ? 1 : 0;
        }
    );
    return $later ? 1 : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::Variables::ProhibitUselessVarClearing - Do not empty a lexical that nothing reads again before it goes out of scope.

=head1 VERSION

version 0.001

=head1 Perl::Critic::Policy::Variables::ProhibitUselessVarClearing

A lexical goes away at the end of the block that declares it.  Perl frees it
then, and nothing that comes after the block can reach it.  So emptying one
that nothing reads again is a statement that does nothing:

    if ($wanted) {
        my %secrets = lookup(%wanted);
        apply( $config, %secrets );
        %secrets = ();                  # violates: the block ends, and so does %secrets
    }

This is a habit from C, where memory stays until something frees it.  In Perl,
the end of the scope frees it, as C<perldoc perlguts> says under garbage
collection.  Clearing it by hand costs a statement, and a reader has to look
for the later read that would explain it, which does not exist.

=head2 PROHIBITED

A statement that only empties a C<my> variable, when the rest of the block that
declares the variable never reads it again:

    %h = ();
    @a = ();
    $x = undef;
    $hr = {};
    $ar = [];
    undef %h;
    undef @a;
    undef $x;
    undef($x);

=head2 ALLOWED

    %h = ();  f(%h);                    # read again later
    my %h;  $r = \%h;  %h = ();         # a reference can still reach it
    my @a;  my $f = sub { @a };  @a = ();   # so can a closure
    my %h;  for (@x) { ...; %h = () }   # the next pass reads it
    our %h;  %h = ();                   # not a lexical
    state %h;  %h = ();                 # lives across calls
    my %h;  sub f { %h = () }           # the next call reads it

A mention of the variable inside a string, a regular expression or a heredoc
counts as a read, whether or not it interpolates.

=head2 WHAT IT CANNOT SEE

Emptying what a reference points to is not reported:

    %$hr = ();
    @{$ar} = ();
    undef %$hr;

That empties a hash or an array that other code can also hold a reference to,
and nothing in the source says whether it does.  So the statement can matter
even when nothing here reads C<$hr> again.  Giving the scalar a new, empty
reference, as C<$hr = {}> does, changes only the scalar, and is reported.

=head2 WHEN THE CLEARING DOES SOMETHING

Emptying a variable runs the C<DESTROY> of what it held at that moment, rather
than at the end of the block.  Releasing a lock or closing a handle before the
slow part of a block is a reason to clear a variable early.  Say so where it
happens:

    undef $lock;    ## no critic (ProhibitUselessVarClearing) -- release the lock before the upload

=head1 CONFIGURATION

None.

=head2 METHODS

What L<Perl::Critic::Policy> asks of a policy, answered here rather than called
from anywhere.

=head3 supported_parameters

None.

=head3 default_severity

Low: the statement does nothing, and costs only a reader's time.

=head3 default_themes

C<maintenance>.

=head3 applies_to

A plain statement, which is what an assignment or a call to C<undef> is.

=head3 violates

Reports a statement that only empties a lexical, when nothing can read the
lexical again before the end of the block that declares it.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/perl-critic-policy-prohibituselessvarclearing/issues>

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
