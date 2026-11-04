package Perl::Critic::Policy::Variables::RequireNoAutovivification 0.001;

# ABSTRACT: Say no autovivification where a read through an element would create it.

use strict;
use warnings FATAL => 'all';

use 5.014;

use re '/aa';

use List::Util qw{ any };
use Readonly;
use Scalar::Util qw{ refaddr };

use Perl::Critic::Utils qw{ :severities is_assignment_operator is_function_call is_perl_builtin };
use parent              qw{Perl::Critic::Policy};


Readonly::Scalar my $DESC => q{Read through an element without "no autovivification"};

Readonly::Hash my %EXPL => (
    fetch  => q{Say "no autovivification;" in this scope: a read through an element creates the element when it is missing ('fetch')},
    exists => q{Say "no autovivification;" in this scope: exists creates every level above the one it tests ('exists')},
    delete => q{Say "no autovivification;" in this scope: delete creates every level above the one it deletes ('delete')},
);

Readonly::Scalar my $PRAGMA => 'autovivification';

# What "no autovivification" turns on without arguments, and every category
# that "use autovivification" can take away.
Readonly::Array my @DEFAULT_CATEGORIES => qw{ fetch exists delete };
Readonly::Hash my %CATEGORY => map { $_ => 1 } @DEFAULT_CATEGORIES, 'store';

# Builtins whose arguments are all lvalues, so perl creates the levels above
# them whatever the pragma says.  Perl passes the arguments of sprintf that way too.
Readonly::Hash my %CHANGES_EVERY_ARGUMENT => map { $_ => 1 } qw{ chomp chop sprintf local map grep };

# Builtins whose first argument is an lvalue, and the rest are read.
Readonly::Hash my %CHANGES_FIRST_ARGUMENT => map { $_ => 1 } qw{
  push unshift splice pop shift each pos undef vec
  read sysread recv open opendir sysopen tie untie tied lock
};

# Builtins that take one argument and need a category of their own for it.
Readonly::Hash my %OWN_CATEGORY => ( exists => 'exists', delete => 'delete', keys => 'fetch', values => 'fetch' );

# Statement modifiers, which is_function_call does not count as calls.
Readonly::Hash my %MODIFIER => ( if => 'fetch', unless => 'fetch', while => 'fetch', until => 'fetch', for => 'lvalue', foreach => 'lvalue' );

Readonly::Hash my %STEP           => map { $_ => 1 } qw{ ++ -- };
Readonly::Hash my %BINDING        => map { $_ => 1 } qw{ =~ !~ };
Readonly::Hash my %COMMA          => map { $_ => 1 } ( q{,}, '=>' );
Readonly::Hash my %POSTFIX        => map { $_ => 1 } qw{ @* %* };
Readonly::Hash my %AGGREGATE_CAST => map { $_ => 1 } qw{ @ % };


sub supported_parameters {
    return (
        {
            name           => 'equivalent_modules',
            description    => q{Modules whose use counts as "no autovivification"},
            default_string => q{},
            behavior       => 'string list',
        },
    );
}

sub default_severity { return $SEVERITY_MEDIUM }
sub default_themes   { return qw{ bugs } }
sub applies_to       { return 'PPI::Document' }


sub violates {
    my ( $self, $elem, $doc ) = @_;

    my @hazards = map { _hazard($_) } _terms($doc) or return;

    my @pragmas = $self->_pragmas($doc);
    @hazards = grep { !_is_covered( $_, \@pragmas ) } @hazards;

    # A read inside a cast is part of the expression that the cast is, so only
    # the cast is reported when both are.
    my %blocks = map { refaddr($_) => 1 } grep { $_->isa('PPI::Structure::Block') } map { @{ $_->{pieces} } } @hazards;
    @hazards = grep { !_is_inside( $_->{pieces}[0], \%blocks ) } @hazards;

    return map { $self->violation( $DESC, $EXPL{ $_->{category} }, $_->{pieces}[0] ) } @hazards;
}

