package Perl::Critic::Policy::BuiltinFunctions::ProhibitIndirectBooleanGrep 0.001;

# ABSTRACT: Use any or first, not a sub that returns a grep, for truth or the first match.

use strict;
use warnings FATAL => 'all';
use 5.014;
use re '/aa';
use Readonly;
use List::Util                 qw{any first};
use Perl::Critic::Distribution ();
use Perl::Critic::Utils        qw{ :severities };

use parent qw{Perl::Critic::Policy};


Readonly::Scalar my $DESC_TRUTH => q{A sub that returns a grep, tested for truth};
Readonly::Scalar my $EXPL_TRUTH => q{Use List::Util::any, which stops at the first match};
Readonly::Scalar my $DESC_FIRST => q{A sub that returns a grep, for its first element};
Readonly::Scalar my $EXPL_FIRST => q{Use List::Util::first, which stops at the first match};

Readonly::Hash my %CONDITIONAL => map { $_ => 1 } qw{ if elsif unless while until };
Readonly::Hash my %NEGATION    => map { $_ => 1 } qw{ ! not };
Readonly::Hash my %LOGICAL     => map { $_ => 1 } qw{ && || and or };

# Change it when what the collector returns changes shape.
Readonly::Scalar my $DATA_FORMAT => 1;

# The part of a name after its last ::, which is all of a bare name.
my $bare_name = sub {
    my ($name) = @_;
    my $at     = rindex $name, '::';
    return $at < 0 ? $name : substr $name, $at + 2;
};


sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_LOW }
sub default_themes       { return qw{ performance } }
sub applies_to           { return 'PPI::Document' }


