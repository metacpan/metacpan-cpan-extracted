package Perl::Critic::Policy::Subroutines::ProhibitSingleUseLexicalSubs 0.001;

# ABSTRACT: Inline a lexical sub that is used in only one place.

use strict;
use warnings FATAL => 'all';

use 5.014;

use re '/aa';

use Readonly;
use List::Util qw{any};

use Perl::Critic::Utils qw{ :severities };
use parent              qw{Perl::Critic::Policy};


Readonly::Scalar my $DESC => q{Lexical sub used in only one place};
Readonly::Scalar my $EXPL => q{Put its body where it is used};

Readonly::Hash my %LEXICAL => map { $_ => 1 } qw{ my state };


sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_LOW }
sub default_themes       { return qw{ maintenance } }
sub applies_to           { return qw{ PPI::Statement::Sub PPI::Statement::Variable } }

# The name that the code uses the sub by, and its body, or nothing if $elem does
# not declare a lexical sub.  A named sub is used by its bare name, and an
# anonymous sub in a scalar by that scalar.
my $declared = sub {
    my ($elem) = @_;

    if ( $elem->isa('PPI::Statement::Sub') ) {
        return unless $LEXICAL{ $elem->type // q{} };
        my $block = $elem->block or return;
        return ( $elem->name, $block );
    }

    return unless $LEXICAL{ $elem->type // q{} };
    my @parts = grep { !$_->isa('PPI::Token::Structure') } $elem->schildren;
    return unless @parts == 5;
    my ( undef, $symbol, $assign, $sub, $block ) = @parts;
    return
         unless $symbol->isa('PPI::Token::Symbol')
      && $symbol->raw_type eq '$'
      && $assign->content eq '='
      && $sub->content eq 'sub'
      && $block->isa('PPI::Structure::Block');
    return ( $symbol->symbol, $block );
};

# Whether $elem declares $name again.
my $redeclares = sub {
    my ( $elem, $name ) = @_;
    return unless $elem->isa('PPI::Statement::Sub') || $elem->isa('PPI::Statement::Variable');
    my ($again) = $declared->($elem);
    return 1 if defined $again && $again eq $name;
    return $elem->isa('PPI::Statement::Variable') && any { $_ eq $name } $elem->variables;
};


sub violates {
    my ( $self, $elem, undef ) = @_;

    my ( $name, $body ) = $declared->($elem);
    return unless defined $name;

    # A bare name used as a method, a hash key or the left of a fat comma is
    # some other thing that is spelled the same.
    my @found;
    my $count = sub {
        my ( undef, $token ) = @_;

        if ( $token->isa('PPI::Token::Symbol') ) {
            push @found, $token if $token->symbol eq $name || $token->symbol eq "&$name";
            return 0;
        }
        return 0 unless $token->isa('PPI::Token::Word') && $token->content eq $name;

        my $before = $token->sprevious_sibling;
        return 0 if $before && $before->isa('PPI::Token::Operator') && $before->content eq '->';

        my $after = $token->snext_sibling;
        return 0 if $after && $after->isa('PPI::Token::Operator') && $after->content eq '=>';

        my $statement = $token->parent;
        return 0 if $statement->parent && $statement->parent->isa('PPI::Structure::Subscript') && $statement->schildren == 1;

        push @found, $token;
        return 0;
    };

    # A use inside its own body is recursion, and a recursive sub needs a name.
    $body->find($count);
    return if @found;

    my $declared_again;
    for ( my $sibling = $elem->snext_sibling; $sibling; $sibling = $sibling->snext_sibling ) {
        $declared_again ||= $redeclares->( $sibling, $name );
        $declared_again ||= $sibling->find_any( sub { $redeclares->( $_[1], $name ) } ) if $sibling->can('find_any');
        $count->( undef, $sibling );
        $sibling->find($count) if $sibling->can('find');
    }
    return if $declared_again || @found != 1;

    return $self->violation( $DESC, $EXPL, $elem );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::Subroutines::ProhibitSingleUseLexicalSubs - Inline a lexical sub that is used in only one place.

=head1 VERSION

version 0.001

=head1 Perl::Critic::Policy::Subroutines::ProhibitSingleUseLexicalSubs

A lexical sub that one place uses is that place, moved somewhere else.  The
reader goes to find it, reads it, and comes back.  Put the body where it is
used, and the reader reads it once, in order:

    my sub total { return sum map { $_->{price} } @_ }    # reported
    say total(@items);

    say sum map { $_->{price} } @items;

    my $by_name = sub { $a->{name} cmp $b->{name} };       # reported
    my @sorted  = sort $by_name @people;

    my @sorted = sort { $a->{name} cmp $b->{name} } @people;

A name still earns its place when two or more places use it.

=head2 PROHIBITED

    my sub helper { ... }            helper(@args);
    state sub helper { ... }         helper(@args);
    my sub helper { ... }            my $ref = \&helper;
    my $helper = sub { ... };        $helper->(@args);
    my $helper = sub { ... };        $self->$helper(@args);
    my $helper = sub { ... };        some_function($helper);

=head2 ALLOWED

    my sub helper { ... }            helper(1); helper(2);
    my sub walk { ... walk(@kids) }  walk($root);     # it calls itself
    my sub helper { ... }                             # unused: see CAVEATS
    sub helper { ... }               helper(@args);   # a package sub
    our $helper = sub { ... };       $helper->();     # a package variable

=head1 CAVEATS

A sub that nothing uses is not reported.  C<Subroutines::ProhibitUnusedPrivateSubroutines>
and the policies about unused variables report that, and it wants deleting
rather than inlining.

The count is of the code after the declaration, in the same block, as PPI
parses it.  A use inside a string, such as C<"@{[ helper() ]}">, is not
counted, so a sub used there and in one other place is reported.

If the block declares the same name again, the policy cannot tell which
declaration a use refers to, and it reports nothing for that name.  That said,
this can only happen without strictures enabled so you have bigger problems.

A sub passed as a callback, such as C<< find({ wanted => $wanted }, $dir) >>,
should be inlined as an anonymous sub.

=head2 METHODS

=head3 supported_parameters

=head3 default_severity

=head3 default_themes

=head3 applies_to

=head3 violates

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/perl-critic-policy-prohibitsingleuselexicalsubs/issues>

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