# Every term in $doc: the pieces of one variable, cast or call, and the
# subscripts, arrows and method calls after it, in order.
sub _terms {
    my ($doc) = @_;

    # 0 rather than undef for an element that is not a head: undef would tell
    # find not to look inside it.
    my $heads = $doc->find( sub { _is_head( $_[1] ) ? 1 : 0 } ) or return;
    return map { [ _term_from($_) ] } @$heads;
}

# Whether $elem starts a term.  A symbol after a cast is part of the cast's
# term, and a cast after an arrow is part of the term before it.
sub _is_head {
    my ($elem) = @_;

    if ( $elem->isa('PPI::Token::Symbol') ) {
        return !_is_dereference( $elem->sprevious_sibling );
    }
    if ( _is_dereference($elem) ) {
        return if _is_operator( $elem->sprevious_sibling, '->' );
        my $next = $elem->snext_sibling;
        return $next && ( $next->isa('PPI::Token::Symbol') || $next->isa('PPI::Structure::Block') );
    }
    if ( $elem->isa('PPI::Token::Word') ) {
        return unless is_function_call($elem);
        my $list = $elem->snext_sibling;
        return $list && $list->isa('PPI::Structure::List') && _is_operator( $list->snext_sibling, '->' );
    }
    return;
}

# The pieces of the term that starts at $head.
sub _term_from {
    my ($head) = @_;

    my @pieces = ($head);
    push @pieces, $head->snext_sibling unless $head->isa('PPI::Token::Symbol');

    while ( my $next = $pieces[-1]->snext_sibling ) {
        if ( $next->isa('PPI::Structure::Subscript') ) {
            push @pieces, $next;
            next;
        }
        last unless _is_operator( $next, '->' );

        my $after = $next->snext_sibling or last;
        if ( $after->isa('PPI::Structure::Subscript') || $after->isa('PPI::Token::Cast') ) {
            push @pieces, $next, $after;
            next;
        }
        last unless $after->isa('PPI::Token::Word');

        # A method call.  Its arguments are part of the term, and the arrow
        # after them is what decides whether the term goes on.
        my $args = $after->snext_sibling;
        my @call = ( $next, $after );
        push @call, $args if $args && $args->isa('PPI::Structure::List');
        last unless _is_operator( $call[-1]->snext_sibling, '->' );
        push @pieces, @call;
    }
    return @pieces;
}

# The read that the term @$pieces is, with the category it needs, or nothing
# when it is not a read through an element.
sub _hazard {
    my ($pieces) = @_;

    my $through = _reads_through_element($pieces) or return;
    my $context = _context($pieces);
    return if $context eq 'lvalue';

    # Of an aggregate that an element refers to, only keys and values vivify:
    # anything else that reads it dies under strict refs.
    if ( $context eq 'aggregate' ) {
        $context = 'fetch';
    }
    elsif ( $through eq 'deref' ) {
        return;
    }
    return { pieces => $pieces, category => $context };
}

# 'subscript' when a subscript in @$pieces is applied to an element, 'deref'
# when the term is an aggregate dereference of an element, and false
# otherwise.
sub _reads_through_element {
    my ($pieces) = @_;

    my ( $head, @rest ) = @$pieces;

    my $element = 0;
    if ( $head->isa('PPI::Token::Cast') ) {
        my $inner = shift @rest;
        if ( $inner->isa('PPI::Structure::Block') ) {
            $element = _holds_element($inner);
            return $element && $AGGREGATE_CAST{ $head->content } ? 'deref' : 0 unless @rest;
        }
    }

    foreach my $index ( 0 .. $#rest ) {
        my $piece = $rest[$index];
        if ( $piece->isa('PPI::Structure::Subscript') ) {
            return 'subscript' if $element;
            $element = 1;
        }
        elsif ( $piece->isa('PPI::Token::Cast') ) {
            return 'deref' if $element && $POSTFIX{ $piece->content } && $index == $#rest;
        }
        elsif ( !_is_operator( $piece, '->' ) ) {
            $element = 0;
        }
    }
    return 0;
}

