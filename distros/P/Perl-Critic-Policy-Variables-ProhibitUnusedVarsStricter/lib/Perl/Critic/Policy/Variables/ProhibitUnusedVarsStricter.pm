package Perl::Critic::Policy::Variables::ProhibitUnusedVarsStricter;

use 5.006001;
use strict;
use warnings;

use English qw{ -no_match_vars };

use PPIx::QuoteLike 0.011;
use PPIx::QuoteLike::Constant 0.011 qw{
    LOCATION_LINE
    LOCATION_LOGICAL_LINE
    LOCATION_CHARACTER
};
use PPIx::Regexp 0.071;
use Readonly;
use Scalar::Util qw{ refaddr };

use Perl::Critic::Exception::Fatal::PolicyDefinition;
use Perl::Critic::Utils qw< :booleans :characters hashify :severities >;

use base 'Perl::Critic::Policy';

our $VERSION = '0.107';

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

Readonly::Scalar my $PACKAGE    => '_' . __PACKAGE__;

Readonly::Scalar my $LEFT_BRACE => q<{>;    # } Seems P::C::U should have

Readonly::Hash my %IS_COMMA     => hashify( $COMMA, $FATCOMMA );
Readonly::Hash my %LOW_PRECEDENCE_BOOLEAN => hashify( qw{ and or xor } );

Readonly::Array my @DOUBLE_QUOTISH => qw{
    PPI::Token::Quote::Double
    PPI::Token::Quote::Interpolate
    PPI::Token::QuoteLike::Backtick
    PPI::Token::QuoteLike::Command
    PPI::Token::QuoteLike::Readline
    PPI::Token::HereDoc
};
Readonly::Array my @REGEXP_ISH => qw{
    PPI::Token::Regexp::Match
    PPI::Token::Regexp::Substitute
    PPI::Token::QuoteLike::Regexp
};

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
        {
            name        => 'allow_state_in_expression',
            description => 'Allow state variable with low-precedence Boolean',
            behavior    => 'boolean',
            default_string  => '0',
        },
        {
            name        => 'dump',
            description => 'UNSUPPORTED: Dump symbol definitions',
            behavior    => 'boolean',
            default_string  => '0',
        },
        {
            name        => 'trace',
            description => 'UNSUPPORTED: Trace variable processing',
            behavior    => 'string list',
        },
    ) }

sub default_severity     { return $SEVERITY_MEDIUM       }
sub default_themes       { return qw< trw maintenance >  }
sub applies_to           { return qw< PPI::Document >    }

#-----------------------------------------------------------------------------

sub violates {
#   my ( $self, $elem, $document ) = @_;
    my ( $self, undef, $document ) = @_;

    $self->{$PACKAGE} = {
        declared        => {},  # Keyed by PPI::Token::Symbol->symbol().
                                # Values are a list of hashes
                                # representing declarations of the given
                                # symbol, in reverse order. In each
                                # hash:
                                # {declaration} is the PPI statement
                                #     object in which the variable is
                                #     declared;
                                # {element} is the PPI::Token::Symbol
                                # {is_allowed_computation} is true
                                #     if the value of the symbol is
                                #     initialized using one of the
                                #     allowed subroutines or classes
                                #     (e.g.  Scope::Guard).
                                # {is_global} is true if the declaration
                                #     is a global (i.e. is 'our', not 'my');
                                # {is_state_in_expression} is true if
                                #     the variable is a 'state' variable
                                #     and the assignment is part of an
                                #     expression.
                                # {is_unpacking} is true if the
                                #     declaration occurs in an argument
                                #     unpacking;
                                # {taking_reference} is true if the code
                                #     takes a reference to the declared
                                #     variable;
                                # {used} is a count of the number of
                                #     times that declaration was used,
                                #     initialized to 0.

        is_declaration  => {},  # Keyed by refaddr of PPI::Token::Symbol.
                                # True if the object represents a
                                # declaration.

        need_sort => $FALSE,    # Boolean that says whether the symbol
                                # declarations need to be sorted in
                                # lexical order. Recording a declaration
                                # must set this. Recording a use must
                                # clear this, doing the sort if it was
                                # previously set.

        ppix_objects  => {},    # Cache of PPIx::QuoteLike and
                                # PPIx::Regexp objects indexed by
                                # refaddr of parent element.

        parent_element => {},   # PPI::Element objects from which
                                # PPI::Document objects have been
                                # derived, indexed by refaddr of derived
                                # document.
    };

    # Ensure entire document is indexed. We don't call index_locations()
    # because that is unconditional. We wrap the whole thing in an eval
    # because last_token() can fail under undiagnosed circumstances.
    {
        local $EVAL_ERROR = undef;
        eval {  ## no critic (RequireCheckingReturnValueOfEval)
            if ( my $token = $document->last_token() ) {
                $token->location();
            }
        }
    }

    $self->_get_symbol_declarations( $document );

    $self->_get_symbol_uses( $document );

    $self->{_dump}
        and $self->_dump();

    return $self->_get_violations();

}

