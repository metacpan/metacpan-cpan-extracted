use strict;
use warnings;
package SQL::SplitStatement;

our $VERSION = '1.00023';


use base 'Class::Accessor::Fast';

use Carp qw(croak);
use SQL::SplitStatement::Tokenizer qw(tokenize_sql);
use List::MoreUtils qw(firstval firstidx each_array);
use Regexp::Common qw(delimited);

use constant {
    NEWLINE        => "\n",
    SEMICOLON      => ';',
    DOT            => '.',
    FORWARD_SLASH  => '/',
    QUESTION_MARK  => '?',
    SINGLE_DOLLAR  => '$',
    DOUBLE_DOLLAR  => '$$',
    OPEN_BRACKET   => '(',
    CLOSED_BRACKET => ')',
    
    SEMICOLON_TERMINATOR => 1,
    SLASH_TERMINATOR     => 2,
    CUSTOM_DELIMITER     => 3
};

my $transaction_RE = qr[^(?:
    ;
    |/
    |WORK
    |TRAN
    |TRANSACTION
    |ISOLATION
    |READ
)$]xi;
my $procedural_END_RE = qr/^(?:IF|CASE|LOOP)$/i;
my $terminator_RE = qr[
    ;\s*\n\s*\.\s*\n\s*/\s*\n?
    |;\s*\n\s*/\s*\n?
    |\.\s*\n\s*/\s*\n?
    |\n\s*/\s*\n?
    |;
]x;
my $begin_comment_RE      = qr/^(?:--|\/\*)/;
my $quoted_RE             = $RE{delimited}{ -delim=>q{"'`} };
my $dollar_placeholder_RE = qr/^\$\d+$/;
my $inner_identifier_RE   = qr/[_a-zA-Z][_a-zA-Z0-9]*/;

my $CURSOR_RE             = qr/^CURSOR$/i;
my $DELIMITER_RE          = qr/^DELIMITER$/i;
my $DECLARE_RE            = qr/^DECLARE$/i;
my $PROCEDURE_FUNCTION_RE = qr/^(?:FUNCTION|PROCEDURE)$/i;
my $PACKAGE_RE            = qr/^PACKAGE$/i;
my $BEGIN_RE              = qr/^BEGIN$/i;
my $END_RE                = qr/^END$/i;
my $AS_RE                 = qr/^AS$/i;
my $IS_RE                 = qr/^IS$/i;
my $TYPE_RE               = qr/^TYPE$/i;
my $BODY_RE               = qr/^BODY$/i;
my $DROP_RE               = qr/^DROP$/i;
my $CRUD_RE               = qr/^(?:DELETE|INSERT|SELECT|UPDATE|REPLACE)$/i;

my $GRANT_REVOKE_RE       = qr/^(?:GRANT|REVOKE)$/i;;
my $CREATE_ALTER_RE       = qr/^(?:CREATE|ALTER)$/i;
my $CREATE_REPLACE_RE     = qr/^(?:CREATE|REPLACE)$/i;
my $OR_REPLACE_RE         = qr/^(?:OR|REPLACE)$/i;
my $OR_REPLACE_PACKAGE_RE = qr/^(?:OR|REPLACE|PACKAGE)$/i;

my $pre_identifier_RE = qr/^(?:
    BODY
    |CONSTRAINT
    |CURSOR
    |DECLARE
    |FUNCTION
    |INDEX
    |PACKAGE
    |PROCEDURE
    |REFERENCES
    |TABLE
    |[.,(]
)$/xi;

SQL::SplitStatement->mk_accessors( qw/
    keep_terminators
    keep_extra_spaces
    keep_empty_statements
    keep_comments
    slash_terminates
    _tokens
    _current_statement
    _custom_delimiter
    _terminators
    _tokens_in_custom_delimiter
/);

# keep_terminators alias
sub keep_terminator { shift->keep_terminators(@_) }

sub new {
    my $class = shift;
    my $parameters = @_ > 1 ? { @_ } : $_[0] || {};
    if ( exists $parameters->{keep_terminators} ) {
        croak( q[keep_terminator and keep_terminators can't be both assigned'] )
            if exists $parameters->{keep_terminator}
    }
    elsif ( exists $parameters->{keep_terminator} ) {
        $parameters->{keep_terminators} = delete $parameters->{keep_terminator}
    }
    $parameters->{slash_terminates} = 1
        unless exists $parameters->{slash_terminates};
    $class->SUPER::new( $parameters )
}

sub split {
    my ($self, $code) = @_;
    my ($statements, undef) = $self->split_with_placeholders($code);
    return @{ $statements }
}

sub split_with_placeholders {
    my ($self, $code) = @_;
    
    my @placeholders = ();
    my @statements   = ();
    my $statement_placeholders = 0;
    
    my $inside_block        = 0;
    my $inside_brackets     = 0;
    my $inside_sub          = 0;
    my $inside_is_as        = 0;
    my $inside_cursor       = 0;
    my $inside_is_cursor    = 0;
    my $inside_declare      = 0;
    my $inside_package      = 0;
    my $inside_grant_revoke = 0;
    my $inside_crud         = 0;
    my $extra_end_found     = 0;
    
    my @sub_names    = ();
    my $package_name = '';
    
    my $dollar_quote;
    my $dollar_quote_to_add;
    
    my $prev_token   = '';
    my $prev_keyword = '';
    
    my $custom_delimiter_def_found = 0;
    
    if ( !defined $code ) {
        $code = "\n"
    } else {
        $code .= "\n"
    };
    $self->_tokens( [ tokenize_sql($code) ] );
    $self->_terminators( [] ); # Needed (only) to remove them afterwards
                               # when keep_terminators is false.
    
    $self->_current_statement('');
    
    while ( defined( my $token = shift @{ $self->_tokens } ) ) {
        my $terminator_found = 0;
        
        # Skip this token if it's a comment and we don't want to keep it.
        next if $self->_is_comment($token) && ! $self->keep_comments;
        
        # Append the token to the current statement;
        $self->_add_to_current_statement($token);
        
        # The token is gathered even if it was a space-only token,
        # but in this case we can skip any further analysis.
        next if $token =~ /^\s+$/;
        
        if ( $dollar_quote ) {
            if ( $self->_dollar_quote_close_found($token, $dollar_quote) ) {
                $self->_add_to_current_statement($dollar_quote_to_add);
                undef $dollar_quote;
                # Saving $prev_token not necessary in this case.
                
                $inside_sub = 0; # Silence sub opening before dollar quote.
                @sub_names = ();
                $inside_is_as = 0; # Silence is_as opening before dollar quote.
                $inside_declare = 0;
                
                next
            }
        }
        
        if ( 
            $prev_token =~ $AS_RE
            and !$dollar_quote
            and $dollar_quote = $self->_dollar_quote_open_found($token)
        ) {
            ( $dollar_quote_to_add = $dollar_quote ) =~ s/^\Q$token//;
            $self->_add_to_current_statement($dollar_quote_to_add)
        }
        elsif ( $token =~ $DELIMITER_RE && !$prev_token ) {
            my $tokens_to_shift = $self->_custom_delimiter_def_found;
            $self->_add_to_current_statement(
                join '', splice @{ $self->_tokens }, 0, $tokens_to_shift
            );
            $custom_delimiter_def_found = 1;
            $self->_custom_delimiter(undef)
                if $self->_custom_delimiter eq SEMICOLON
        }
        elsif ( $token eq OPEN_BRACKET ) {
            $inside_brackets++
        }
        elsif ( $token eq CLOSED_BRACKET ) {
            $inside_brackets--
        }
        elsif ( $self->_is_BEGIN_of_block($token, $prev_token) ) {
            $extra_end_found = 0 if $extra_end_found;
            $inside_block++
        }
        elsif ( $token =~ $CREATE_ALTER_RE ) {
            my $next_token = $self->_peek_at_next_significant_token(
                $OR_REPLACE_RE
            );
            if ( $next_token =~ $PACKAGE_RE ) {
                $inside_package = 1;
                $package_name = $self->_peek_at_package_name
            }
        }
        elsif (
            $token =~ $PROCEDURE_FUNCTION_RE
            || $token =~ $BODY_RE && $prev_token =~ $TYPE_RE
        ) {
            if (
                !$inside_block && !$inside_brackets
                && $prev_token !~ $DROP_RE
                && $prev_token !~ $pre_identifier_RE
            ) {
                $inside_sub++;
                $prev_keyword = $token;
                push @sub_names, $self->_peek_at_next_significant_token
            }
        }
        elsif ( $token =~ /$IS_RE|$AS_RE/ ) {
            if (
                $prev_keyword =~ /$PROCEDURE_FUNCTION_RE|$BODY_RE/
                && !$inside_block && $prev_token !~ $pre_identifier_RE
            ) {
                $inside_is_as++;
                $prev_keyword = ''
            }
            
            $inside_is_cursor = 1
                if $inside_declare && $inside_cursor
        }
        elsif ( $token =~ $DECLARE_RE ) {
            # In MySQL a declare can only appear inside a BEGIN ... END block.
            $inside_declare = 1
                if !$inside_block
                && $prev_token !~ $pre_identifier_RE
        }
        elsif ( $token =~ $CURSOR_RE ) {
            $inside_cursor = 1
                if $inside_declare
                && $prev_token !~ $DROP_RE
                && $prev_token !~ $pre_identifier_RE
        }
        elsif ( $token =~ /$GRANT_REVOKE_RE/ ) {
            $inside_grant_revoke = 1 unless $prev_token
        }
        elsif (
            defined ( my $name = $self->_is_END_of_block($token) )
        ) {
            $extra_end_found = 1 if !$inside_block;
            
            $inside_block-- if $inside_block;
            
            if ( !$inside_block ) {
                # $name contains the next (significant) token.
                if ( $name eq SEMICOLON ) {
                    # Keep this order!
                    if ( $inside_sub && $inside_is_as ) {
                        $inside_sub--;
                        $inside_is_as--;
                        pop @sub_names if $inside_sub < @sub_names
                    } elsif ( $inside_declare ) {
                        $inside_declare = 0
                    } elsif ( $inside_package ) {
                        $inside_package = 0;
                        $package_name = ''
                    }
                }
                
                if ( $inside_sub && @sub_names && $name eq $sub_names[-1] ) {
                    $inside_sub--;
                    pop @sub_names if $inside_sub < @sub_names
                }
                
                if ( $inside_package && $name eq $package_name ) {
                    $inside_package = 0;
                    $package_name = ''
                }
            }
        }
        elsif ( $token =~ $CRUD_RE ) {
            $inside_crud = 1
        }
        elsif (
            $inside_crud && (
                my $placeholder_token
                    = $self->_questionmark_placeholder_found($token)
                    || $self->_named_placeholder_found($token)
                    || $self->_dollar_placeholder_found($token)
            )
        ) {
            $statement_placeholders++
                if !$self->_custom_delimiter
                    || $self->_custom_delimiter ne $placeholder_token;
            
# Needed by SQL::Tokenizer pre-0.21
            # The only multi-token placeholder is a dollar placeholder.
#            if ( ( my $token_to_add = $placeholder_token ) =~ s[^\$][] ) {
#                $self->_add_to_current_statement($token_to_add)
#            }
        }
        else {
            $terminator_found = $self->_is_terminator($token);
            
            if (
                $terminator_found && $terminator_found == SEMICOLON_TERMINATOR
                && !$inside_brackets
            ) {
                if ( $inside_sub && !$inside_is_as && !$inside_block ) {
                    # Needed to close PL/SQL sub forward declarations such as:
                    # PROCEDURE proc(number1 NUMBER);
                    $inside_sub--
                }
                
                if ( $inside_declare && $inside_cursor && !$inside_is_cursor ) {
                    # Needed to close CURSOR decl. other than those in PL/SQL
                    # inside a DECLARE;
                    $inside_declare = 0
                }
                
                $inside_crud = 0 if $inside_crud
            }
        }
        
        $prev_token = $token
            if $token =~ /\S/ && ! $self->_is_comment($token);
        
        # If we've just found a new custom DELIMITER definition, we certainly
        # have a new statement (and no terminator).
        unless (
            $custom_delimiter_def_found
            || $terminator_found && $terminator_found == CUSTOM_DELIMITER
        ) {
            # Let's examine any condition that can make us remain in the
            # current statement.
            next if
                !$terminator_found || $dollar_quote || $inside_brackets
                || $self->_custom_delimiter;
            
            next if
                $terminator_found
                && $terminator_found == SEMICOLON_TERMINATOR
                && (
                    $inside_block || $inside_sub
                    || $inside_declare || $inside_package || $inside_crud
                ) && !$inside_grant_revoke && !$extra_end_found
        }
        
        # Whenever we get this far, we have a new statement.
        
        push @statements, $self->_current_statement;
        push @placeholders, $statement_placeholders;
        
        # If $terminator_found == CUSTOM_DELIMITER
        # @{ $self->_terminators } element has already been pushed,
        # so we have to set it only in the case tested below.
        push @{ $self->_terminators }, [ $terminator_found, undef ]
            if (
                $terminator_found == SEMICOLON_TERMINATOR
                || $terminator_found == SLASH_TERMINATOR
            );
        
        $self->_current_statement('');
        $statement_placeholders = 0;
        
        $prev_token   = '';
        $prev_keyword = '';
        
        $inside_brackets     = 0;
        $inside_block        = 0;
        $inside_cursor       = 0;
        $inside_is_cursor    = 0;
        $inside_sub          = 0;
        $inside_is_as        = 0;
        $inside_declare      = 0;
        $inside_package      = 0;
        $inside_grant_revoke = 0;
        $inside_crud         = 0;
        $extra_end_found     = 0;
        @sub_names           = ();
        
        $custom_delimiter_def_found = 0
    }
    
    # Last statement.
    chomp( my $last_statement = $self->_current_statement );
    push @statements, $last_statement;
    push @{ $self->_terminators }, [undef, undef];
    push @placeholders, $statement_placeholders;
    
    my @filtered_statements;
    my @filtered_terminators;
    my @filtered_placeholders;
    
    if ( $self->keep_empty_statements ) {
        @filtered_statements   = @statements;
        @filtered_terminators  = @{ $self->_terminators };
        @filtered_placeholders = @placeholders
    } else {
        my $sp = each_array(
            @statements, @{ $self->_terminators }, @placeholders
        );
        while ( my ($statement, $terminator, $placeholder_num) = $sp->() ) {
            my $only_terminator_RE
                = $terminator->[0] && $terminator->[0] == CUSTOM_DELIMITER
                ? qr/^\s*\Q$terminator->[1]\E?\s*$/
                : qr/^\s*$terminator_RE?\z/;
            unless ( $statement =~ $only_terminator_RE ) {
                push @filtered_statements, $statement;
                push @filtered_terminators, $terminator;
                push @filtered_placeholders, $placeholder_num
            }
        }
    }
    
    unless ( $self->keep_terminators ) {
        for ( my $i = 0; $i < @filtered_statements; $i++ ) {
            my $terminator = $filtered_terminators[$i];
            if ( $terminator->[0] ) {
                if ( $terminator->[0] == CUSTOM_DELIMITER ) {
                    $filtered_statements[$i] =~ s/\Q$terminator->[1]\E$//
                } else {
                    $filtered_statements[$i] =~ s/$terminator_RE$//
                }
            }
        }
    }
    
    unless ( $self->keep_extra_spaces ) {
        s/^\s+|\s+$//g foreach @filtered_statements
    }
    
    return ( \@filtered_statements, \@filtered_placeholders )
}

sub _add_to_current_statement {
    my ($self, $token) = @_;
    $self->_current_statement( $self->_current_statement() . $token )
}

sub _is_comment {
    my ($self, $token) = @_;
    return $token =~ $begin_comment_RE
}

sub _is_BEGIN_of_block {
    my ($self, $token, $prev_token) = @_;
    return 
        $token =~ $BEGIN_RE
        && $prev_token !~ $pre_identifier_RE
        && $self->_peek_at_next_significant_token !~ $transaction_RE
}

sub _is_END_of_block {
    my ($self, $token) = @_;
    my $next_token = $self->_peek_at_next_significant_token;
    
    # Return possible package name.
    if (
        $token =~ $END_RE && (
            !defined($next_token)
            || $next_token !~ $procedural_END_RE
        )
    ) { return defined $next_token ? $next_token : '' }
    
    return
}

sub _dollar_placeholder_found {
    my ($self, $token) = @_;
    
    return $token =~ $dollar_placeholder_RE ? $token : '';

# Needed by SQL::Tokenizer pre-0.21
#    return '' if $token ne SINGLE_DOLLAR;
#    
#    # $token must be: '$'
#    my $tokens = $self->_tokens;
#    
#    return $tokens->[0] =~ /^\d+$/ && $tokens->[1] !~ /^\$/
#        ? $token . shift( @$tokens ) : ''
}

sub _named_placeholder_found {
    my ($self, $token) = @_;
    
    return $token =~ /^:(?:\d+|[_a-z][_a-z\d]*)$/ ? $token : ''
}

sub _questionmark_placeholder_found {
    my ($self, $token) = @_;
    
    return $token eq QUESTION_MARK ? $token : ''
}

sub _dollar_quote_open_found {
    my ($self, $token) = @_;
    
    return '' if $token !~ /^\$/;
    
    # Includes the DOUBLE_DOLLAR case
    return $token if $token =~ /^\$$inner_identifier_RE?\$$/;
#    Used with SQL::Tokenizer pre-0.21
#    return $token if $token eq DOUBLE_DOLLAR;
    
    # $token must be: '$' or '$1', '$2' etc.
    return '' if $token =~ $dollar_placeholder_RE;
    
    # $token must be: '$'
    my $tokens = $self->_tokens;
    
    # False alarm!
    return '' if $tokens->[1] !~ /^\$/;
    
    return $token . shift( @$tokens ) . shift( @$tokens )
        if $tokens->[0] =~ /^$inner_identifier_RE$/
        && $tokens->[1] eq SINGLE_DOLLAR;
    
    # $tokens->[1] must match: /$.+/
    my $quote = $token . shift( @$tokens ) . '$';
    $tokens->[0] = substr $tokens->[0], 1;
    return $quote
}

sub _dollar_quote_close_found {
    my ($self, $token, $dollar_quote) = @_;
    
    return if $token !~ /^\$/;
    return 1 if $token eq $dollar_quote; # $token matches /$.*$/
    
    # $token must be: '$' or '$1', '$2' etc.
    return if $token =~ $dollar_placeholder_RE;
    
    # $token must be: '$'
    my $tokens = $self->_tokens;
    
    # False alarm!
    return if $tokens->[1] !~ /^\$/;
    
    if ( $dollar_quote eq $token . $tokens->[0] . $tokens->[1] ) {
        shift( @$tokens ); shift( @$tokens );
        return 1
    }
    
    # $tokens->[1] must match: /$.+/
    if ( $dollar_quote eq $token . $tokens->[0] . '$' ) {
        shift( @$tokens );
        $tokens->[0] = substr $tokens->[0], 1;
        return 1
    }
    
    return
}

sub _peek_at_package_name {
    shift->_peek_at_next_significant_token(
        qr/$OR_REPLACE_PACKAGE_RE|$BODY_RE/
    )
}

sub _custom_delimiter_def_found {
    my $self = shift;
    
    my $tokens = $self->_tokens;
    
    my $base_index = 0;
    $base_index++ while $tokens->[$base_index] =~ /^\s$/;
    
    my $first_token_in_delimiter = $tokens->[$base_index];
    my $delimiter = '';
    my $tokens_in_delimiter;
    my $tokens_to_shift;
    
    if ( $first_token_in_delimiter =~ $quoted_RE ) {
        # Quoted custom delimiter: it's just a single token (to shift)...
        $tokens_to_shift = $base_index + 1;
        # ... However it can be composed by several tokens
        # (according to SQL::Tokenizer), once removed the quotes.
        $delimiter = substr $first_token_in_delimiter, 1, -1;
        $tokens_in_delimiter =()= tokenize_sql($delimiter)
    } else {
        # Gather an unquoted custom delimiter, which could be composed
        # by several tokens (that's the SQL::Tokenizer behaviour).
        foreach ( $base_index .. $#{ $tokens } ) {
            last if $tokens->[$_] =~ /^\s+$/;
            $delimiter .= $tokens->[$_];
            $tokens_in_delimiter++
        }
        $tokens_to_shift = $base_index + $tokens_in_delimiter
    }
    
    $self->_custom_delimiter($delimiter);
    
    # We've just found a custom delimiter definition,
    # which means that this statement has no (additional) terminator,
    # therefore we won't have to delete anything.
    push @{ $self->_terminators }, [undef, undef];
    
    $self->_tokens_in_custom_delimiter($tokens_in_delimiter);
    
    return $tokens_to_shift
}

sub _is_custom_delimiter {
    my ($self, $token) = @_;
    
    my $tokens = $self->_tokens;
    my @delimiter_tokens
        = splice @{$tokens}, 0, $self->_tokens_in_custom_delimiter() - 1;
    my $lookahead_delimiter = join '', @delimiter_tokens;
    if ( $self->_custom_delimiter eq $token . $lookahead_delimiter ) {
        $self->_add_to_current_statement($lookahead_delimiter);
        push @{ $self->_terminators },
            [ CUSTOM_DELIMITER, $self->_custom_delimiter ];
        return 1
    } else {
        unshift @{$tokens}, @delimiter_tokens;
        return
    }
}

sub _is_terminator {
    my ($self, $token) = @_;
    
    # This is the first test to perform!
    if ( $self->_custom_delimiter ) {
        # If a custom delimiter is currently defined,
        # no other token can terminate a statement.
        return CUSTOM_DELIMITER if $self->_is_custom_delimiter($token);
        
        return
    }
    
    return if $token ne FORWARD_SLASH && $token ne SEMICOLON;
    
    my $tokens = $self->_tokens;
            
    if ( $token eq FORWARD_SLASH ) {
        # Remove the trailing FORWARD_SLASH from the current statement
        chop( my $current_statement = $self->_current_statement );
        
        my $next_token      = $tokens->[0];
        my $next_next_token = $tokens->[1];
        
        if (
            !defined($next_token)
            || $next_token eq NEWLINE
            || $next_token =~ /^\s+$/ && $next_next_token eq NEWLINE
        ) {
            return SLASH_TERMINATOR
                if $current_statement =~ /;\s*\n\s*\z/
                    || $current_statement =~ /\n\s*\.\s*\n\s*\z/;
            
            # Slash with no preceding semicolon or period:
            # this is to be treated as a semicolon terminator...
            my $next_significant_token_idx
                = $self->_next_significant_token_idx;
            # ... provided that it's not a division operator
            # (at least not a blatant one ;-)
            return SEMICOLON_TERMINATOR
                if $self->slash_terminates
                && $current_statement =~ /\n\s*\z/
                && (
                    $next_significant_token_idx == -1
                        ||
                    $tokens->[$next_significant_token_idx] ne OPEN_BRACKET
                    && $tokens->[$next_significant_token_idx] !~ /^\d/
                    && !(
                        $tokens->[$next_significant_token_idx] eq DOT
                        && $tokens->[$next_significant_token_idx + 1] =~ /^\d/
                    )
                )
        }
        
        return
    }
    
    # $token eq SEMICOLON.
    
    my $next_code_portion = '';
    my $i = 0;
    $next_code_portion .= $tokens->[$i++]
        while $i <= 8 && defined $tokens->[$i];
    
    return SEMICOLON_TERMINATOR
        if $token eq SEMICOLON
            && $next_code_portion !~ m#\A\s*\n\s*/\s*$#m
            && $next_code_portion !~ m#\A\s*\n\s*\.\s*\n\s*/\s*$#m;
    
    # there is a FORWARD_SLASH next: let's wait for it to terminate.
    return
}

sub _peek_at_next_significant_token {
    my ($self, $skiptoken_RE) = @_;
    
    my $tokens = $self->_tokens;
    my $next_significant_token = $skiptoken_RE
        ? firstval {
            /\S/ && ! $self->_is_comment($_) && ! /$skiptoken_RE/
        } @{ $tokens }
        : firstval {
            /\S/ && ! $self->_is_comment($_)
        } @{ $tokens };
    
    return $next_significant_token if defined $next_significant_token;
    return ''
}

sub _next_significant_token_idx {
    my ($self, $skiptoken_RE) = @_;
    
    my $tokens = $self->_tokens;
    return $skiptoken_RE
        ? firstidx {
            /\S/ && ! $self->_is_comment($_) && ! /$skiptoken_RE/
        } @{ $tokens }
        : firstidx {
            /\S/ && ! $self->_is_comment($_)
        } @{ $tokens }
}

1;

__END__

=head1 NAME

SQL::SplitStatement - Split any SQL code into atomic statements

=head1 SYNOPSIS

    # Multiple SQL statements in a single string
    my $sql_code = <<'SQL';
    CREATE TABLE parent(a, b, c   , d    );
    CREATE TABLE child (x, y, "w;", "z;z");
    /* C-style comment; */
    CREATE TRIGGER "check;delete;parent;" BEFORE DELETE ON parent WHEN
        EXISTS (SELECT 1 FROM child WHERE old.a = x AND old.b = y)
    BEGIN
        SELECT RAISE(ABORT, 'constraint failed;'); -- Inline SQL comment
    END;
    -- Standalone SQL; comment; with semicolons;
    INSERT INTO parent (a, b, c, d) VALUES ('pippo;', 'pluto;', NULL, NULL);
    SQL
        
    use SQL::SplitStatement;
        
    my $sql_splitter = SQL::SplitStatement->new;
    my @statements = $sql_splitter->split($sql_code);
        
    # @statements now is:
    #
    # (
    #     'CREATE TABLE parent(a, b, c   , d    )',
    #     'CREATE TABLE child (x, y, "w;", "z;z")',
    #     'CREATE TRIGGER "check;delete;parent;" BEFORE DELETE ON parent WHEN
    #     EXISTS (SELECT 1 FROM child WHERE old.a = x AND old.b = y)
    # BEGIN
    #     SELECT RAISE(ABORT, \'constraint failed;\');
    # END',
    #     'INSERT INTO parent (a, b, c, d) VALUES (\'pippo;\', \'pluto;\', NULL, NULL)'
    # )

=head1 DESCRIPTION

This is a simple module which tries to split any SQL code, even including
non-standard extensions (for the details see the L</SUPPORTED DBMSs> section
below), into the atomic statements it is composed of.

The logic used to split the SQL code is more sophisticated than a raw C<split>
on the C<;> (semicolon) character: first, various different statement terminator
I<tokens> are recognized (see below for the list), then this module is able to
correctly handle the presence of said tokens inside identifiers, values,
comments, C<BEGIN ... END> blocks (even nested), I<dollar-quoted> strings, MySQL
custom C<DELIMITER>s, procedural code etc., as (partially) exemplified in the
L</SYNOPSIS> above.

Consider however that this is by no means a validating parser (technically
speaking, it's just a I<context-sensitive tokenizer>). It should rather be seen
as an in-progress I<heuristic> approach, which will gradually improve as test
cases will be reported. This also means that, except for the L</LIMITATIONS>
detailed below, there is no known (to the author) SQL code the most current
release of this module can't correctly split.

The test suite bundled with the distribution (which now includes the popular
I<Sakila> and I<Pagila> sample db schemata, as detailed in the L</SHOWCASE>
section below) should give you an idea of the capabilities of this module

If your atomic statements are to be fed to a DBMS, you are encouraged to use
L<DBIx::MultiStatementDo> instead, which uses this module and also (optionally)
offers automatic transactions support, so that you'll have the I<all-or-nothing>
behavior you would probably want.

=head1 METHODS

=head2 C<new>

=over 4

=item * C<< SQL::SplitStatement->new( %options ) >>

=item * C<< SQL::SplitStatement->new( \%options ) >>

=back

It creates and returns a new SQL::SplitStatement object. It accepts its options
either as a hash or a hashref.

C<new> takes the following Boolean options, which for documentation purposes can
be grouped in two sets: L</Formatting Options> and L</DBMSs Specific Options>.

=head3 Formatting Options

=over 4

=item * C<keep_terminators>

A Boolean option which causes, when set to a false value (which is the default),
the trailing terminator token to be discarded in the returned atomic statements.
When set to a true value, the terminators are kept instead.

The possible terminators (which are treated as such depending on the context)
are:

=over 4

=item * C<;> (the I<semicolon> character);

=item * any string defined by the MySQL C<DELIMITER> command;

=item * an C<;> followed by an C</> (I<forward-slash> character) on its own
line;

=item * an C<;> followed by an C<.> (I<dot> character) on its own line,
followed by an C</> on its own line;

=item * an C</> on its own line regardless of the preceding characters
(only if the C<slash_terminates> option, explained below, is set).

=back

The multi-line terminators above are always treated as a single token, that is
they are discarded (or returned) as a whole (regardless of the
C<slash_terminates> option value).

If your statements are to be fed to a DBMS, you are advised to keep this option
to its default (false) value, since some drivers/DBMSs don't want the terminator
to be present at the end of the (single) statement.

(Note that the last, possibly empty, statement of a given SQL text, never has a
trailing terminator. See below for an example.)

=item * C<keep_terminator>

An alias for the the C<keep_terminators> option explained above.
Note that if C<keep_terminators> and C<keep_terminator> are both passed to
C<new>, an exception is thrown.

=item * C<keep_extra_spaces>

A Boolean option which causes, when set to a false value (which is the default),
the spaces (C<\s>) around the statements to be trimmed.
When set to a true value, these spaces are kept instead.

When C<keep_terminators> is set to false as well, the terminator is discarded
first (regardless of the spaces around it) and the trailing spaces are trimmed
then. This ensures that if C<keep_extra_spaces> is set to false, the returned
statements will never have trailing (nor leading) spaces, regardless of the
C<keep_terminators> value.

=item * C<keep_comments>

A Boolean option which causes, when set to a false value (which is the default),
the comments to be discarded in the returned statements. When set to a true
value, they are kept with the statements instead.

Both SQL and multi-line C-style comments are recognized.

When kept, each comment is returned in the same string with the atomic statement
it belongs to. A comment belongs to a statement if it appears, in the original
SQL code, before the end of that statement and after the terminator of the
previous statement (if it exists), as shown in this pseudo-SQL snippet:

    /* This comment
    will be returned
    together with statement1 */
    
    <statement1>; -- This will go with statement2
                  -- (note the semicolon which closes statement1)
    
    <statement2>
    -- This with statement2 as well

=item * C<keep_empty_statements>

A Boolean option which causes, when set to a false value (which is the default),
the empty statements to be discarded. When set to a true value, the empty
statements are returned instead.

A statement is considered empty when it contains no characters other than the
terminator and space characters (C<\s>).

A statement composed solely of comments is not recognized as empty and may
therefore be returned even when C<keep_empty_statements> is false. To avoid
this, it is sufficient to leave C<keep_comments> to false as well.

Note instead that an empty statement is recognized as such regardless of the
value of the options C<keep_terminators> and C<keep_extra_spaces>.

=back

These options are basically to be kept to their default (false) values,
especially if the atomic statements are to be given to a DBMS.

They are intended mainly for I<cosmetic> reasons, or if you want to count by how
many atomic statements, including the empty ones, your original SQL code was
composed of.

Another situation where they are useful (in the general case necessary, really),
is when you want to retain the ability to verbatim rebuild the original SQL
string from the returned statements:

    my $verbatim_splitter = SQL::SplitStatement->new(
        keep_terminators      => 1,
        keep_extra_spaces     => 1,
        keep_comments         => 1,
        keep_empty_statements => 1
    );
    
    my @verbatim_statements = $verbatim_splitter->split($sql_string);
    
    $sql_string eq join '', @verbatim_statements; # Always true, given the constructor above.

Other than this, again, you are recommended to stick with the defaults.

=head3 DBMSs Specific Options

The same syntactic structure can have different semantics across different SQL
dialects, so sometimes it is necessary to help the parser to make the right
decision. This is the function of these options.

=over 4

=item * C<slash_terminates>

A Boolean option which causes, when set to a true value (which is the default),
a C</> (I<forward-slash>) on its own line, even without a preceding semicolon,
to be admitted as a (possible) terminator.

If set to false, a forward-slash on its own line is treated as a statement
terminator only if preceded by a semicolon or by a dot and a semicolon.

If you are dealing with Oracle's SQL, you should let this option set, since a
slash (alone, without a preceding semicolon) is sometimes used as a terminator,
as it is permitted by SQL*Plus (on non-I<block> statements).

With SQL dialects other than Oracle, there is the (theoretical) possibility that
a slash on its own line can pass the additional checks and be considered a
terminator (while it shouldn't). This chance should be really tiny (it has never
been observed in real world code indeed). Though negligible, by setting this
option to false that risk can anyway be ruled out.

=back

=head2 C<split>

=over 4

=item * C<< $sql_splitter->split( $sql_string ) >>

=back

This is the method which actually splits the SQL code into its atomic
components.

It returns a list containing the atomic statements, in the same order they
appear in the original SQL code. The atomic statements are returned according to
the options explained above.

Note that, as mentioned above, an SQL string which terminates with a terminator
token (for example a semicolon), contains a trailing empty statement: this is
correct and it is treated accordingly (if C<keep_empty_statements> is set to a
true value):

    my $sql_splitter = SQL::SplitStatement->new(
        keep_empty_statements => 1
    );
    
    my @statements = $sql_splitter->split( 'SELECT 1;' );
    
    print 'The SQL code contains ' . scalar(@statements) . ' statements.';
    # The SQL code contains 2 statements.

=head2 C<split_with_placeholders>

=over 4

=item * C<< $sql_splitter->split_with_placeholders( $sql_string ) >>

=back

It works exactly as the C<split> method explained above, except that it returns
also a list of integers, each of which is the number of the I<placeholders>
contained in the corresponding atomic statement.

More precisely, its return value is a list of two elements, the first of which
is a reference to the list of the atomic statements exactly as returned by the
C<split> method, while the second is a reference to the list of the number of
placeholders as explained above.

Here is an example:

    # 4 statements (valid SQLite SQL)
    my $sql_code = <<'SQL';
    CREATE TABLE state (id, name);
    INSERT INTO  state (id, name) VALUES (?, ?);
    CREATE TABLE city  (id, name, state_id);
    INSERT INTO  city  (id, name, state_id) VALUES (?, ?, ?)
    SQL
        
    my $splitter = SQL::SplitStatement->new;
        
    my ( $statements, $placeholders )
        = $splitter->split_with_placeholders( $sql_code );
        
    # $placeholders now is: [0, 2, 0, 3]

where the returned C<$placeholders> list(ref) is to be read as follows: the
first statement contains 0 placeholders, the second 2, the third 0 and the
fourth 3.

The recognized placeholders are:

=over 4

=item * I<question mark> placeholders, represented by the C<?> character;

=item * I<dollar sign numbered> placeholders, represented by the
C<$1, $2, ..., $n> strings;

=item * I<named parameters>, such as C<:foo>, C<:bar>, C<:baz> etc.

=back

=head2 C<keep_terminators>

=over 4

=item * C<< $sql_splitter->keep_terminators >>

=item * C<< $sql_splitter->keep_terminators( $boolean ) >>

Getter/setter method for the C<keep_terminators> option explained above.

=back

=head2 C<keep_terminator>

An alias for the C<keep_terminators> method explained above.

=head2 C<keep_extra_spaces>

=over 4

=item * C<< $sql_splitter->keep_extra_spaces >>

=item * C<< $sql_splitter->keep_extra_spaces( $boolean ) >>

Getter/setter method for the C<keep_extra_spaces> option explained above.

=back

=head2 C<keep_comments>

=over 4

=item * C<< $sql_splitter->keep_comments >>

=item * C<< $sql_splitter->keep_comments( $boolean ) >>

Getter/setter method for the C<keep_comments> option explained above.

=back

=head2 C<keep_empty_statements>

=over 4

=item * C<< $sql_splitter->keep_empty_statements >>

=item * C<< $sql_splitter->keep_empty_statements( $boolean ) >>

Getter/setter method for the C<keep_empty_statements> option explained above.

=back

=head2 C<slash_terminates>

=over 4

=item * C<< $sql_splitter->slash_terminates >>

=item * C<< $sql_splitter->slash_terminates( $boolean ) >>

Getter/setter method for the C<slash_terminates> option explained above.

=back

=head1 SUPPORTED DBMSs

SQL::SplitStatement aims to cover the widest possible range of DBMSs, SQL
dialects and extensions (even proprietary), in a (nearly) fully transparent way
for the user.

Currently it has been tested mainly on SQLite, PostgreSQL, MySQL and Oracle.

=head2 Procedural Extensions

Procedural code is by far the most complex to handle.

Currently any block of code which start with C<FUNCTION>, C<PROCEDURE>,
C<DECLARE>, C<CREATE> or C<CALL> is correctly recognized, as well as
I<anonymous> C<BEGIN ... END> blocks, I<dollar quoted> blocks and blocks
delimited by a C<DELIMITER>-defined I<custom terminator>, therefore a wide range
of procedural extensions should be handled correctly. However, only PL/SQL,
PL/PgSQL and MySQL code has been tested so far.

If you need also other procedural languages to be recognized, please let me know
(possibly with some test cases).

=head1 LIMITATIONS

Bound to be plenty, given the heuristic nature of this module (and its ambitious
goals). However, no limitations are currently known.

Please report any problematic test case.

=head2 Non-limitations

To be split correctly, the given input must, in general, be syntactically valid
SQL. For example, an unbalanced C<BEGIN> or a misspelled keyword could, under
certain circumstances, confuse the parser and make it trip over the next
statement terminator, thus returning non-split statements.
This should not be seen as a limitation though, as the original (invalid) SQL
code would have been unusable anyway (remember that this is NOT a validating
parser!)

=head1 SHOWCASE

To test the capabilities of this module, you can run it
(or rather run L<sql-split>) on the files F<t/data/sakila-schema.sql> and
F<t/data/pagila-schema.sql> included in the distribution, which contain two
quite large and complex I<real world> db schemata, for MySQL and PostgreSQL
respectively.

For more information:

=over 4

=item * Sakila db: L<http://dev.mysql.com/doc/sakila/en/sakila.html>

=item * Pagila db: L<http://pgfoundry.org/projects/dbsamples>

=back

=head1 DEPENDENCIES

SQL::SplitStatement depends on the following modules:

=over 4

=item * L<Carp>

=item * L<Class::Accessor::Fast>

=item * L<List::MoreUtils>

=item * L<Regexp::Common>

=item * L<SQL::Tokenizer> 0.22 or newer

=back

=head1 AUTHOR

Emanuele Zeppieri, C<< <emazep@cpan.org> >>

=head1 BUGS

No known bugs.

Please report any bugs or feature requests to
C<bug-sql-SplitStatement at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SQL-SplitStatement>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command:

    perldoc SQL::SplitStatement

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SQL-SplitStatement>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SQL-SplitStatement>

=item * On MetaCPAN

L<https://metacpan.org/pod/SQL::SplitStatement/>

=back

=head1 ACKNOWLEDGEMENTS

Igor Sutton for his excellent L<SQL::Tokenizer>, which made writing
this module a joke.

=head1 SEE ALSO

=over 4

=item * L<DBIx::MultiStatementDo>

=item * L<sql-split>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2011 Emanuele Zeppieri.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation, or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