# Whether $block holds one term, and that term ends in a subscript.
sub _holds_element {
    my ($block) = @_;

    my @statements = $block->schildren;
    return 0 unless @statements == 1;

    my @children = $statements[0]->schildren;
    return 0 unless @children && _is_head( $children[0] );

    my @pieces = _term_from( $children[0] );
    return @pieces == @children && $pieces[-1]->isa('PPI::Structure::Subscript');
}

# How the term @$pieces is used: 'lvalue', 'fetch', 'aggregate' for the
# argument of keys or values, 'exists' or 'delete'.
sub _context {
    my ($pieces) = @_;

    my $next = $pieces->[-1]->snext_sibling;
    if ($next) {
        return 'lvalue' if is_assignment_operator($next) || _is_step($next);
        return 'lvalue' if _is_binding($next) && _changes( $next->snext_sibling );

        my $method = $next->snext_sibling;
        return 'lvalue' if _is_operator( $next, '->' ) && $method && $method->isa('PPI::Token::Word');
    }

    my $prev = $pieces->[0]->sprevious_sibling;
    if ($prev) {
        return 'lvalue' if $prev->isa('PPI::Token::Cast') && $prev->content eq q{\\};
        return 'lvalue' if _is_step($prev);
    }
    return _governed($pieces);
}

# The context that what comes before the term in its statement gives it, or
# else the context of the parens or cast around the statement.
sub _governed {
    my ($pieces) = @_;

    my $first  = $pieces->[0];
    my $commas = 0;
    for ( my $prev = $first->sprevious_sibling; $prev; $prev = $prev->sprevious_sibling ) {
        if ( $prev->isa('PPI::Token::Operator') ) {
            return 'fetch' unless $COMMA{ $prev->content };
            $commas++;
            next;
        }
        next unless $prev->isa('PPI::Token::Word');

        my $modifier = $MODIFIER{ $prev->content };
        return $modifier if $modifier;
        next unless is_function_call($prev);

        my $immediate = refaddr($prev) == refaddr( $first->sprevious_sibling );
        return _argument_of( $prev, $immediate, $commas, [ $prev, @$pieces ] );
    }

    my $statement = $first->parent;
    my $container = $statement && $statement->parent or return 'fetch';
    my $whole     = !$first->sprevious_sibling;

    if ( $container->isa('PPI::Structure::List') ) {
        my $compound = $container->parent;
        return 'lvalue' if $compound->isa('PPI::Statement::Compound') && $compound->type eq 'foreach';
        return _argument_of_list( $container, $whole, $commas );
    }
    if ( $container->isa('PPI::Structure::Block') && $container->schildren == 1 ) {
        my $cast = $container->sprevious_sibling;
        return _context( [ _term_from($cast) ] ) if _is_dereference($cast);
    }
    return 'fetch';
}

# The context of a statement in the parens $list.  $whole is whether the term
# is all of the statement, and $commas how many arguments are before it.
sub _argument_of_list {
    my ( $list, $whole, $commas ) = @_;

    my $before = $list->sprevious_sibling;
    if ($before) {
        return 'lvalue' if _is_operator( $before, '->' );
        return 'lvalue' if $before->isa('PPI::Token::Symbol') && index( $before->content, q{&} ) == 0;
        if ( $before->isa('PPI::Token::Word') ) {
            return 'lvalue'                                                     if _is_operator( $before->sprevious_sibling, '->' );
            return _argument_of( $before, $whole, $commas, [ $before, $list ] ) if is_function_call($before);
        }
    }

    # Parens that only group: what is in them is used the way they are.
    my $outer = _context( [$list] );
    return $outer if $outer eq 'lvalue' || $outer eq 'fetch';
    return $whole && !$commas ? $outer : 'fetch';
}