#-----------------------------------------------------------------------------

sub _dump {
    my ( $self ) = @_;
    foreach my $name ( sort keys %{ $self->{$PACKAGE}{declared} } ) {
        # NOTE that 'print { STDERR } ... ' does not compile under
        # strict refs. '{ *STDERR }' is a terser way to satisfy
        # InputOutput::RequireBracedFileHandleWithPrint.
        print { *STDERR } "$name\n";
        foreach my $decl ( @{ $self->{$PACKAGE}{declared}{$name} } ) {
            my $sym = $decl->{element};
            my $fn = $sym->logical_filename();
            if ( defined $fn ) {
                $fn =~ s/ (?= [\\'] ) /\\/smxg;
                $fn = "'$fn'";
            } else {
                $fn = 'undef';
            }
            printf { *STDERR }
                "    %s line %d column %d used %d\n",
                $fn,
                $sym->logical_line_number(),
                $sym->column_number(),
                $decl->{used};
        }
    }
    return;
}

#-----------------------------------------------------------------------------

sub _get_symbol_declarations {
    my ( $self, $document ) = @_;

    $self->_get_variable_declarations( $document );

    $self->_get_stray_variable_declarations( $document );

    return;

}

#-----------------------------------------------------------------------------

# We assume the argument is actually eligible for this operation.
sub _get_ppix_quotelike {
    my ( $self, $elem ) = @_;
    return $self->{$PACKAGE}{ppix_objects}{ refaddr $elem } ||=
        PPIx::QuoteLike->new( $elem );
}

#-----------------------------------------------------------------------------

# We assume the argument is actually eligible for this operation. The
# complication here is that if we are dealing with an element of a
# Perl::Critic::Document we want to call ppix_regexp_from_element(),
# since that caches the returned object, making it available to all
# policies. But the ppi() method returns a PPI::Document, so the best we
# can do is to cache locally.
sub _get_ppix_regexp {
    my ( $self, $elem ) = @_;
    return $self->{$PACKAGE}{ppix_objects}{ refaddr $elem } ||= do {
        my $doc = $elem->top();
        my $code;
        ( $code = $doc->can( 'ppix_regexp_from_element' ) ) ?
            $code->( $doc, $elem ) :
            PPIx::Regexp->new( $elem );
    };
}

#-----------------------------------------------------------------------------

# Get the PPI::Document that represents a PPIx::* class that supports
# one. The arguments are:
#  $ppix_elem - the PPIx::* element providing the document. This MUST
#    support the ->ppi() method.
#  $elem - the original PPI::Element from which this element was
#    derived.
# NOTE that all calls to ->ppi() MUST come through here.
sub _get_derived_ppi_document {
    my ( $self, $ppix_elem, $elem ) = @_;
    my $ppi = $ppix_elem->ppi()
        or return;
    $self->{$PACKAGE}{parent_element}{ refaddr( $ppi ) } ||= $elem;
    return $ppi;
}

#-----------------------------------------------------------------------------

# Get the PPI::Element that is the parent of the given PPI::Element,
# taking into account that the given element may be a derived
# PPI::Document.
# NOTE that all calls to PPI::Element->parent() MUST come through here.
sub _get_parent_element {
    my ( $self, $elem ) = @_;
    if ( my $parent = $elem->parent() ) {
        return $parent;
    } else {
        return $self->{$PACKAGE}{parent_element}{ refaddr( $elem ) };
    }
}

#-----------------------------------------------------------------------------

# Get the lowest parent of the inner element that is in the same
# document as the outer element.
sub _get_lowest_in_same_doc {
    my ( $self, $inner_elem, $outer_elem ) = @_;
    my $outer_top = $outer_elem->top()
        or return;
    while ( 1 ) {
        my $inner_top = $inner_elem->top()
            or last;
        $inner_top == $outer_top
            and return $inner_elem;
        $inner_elem = $self->_get_parent_element( $inner_top )
            or last;
    }
    return;
}

#-----------------------------------------------------------------------------

sub _get_ppi_statement_variable {
    my ( $self, $document ) = @_;

    my @rslt = @{ $document->find( 'PPI::Statement::Variable' ) || [] };

    foreach my $class ( @DOUBLE_QUOTISH ) {
        foreach my $elem ( @{ $document->find( $class ) || [] } ) {
            my $str = $self->_get_ppix_quotelike( $elem )
                or next;
            foreach my $code ( @{ $str->find(
                'PPIx::QuoteLike::Token::Interpolation' ) || [] } ) {
                my $ppi = $self->_get_derived_ppi_document( $code, $elem )
                    or next;
                push @rslt, $self->_get_ppi_statement_variable( $ppi );
            }
        }
    }

    foreach my $class ( @REGEXP_ISH ) {
        foreach my $elem ( @{ $document->find( $class ) || [] } ) {
            my $pre = $self->_get_ppix_regexp( $elem )
                or next;
            foreach my $code ( @{ $pre->find(
                'PPIx::Regexp::Token::Code' ) || [] } ) {
                my $ppi = $self->_get_derived_ppi_document( $code, $elem )
                    or next;
                push @rslt, $self->_get_ppi_statement_variable( $ppi );
            }
        }
    }

    return @rslt;
}

#-----------------------------------------------------------------------------

# Sorry, but this is just basicly hard.
sub _get_variable_declarations {    ## no critic (ProhibitExcessComplexity)
    my ( $self, $document ) = @_;

    foreach my $declaration ( $self->_get_ppi_statement_variable( $document ) ) {

        # This _should_ be the initial 'my', 'our' 'state'
        my $elem = $declaration->schild( 0 )
            or next;

        my $is_unpacking = $declaration->content() =~ m<
            = \s* (?: \@_ |
                shift (?: \s* \@_ )? ) |
                \$_ [[] .*? []]
            \s* ;? \z >smx;

        my $taking_reference = $self->_taking_reference_of_variable(
            $declaration );

        my $returned_lexical = $self->_returned_lexical( $declaration );

        while ( 1 ) {

            # Looking for 'my', 'our', or 'state'
            $elem->isa( 'PPI::Token::Word' )
                or next;
            defined( my $is_global = $GLOBAL_DECLARATION{
                $elem->content()} )
                or next;

            $elem = $elem->snext_sibling()
                or last;

            # We can't just look for symbols, since PPI parses the
            # parens in
            # open( my $fh, '>&', \*STDOUT )
            # as a PPI::Statement::Variable, and we get a false positive
            # on STDOUT.
            my @symbol_list;
            if ( $elem->isa( 'PPI::Token::Symbol' ) ) {
                push @symbol_list, $elem;
            } elsif ( $elem->isa( 'PPI::Structure::List' ) ) {
                push @symbol_list, @{
                    $elem->find( 'PPI::Token::Symbol' ) || [] };
            } else {
                next;
            }

            my ( $assign, $is_allowed_computation,
                $is_state_in_expression );

            while ( $elem = $elem->snext_sibling() ) {
                $elem->isa( 'PPI::Token::Operator' )
                    or next;
                my $content = $elem->content();
                $IS_COMMA{$content}
                    and last;
                if ( $EQUAL eq $content ) {
                    $assign = $elem;

                    $is_allowed_computation = $self->_is_allowed_computation(
                        $assign );

                    $is_state_in_expression = $self->_is_state_in_expression(
                        $declaration, $assign );

                    last;
                }
            }

            foreach my $symbol ( @symbol_list ) {

                if ( $assign ) {
                    $symbol->logical_line_number() <
                            $assign->logical_line_number()
                        or $symbol->logical_line_number() ==
                            $assign->logical_line_number()
                        and $symbol->column_number() < $assign->column_number()
                        or next;
                }

                $self->_record_symbol_definition(
                    $symbol, $declaration,
                    is_allowed_computation  => $is_allowed_computation,
                    is_global               => $is_global,
                    is_state_in_expression  => $is_state_in_expression,
                    is_unpacking            => $is_unpacking,
                    taking_reference        => $taking_reference,
                    returned_lexical        => $returned_lexical,
                );

            }


        } continue {
            $elem
                and $elem = $elem->snext_sibling()
                or last;
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
        my ( $self, $document ) = @_;

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

                    $self->_record_symbol_definition(
                        $symbol, $declaration,
                        is_global           => $is_global,
                        returned_lexical    => $info->{returned_lexical},
                    );

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

# Find cases where the value of a state variable is used by the
# statement that declares it, or an expression in which that statement
# appears. The user may wish to accept such variables even if the
# variable itself appears only in the statement that declares it.
#
# $declaration is assumed to be a PPI::Statement::Variable. We return
# $FALSE unless it declares state variables.
#
# $operator is the first assignment operator in $declaration.
#
# NOTE that this will never be called for stuff like
#   $foo and state $bar = 42
# because PPI does not parse this as a PPI::Statement::Variable.
sub _is_state_in_expression {
    my ( $self, $declaration, $operator ) = @_;

    # We're only interested in state declarations.
    q<state> eq $declaration->type()
        or return $FALSE;

    # We accept things like
    #   state $foo = bar() and ...
    my $next_sib = $operator;
    while ( $next_sib = $next_sib->snext_sibling() ) {
        $next_sib->isa( 'PPI::Token::Operator' )
            and $LOW_PRECEDENCE_BOOLEAN{ $next_sib->content() }
            and return $TRUE;
    }

    # We accept things like
    #     ... ( state $foo = bar() ) ...
    # IF at least one of the ellipses has an operator adjacent to our
    # declaration. 
    my $elem = $declaration;
    while ( $elem ) {
        foreach my $method ( qw{ snext_sibling sprevious_sibling } ) {
            my $sib = $elem->$method()
                or next;
            $sib->isa( 'PPI::Token::Operator' )
                and return $TRUE;
        }
        $elem = $self->_get_parent_element( $elem );
    }

    # There are no other known cases where a state variable's value can
    # be used without the variable name appearing anywhere other than
    # its initialization.
    return $FALSE;
}

#-----------------------------------------------------------------------------

sub _taking_reference_of_variable {
    my ( $self, $elem ) = @_;   # Expect a PPI::Statement::Variable
    my $parent = $self->_get_parent_element( $elem )
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
    my ( $self, $elem ) = @_;  # Expect a PPI::Statement::Variable
    my $parent = $self->_get_parent_element( $elem )
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

    Readonly::Hash my %CAST_FOR_BARE_BRACKETED_VARIABLE => qw{
        @ @
        $ $
        $$ $
        % %
    };

    sub _get_symbol_uses {
        my ( $self, $document ) = @_;

        foreach my $symbol (
            @{ $document->find( 'PPI::Token::Symbol' ) || [] }
        ) {
            $self->{$PACKAGE}{is_declaration}->{ refaddr( $symbol ) } and next;

            $self->_record_symbol_use( $document, $symbol );

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

            $self->_record_symbol_use( $document, $elem, $name );
        }

        # Occasionally you see something like ${foo} outside quotes.
        # This is legitimate, though PPI parses it as a cast followed by
        # a block. On the assumption that there are fewer blocks than
        # words in most Perl, we start at the top and work down. Perl
        # also handles punctuation variables specified this way, but
        # since PPI goes berserk when it sees this, we won't bother.
        #
        # And EXTREMELY occasionally something like $${foo} gets parsed
        # as magic followed by subscript.
        foreach my $class ( qw{
            PPI::Structure::Block
            PPI::Structure::Subscript
            }
        ) {
            foreach my $elem (
                @{ $document->find( $class ) || [] }
            ) {
                $LEFT_BRACE eq $elem->start()   # Only needed for subscript.
                    or next;
                my $previous = $elem->sprevious_sibling()
                    or next;
                $previous->isa( 'PPI::Token::Cast' )
                    or $previous->isa( 'PPI::Token::Magic' )    # $${foo}
                    or next;
                my $sigil = $CAST_FOR_BARE_BRACKETED_VARIABLE{
                        $previous->content() }
                    or next;

                my @kids = $elem->schildren();
                1 == @kids
                    or next;
                $kids[0]->isa( 'PPI::Statement' )
                    or next;

                my @grand_kids = $kids[0]->schildren();
                1 == @grand_kids
                    or next;

                # Yes, "${v6}_..." occurred, and was parsed as a
                # PPI::Token::Number::Version by PPI 1.270.
                $grand_kids[0]->isa( 'PPI::Token::Word' )
                    or $grand_kids[0]->isa( 'PPI::Token::Number::Version' )
                    or next;

                $self->_record_symbol_use( $document, $elem,
                    $sigil . $grand_kids[0]->content(),
                );
            }
        }

        $self->_get_regexp_symbol_uses( $document );

        $self->_get_double_quotish_string_uses( $document );

        return;
    }

}

#-----------------------------------------------------------------------------

# Record the definition of a symbol.
# $symbol is the PPI::Token::Symbol
# $declaration is the statement that declares it
# %arg is optional arguments, collected and recorded to support the
#     various configuration items.
sub _record_symbol_definition {
    my ( $self, $symbol, $declaration, %arg ) = @_;

    my $ref_addr = refaddr( $symbol );
    my $sym_name = $symbol->symbol();

    $self->{$PACKAGE}{is_declaration}{$ref_addr} = 1;

    $arg{declaration}   = $declaration;
    $arg{element}       = $symbol;
    $arg{used}          = 0;

    foreach my $key ( qw{
        is_allowed_computation
        is_global
        is_state_in_expression
        is_unpacking
        taking_reference
        returned_lexical
        } ) {
        exists $arg{$key}
            or $arg{$key} = $FALSE;
    }

    if ( $self->{_trace}{$sym_name} ) {
        printf { *STDERR }
            "%s 0x%x declared at line %d col %d\n",
            $sym_name, $ref_addr,
            $symbol->logical_line_number(), $symbol->column_number();
    }

    push @{ $self->{$PACKAGE}{declared}{ $sym_name } ||= [] }, \%arg;

    $self->{$PACKAGE}{need_sort} = $TRUE;

    return;
}

#-----------------------------------------------------------------------------

sub _record_symbol_use {
    my ( $self, undef, $symbol, $symbol_name ) = @_;    # $document not used

    my $declaration;

    defined $symbol_name
        or $symbol_name = $symbol->symbol();

    if ( ! ( $declaration = $self->{$PACKAGE}{declared}{$symbol_name} ) ) {
        # If we did not find a declaration for the symbol, it may
        # have been declared en passant, as part of doing something
        # else.
        my $prev = $symbol->sprevious_sibling()
            or return;
        $prev->isa( 'PPI::Token::Word' )
            or return;
        my $content = $prev->content();
        exists $GLOBAL_DECLARATION{$content}
            or return;

        # Yup. It's a declaration. Record it.
        $declaration = $symbol->statement();

        my $cast = $prev->sprevious_sibling();
        if ( ! $cast ) {
            my $parent;
            $parent = $self->_get_parent_element( $prev )
                and $cast = $parent->sprevious_sibling();
        }

        $self->_record_symbol_definition(
            $symbol, $declaration,
            is_global           => $GLOBAL_DECLARATION{$content},
            taking_reference    => _element_takes_reference( $cast ),
        );

        return;
    }

    if ( delete $self->{$PACKAGE}{need_sort} ) {
        # Because we need multiple passes to find all the declarations,
        # we have to put them in reverse order when we're done. We need
        # to repeat the check because of the possibility of picking up
        # declarations made in passing while trying to find uses.
        # Re the 'no critic' annotation: I understand that 'reverse ...'
        # is faster and clearer than 'sort { $b cmp $a } ...', but I
        # think the dereferenes negate this.
        foreach my $decls ( values %{ $self->{$PACKAGE}{declared} } ) {
            @{ $decls } = map { $_->[0] }
                sort { ## no critic (ProhibitReverseSortBlock)
                    $b->[1][LOCATION_LOGICAL_LINE] <=>
                        $a->[1][LOCATION_LOGICAL_LINE] ||
                    $b->[1][LOCATION_CHARACTER] <=>
                        $a->[1][LOCATION_CHARACTER]
                }
                map { [ $_, $_->{element}->location() ] }
                @{ $decls };
        }
    }

    foreach my $decl_scope ( @{ $declaration } ) {
        $self->_derived_element_is_in_lexical_scope_after_statement_containing(
            $symbol, $decl_scope->{declaration} )
            or next;
        $decl_scope->{used}++;
        if ( $self->{_trace}{$symbol_name} ) {
            my $elem = $decl_scope->{element};
            printf { *STDERR }
                "%s at line %d col %d refers to 0x%x at line %d col %d\n",
                $symbol_name,
                $symbol->logical_line_number(),
                $symbol->column_number(),
                refaddr( $elem ),
                $elem->logical_line_number(),
                $elem->column_number(),
                ;
        }
        return;
    }

    if ( $self->{_trace}{$symbol_name} ) {
        printf { *STDERR }
            "Failed to resolve %s at line %d col %d\n",
            $symbol_name,
            $symbol->logical_line_number(),
            $symbol->column_number(),
            ;
    }

    return;

}

sub _derived_element_is_in_lexical_scope_after_statement_containing {
    my ( $self, $inner_elem, $outer_elem ) = @_;

    my $effective_inner = $self->_get_lowest_in_same_doc( $inner_elem,
        $outer_elem )
        or return $FALSE;

    return _element_is_in_lexical_scope_after_statement_containing(
        $effective_inner, $outer_elem );

}

#-----------------------------------------------------------------------------

sub _element_takes_reference {
    my ( $elem ) = @_;
    return $elem && $elem->isa( 'PPI::Token::Cast' ) &&
        $BSLASH eq $elem->content();
}

#-----------------------------------------------------------------------------

sub _get_double_quotish_string_uses {
    my ( $self, $document ) = @_;

    foreach my $class ( @DOUBLE_QUOTISH ) {
        foreach my $double_quotish (
            @{ $document->find( $class ) || [] }
        ) {

            my $str = $self->_get_ppix_quotelike( $double_quotish )
                or next;

            foreach my $interp ( @{
                $str->find( 'PPIx::QuoteLike::Token::Interpolation' ) || [] } ) {

                my $subdoc = $self->_get_derived_ppi_document(
                    $interp, $double_quotish )
                    or next;

                $self->_get_symbol_uses( $subdoc, $double_quotish );

            }

        }
    }

    return;
}

#-----------------------------------------------------------------------------

sub _get_regexp_symbol_uses {
    my ( $self, $document ) = @_;

    foreach my $class ( @REGEXP_ISH ) {

        foreach my $regex ( @{ $document->find( $class ) || [] } ) {

            my $ppix = $self->_get_ppix_regexp( $regex )
                or next;

            foreach my $code ( @{
                $ppix->find( 'PPIx::Regexp::Token::Code' ) || [] } ) {

                my $subdoc = $self->_get_derived_ppi_document( $code,
                    $regex );

                $self->_get_symbol_uses( $subdoc, $regex );
            }

        }

    }

    return;
}

#-----------------------------------------------------------------------------

sub _get_violations {
    my ( $self ) = @_;

    my @in_violation;

    foreach my $name ( values %{ $self->{$PACKAGE}{declared} } ) {
        foreach my $declaration ( @{ $name } ) {
            $declaration->{is_global}
                and next;
            $declaration->{used}
                and next;
            $declaration->{is_allowed_computation}
                and next;
            $declaration->{is_state_in_expression}
                and $self->{_allow_state_in_expression}
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
        ) } sort { $a->logical_line_number() <=> $b->logical_line_number() ||
            $a->column_number() <=> $b->column_number() }
        @in_violation );
}

#-----------------------------------------------------------------------------

# THIS CODE HAS ABSOLUTELY NO BUSINESS BEING HERE. It should probably be
# its own module; PPIx::Scope or something like that. The problem is
# that I no longer "own" it, and am having trouble getting modifications
# through. So I have stuck it here for the moment, but I hope it will
# not stay here. Other than here, it appears in Perl::Critic::Document
# (the copy I am trying to get modified) and Perl::ToPerl6::Document (a
# cut-and-paste of an early version.)
#
# THIS CODE IS PRIVATE TO THIS MODULE. The author reserves the right to
# change it or remove it without any notice whatsoever. YOU HAVE BEEN
# WARNED.
#
# This got hung on the Perl::Critic::Document, rather than living in
# Perl::Critic::Utils::PPI, because of the possibility that caching of scope
# objects would turn out to be desirable.

# sub element_is_in_lexical_scope_after_statement_containing {...}
sub _element_is_in_lexical_scope_after_statement_containing {
    my ( $inner_elem, $outer_elem ) = @_;

    $inner_elem->top() == $outer_elem->top()
        or Perl::Critic::Exception::Fatal::PolicyDefinition->throw(
            message => 'Elements must be in same document' );

    # If the outer element defines a scope, we're true if and only if
    # the outer element contains the inner element, and the inner
    # element is not somewhere that is hidden from the scope.
    if ( $outer_elem->scope() ) {
        return _inner_element_is_in_outer_scope_really(
            $inner_elem, $outer_elem );
    }

    # In the more general case:

    # The last element of the statement containing the outer element
    # must be before the inner element. If not, we know we're false,
    # without walking the parse tree.

    my $stmt = $outer_elem->statement()
        or return;

    my $last_elem = $stmt;
    while ( $last_elem->isa( 'PPI::Node' ) ) {
        $last_elem = $last_elem->last_element()
            or return;
    }

    my $stmt_loc = $last_elem->location()
        or return;

    my $inner_loc = $inner_elem->location()
        or return;

    $stmt_loc->[LOCATION_LINE] > $inner_loc->[LOCATION_LINE]
        and return;
    $stmt_loc->[LOCATION_LINE] == $inner_loc->[LOCATION_LINE]
        and $stmt_loc->[LOCATION_CHARACTER] >= $inner_loc->[LOCATION_CHARACTER]
        and return;

    # Since we know the inner element is after the outer element, find
    # the element that defines the scope of the statement that contains
    # the outer element.

    my $parent = $stmt;
    while ( ! $parent->scope() ) {
        # Things appearing in the right-hand side of a
        # PPI::Statement::Variable are not in-scope to its left-hand
        # side. RESTRICTION -- this code does not handle truly
        # pathological stuff like
        # my ( $c, $d ) = qw{ e f };
        # my ( $a, $b ) = my ( $c, $d ) = ( $c, $d );
        _inner_is_defined_by_outer( $inner_elem, $parent )
            and _location_is_in_right_hand_side_of_assignment(
                $parent, $inner_elem )
            and return;
        $parent = $parent->parent()
            or return;
    }

    # We're true if and only if the scope of the outer element contains
    # the inner element.

    return $inner_elem->descendant_of( $parent );

}

# Helper for element_is_in_lexical_scope_after_statement_containing().
# Return true if and only if $outer_elem is a statement that defines
# variables and $inner_elem is actually a variable defined in that
# statement.
sub _inner_is_defined_by_outer {
    my ( $inner_elem, $outer_elem ) = @_;
    $outer_elem->isa( 'PPI::Statement::Variable' )
        and $inner_elem->isa( 'PPI::Token::Symbol' )
        or return;
    my %defines = hashify( $outer_elem->variables() );
    return $defines{$inner_elem->symbol()};
}

# Helper for element_is_in_lexical_scope_after_statement_containing().
# Given that the outer element defines a scope, there are still things
# that are lexically inside it but outside the scope. We return true if
# and only if the inner element is inside the outer element, but not
# inside one of the excluded elements. The cases handled so far:
#   for ----- the list is not part of the scope
#   foreach - the list is not part of the scope

sub _inner_element_is_in_outer_scope_really {
    my ( $inner_elem, $outer_elem ) = @_;
    $outer_elem->scope()
        or return;
    $inner_elem->descendant_of( $outer_elem )
        or return;
    if ( $outer_elem->isa( 'PPI::Statement::Compound' ) ) {
        my $first = $outer_elem->schild( 0 )
            or return;
        if ( { for => 1, foreach => 1 }->{ $first->content() } ) {
            my $next = $first;
            while ( $next = $next->snext_sibling() ) {
                $next->isa( 'PPI::Structure::List' )
                    or next;
                return ! $inner_elem->descendant_of( $next );
            }
        }
    }
    return $TRUE;
}

# Helper for element_is_in_lexical_scope_after_statement_containing().
# Given and element that represents an assignment or assignment-ish
# statement, and a location, return true if the location is to the right
# of the equals sign, and false otherwise (including the case where
# there is no equals sign). Only the leftmost equals is considered. This
# is a restriction.
sub _location_is_in_right_hand_side_of_assignment {
    my ( $elem, $inner_elem ) = @_;
    my $inner_loc = $inner_elem->location();
    my $kid = $elem->schild( 0 );
    while ( $kid ) {
        $kid->isa( 'PPI::Token::Operator' )
            and q{=} eq $kid->content()
            or next;
        my $l = $kid->location();
        $l->[LOCATION_LINE] > $inner_loc->[LOCATION_LINE]
            and return;
        $l->[LOCATION_LINE] == $inner_loc->[LOCATION_LINE]
            and $l->[LOCATION_CHARACTER] >= $inner_loc->[LOCATION_CHARACTER]
            and return;
        return $inner_elem->descendant_of( $elem );
    } continue {
        $kid = $kid->snext_sibling();
    }
    return;
}

# END OF CODE THAT ABSOLUTELY SHOULD NOT BE HERE

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
B<used> inside such constructions B<will> be detected.


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
going to be used as lvalues by the caller. If you wish to declare a
violation in this case, you can add a block like this to your
F<.perlcriticrc> file:

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

=head2 allow_state_in_expression

By default, this policy handles C<state> variables as any other lexical,
and a violation is declared if they appear only in the statement that
declares them.

One might, however, do something like

    state $foo = compute_foo() or do_something_else();

In this case, C<compute_foo()> is called only once, but if it returns a
false value C<do_something_else()> will be executed every time this
statement is encountered.

If you wish to allow such code, you can add a block like this to your
F<.perlcriticrc> file:

    [Variables::ProhibitUnusedVarsStricter]
    allow_state_in_expression = 1

This allows an otherwise-unused state variable if its value appears to
be used in an expression -- that is, if its declaration is followed by a
low-precedence boolean, or one of its ancestors is preceded or followed
by any operator. The latter means that something like

 my $bar = ( state $foo = compute_foo() ) + 42;

will be accepted.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT

Copyright (C) 2012-2020 Thomas R. Wyant, III

=head1 LICENSE

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
