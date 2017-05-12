package Perl::Critic::Policy::Variables::ProhibitUnusedVarsStricter;

use 5.006001;
use strict;
use warnings;

use Perl::Critic::Document;
use PPIx::QuoteLike;
use Readonly;
use Scalar::Util qw{ refaddr };

use PPI::Token::Symbol;

use Perl::Critic::Utils qw< :booleans :characters hashify :severities >;

use base 'Perl::Critic::Policy';

our $VERSION = '0.100';

#-----------------------------------------------------------------------------

Readonly::Scalar my $EXPL =>
    q<Unused variables clutter code and make it harder to read>;

# Determine whether a PPI::Statement::Variable refers to a global or a
# lexical variable. We need to track globals to avoid false negatives
# from things like
#
# my $foo;
# {
#     our $foo;
#     $foo = 'bar';
# }
#
# but we do not need to track 'local', because if you
# s/ \b our \b /local/smxg
# in the above, Perl complains that you can not localize a lexical
# variable, rather than localizing the corresponding global variable.
Readonly::Hash my %GLOBAL_DECLARATION => (
    my      => $FALSE,
    state   => $FALSE,
    our     => $TRUE,
);

# Contents of regular expression to find interpolations. It captures:
# $1 = the sigil ( '$' or '@' ), with leading cast if any
# $2 = the variable (\w+, since we are not worried about built-ins, but
#      possibly with enclosing {})
# $3 = the first character of the subscript ( '[' or '{' ), if any
# The (*SKIP) prevents backtracking past that point, which causes the
# expression to be really, really slow on very long strings such as the
# 447776-character one in CPAN module Bhagavatgita.
#Readonly::Scalar my $FIND_INTERPOLATION => qr/
#    (?: \A | (?<! [\\] ) ) (?: \\\\ )* (*SKIP)
#    ( [\$\@]{1,2} ) ( \w+ | [{] \w+ [}] ) ( [[{]? )
#/smx;
#
# But it turned out to be slightly faster (0.8 seconds versus 1 second
# to analyze module Bhagavatgita) to capture the back slashes (if any)
# in front of a potential interpolation, and then weed out the ones that
# turn out to be escaped. The following captures:
# $1 = any leading back slashes
# $2 = the sigil ( '$' or '@' ), with leading cast if any
# $3 = the variable (\w+, since we are not worried about built-ins, but
#      possibly with enclosing {})
# $4 = the first character of the subscript ( '[' or '{' ), if any
Readonly::Scalar my $FIND_INTERPOLATION => qr/
    ( \\* ) ( [\$\@]{1,2} ) ( \w+ | [{] \w+ [}] ) ( [[{]? )
/smx;

Readonly::Scalar my $LAST_CHARACTER => -1;

#-----------------------------------------------------------------------------

sub supported_parameters { return (
        {
            name        => 'allow_if_computed_by',
            description => 'Allow if computed by one of these',
            behavior    => 'string list',
        },
        {   name        => 'prohibit_reference_only_variables',
            description => 'Prohibit reference-only variables',
            behavior    => 'boolean',
            default_string  => '0',
        },
        {   name        => 'prohibit_returned_lexicals',
            description => 'Prohibit returned lexicals',
            behavior    => 'boolean',
            default_string  => '0',
        },
        {   name        => 'allow_unused_subroutine_arguments',
            description => 'Allow unused subroutine arguments',
            behavior    => 'boolean',
            default_string  => '0',
        },
    ) }

sub default_severity     { return $SEVERITY_MEDIUM       }
sub default_themes       { return qw< trw maintenance >  }
sub applies_to           { return qw< PPI::Document >    }

#-----------------------------------------------------------------------------

sub violates {
#   my ( $self, $elem, $document ) = @_;
    my ( $self, undef, $document ) = @_;

    my %is_declaration; # Keyed by refaddr of PPI::Token::Symbol. True
                        # if the object represents a declaration.

    my %declared;       # Keyed by PPI::Token::Symbol->symbol(). Values
                        # are a list of hashes representing declarations
                        # of the given symbol, in reverse order. In each
                        # hash:
                        # {declaration} is the PPI statement object in
                        #     which the variable is declared;
                        # {element} is the PPI::Token::Symbol
                        # {is_allowed_computation} is true if the value
                        #     of the symbol is initialized using one of
                        #     the allowed subroutines or classes (e.g.
                        #     Scope::Guard).
                        # {is_global} is true if the declaration is a
                        #     global (i.e. is 'our', not 'my');
                        # {is_unpacking} is true if the declaration
                        #     occurs in an argument unpacking;
                        # {taking_reference} is true if the code takes a
                        #     reference to the declared variable;
                        # {used} is a count of the number of times that
                        #     declaration was used, initialized to 0.

    $self->_get_symbol_declarations(
        $document, \%declared, \%is_declaration );

    _get_symbol_uses( $document, undef, \%declared, \%is_declaration );

    _get_regexp_symbol_uses( $document, \%declared, \%is_declaration );

    _get_double_quotish_string_uses( $document, undef, \%declared );

    return $self->_get_violations( \%declared );

}

#-----------------------------------------------------------------------------

sub _get_symbol_declarations {
    my ( $self, $document, $declared, $is_declaration ) = @_;

    $self->_get_variable_declarations( $document, $declared,
        $is_declaration );

    _get_stray_variable_declarations( $document, $declared,
        $is_declaration );

    # Because we need multiple passes to find all the declarations, we
    # have to put them in reverse order when we're done.
    foreach my $decls ( values %{ $declared } ) {
        @{ $decls } = map { $_->[0] }
            sort { $b->[1][0] <=> $a->[1][0] || $b->[1][1] <=> $a->[1][1] }
            map { [ $_, $_->{element}->location() ] }
            @{ $decls };
    }

    return;

}

#-----------------------------------------------------------------------------

sub _get_variable_declarations {
    my ( $self, $document, $declared, $is_declaration ) = @_;

    foreach my $declaration ( @{ $document->find( 'PPI::Statement::Variable' )
        || [] } ) {

        defined( my $is_global = $GLOBAL_DECLARATION{
            $declaration->type() } )
            or next;

        my ( $assign, $is_allowed_computation, $is_unpacking );

        foreach my $operator ( @{ $declaration->find( 'PPI::Token::Operator' )
            || [] } ) {
            q<=> eq $operator->content()
                or next;
            $assign = $operator;
            my $content = $declaration->content();
            $is_unpacking = $content =~ m<
                = \s* (?: \@_ |
                    shift (?: \s* \@_ )? ) |
                    \$_ [[] .*? []]
                \s* ;? \z >smx;
            $is_allowed_computation = $self->_is_allowed_computation(
                $operator );
            last;
        }

        # We _should_ always get a $first_operand. However, given
        #   use Object::InsideOut;
        #       .
        #       .
        #       ,
        #   my @state : Field : Arg(state) : Get(state);
        # (which appears in MetasploitExpress::Parser::Host), PPI parses
        # the second and third occurrences of the string 'state' as a
        # PPI::Statement::Variable, when it probably ought to be a
        # PPI::Token::Word. We need to protect ourselves, so ...
        my $first_operand = $declaration->schild( 1 )
            or next;

        # We can't just look for symbols, since PPI parses the parens in
        # open( my $fh, '>&', \*STDOUT )
        # as a PPI::Statement::Variable, and we get a false positive on
        # STDOUT.
        my @symbol_list;
        if ( $first_operand->isa( 'PPI::Token::Symbol' ) ) {
            push @symbol_list, $first_operand;
        } elsif ( $first_operand->isa( 'PPI::Structure::List' ) ) {
            push @symbol_list, @{
                $first_operand->find( 'PPI::Token::Symbol' ) || [] };
        } else {
            next;
        }

        foreach my $symbol ( @symbol_list ) {

            if ( $assign ) {
                $symbol->line_number() < $assign->line_number()
                    or $symbol->line_number() == $assign->line_number()
                    and $symbol->column_number() < $assign->column_number()
                    or next;
            }

            $is_declaration->{ refaddr( $symbol ) } = 1;

            # Yes, the hash values are supposed to be in reverse order.
            # But since we have to make multiple passes to find all the
            # declarations, we put them in the correct order later.
            push @{ $declared->{ $symbol->symbol() } ||= [] }, {
                declaration => $declaration,
                element     => $symbol,
                is_allowed_computation => $is_allowed_computation,
                is_global   => $is_global,
                is_unpacking => $is_unpacking,
                taking_reference => scalar _taking_reference_of_variable(
                    $declaration ),
                returned_lexical => scalar _returned_lexical(
                    $declaration ),
                used        => 0,
            };

        }

    }

    return;
}

#-----------------------------------------------------------------------------

{

    Readonly::Hash my %IS_FOR => hashify( qw{ for foreach } );
    Readonly::Hash my %IS_RETURN => hashify( qw{ return } );

    # Get stray declarations that do not show up in
    # PPI::Statement::Variable statements. These show up in
    # PPI::Statement::Compound (specifically 'for' and 'foreach'), and
    # in PPI::Statement::Break (specifically 'return'). In the case of
    # 'return', we do not need to descend into paren, because if there
    # are parens, PPI produces a PPI::Statement::Variable.

    sub _get_stray_variable_declarations {
        my ( $document, $declared, $is_declaration ) = @_;

        foreach (
            [ 'PPI::Statement::Compound' => {
                    want                => \%IS_FOR,
                    returned_lexical    => $FALSE,
                } ],
            [ 'PPI::Statement::Break'   => {
                    want                => \%IS_RETURN,
                    returned_lexical    => $TRUE,
                } ],
        ) {
            my ( $class, $info ) = @{ $_ };
            foreach my $declaration (
                @{ $document->find( $class ) || [] }
            ) {

                my $type = $declaration->schild( 0 )
                    or next;

                my $type_str = $type->content();

                if ( $info->{want}{$type_str} ) {

                    my $sib = $type->snext_sibling()
                        or next;

                    # We're looking for 'my', 'state', or 'our'.
                    $sib->isa( 'PPI::Token::Word' )
                        or next;
                    my $sib_content = $sib->content();
                    defined( my $is_global = $GLOBAL_DECLARATION{$sib_content} )
                        or next;

                    my $symbol = $sib->snext_sibling()
                        or next;
                    $symbol->isa( 'PPI::Token::Symbol' )
                        or next;

                    $is_declaration->{ refaddr( $symbol ) } = 1;

                    # Yes, the hash values are supposed to be in reverse
                    # order. But since we have to make multiple passes
                    # to find all the declarations, we put them in the
                    # correct order later.
                    push @{ $declared->{ $symbol->symbol() } ||= [] }, {
                        declaration         => $declaration,
                        element             => $symbol,
                        is_allowed_computation => $FALSE,
                        is_global           => $is_global,
                        is_unpacking        => $FALSE,
                        taking_reference    => $FALSE,
                        returned_lexical    => $info->{returned_lexical},
                        used                => 0,
                    };

                }

            }

        }

        return;
    }

}

#-----------------------------------------------------------------------------

sub _is_allowed_computation {
    my ( $self, $elem ) = @_;  # $elem presumed to be '='.

    my $next_sib = $elem->snext_sibling() or return;

    if ( $next_sib->isa( 'PPI::Token::Word' ) ) {

        # We are presumed to be a subroutine call.
        my $content = $next_sib->content();
        $self->{_allow_if_computed_by}{$content}
            and return $content;

    } elsif ( $next_sib->isa( 'PPI::Token::Symbol' ) ) {

        # We might be a method call.
        $next_sib = $next_sib->snext_sibling()
            or return;
        $next_sib->isa( 'PPI::Token::Operator' )
            and q{->} eq $next_sib->content()
            or return;
        $next_sib = $next_sib->snext_sibling()
            or return;
        my $content = $next_sib->content();
        $self->{_allow_if_computed_by}{$content}
            and return $content;
    }

    return;
}

#-----------------------------------------------------------------------------

sub _taking_reference_of_variable {
    my ( $elem ) = @_;  # Expect a PPI::Statement::Variable
    my $parent = $elem->parent()
        or return;
    my $cast;

    if ( $parent->isa( 'PPI::Structure::List' ) ) {

        $cast = $parent->sprevious_sibling()
            or return;

    } elsif ( $parent->isa( 'PPI::Structure::Block' ) ) {

        my $prev = $parent->sprevious_sibling()
            or return;

        $prev->isa( 'PPI::Token::Word' )
            or return;
        'do' eq $prev->content()
            or return;

        $cast = $prev->sprevious_sibling()

    }

    $cast
        or return;
    $cast->isa( 'PPI::Token::Cast' )
        or return;
    return q<\\> eq $cast->content()
}

#-----------------------------------------------------------------------------

sub _returned_lexical {
    my ( $elem ) = @_;  # Expect a PPI::Statement::Variable
    my $parent = $elem->parent()
        or return;
    my $stmt = $parent->statement()
        or return;
    $stmt->isa( 'PPI::Statement::Break' )
        or return;
    my $kind = $stmt->schild( 0 )
        or return;  # Should never happen.
    return 'return' eq $kind->content();
}

#-----------------------------------------------------------------------------

{

    Readonly::Hash my %CAST_ALLOWED_FOR_BARE_BRACKETED_VARIABLE =>
        hashify( qw{ @ $ % } );

    sub _get_symbol_uses {
        my ( $document, $scope_of_record, $declared, $is_declaration ) = @_;

        foreach my $symbol (
            @{ $document->find( 'PPI::Token::Symbol' ) || [] }
        ) {
            $is_declaration->{ refaddr( $symbol ) } and next;

            _record_symbol_use( $document, $symbol->symbol(),
                $scope_of_record || $symbol, $declared );

        }

        # For some reason, PPI parses '$#foo' as a
        # PPI::Token::ArrayIndex.  $#$foo is parsed as a Cast followed
        # by a Symbol, so as long as nobody decides the '$#' cast causes
        # $elem->symbol() to return something other than '$foo', we're
        # cool.
        foreach my $elem (
            @{ $document->find( 'PPI::Token::ArrayIndex' ) || [] }
        ) {

            my $name = $elem->content();
            $name =~ s/ \A \$ [#] /@/smx or next;

            _record_symbol_use( $document, $name,
                $scope_of_record || $elem, $declared );
        }

        # Occasionally you see something like ${foo} outside quotes.
        # This is legitimate, though PPI parses it as a cast followed by
        # a block. On the assumption that there are fewer blocks than
        # words in most Perl, we start at the top and work down. Perl
        # also handles punctuation variables specified this way, but
        # since PPI goes berserk when it sees this, we won't bother.
        foreach my $elem (
            @{ $document->find( 'PPI::Structure::Block' ) || [] }
        ) {

            my $previous = $elem->sprevious_sibling()
                or next;
            $previous->isa( 'PPI::Token::Cast' )
                or next;
            my $sigil = $previous->content();
            $CAST_ALLOWED_FOR_BARE_BRACKETED_VARIABLE{ $sigil }
                or next;

            my @kids = $elem->schildren();
            1 == @kids
                or next;
            $kids[0]->isa( 'PPI::Statement' )
                or next;

            my @grand_kids = $kids[0]->schildren();
            1 == @grand_kids
                or next;
            $grand_kids[0]->isa( 'PPI::Token::Word' )
                or next;

            _record_symbol_use( $document,
                $sigil . $grand_kids[0]->content(),
                $scope_of_record || $elem, $declared
            );
        }

        return;
    }

}

#-----------------------------------------------------------------------------

sub _record_symbol_use {
    my ( $document, $symbol_name, $scope, $declared ) = @_;
    my $declaration = $declared->{ $symbol_name }
        or return;

    foreach my $decl_scope ( @{ $declaration } ) {
        $document->element_is_in_lexical_scope_after_statement_containing(
            $scope, $decl_scope->{declaration} )
            or next;
        $decl_scope->{used}++;
        last;
    }

    return;

}

#-----------------------------------------------------------------------------

sub _get_double_quotish_string_uses {
    my ( $document, $scope_of_record, $declared ) = @_;

    foreach my $class ( qw{
        PPI::Token::Quote::Double
        PPI::Token::Quote::Interpolate
        PPI::Token::QuoteLike::Backtick
        PPI::Token::QuoteLike::Command
        PPI::Token::QuoteLike::Readline
        PPI::Token::HereDoc
        } ) {
        foreach my $double_quotish (
            @{ $document->find( $class ) || [] }
        ) {
            my $str = PPIx::QuoteLike->new( $double_quotish )
                or next;

            foreach my $var ( $str->variables() ) {
                _record_symbol_use( $document, $var,
                    $scope_of_record || $double_quotish, $declared );
            }
        }
    }

    return;
}

#-----------------------------------------------------------------------------

sub _get_regexp_symbol_uses {
    my ( $document, $declared, $is_declaration ) = @_;

    foreach my $class ( qw{
        PPI::Token::Regexp::Match
        PPI::Token::Regexp::Substitute
        PPI::Token::QuoteLike::Regexp
        } ) {

        foreach my $regex ( @{ $document->find( $class ) || [] } ) {

            my $ppix = $document->ppix_regexp_from_element( $regex ) or next;
            $ppix->failures() and next;

            foreach my $code ( @{
                $ppix->find( 'PPIx::Regexp::Token::Code' ) || [] } ) {

                my $subdoc = Perl::Critic::Document->new(
                    '-source'               => $code->ppi(),
                    '-filename-override'    => $document->filename(),
                );

                _get_symbol_uses( $subdoc, $regex,
                    $declared, $is_declaration );

                # Yes, someone did s/.../"..."/e.
                _get_double_quotish_string_uses( $subdoc,
                    $regex, $declared );

            }

        }

    }

    return;
}

#-----------------------------------------------------------------------------

sub _get_violations {
    my ( $self, $declared ) = @_;

    my @in_violation;

    foreach my $name ( values %{ $declared } ) {
        foreach my $declaration ( @{ $name } ) {
            $declaration->{is_global}
                and next;
            $declaration->{used}
                and next;
            $declaration->{is_allowed_computation}
                and next;
            $declaration->{taking_reference}
                and not $self->{_prohibit_reference_only_variables}
                and next;
            $declaration->{returned_lexical}
                and not $self->{_prohibit_returned_lexicals}
                and next;
            $declaration->{is_unpacking}
                and $self->{_allow_unused_subroutine_arguments}
                and next;
            push @in_violation, $declaration->{element};
        }
    }

    return ( map { $self->violation(
            sprintf( '%s is declared but not used', $_->symbol() ),
            $EXPL,
            $_
        ) } sort { $a->line_number() <=> $b->line_number() ||
            $a->column_number() <=> $b->column_number() }
        @in_violation );
}

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Variables::ProhibitUnusedVarsStricter - Don't ask for storage you don't need.


=head1 AFFILIATION

This Policy is stand-alone, and is not part of the core
L<Perl::Critic|Perl::Critic>.


=head1 NOTE

As of version 0.099_001, the logic that recognizes variables
interpolated into double-quotish strings has been refactored into module
L<PPIx::QuoteLike|PPIx::QuoteLike>.

=head1 DESCRIPTION

Unused variables clutter code and require the reader to do mental
bookkeeping to figure out if the variable is actually used or not.

Right now, this only looks for lexical variables which are unused other
than in the statement that declares them.

    my $x;          # not ok, assuming no other appearances.
    my @y = ();     # not ok, assuming no other appearances.
    our $z;         # ok, global.
    local $w;       # ok, global.

This policy is a variant on the core policy
L<Perl::Critic::Policy::Variables::ProhibitUnusedVariables|Perl::Critic::Policy::Variables::ProhibitUnusedVariables>
which attempts to be more strict in its checking of whether a variable
is used. The specific differences are:

* An attempt is made to take into account the scope of the declaration.

* An attempt is made to find variables which are interpolated into
double-quotish strings (including regexes) and here documents.

* An attempt is made to find variables which are used in regular
expression C<(?{...})> and C<(??{...})> constructions, and in the
replacement portion of C<s/.../.../e>.

This policy intentionally does not report variables as unused if the
code takes a reference to the variable, even if it is otherwise unused.
For example things like

    \( my $foo = 'bar' )
    \do{ my $foo => 'bar' }

will not be reported as a violation even if C<$foo> is otherwise unused.
The reason is that this is an idiom for making a reference to a mutable
string when all you have is an immutable string. This policy does not
check to see if anything is done with the reference.

This policy also does not detect unused variables declared inside
various odd corners such as

    s///e
    qr{(?{...})}
    qr{(??{...})}
    "@{[ ... ]}"
    ( $foo, my $bar ) = ( 1, 2 )

Most of these are because the PPI parse of the original document does
not include the declarations. The list assignment is missed because PPI
does not parse it as containing a
L<PPI::Statement::Variable|PPI::Statement::Variable>. However, variables
B<used> inside such construction B<will> be detected.


=head1 CONFIGURATION

This policy supports the following configuration items:

=head2 allow_unused_subroutine_arguments

By default, this policy prohibits unused subroutine arguments -- that
is, unused variables on the right-hand side of such simple assignments
as

    my ( $foo ) = @_;
    my $bar     = shift;
    my $baz     = shift @_;
    my $burfle  = $_[0];

If you wish to allow unused variables in this case, you can add a block
like this to your F<.perlcriticrc> file:

    [Variables::ProhibitUnusedVarsStricter]
    allow_unused_subroutine_arguments = 1

=head2 prohibit_reference_only_variables

By default, this policy allows otherwise-unused variables if the code
takes a reference to the variable when it is created. If you wish to
declare a violation in this case, you can add a block like this to your
F<.perlcriticrc> file:

    [Variables::ProhibitUnusedVarsStricter]
    prohibit_reference_only_variables = 1

=head2 prohibit_returned_lexicals

By default, this policy allows otherwise-unused variables if they are
being returned from a subroutine, under the presumption that they are
going to be used as lvalues. If you wish to declare a violation in this
case, you can add a block like this to your F<.perlcriticrc> file:

    [Variables::ProhibitUnusedVarsStricter]
    prohibit_returned_lexicals = 1

=head2 allow_if_computed_by

You may wish to allow variables to be unused when computed in certain
ways. For example, you might want to allow place-holder variables in a
list computed by C<stat()> or C<unpack()>. Or you may be doing
end-of-scope detection with something like
C<< my $foo = Scope::Guard->new( \&end_of_scope ) >>. To ignore all
these, you can add a block like this to your F<.perlcriticrc> file:

    [Variables::ProhibitUnusedVarsStricter]
    allow_if_computed_by = stat unpack Scope::Guard

This property takes as its value a whitespace-delimited list of class or
subroutine names. Nothing complex is done to implement this -- the
policy simply looks at the first word after the equals sign, if any.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2016 Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 72
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=72 ft=perl expandtab shiftround :