# The context of an argument of the call $word.  $immediate is whether the
# argument comes first and alone, $commas how many arguments are before it, and
# $call the call up to the argument, for scalar, which passes on the context it
# is in.
sub _argument_of {
    my ( $word, $immediate, $commas, $call ) = @_;

    my $name = $word->content;
    if ( my $own = $OWN_CATEGORY{$name} ) {
        return 'fetch' unless $immediate;
        return $own eq 'fetch' ? 'aggregate' : $own;
    }
    return _context($call) if $name eq 'scalar' && $immediate;
    return 'lvalue'        if $CHANGES_EVERY_ARGUMENT{$name};
    return $commas ? 'fetch' : 'lvalue' if $CHANGES_FIRST_ARGUMENT{$name};
    return is_perl_builtin($word) ? 'fetch' : 'lvalue';
}

# The pragmas in $doc that turn categories on or off, in order: each is the
# statement, whether it turns them on, and the categories.
sub _pragmas {
    my ( $self, $doc ) = @_;

    my $includes   = $doc->find('PPI::Statement::Include') or return;
    my %equivalent = %{ $self->{_equivalent_modules} };

    my @pragmas;
    foreach my $include (@$includes) {
        my $module = $include->module;
        my $type   = $include->type;
        if ( $type eq 'use' && $equivalent{$module} ) {
            push @pragmas, { statement => $include, on => 1, categories => [@DEFAULT_CATEGORIES] };
            next;
        }
        next unless $module eq $PRAGMA && ( $type eq 'use' || $type eq 'no' );

        my $on         = $type eq 'no';
        my @words      = _argument_words($include);
        my @categories = !@words ? () : !defined $words[0] ? ( $on ? @DEFAULT_CATEGORIES : keys %CATEGORY ) : grep { $CATEGORY{$_} } @words;
        push @pragmas, { statement => $include, on => $on, categories => \@categories } if @categories;
    }
    return @pragmas;
}

# The words of the arguments of $include.  A lone undef when there are no
# arguments, or arguments that cannot be read without running them, both of
# which mean the defaults.  An empty list when the arguments are an empty list,
# since then perl does not call unimport or import at all.
sub _argument_words {
    my ($include) = @_;

    my @arguments = $include->arguments;
    return (undef) unless @arguments;

    my @words;
    foreach my $argument ( map { _flatten($_) } @arguments ) {
        if ( $argument->isa('PPI::Token::QuoteLike::Words') ) {
            push @words, $argument->literal;
        }
        elsif ( $argument->isa('PPI::Token::Quote') ) {
            return (undef) if $argument->can('interpolations') && $argument->interpolations;
            push @words, $argument->string;
        }
        elsif ( $argument->isa('PPI::Token::Word') ) {
            push @words, $argument->content;
        }
        elsif ( !( $argument->isa('PPI::Token::Operator') && $COMMA{ $argument->content } ) ) {
            return (undef);
        }
    }
    return @words;
}

# $elem, or the significant tokens inside it when it is a list.
sub _flatten {
    my ($elem) = @_;

    return $elem unless $elem->isa('PPI::Structure::List');
    return map { _flatten($_) } map { $_->schildren } $elem->schildren;
}

# Whether the pragmas in scope at $hazard turn on the category it needs.
sub _is_covered {
    my ( $hazard, $pragmas ) = @_;

    my $at = $hazard->{pieces}[0];
    my %on;
    foreach my $pragma ( grep { _is_in_scope( $_->{statement}, $at ) } @$pragmas ) {
        foreach my $category ( @{ $pragma->{categories} } ) {
            if ( $pragma->{on} ) { $on{$category} = 1 }
            else                 { delete $on{$category} }
        }
    }
    return $on{ $hazard->{category} };
}