sub initialize_if_enabled {
    my ( $self, $config ) = @_;

    Perl::Critic::Distribution->register(
        name    => __PACKAGE__,
        version => join( q{/}, $DATA_FORMAT, Perl::Critic::Distribution->stamp(__FILE__) // q{} ),
        collect => sub {
            my ($ppi) = @_;
            return { grep_subs => [ map { $_->[1] } grep { !$_->[0]->type } grep_subs_in( $ppi, packages_in($ppi) ) ] };
        },
    );
    return $self->SUPER::initialize_if_enabled($config);
}


sub violates {
    my ( $self, undef, $doc ) = @_;

    # The subs of this file by the name that a call here uses, and those of
    # the rest of the distribution by their full name.
    my $packages = packages_in($doc);
    my %local    = map { ( $_->[0]->name => 1 ) } grep_subs_in( $doc, $packages );
    my %remote;
    my $filename = $doc->filename;
    if ( my $dist = defined $filename && Perl::Critic::Distribution->for_file($filename) ) {
        %remote = map {
            map { ( $_ => 1 ) }
              @{ $_->{grep_subs} }
        } values %{ $dist->collected(__PACKAGE__) };
    }
    return if !%local && !%remote;

    # The last part of each full name, so that a word that cannot be one is
    # passed over before its package is looked for.
    my %bare = map { ( $bare_name->($_) => 1 ) } keys %remote;

    my @violations;
    foreach my $word ( @{ $doc->find('PPI::Token::Word') || [] } ) {
        my $name = $word->content;
        next if !$local{$name} && !$bare{ $bare_name->($name) };
        my $full = index( $name, '::' ) >= 0 ? $name : package_at( $word, $packages ) . "::$name";
        next if !$local{$name} && !$remote{$full};
        next if !is_call($word);

        my $use = use_of($word) or next;
        push @violations, $use eq 'first'
          ? $self->violation( $DESC_FIRST, $EXPL_FIRST, $word )
          : $self->violation( $DESC_TRUTH, $EXPL_TRUTH, $word );
    }
    return @violations;
}


sub grep_subs_in {
    my ( $ppi, $packages ) = @_;

    my @found;
    foreach my $sub ( @{ $ppi->find('PPI::Statement::Sub') || [] } ) {
        my $block = $sub->block or next;
        next if $block->find_any( sub { $_[1]->isa('PPI::Token::Word') && $_[1]->content eq 'wantarray' } );
        next if !returns_grep($block);

        my $name = $sub->name;
        push @found, [ $sub, index( $name, '::' ) >= 0 ? $name : package_at( $sub, $packages ) . "::$name" ];
    }
    return @found;
}


sub returns_grep {
    my ($block) = @_;

    my $starts_grep = sub {
        my ( $statement, $skip ) = @_;
        my @parts = $statement->schildren;
        shift @parts if $skip;
        return @parts && $parts[0]->isa('PPI::Token::Word') && $parts[0]->content eq 'grep';
    };

    my $returns = $block->find( sub { $_[1]->isa('PPI::Statement::Break') && ( $_[1]->schild(0) // q{} ) eq 'return' } ) || [];
    foreach my $return (@$returns) {
        next if !$starts_grep->( $return, 1 );

        # One inside an inner sub returns from that sub.
        my $inner = 0;
        for ( my $up = $return->parent; $up && $up != $block; $up = $up->parent ) {
            $inner ||= $up->isa('PPI::Statement::Sub') || ( $up->isa('PPI::Structure::Block') && ( $up->sprevious_sibling // q{} ) eq 'sub' );
        }
        return 1 if !$inner;
    }

    my $last = ( grep { $_->isa('PPI::Statement') } $block->schildren )[-1];
    return $last && ref $last eq 'PPI::Statement' && $starts_grep->( $last, 0 );
}


sub packages_in {
    my ($ppi) = @_;
    return $ppi->find('PPI::Statement::Package') || [];
}


sub package_at {
    my ( $elem, $packages ) = @_;

    my $package = 'main';
    foreach my $statement (@$packages) {
        my $block = first { $_->isa('PPI::Structure::Block') } $statement->schildren;
        if ($block) {
            for ( my $up = $elem->parent; $up; $up = $up->parent ) {
                return $statement->namespace if $up == $block;
            }
            next;
        }
        my ( $line,    $col )    = @{ $statement->location }[ 0, 1 ];
        my ( $at_line, $at_col ) = @{ $elem->location }[ 0, 1 ];
        $package = $statement->namespace if $line < $at_line || ( $line == $at_line && $col < $at_col );
    }
    return $package;
}


sub is_call {
    my ($word) = @_;

    my $parent = $word->parent;
    return 0 if $parent->isa('PPI::Statement::Sub');
    my $before = $word->sprevious_sibling;
    return 0 if $before && $before->isa('PPI::Token::Operator') && $before->content eq '->';
    my $after = $word->snext_sibling;
    return 0 if $after          && $after->isa('PPI::Token::Operator')               && $after->content eq '=>';
    return 0 if $parent->parent && $parent->parent->isa('PPI::Structure::Subscript') && $parent->schildren == 1;
    return 1;
}


sub use_of {
    my ($word) = @_;

    # The call as an operand: the word, and its argument list when it has one.
    my $end = $word->snext_sibling;
    $end = $word if !( $end && $end->isa('PPI::Structure::List') );

    my $before    = $word->sprevious_sibling;
    my $statement = $word->parent;

    # The semicolon that ends the statement is not a thing after the call.
    my $after = $end->snext_sibling;
    undef $after if $after && $after->isa('PPI::Token::Structure') && $after->content eq ';';

    return 'truth' if $before && $NEGATION{ $before->content };
    return 'truth' if $after && $after->content eq '?' && ( !$before || $before->content eq '=' || $before->content eq 'return' );

    # In a condition, alone or among logical operators and their operands.
    my $holder = $statement->parent;
    if ( $holder && $holder->isa('PPI::Structure::Condition') ) {
        my $only_logic = 1;
        foreach my $part ( $statement->schildren ) {
            next            if $part == $word             || $part == $end;
            next            if $LOGICAL{ $part->content } || $NEGATION{ $part->content };
            $only_logic = 0 if $part->isa('PPI::Token::Operator');
        }
        return 'truth' if $only_logic;
    }

    # After a postfix modifier, by place among the parts of the statement,
    # because a statement can wrap.
    my @parts    = $statement->schildren;
    my ($at)     = grep { $parts[$_] == $word } 0 .. $#parts;
    my $modifier = first { $_ > 0 && $parts[$_]->isa('PPI::Token::Word') && $CONDITIONAL{ $parts[$_]->content } } 0 .. $at - 1;
    if ( defined $modifier ) {
        return 'truth' if $before == $parts[$modifier];
        return 'truth'
          if $LOGICAL{ $before->content }
          && !any { $_->isa('PPI::Token::Operator') && !$LOGICAL{ $_->content } && !$NEGATION{ $_->content } } @parts[ $modifier + 1 .. $at - 1 ];
    }

    # The left of a logical operator that starts the statement, as in a check
    # followed by or die.
    return 'truth' if !$before && $after && $LOGICAL{ $after->content } && $statement->schild(0) == $word;

    # A list of one scalar on the left of the assignment, declared or not.
    if ( $before && $before->content eq '=' && !$after ) {
        my $target = $before->sprevious_sibling;
        if ( $target && $target->isa('PPI::Structure::List') ) {
            my @symbols = @{ $target->find('PPI::Token::Symbol') || [] };
            return 'first' if @symbols == 1 && $symbols[0]->raw_type eq '$';
        }
    }
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::BuiltinFunctions::ProhibitIndirectBooleanGrep - Use any or first, not a sub that returns a grep, for truth or the first match.

=head1 VERSION

version 0.001

=head1 DESCRIPTION

C<BuiltinFunctions::ProhibitBooleanGrep> reports a C<grep> whose result is
only tested for truth, because C<any> from L<List::Util> stops at the first
match and the C<grep> reads the whole list.  It cannot see the same C<grep>
one call away:

    my sub waiting { return grep { !$out{$_} } @found }
    ...
    while ( waiting() ) { ... }    # reported

This policy reports such a call.  The result of the sub is a C<grep>: the
value of a C<return>, or its last statement.  The call is reported where the
caller uses only whether the result is empty, and where it uses only the first
element, which C<first> finds without reading the rest:

    my ($next) = waiting();        # reported

The report is at the call and not at the sub, because the same sub can be
right for a caller that wants the list.  The fix is usually a second sub, or
C<any> or C<first> at the call.

=head2 Where the sub can be

In the same file, by its name.  In another file of the same distribution,
which L<Perl::Critic::Distribution> reads: a package sub, called by its full
name, as C<Some::hits()>, or by its bare name from the same package.  A policy
that reads the distribution through the same library shares its parse.

=head2 Truth

A call is tested for truth when it is, or is an operand of C<!>, C<not>,
C<&&>, C<||>, C<and> or C<or> inside, the condition of C<if>, C<elsif>,
C<unless>, C<while> or C<until>, of a postfix modifier, or of a ternary.  So is
a call under C<!> or C<not> anywhere, and the left operand of C<and>, C<or>,
C<&&> or C<||> that starts a statement, such as C<check() or die>.

=head2 What it leaves alone

A call in list context, a count, a comparison, or a call through
C<scalar()>.  A sub that asks C<wantarray>, because it chooses its own result
for scalar context.  A C<grep> that reaches the return through a variable, and
one inside an inner anonymous sub.  A method call, because the method that
runs can be another sub of the same name.  A bare call of a sub from another
file in another package, because what it imports is not known.  A C<map>, for
which there is no C<any> to use instead.

=head1 CONFIGURATION

This Policy is not configurable except for the standard options.

=head2 METHODS

=head3 supported_parameters

=head3 default_severity

=head3 default_themes

=head3 applies_to

The whole document, because a call can come before the sub that it calls.

=head3 initialize_if_enabled

Registers what this policy needs from each file of a distribution with
L<Perl::Critic::Distribution>: the package subs whose value is a C<grep>.  A
lexical sub is left out, because no other file can call it.

=head3 violates

=head2 FUNCTIONS

The steps of C<violates>, for its tests.

=head3 grep_subs_in

    my @found = grep_subs_in( $ppi, packages_in($ppi) );

Each sub of a document whose value is a C<grep>, as a pair of its statement
and its full name.  A sub that asks C<wantarray> is not one.

=head3 returns_grep

Whether the value of a block is a C<grep>: the value of a C<return> anywhere in
it, or its last statement.  Not a C<return> inside an inner sub, which returns
from that sub.

=head3 packages_in

The C<package> statements of a document, in order, for C<package_at>.  A
document is searched once, and not once for each element.

=head3 package_at

    my $package = package_at( $elem, packages_in($ppi) );

The package that an element is in: that of the block of a C<package NAME { }>
around it, or else that of the last C<package NAME;> before it, or C<main>.

=head3 is_call

Whether a word is a call of a sub by that name, and not a method, a hash key,
the left of a fat comma, or the name in a sub statement.

=head3 use_of

How the caller uses the result of a call: C<truth>, C<first>, or nothing.
L</Truth> says when a call is tested for truth.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/perl-critic-policy-prohibitindirectbooleangrep/issues>

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