# Whether $statement is in a block around $elem, and before it.  The lexical
# scope of a pragma is the rest of the block that it is in.
sub _is_in_scope {
    my ( $statement, $elem ) = @_;

    my $scope = refaddr( $statement->parent );
    return unless any { refaddr($_) == $scope } _ancestors($elem);

    my ( $statement_line, $statement_column ) = @{ $statement->location }[ 0, 1 ];
    my ( $line,           $column )           = @{ $elem->location }[ 0, 1 ];
    return $statement_line < $line || ( $statement_line == $line && $statement_column < $column );
}

# Whether an ancestor of $elem is one of %$blocks, which are keyed by refaddr.
sub _is_inside {
    my ( $elem, $blocks ) = @_;

    return any { $blocks->{ refaddr($_) } } _ancestors($elem);
}

sub _ancestors {
    my ($elem) = @_;

    my @ancestors;
    for ( my $parent = $elem->parent; $parent; $parent = $parent->parent ) {
        push @ancestors, $parent;
    }
    return @ancestors;
}

# Whether $elem is a cast that dereferences, which \ does not.
sub _is_dereference {
    my ($elem) = @_;

    return $elem && $elem->isa('PPI::Token::Cast') && $elem->content ne q{\\};
}

sub _is_operator {
    my ( $elem, $operator ) = @_;

    return $elem && $elem->isa('PPI::Token::Operator') && $elem->content eq $operator;
}

sub _is_step {
    my ($elem) = @_;

    return $elem->isa('PPI::Token::Operator') && $STEP{ $elem->content };
}

sub _is_binding {
    my ($elem) = @_;

    return $elem->isa('PPI::Token::Operator') && $BINDING{ $elem->content };
}

# Whether the right side of a binding changes the string that it is bound to.
sub _changes {
    my ($elem) = @_;

    return $elem && ( $elem->isa('PPI::Token::Regexp::Substitute') || $elem->isa('PPI::Token::Regexp::Transliterate') );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::Variables::RequireNoAutovivification - Say no autovivification where a read through an element would create it.

=head1 VERSION

version 0.001

=head1 Perl::Critic::Policy::Variables::RequireNoAutovivification

A read through an element creates that element when it is missing.  Perl calls
this autovivification.  C<$h{a}{b}> looks up C<b> in the hash that C<$h{a}>
refers to.  When C<$h{a}> is not there, perl makes it an empty hash first, and
leaves it there after the read.  C<exists $h{a}{b}> and C<delete $h{a}{b}> do
the same.  The next C<exists $h{a}>, C<keys %h> or serialization of C<%h> then
sees a key that nobody stored.

The C<autovivification> pragma from CPAN stops it.  Say
C<no autovivification;> in the scope of the read:

    my $port = $config{server}{port};                              # reported

    no autovivification;
    my $port = $config{server}{port};                              # OK!

    if ( exists $seen{$user}{$host} ) { ... }                      # reported
    my @names = keys %{ $self->{children} };                       # reported

    no autovivification;
    if ( exists $seen{$user}{$host} ) { ... }                      # OK!
    my @names = keys %{ $self->{children} };                       # OK!

Only a read through an element is reported.  A read of one level,
C<$h{$k}>, creates nothing in C<%h>, so a file without a read through an
element needs no pragma.  A store through an element creates the levels on
purpose, and is not reported:

    $count{$user}{$host}++;                                        # OK!
    push @{ $children{$parent} }, $child;                          # OK!

=head2 PROHIBITED

Each of these, without a C<no autovivification> in scope that covers it:

    $h{a}{b}                  # two levels
    $h{a}->{b}                # the same, with the arrow
    $r->{a}[0]                # a reference, then two levels
    $_[0]{a}                  # an element of @_ is the caller's variable
    $$r{a}{b}                 # $r->{a}{b}
    ${ $h{a} }{b}             # a block dereference of an element
    @{ $h{a} }{qw(b c)}       # a slice of an element
    $h{a}->@{qw(b c)}         # a postfix slice
    $o->m->{a}{b}             # through what a method returned
    @{ $h{a}{b} }             # a read through an element, inside a cast
    keys %{ $h{a} }           # keys or values of an element
    keys $h{a}->%*            # with a postfix cast
    exists $h{a}{b}           # needs the 'exists' category
    delete $h{a}{b}           # needs the 'delete' category

=head2 ALLOWED

    $h{a}                     # one level
    $r->{a}                   # one level, through a reference
    @{ $h{a} }                # strict refs dies here, it does not vivify
    exists $h{a}              # one level
    f()->{a}                  # one level of what a sub returned
    ( f() )[0]{k}             # a list slice is a copy
    $h{a}{b} = 1              # an assignment
    $h{a}{b}++                # and any other change
    push @{ $h{a}{b} }, 1     # the first argument of push, pop and the like
    \$h{a}{b}                 # a reference
    local $h{a}{b}
    f( $h{a}{b} )             # an argument of a sub or method, see CAVEATS
    $h{a}{b}->m               # the invocant of a method
    for ( @{ $h{a}{b} } ) {}  # a foreach list, and the list of map and grep
    $h{a}{b} =~ s/x//         # a substitution or transliteration
    chomp $h{a}{b}            # chomp, chop, undef, sprintf

=head2 SCOPE AND CATEGORIES

C<no autovivification> is lexical, like C<no strict>.  It covers the rest of
the block that it is in, from the statement after it, and every block inside
that.  A C<no autovivification> inside a sub covers only that sub.

Each read needs one category.  A read, and C<keys> or C<values>, needs
C<fetch>.  C<exists> needs C<exists>, and C<delete> needs C<delete>.  Without
arguments, C<no autovivification> turns on all three.  With arguments, it
turns on only the categories it names, so these do not cover a read:

    no autovivification qw(store);     # store only
    no autovivification 'warn';        # warn and strict alone turn on nothing
    no autovivification ();            # empty parens do not call unimport

C<warn> and C<strict> with categories, such as
C<< no autovivification strict => 'fetch' >>, turn those categories on.  Each
C<no autovivification> adds to the categories in scope.  C<use
autovivification> takes away the ones it names, or all of them without
arguments, until the end of its block.

The policy does not ask for C<store>.  Under C<store>, a store through a
missing level dies instead of creating it.  That changes what a correct
program does, where the other categories only stop a read from writing.

=head2 CAVEATS

Perl passes the arguments of a sub or method, a C<foreach> list, and the list
of C<map> and C<grep> as aliases, so it creates the levels above them as it
does for a store.  The default categories do not stop that, so the policy does
not report it.  Copy the value into a variable first:

    my $port = $config{server}{port};
    connect_to($port);

An argument that the policy cannot read, such as
C<no autovivification @categories>, counts as no arguments.

The policy does not read inside strings.  C<"$h{a}{b}"> creates C<$h{a}> as
well.

A read of one level through a reference, C<< $r->{a} >>, makes C<$r> a
reference to an empty hash when C<$r> is undefined.  The policy does not report
it: the variable that changes is the one that the code reads through, and the
code is about to find out what it holds.

=head1 CONFIGURATION

C<equivalent_modules> names modules that turn the default categories on in
the scope of the code that uses them, the way some bundles of pragmas do.  A
C<use> of one of them counts as C<no autovivification;>.

    [Variables::RequireNoAutovivification]
    equivalent_modules = My::Kit

=head2 METHODS

=head3 supported_parameters

=head3 default_severity

=head3 default_themes

=head3 applies_to

=head3 violates

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/perl-critic-policy-requirenoautovivification/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 CONTRIBUTOR

=for stopwords troglodyne-bot

troglodyne-bot <morpheus@troglodyne.net>

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
