package Switch::Back;

use 5.036;
our $VERSION = '0.000005';

use experimental qw< builtin refaliasing try >;
use builtin      qw< true false blessed created_as_number >;
use Scalar::Util qw < looks_like_number >;

use Multi::Dispatch;
use PPR::X;
use Carp qw< croak carp >;

# Useful patterns...
my $OWS; BEGIN { $OWS = q{(?>(?&PerlOWS))}; }
my $CONTAINER_VARIABLE;
BEGIN { $CONTAINER_VARIABLE
    = qr{ \A (?>             (?&PerlVariableArray) | (?&PerlVariableHash)
             |   my $OWS (?> (?&PerlVariableArray) | (?&PerlVariableHash) ) $OWS = .*
             )
          \z $PPR::GRAMMAR
      }xms;
}
my $ARRAY_SLICE;
BEGIN { $ARRAY_SLICE
    = qr{ \A (?>         (?&PerlArrayAccess)
             |   my $OWS (?&PerlArrayAccess) $OWS = .*
             )
          \z $PPR::GRAMMAR
      }xms;
}
my $HASH_SLICE;
BEGIN { $HASH_SLICE
    = qr{ \A (?>         (?&PerlHashAccess)
             |   my $OWS (?&PerlHashAccess) $OWS = .*
             )
          \z $PPR::GRAMMAR
      }xms;
}
my $SMARTMATCHABLE;
BEGIN { $SMARTMATCHABLE
    = qr{ \A
             (?> \\ $OWS   (?&PerlVariableArray)
             |   \\ $OWS   (?&PerlVariableHash)
             |   \\ $OWS & (?&PerlQualifiedIdentifier)
             |             (?&PerlPrefixUnaryOperator) (?&PerlScalarAccess)
             |             (?&PerlScalarAccess) (?&PerlPostfixUnaryOperator)?+
             |             (?&PerlAnonymousArray)
             |             (?&PerlAnonymousHash)
             |             (?&PerlAnonymousSubroutine)
             |             (?&PerlString)
             |             (?&PerlNumber)
             |             (?&PerlQuotelikeQR)
             |             (?&PerlBareword)
             |             undef
             )
          $OWS
          \z $PPR::GRAMMAR
      }xms;
}

# Install the new keywords, functions, and smartmatching...
sub import {
    # Export replacement keywords...
    use Keyword::Simple;
    Keyword::Simple::define given    => \&_given_impl;
    Keyword::Simple::define when     => \&_when_impl;
    Keyword::Simple::define default  => \&_default_impl;

    # Outside a given a 'break' is an error; outside a when a 'continue' is too...
    {
        no strict 'refs';
        no warnings qw< redefine >;
        *{caller.'::break'}     = \&break;
        *{caller.'::continue'}  = \&continue;
    }

    # Export smartmatch()...
    multi smartmatch :export;
}

# Detect and rewrite "pure" given blocks (recursively if necessary)...
sub _pure_given_impl { my ($source) = @_;

    # Recognize a valid "pure" given block (i.e. containing only when and default blocks)...
    state @pure_statements;
    @pure_statements = ();
    state $VALIDATE_PURE_GIVEN = qr{
        \A  given (?<GIVEN>  (?<ws_post_kw>   $OWS    )  \(
                             (?<ws_pre_expr>  $OWS    )  (?>(?<EXPR> (?&PerlExpression)))
                             (?<ws_pre_close> $OWS    )  \)
                             (?<ws_pre_block> $OWS \{ $OWS )  (?>(?<BLOCK>  (?&PureBlock)  ))  \}
            )
            (?>(?<TRAILING_CODE>  .*  ))

            (?(DEFINE)
                (?<PureBlock>    # Distinguish "when", "default", and "given" from other statements...
                    (?:
                        when (?<WHENOPEN> $OWS \( $OWS )
                             (?<WHENEXPR> (?>(?&PerlExpression)))
                             (?<WHENCLOSE> $OWS \) $OWS )
                             (?>(?<WHENBLOCK> (?&PerlBlock) ))
                             (?<WHENPOST> $OWS )
                             (?{ push @pure_statements, { TYPE => 'when', %+ }; })
                    |
                        default (?<DEFPRE>  $OWS )
                                (?>(?<DEFBLOCK> (?&PerlBlock) ))
                                (?<DEFPOST> $OWS )
                            (?{ push @pure_statements, { TYPE => 'default', %+ }; })
                    |
                        (?<NESTEDGIVEN>
                            given \b $OWS  \(
                                (?: $OWS (?> any | all | none )  $OWS  => )?+
                                    $OWS (?>(?<EXPR> (?>(?&PerlExpression))))
                                    $OWS \)
                                    $OWS (?>(?<BLOCK>  (?&NestedPureBlock)  )) $OWS
                        )
                            (?{ push @pure_statements, { TYPE => 'given', %+ }; })
                    |
                        (?! $OWS (?> when | default ) \b )
                        (?>(?<STATEMENT> (?&PerlStatement)  $OWS ))
                            (?{ push @pure_statements, { TYPE => 'other', %+ }; })
                    )*+

                    # Possible trailing whitespace at the end of the block...
                    ( (?>(?<STATEMENT> (?&PerlNWS) ))
                        (?{ push @pure_statements, { TYPE => 'other', %+ }; })
                    )?+
                )
                (?<NestedPureBlock>    # Non-capturing version of the above
                    \{  $OWS
                    (?:
                        when $OWS \( (?: $OWS (?> any | all | none ) $OWS => )?+
                                         $OWS (?>(?&PerlExpression))
                             $OWS \) $OWS (?>(?&PerlBlock))  $OWS
                    |
                        default $OWS (?>(?&PerlBlock))  $OWS
                    |
                        given \b $OWS \( (?: $OWS (?> any | all | none )  $OWS  => )?+
                                              $OWS (?>(?&PerlExpression))
                                 $OWS \)
                                 $OWS (?>(?&NestedPureBlock)) $OWS
                    |
                        (?! when \b | default | given \b ) (?>(?&PerlStatement)) $OWS
                    )*+
                    \}
                )
                (?<PerlBuiltinFunction>
                    # Pure given can't have a continue or break or goto in it...
                    (?: continue | break | goto ) \b (*COMMIT)(*FAIL)
                |
                    (?&PerlStdBuiltinFunction)
                )
                (?<PerlStatementModifier>
                    # "Pure" given can't have a postfix "when" modifier in it...
                    (?> if | for(?:each)?+ | while | unless | until | when (*COMMIT)(*FAIL) )
                    \b
                    (?>(?&PerlOWS))
                    (?&PerlExpression)
                ) # End of rule (?<PerlStatementModifier>)
            )
            $PPR::X::GRAMMAR
    }xms;

    # Generate an optimized given/when implementation if the given is "pure"...
    no warnings 'once';
    if ($source =~ $VALIDATE_PURE_GIVEN) {
        my %matched = %+;
        my $nesting_depth     = 0;
        my $after_a_statement = 0;

        return
              "if (1) $matched{ws_post_kw} { local *_ = $matched{ws_pre_expr} \\scalar($matched{EXPR}); $matched{ws_pre_close} if(0) $matched{ws_pre_block} }"
            . join("", map {
                my $PREFIX = $after_a_statement ? 'if(0){}' : q{};
                if ($_->{TYPE} eq 'when') {
                    my $BLOCK = $_->{WHENBLOCK};
                    $after_a_statement = 0;
                      "$PREFIX elsif $_->{WHENOPEN}" . _apply_when_magic($_->{WHENEXPR}) . " $_->{WHENCLOSE} $BLOCK $_->{WHENPOST}"
                }
                elsif ($_->{TYPE} eq 'default') {
                    $after_a_statement = 0;
                    "$PREFIX elsif (1) $_->{DEFPRE} $_->{DEFBLOCK} $_->{DEFPOST}"
                }
                elsif ($_->{TYPE} eq 'given') {
                    my $nested = _pure_given_impl($_->{NESTEDGIVEN});
                    if ($after_a_statement) {
                        $nested;
                    }
                    else {
                        $after_a_statement = 1;
                        $nesting_depth++;
                        "else { $nested ";
                    }
                }
                else { # Must be a regular statement...
                    if ($after_a_statement) {
                        $_->{STATEMENT};
                    }
                    else {
                        $after_a_statement = 1;
                        $nesting_depth++;
                        "else { $_->{STATEMENT}";
                    }
                }
              } @{[@pure_statements]} )
            . (!$after_a_statement ? "else{}" : q{})
            . ('}' x $nesting_depth)
            . "}$matched{TRAILING_CODE}";
    }

    # Otherwise, fail...
    return;
}

# Implement "given" keyword...
sub _given_impl { my ($source_ref) = @_;  # Has to be this way because of code blocks in regex

    # First try the "pure" approach (only works on a limited selection of "given" blocks)...
    my $REPLACEMENT_CODE = _pure_given_impl('given ' . ${$source_ref});

    # Otherwise recognize a valid general-purpose given block (with a single scalar argument)...
    if (!defined $REPLACEMENT_CODE) {

        # Recognize a valid given block (with a single scalar argument)...
        state $VALIDATE_GIVEN = qr{
            \A  (?<GIVEN> $OWS  \(
                    $OWS  (?>(?<EXPR> (?&PerlExpression)))
                    $OWS  \)
                    (?>
                        $OWS  (?>(?<BLOCK>  (?&PerlBlock)  ))
                    |
                        (?<INVALID_BLOCK>)
                    )
                )
                (?>(?<TRAILING_CODE>  .*  ))
                $PPR::GRAMMAR
        }xms;
        ${$source_ref} =~ $VALIDATE_GIVEN;

        # Extract components...
        my %result = %+;

        # It's a valid "given"...
        if (exists $result{BLOCK}) {
            my ($GIVEN, $EXPR, $BLOCK, $TRAILING_CODE) = @result{qw< GIVEN EXPR BLOCK TRAILING_CODE >};

            # Augment the block with control flow and other necessary components...
            $BLOCK = _augment_block(given => "$BLOCK");

            # Topicalize the "given" argument...
            substr($BLOCK, 1, 0) = qq{local *_ = \\($EXPR);};

            # Implement "given" as a (trivial) "if" block...
            $REPLACEMENT_CODE = qq{ if (1) $BLOCK };

            # At what line should the "given" end???
            my $end_line = (caller)[2] + $GIVEN =~ tr/\n//;

            # Append the trailing code (at the right line number)...
            $REPLACEMENT_CODE .= "\n#line $end_line\n$TRAILING_CODE";
        }

        # Otherwise, report the error in context...
        elsif (exists $result{EXPR}) {
            $REPLACEMENT_CODE = q{ BEGIN { warn  q{Invalid code somewhere in "given" block starting} } }
                            . q{ BEGIN { warn qq{(Note: the error reported below may be misleading)\\n}}}
                            . qq{ if ${$source_ref} };
        }
    }

    # Install standard code in place of keyword...
    ${$source_ref} = $REPLACEMENT_CODE;
}

# Implementation of "when" keyword...
sub _when_impl ($source_ref) {
    my ($REPLACEMENT_CODE, $TRAILING_CODE);

    # What various kinds of "when" look like...
    state $WHEN_CLASSIFIER = qr{
            \A  (?<WHEN> $OWS
                         (        \(
                             $OWS (?<EXPR> (?&PerlExpression))
                             $OWS \)
                             $OWS (?>(?<BLOCK> (?&PerlBlock) )
                                  |  (?<INVALID_BLOCK>)
                                  )
                         |
                             (?>(?<MODIFIER> (?&PerlCommaList)))
                             (?>(?&PerlOWSOrEND)) (?> ; | (?= \} | \z ))
                         |
                             (?<INCOMPREHENSIBLE> \N{0,20} )
                         )
                )
                (?<TRAILING_CODE> .* )
            $PPR::GRAMMAR
    }xms;

    # Classify the type of "when" we're processing...
    ${$source_ref} =~ $WHEN_CLASSIFIER;
    my %matched = %+;

    # Handle a valid when block (with a list of scalar arguments)...
    if (defined $matched{BLOCK} && defined $matched{EXPR}) {
        my ($WHEN, $EXPR, $BLOCK, $TRAILING_CODE)
            = @matched{qw< WHEN EXPR BLOCK TRAILING_CODE>};

        # Augment the block with control flow and other necessary components...
        $BLOCK = _augment_block(when => "$BLOCK");

        # Implement the boolean operator magic...
        $EXPR = _apply_when_magic($EXPR);

        # Implement the "when" as an "if"...
        $REPLACEMENT_CODE = qq{if(1){local \$Switch::Back::when_value = ($EXPR); if(1){if (\$Switch::Back::when_value) $BLOCK }}};

        # At what line should the "when" end???
        my $end_line = (caller)[2] + $WHEN =~ tr/\n//;

        # Append the trailing code (at the right line number)...
        $REPLACEMENT_CODE .= "\n#line $end_line\n$TRAILING_CODE";
    }

    # Otherwise, reject the "when" with extreme prejudice...
    elsif (defined $matched{MODIFIER}) {
        $REPLACEMENT_CODE = qq{ BEGIN { die q{Can't specify postfix "when" modifier outside a "given"} } };
    }
    elsif (exists $matched{INVALID_BLOCK}) {
        $REPLACEMENT_CODE = qq{ BEGIN { warn  q{Invalid code block in "when"} } }
                          . qq{ BEGIN { warn qq{(Note: the error reported below may be misleading)\\n} } }
                          . qq{ if ${$source_ref} };
    }
    else {
        $REPLACEMENT_CODE = qq{ BEGIN { die q{Incomprehensible "when" (near: $matched{INCOMPREHENSIBLE})} } };
    }

    # Install code implementing keyword behaviour...
    ${$source_ref} = $REPLACEMENT_CODE;
}

sub _default_impl ($source_ref) {
    state $DEFAULT_CLASSIFIER = qr{
            (?<DEFAULT> $OWS (?>(?<BLOCK> (?&PerlBlock) )) )
            (?<TRAILING_CODE> .* )
            $PPR::GRAMMAR
    }xms;

    # Verify that we match the syntax for a "default" block...
    ${$source_ref} =~ $DEFAULT_CLASSIFIER;
    my %matched = %+;

    # Implement the "default" block...
    if (defined $matched{BLOCK}) {
        # Install the necessary extras...
        my $BLOCK = _augment_block(default => $matched{BLOCK});

        # Build the implementation of the "default"...
        my $REPLACEMENT_CODE = qq{ if (1) $BLOCK };

        # At what line should the "default" end???
        my $end_line = (caller)[2] + $matched{DEFAULT} =~ tr/\n//;

        # Append the trailing code (at the right line number)...
        ${$source_ref} = "$REPLACEMENT_CODE\n#line $end_line\n$matched{TRAILING_CODE}";
    }

    # Report the error...
    else {
        ${$source_ref}
            = qq{ BEGIN { die q{Incomprehensible "default" (near: $matched{INCOMPREHENSIBLE})} } };
    }
}

# Implement the "continue" command...
sub continue () {
    # Which "when" block are we in???
    my $AFTERWHEN = (caller 0)[10]{'Switch::Back/Afterwhen'};

    # Jump out of it, if possible...
    no warnings;
    eval { goto $AFTERWHEN };

    # If not possible, that's fatal...
    croak q{Can't "continue" outside a "when" or "default"};
}

# Implement the "break" command...
sub break () {
    # Which "given" block are we in???
    my $AFTERGIVEN = (caller 0)[10]{'Switch::Back/Aftergiven'};

    # Jump out of it, if possible...
    no warnings;
    eval { goto $AFTERGIVEN };

    # If we weren't in a "given", can we jump out of a surrounding loop???
    eval { next };

    # Otherwise, the "break" was illegal and must be punished...
    croak q{Can't "break" outside a "given"};
}


# Insert unique identifying information into a "given"/"when"/"default" source code block...
sub _augment_block ($TYPE, $BLOCK) {
        # Unique identifiers for each type of block...
        state %ID;

        # Who and what is this block???
        my $KIND = $TYPE eq 'default' ? "when" : $TYPE;
        my $NAME = "After$KIND";
        my $ID   = $NAME . ++$ID{$KIND};

        # Give each block a unique name (uses refaliasing to create a lexical constant)...
        substr($BLOCK, 1,0)
            = qq{ BEGIN { \$^H{'Switch::Back/$NAME'} = '$ID'; } };

        # A when block auto-breaks at the end of its block...
        if ($KIND eq 'when') {
            my $AFTERGIVEN = $^H{'Switch::Back/Aftergiven'};
            substr($BLOCK,-1,0)
                = ';'
                . (defined($AFTERGIVEN) ? qq{eval { no warnings; goto $AFTERGIVEN } || } : q{})
                . qq{eval { no warnings; next } || die q{Can't "$TYPE" outside a topicalizer} };
        }

        # Given blocks must to pre-convert postfix "when" modifiers (which can't be keyworded)...
        # and must also preprocess "continue" to a unpunned name...
        elsif ($KIND eq 'given') {
            $BLOCK = _convert_postfix_whens($BLOCK);
        }

        # Return identified block...
        return "$BLOCK $ID:;";
}

# Identify and pre-convert "EXPR when EXPR" syntax...
sub _convert_postfix_whens ($BLOCK) {
    # Track locations of "when" modifiers in the block's source...
    my @target_pos;

    # Extract those locations, whenever a statement has a "when" modifier...
    $BLOCK =~ m{
        \{ (?&PerlStatementSequence) \}

        (?(DEFINE)
            (?<PerlStatement>
                (?>
                    (?>(?&PerlPodSequence))
                    (?: (?>(?&PerlLabel)) (?&PerlOWSOrEND) )?+
                    (?>(?&PerlPodSequence))

                    (?> (?&PerlKeyword)
                    |   (?&PerlSubroutineDeclaration)
                    |   (?&PerlMethodDeclaration)
                    |   (?&PerlUseStatement)
                    |   (?&PerlPackageDeclaration)
                    |   (?&PerlClassDeclaration)
                    |   (?&PerlFieldDeclaration)
                    |   (?&PerlControlBlock)
                    |   (?&PerlFormat)
                    |
                        # POSTFIX when HAS TO BE REWRITTEN BEFORE OTHER POSTFIX MODIFIERS ARE MATCHED...
                        (?<MATCH>
                            (?<EXPR> (?>(?&PerlExpression))    (?>(?&PerlOWS))      )
                                     (?= when \b )
                            (?<MOD>  (?&PerlStatementModifier) (?>(?&PerlOWSOrEND)) )
                            (?<END>  (?> ; | (?= \} | \z ))                         )
                        )
                        (?{ my $len = length($+{MATCH});
                            unshift @target_pos, {
                                expr        => $+{EXPR},
                                mod         => substr($+{MOD},4),
                                end         => $+{END},
                                from        => pos() - $len,
                                len         => $len,
                            }
                        })
                    |
                        (?>(?&PerlExpression))          (?>(?&PerlOWS))
                        (?&PerlStatementModifier)?+     (?>(?&PerlOWSOrEND))
                        (?> ; | (?= \} | \z ))
                    |   (?&PerlBlock)
                    |   ;
                    )
                | # A yada-yada...
                    \.\.\. (?>(?&PerlOWSOrEND))
                    (?> ; | (?= \} | \z ))

                | # Just a label...
                    (?>(?&PerlLabel)) (?>(?&PerlOWSOrEND))
                    (?> ; | (?= \} | \z ))

                | # Just an empty statement...
                    (?>(?&PerlOWS)) ;
                )
            )
        )
        $PPR::X::GRAMMAR
    }xms;

    # Replace each postfix "when"...
    for my $pos (@target_pos) {
        # Unique ID for the "when" (needed by continue())...
        state $ID; $ID++;

        # Convert postfix "when" to a postfix "if" (preserving Afterwhen info for continue())...
        substr($BLOCK, $pos->{from}, $pos->{len})
            = "BEGIN { \$^H{'Switch::Back/Afterwhenprev'} = \$^H{'Switch::Back/Afterwhen'};"
            . "        \$^H{'Switch::Back/Afterwhen'} = 'Afterpostfixwhen$ID'; }"
            . "$pos->{expr}, break if " . _apply_when_magic($pos->{mod})
            . ";Afterpostfixwhen$ID:"
            . "BEGIN { \$^H{'Switch::Back/Afterwhen'} = \$^H{'Switch::Back/Afterwhenprev'}; }"
            . $pos->{end};
    }

    return $BLOCK;
}

# Change the target expression of a "when" to implement all the magic behaviours...
sub _apply_when_magic ($EXPR) {
    # Reduce the expression to what the compiler would see...
    $EXPR = _simplify_expr($EXPR);

    # Split on low-precedence or...
    my @low_disj = grep { defined }
                   $EXPR =~ m{ (                 (?>(?&PerlLowPrecedenceNotExpression))
                                (?:
                                    (?>(?&PerlOWS)) and
                                    (?>(?&PerlOWS)) (?&PerlLowPrecedenceNotExpression)
                                )*+
                               )
                               (?>(?&PerlOWS))  (?: or | \z )  (?>(?&PerlOWS))

                               (?(DEFINE)
                                    (?<PerlCommaList>
                                                                (?>(?&PerlAssignment))
                                        (?:
                                            (?: (?>(?&PerlOWS)) (?>(?&PerlComma))  )++
                                                (?>(?&PerlOWS)) (?>(?&PerlAssignment))
                                        )*+
                                            (?: (?>(?&PerlOWS)) (?>(?&PerlComma)) )*+
                                    ) # End of rule (?<PerlCommaList>)
                               )

                               $PPR::GRAMMAR }gxms;

    # If expression is a low-precedence or, apply any appropriate magic...
    if (@low_disj > 1) {
        # If the left-most operand isn't smartmatchable, the expression as a whole isn't,
        # so just return it...
        my $low_lhs   = shift @low_disj;
        my $magic_lhs = _apply_low_conj_magic($low_lhs);
        if ($low_lhs eq $magic_lhs) {
            return $EXPR;
        }

        # Otherwise, every operand has magic applied to it...
        else {
            return join ' or ', $magic_lhs, map { _apply_low_conj_magic($_) } @low_disj;
        }
    }

    # Otherwise, see if it's a low-precedence conjunction...
    return _apply_low_conj_magic($EXPR);
}

sub _apply_low_conj_magic ($EXPR) {
    # Split on low-precedence and...
    my @low_conj = grep { defined }
                   $EXPR =~ m{ ( (?>(?&PerlLowPrecedenceNotExpression)) )
                               (?>(?&PerlOWS))  (?: and | \z )  (?>(?&PerlOWS))

                               (?(DEFINE)
                                    (?<PerlCommaList>
                                                                (?>(?&PerlAssignment))
                                        (?:
                                            (?: (?>(?&PerlOWS)) (?>(?&PerlComma))  )++
                                                (?>(?&PerlOWS)) (?>(?&PerlAssignment))
                                        )*+
                                            (?: (?>(?&PerlOWS)) (?>(?&PerlComma)) )*+
                                    ) # End of rule (?<PerlCommaList>)
                               )

                               $PPR::GRAMMAR }gxms;

    # If expression is a low-precedence and, apply any appropriate magic...
    if (@low_conj > 1) {
        # Every operand must be recursively magical, or none of them are...
        my @magic_expr;
        for my $next_operand (@low_conj) {
            my $magic_operand = _apply_high_disj_magic($next_operand);

            # If any operand isn't smartmatchable, the whole expr isn't magical,
            # so just smartmatch the entire expression...
            if ($magic_operand eq $next_operand) {
                return $EXPR;
            }

            # Otherwise, accumulate the magic...
            push @magic_expr, $magic_operand;
        }
        return join " and ", @magic_expr;
    }

    # Otherwise, see if it's a high-precedence disjunction...
    return _apply_high_disj_magic($EXPR);
}

sub _apply_high_disj_magic ($EXPR) {
    # Split on high-precedence or...
    my @high_disj = grep { defined }
                   $EXPR =~ m{ ( (?>(?&PerlBinaryExpression)) )
                               (?>(?&PerlOWS))  ( \|\| | // | \z )  (?>(?&PerlOWS))

                               (?(DEFINE)
                                    (?<PerlInfixBinaryOperator>
                                        (?! \|\| | // ) (?&PerlStdInfixBinaryOperator)
                                    )
                               )
                               $PPR::X::GRAMMAR
                           }gxms;

    # If expression is a high-precedence || or //, apply any appropriate magic...
    if (@high_disj > 1) {
        # If the left-most operand isn't smartmatchable, the expression as a whole isn't,
        # so just return it...
        my $high_lhs    = shift @high_disj;
        my $magic_expr = _apply_high_conj_magic($high_lhs);
        if ($high_lhs eq $magic_expr) {
            return $EXPR;
        }

        # Otherwise, every operand has magic applied to it...
        else {
            while (@high_disj > 1) {
                my $next_operator = shift @high_disj;
                my $next_operand  = shift @high_disj;
                $magic_expr .= " $next_operator " . _apply_high_conj_magic($next_operand);
            }
            return $magic_expr;
        }
    }

    # Otherwise, see if it's a high-precedence conjunction...
    return _apply_high_conj_magic($EXPR);
}

sub _apply_high_conj_magic ($EXPR) {
    # Split on high-precedence &&...
    my @high_conj = grep { defined }
                   $EXPR =~ m{ ( (?>(?&PerlBinaryExpression)) )
                               (?>(?&PerlOWS))  (?: && | \z )  (?>(?&PerlOWS))

                               (?(DEFINE)
                                    (?<PerlInfixBinaryOperator>
                                        (?! && ) (?&PerlStdInfixBinaryOperator)
                                    )
                               )
                               $PPR::X::GRAMMAR
                           }gxms;

    # If expression is a high-precedence &&, apply any appropriate magic...
    if (@high_conj > 1) {
        # Every operand must be recursively smartmatchable, or none of them are...
        my @magic_expr;
        for my $next_operand (@high_conj) {
            my $magic_operand = _apply_term_magic($next_operand);

            # If any operand isn't smartmatchable, the whole expr isn't magical,
            # so just treat the entire expression as a boolean expression...
            if ($magic_operand eq $next_operand) {
                return $EXPR;
            }

            # Otherwise, accumulate the magic...
            push @magic_expr, $magic_operand;
        }
        return join " && ", @magic_expr;
    }

    # Otherwise, see if it's a magical term...
    return _apply_term_magic($EXPR);
}

# Detect whether a term in a "when" expression is magical and adjust it accordingly...
sub _apply_term_magic ($EXPR) {

    # An @array or %hash gets enreferenced and then smartmatched...
    if ($EXPR =~ $CONTAINER_VARIABLE) {
        return " smartmatch(\$_, \\$EXPR) ";
    }

    # An @array[@slice] or %kv[@slice] gets appropriately wrapped and then smartmatched...
    if ($EXPR =~ $ARRAY_SLICE) {
        return " smartmatch(\$_, [$EXPR]) ";
    }
    if ($EXPR =~ $HASH_SLICE) {
        return " smartmatch(\$_, {$EXPR}) ";
    }

    # Non-magical values get smartmatched...
    if ($EXPR =~ $SMARTMATCHABLE) {
        return " smartmatch(\$_, $EXPR) ";
    }

    # Anything else is magically NOT smartmatched (it's treated as a simple boolean test)...
    return $EXPR;
}


# Reduce a compile-time expression to what the compiler actually sees...
# (Essential because that's what when() actually sees and how it decides
#  whether or not smartmatch is magically distributive over a boolean expression)...
sub _simplify_expr ($code) {
    no warnings;
    use B::Deparse;
    state $deparse = B::Deparse->new;
    return $deparse->coderef2text(eval qq{no strict; sub{ANSWER( $code );DONE()}})
                =~ s{.* ANSWER \( (.*) \) \s* ; \s* DONE() .* \z}{$1}gxmsr;
}


# Reimplement the standard smartmatch operator
# (This could have been a set of multis, but a single multi is currently much faster)...

multi smartmatch ($left, $right) {

    # Categorize the two args...
    my $right_type = ref $right;
    my $left_type  = ref $left;

    # Track "use integer" status in original caller (passing it down to nested smartmatches)...
    local $Switch::Back::_use_integer = $Switch::Back::_use_integer // (caller 0)[8] & 0x1;

    # 1. Handle RHS undef...
    if (!defined $right) {
        return !defined $left;
    }

    # 2. Objects on the RHS can't be handled (at all, because no ~~ overloading available)...
    croak 'Smart matching an object breaks encapsulation'
        if $right_type ne 'Regexp' && blessed($right);

    # 3. Array on the RHS..
    if ($right_type eq 'ARRAY') {

        # 3a. Array of the LHS too...
        if ($left_type eq 'ARRAY') {
            # Match if identical array refs...
            return true if $left == $right;

            # Different lengths, so won't match...
            return false if @{$left} != @{$right};

            # Handle non-identical self-referential structures...
            local %Sm4r7m4tCh::seen = %Sm4r7m4tCh::seen;
            return false if $Sm4r7m4tCh::seen{"L$left"}++ || $Sm4r7m4tCh::seen{"R$right"}++;

            # Otherwise every pair of elements from the two arrays must smartmatch...
            for my $n (keys @{$right}) {
                return false if !smartmatch($left->[$n], $right->[$n]);
            }
            return true;
        }

        # 3b. Hash on the LHS...
        elsif ($left_type eq 'HASH') {
            # Matches if any right array element is a left hash key...
            for my $r (@{$right}) {
                if (!defined $r) {
                    carp 'Use of uninitialized value in smartmatch'
                        if warnings::enabled('uninitialized');
                }
                return true if exists $left->{ $r // q{} };
            }
            return false;
        }

        # 3c. Regex on the LHS...
        elsif ($left_type eq 'Regexp') {
            # Matches if left arg pattern-matches any element of right array...
            for my $r (@{$right}) {
                return true if $r =~ $left;
            }
            return false;
        }

        # 3d. undef on the LHS...
        elsif (!defined $left) {
            # Matches if any element of right array is undefined (NON-RECURSIVELY)...
            for my $r (@{$right}) {
                return true if !defined $r;
            }
            return false;
        }

        # 3e. Anything else on the LHS...
        else {
            # Matches if left arg smartmatches any element of right array...
            for my $r (@{$right}) {
                if (!defined $r) {
                    carp 'Use of uninitialized value in smartmatch'
                        if warnings::enabled('uninitialized');
                }
                return true if smartmatch($left, $r);
            }
            return false;
        }
    }

    # 4. Hash on the RHS...
    if ($right_type eq 'HASH') {

        # 4a. Hash on the LHS...
        if ($left_type eq 'HASH') {
            # Match if they're the same hashref...
            return true  if $left == $right;

            # Fail to match if they have different numbers of keys...
            return false if %{$left} != %{$right};

            # Otherwise, match if all their keys match...
            for my $lkey (keys %{$left}) {
                return false if !exists $right->{$lkey};
            }
            return true;
        }

        # 4b. Array on the LHS...
        elsif ($left_type eq 'ARRAY') {

            # Handle self-referential structures...
            local %Sm4r7m4tCh::seen = %Sm4r7m4tCh::seen;
            return false if $Sm4r7m4tCh::seen{"L$left"}++;

            # Match if any top-level array element is (NON-RECURSIVELY) a key in the hash...
            for my $l (@{$left}) {
                if (!defined $l) {
                    carp 'Use of uninitialized value in smartmatch'
                        if warnings::enabled('uninitialized');
                }
                return true if exists $right->{ $l // q{} };
            }
            return false;
        }

        # 4c. Regex on the LHS...
        elsif ($left_type eq 'Regexp') {
            # Match if any hash key is matched by the regex...
            for my $rkey (keys %{$right}) {
                return true if $rkey =~ $left;
            }
            return false;
        }

        # 4d. undef on the LHS...
        elsif (!defined $left) {
            # Hash keys can never be undef...
            return false;
        }

        # 4e. Anything else on the LHS...
        else {
            # Match if the stringified left arg is a key of right hash...
            if (!defined $left) {
                carp 'Use of uninitialized value in smartmatch'
                    if warnings::enabled('uninitialized');
            }
            return exists $right->{ $left // q{} };
        }
    }

    # 5. Subroutine reference on the RHS...
    if ($right_type eq 'CODE') {

        # 5a. Array on the LHS...
        if ($left_type eq 'ARRAY') {

            # Handle self-referential structures...
            local %Sm4r7m4tCh::seen = %Sm4r7m4tCh::seen;
            return false if $Sm4r7m4tCh::seen{"L$left"}++;

            # Sub must always return true when called on every element of array...
            for my $l (@{$left}) {
                return false if !$right->($l);
            }
            return true;
        }

        # 5b. Hash on the LHS...
        elsif ($left_type eq 'HASH') {
            # Sub must always return true when called on every key of hash...
            for my $lkey (keys %{$left}) {
                return false if !$right->($lkey);
            }
            return true;
        }

        # 5c. Anything else on the LHS...
        else {
            # Otherwise, sub must return true when passed left arg...
            return !!$right->($left);
        }
    }

    # 6. Regexp on the RHS...
    if ($right_type eq 'Regexp') {

        # 6a. Array on the LHS...
        if ($left_type eq 'ARRAY') {

            # Handle self-referential structures...
            local %Sm4r7m4tCh::seen = %Sm4r7m4tCh::seen;
            return false if $Sm4r7m4tCh::seen{"L$left"}++;

            # Match if any left array element pattern-matches the right regex...
            for my $l (@{$left}) {
                if (!defined $l) {
                    carp 'Use of uninitialized value in smartmatch'
                        if warnings::enabled('uninitialized');
                }
                no warnings;
                return true if $l =~ $right;
            }
            return false;
        }

        # 6b. Hash on the LHS...
        elsif ($left_type eq 'HASH') {
            # Match if any left key of the hash pattern-matches the right regex...
            for my $lkey (keys %{$left}) {
                return true if $lkey =~ $right;
            }
            return false;
        }

        # 6c. Anything else on the LHS...
        else {
            # Otherwise, the stringified left arg must pattern-match right regex...
            if (!defined $left) {
                carp 'Use of uninitialized value in pattern match (m//)'
                    if warnings::enabled('uninitialized');
            }
            no warnings;
            return $left =~ $right;
        }
    }

    # 7. Primordial numbers on the RHS attempt numeric matching against LHS values...
    if (created_as_number($right)) {
        no warnings;
        if ($Switch::Back::_use_integer) {
            use integer;
            return defined $left && $left == $right;
        }
        else {
            return defined $left && $left == $right;
        }
    }

    # 8. Primordial numbers on the LHS attempt numeric matching against LHS number-ish values...
    if (created_as_number($left) && looks_like_number($right)) {
        if ($Switch::Back::_use_integer) {
            use integer;
            return $left == $right;
        }
        else {
            return $left == $right;
        }
    }

    # 9. If LHS is undef, RHS must be too,
    #    but we know it isn't at this point, because test 1. would have caught that...
    if (!defined $left) {
        return false;
    }

    # 10. Otherwise, we just string match...
    else {
        no warnings;
        return $left eq $right;
    }
}


1; # Magic true value required at end of module
__END__

=head1 NAME

Switch::Back - C<given>/C<when> for a post-C<given>/C<when> Perl


=head1 VERSION

This document describes Switch::Back version 0.000005


=head1 SYNOPSIS

    use v5.42;          # given/when were removed in this version of Perl

    use Switch::Back;   # But this module brings them back

    given ($some_value) {

        when (1)   { say 1; }

        when ('a') { say 'a'; continue; }

        break when ['b'..'e'];

        default    { say "other: $_" }
    }


=head1 DESCRIPTION

The C<given>/C<when> construct was added to Perl in v5.10,
deprecated in Perl v5.38, and removed from the language in Perl v5.42.

Code that uses the construct must therefore be rewritten if it is to
be used with any Perl after v5.40.

Or you can leave the C<given> and C<when> code in place and use this
module to (partially) resurrect the former feature in more recent Perls.

The module exports three keywords: C<given>, C<when>, and C<default>,
and two subroutines: C<break> and C<continue>, which collectively
provide most of the previous behaviour provided by C<use feature 'switch'>.

The module I<doesn't> resurrect the smartmatch operator (C<~~>), but does
export a C<smartmatch()> subroutine that implements a nearly complete subset
of the operator's former behaviour.


=head1 INTERFACE

The module has no options or configuration.
You simply load the module:

    use Switch::Back;

...and its exported keywords will then rewrite the rest of your source code
I<(safely, using the extensible keyword mechanism, B<not> a source filter)>
to translate any subsequent C<given>, C<when>, and C<default> blocks
into the equivalent post-Perl-v5.42 code. See L<"LIMITATIONS"> for an
overview of just how backwards compatible (or not) this approach is.

Loading the module also unconditionally exports two subroutines, C<break()> and
C<continue()>, which provide the same explicit flow control as the former
built-in C<break()> and C<continue()> functions.

The module also unconditionally exports a multiply dispatched subroutine named
C<smartmatch()>, which takes two arguments and smartmatches them using the same
logic as the former C<~~> operator. See L<"Smartmatching differences"> for a
summary of the differences between C<smartmatch()> and the former built-in C<~~> operator.
See L<"Overloading C<smartmatch()>"> for an explanation of how to add new matching
behaviours to C<smartmatch()> (now that C<~~> is no longer overloadable).

=head2 Smartmatching differences

The C<smartmatch()> subroutine provided by this module implements almost all of the
behaviours of the L<former C<~~> operator|https://perldoc.perl.org/5.40.0/perlop#Smartmatch-Operator>,
with the exceptions listed below.

Note, however, that despite these limitations on smartmatching,
the C<given> and C<when> keywords implement almost the complete range
of smartmatching behaviours of the former C<given> and C<when> constructs.
Specifically these two keywords will still auto-enreference arrays, hashes,
and slices that are passed to them, and C<when> also implements the so-called
L<"smartsmartmatching" behaviours on boolean expressions|https://perldoc.perl.org/5.40.0/perlsyn#Experimental-Details-on-given-and-when>.

=head3 1. No auto-enreferencing of arguments

The C<smartmatch()> subroutine is a regular Perl subroutine so, unlike
the C<~~> operator, it cannot auto-enreference an array or hash or slice
that is passed to it. That is:

                %hash ~~ @array    # Works (autoconverted to; \%hash ~~ \@array)

    smartmatch( %hash,   @array)   # Error (hash and array are flattened within arglist)

    smartmatch(\%hash,  \@array)   # Works (smartmatch() always expects two args)


=head3 2. No overloading of C<~~>

Because overloading of the C<~~> operator was removed in Perl 5.42, the C<smartmatch()>
subroutine always dies if its right argument is an object.
The former C<~~> would first attempt to call the object's overloaded C<~~>,
only dying if no suitable overload was found.
See L<"Overloading C<smartmatch()>"> for details on how to extend the behavior of
C<smartmatch()> so it can accept objects.


=head2 Overloading C<smartmatch()>

Because the C<smartmatch()> subroutine provided by this module is actually
a I<multisub>, implemented via the L<Multi::Dispatch> module,
it can easily be extended to match between additional types of arguments.

For example, if you want to be able to smartmatch against an C<ID::Validator>
object (by calling its C<validate()> method), you would just write:

    use Switch::Back;
    use Multi::Dispatch;

    # Define new smartmatching behaviour on ID::Validator objects...
    multi smartmatch ($value, ID::Validator $obj) {
        return $obj->validate( $value );
    }

    # and thereafter...

    state $VALID_ID = ID::Validator->new();

    given ($id) {
        when ($VALID_ID) { say 'valid ID' }     # Same as: if ($VALID_ID->validate($_)) {...}
        default          { die 'invalid ID' }
    }

More generally, if you wanted to allow any object to be passed as the right-hand
argument to C<smartmatch()>, provided the object has a stringification or numerification
overloading, you could write:

    use Multi::Dispatch;
    use Types::Standard ':all';

    # Allow smartmatch() to accept RHS objects that can convert to numbers...
    multi smartmatch (Num $left, Overload['0+'] $right) {
        return next::variant($left, 0+$right);
    }

    # Allow smartmatch() to accept RHS objects that can convert to strings...
    multi smartmatch (Str $left, Overload[q{""}] $right) {
        return next::variant($left, "$right");
    }

You can also change the existing behaviour of C<smartmatch()> by providing
a variant for specific cases that the multisub already handles:

    use Multi::Dispatch;

    # Change how smartmatch() compares a hash and an array
    # (The standard behaviour is to match if ANY hash key is present in the array;
    #  but here we change it so that ALL hash keys must be present)...

    multi smartmatch (HASH $href, ARRAY $aref) {
        for my $key (keys %{$href}) {
            return false if !smartmatch($key, $aref);
        }
        return true;
    }

For further details on the numerous features and capabilities of the C<multi> keyword,
see the L<Multi::Dispatch> module.


=head1 LIMITATIONS

The re-implementation of C<given>/C<when> provided by this module aims to be
fully backwards compatible with the former built-in C<given>/C<when> construct,
but currently fails to meet that goal in several ways:

=head2 Limitation 1. You can't always use a C<given> inside a C<do> block

The former built-in switch feature allowed you to place a C<given> inside a C<do> block
and then use a series of C<when> blocks to select the result of the C<do>. Like so:

    my $result = do {
        given ($some_value) {
            when (undef)         { 'undef' }
            when (any => [0..9]) { 'digit' }
            break when /skip/;
            when ('quit')        { 'exit'  }
            default              { 'huh?'  }
        }
    };

The module currently only supports a limited subset of that capability. For
example, the above code will still compile and execute, but the value assigned
to C<$result> will always be undefined, regardless of the contents of
C<$some_value>.

This is because it seems to be impossible to fully emulate the implicit flow
control at the end of a C<when> block I<(i.e. automatically jumping out of the
surrounding C<given> after the last statement in a C<when>)> by using other
standard Perl constructs. Likewise, to emulate the explicit control flow
provided by C<continue> and C<break>, the code has to be translated by adding
at least one extra statement after the block of each C<given> and C<when>.

So it does not seem possible to rewrite an arbitrary C<given>/C<when> such that
the last statement in a C<when> is also the last executed statement in its C<given>,
and hence is the last executed statement in the surrounding C<do> block.

However, the module is able to correctly rewrite at least I<some> (perhaps I<most>)
C<given>/C<when> combinations so that they work correctly within a C<do> block.
Specifically, as long as a C<given>'s block B<does not> contain an explicit
C<continue> or C<break> or C<goto>, or a postfix C<when> statement modifier,
then the module optimizes its rewriting of the entire C<given>,
converting it into a form that I<can> be placed inside a C<do> block
and still successfully produce values. Hence, although the previous example
did not work, if the C<break when...> statement it contains were removed:

    my $result = do {
        given ($some_value) {
            when (undef)         { 'undef' }
            when (any => [0..9]) { 'digit' }
                                                # <-- POSTFIX when REMOVED
            when ('quit')        { 'exit'  }
            default              { 'huh?'  }
        }
    };

...or even if the postfix C<when> were converted to the equivalent C<when> block:

    my $result = do {
        given ($some_value) {
            when (undef)         { 'undef' }
            when (any => [0..9]) { 'digit' }
            when (/skip/)        {  undef  }   # <-- CONVERTED FROM POSTFIX
            when ('quit')        { 'exit'  }
            default              { 'huh?'  }
        }
    };

...then the code B<would> work as expected and C<$result> would
receive an appropriate value.

In general, if you have written a C<do> block with a nested C<given>/C<when>
that is B<not> going to work under this module, you will usually receive
a series of compile-time I<"Useless use of a constant in void context"> warnings,
one for each C<when> block.

See the file F<t/given_when.t> for examples of this construction that do work,
and the file F<t/given_when_noncompatible.t> for examples the will not
(currently, or probably ever) work.



=head2 2. Use of C<when> modifiers outside a C<given>

The former built-in mechanism allowed a postfix C<when> modifier to be used
within a C<for> loop, like so:

    for (@data) {
        say when @target_value;
    }

This module does not allow C<when> to be used as a statement modifier
anywhere except inside a C<given> block. The above code would therefore have to
be rewritten to either:

    for (@data) {
        given ($) {
            say when @target_value;
        }
    }

...or to:

    for (@data) {
        when (@target_value) { say }
    }


=head2 3. Scoping anomalies of C<when> modifiers

The behaviour of obscure usages such as:

    my $x = 0;
    given (my $x = 1) {
        my $x = 2, continue when 1;
        say $x;
    }

...differs between the built-in C<given>/C<when> and this module's reimplementation.
Under the built-in feature, C<$x> contains C<undef> at the S<C<say $x>> line;
under the module, C<$x> contains 2.

As neither result seems to make much sense, or be particularly useful,
it is unlikely that this backwards incompatibility will ever be rectified.

=head1 DIAGNOSTICS

=over

=item C<< Incomprehensible "when" >>

=item C<< Incomprehensible "default" >>

You specified a C<when> or C<default> keyword, but the code following it
did not conform to the correct syntax for those blocks. The error message
will attempt to indicate where the problem was, but that indication
may not be accurate.

Check the syntax of your block.


=item C<< Can't "when" outside a topicalizer >>

=item C<< Can't "default" outside a topicalizer >>

C<when> and C<default> blocks can only be executed inside a C<given>
or a C<for> loop. Your code is attempting to execute a C<when> or C<default>
somewhere else. That never worked with the built-in syntax, and so it doesn't
work with this module either.

Move your block inside a C<given> or a C<for> loop.


=item C<< Can't specify postfix "when" modifier outside a "given" >>

It is a limitation of this module that you can only use the C<EXPR when EXPR>
syntax inside a C<given> (not inside a C<for> loop). And, of course, you couldn't
ever use it outside of both.

If your postfix C<when> is inside a loop, convert it to a C<when> block instead.


=item C<< Can't "continue" outside a "when" or "default" >>

Calling a C<continue> to override the automatic S<I<"jump-out-of-the-surrounding-C<given>">>
behaviour of C<when> and C<default> blocks only makes sense if you're actually inside
a C<when> or a C<default>. However, your code is attempting
to call C<continue> somewhere else.

Move your C<continue> inside a C<when> or a C<default>.


=item C<< Can't "break" outside a "given" >>

Calling a C<break> to explicitly S<I<"jump-out-of-the-surrounding-C<given>">>
only makes sense when you're inside a C<given> in the first place.

Move your C<break> inside a C<given>.

Or, if you're trying to escape from a C<when> in a loop,
change C<break> to C<next> or C<last>.


=item C<< Smart matching an object breaks encapsulation >>

This module does not support the smartmatching of objects
(because from Perl v5.42 onwards there is no way to overload C<~~>
for an object).

If you want to use an object in a C<given> or C<when>, you will need
to provide a variant of C<smartmatch()> that handles that kind of object.
See L<"Overloading C<smartmatch()>"> for details of how to do that.


=item C<< Use of uninitialized value in pattern match >>

=item C<< Use of uninitialized value in smartmatch >>

You passed a value to C<given> or C<when> that included an C<undef>,
which was subsequently matched against a regex or against some other
defined value. The former C<~~> operator warned about this in some cases,
so the C<smartmatch()> subroutine does too.

To silence this warning, add:

    no warnings 'uninitialized';

before the attempted smartmatch.

=back


=head1 CONFIGURATION AND ENVIRONMENT

Switch::Back requires no configuration files or environment variables.


=head1 DEPENDENCIES

This module requires the L<Multi::Dispatch>, L<PPR>, L<Keyword::Simple>,
and L<Type::Tiny> modules.


=head1 INCOMPATIBILITIES

This module uses the Perl keyword mechanism to (re)extend the Perl syntax
to include C<given>/C<when>/C<default> blocks. Hence it is likely to be
incompatible with other modules that add other keywords to the language.


=head1 BUGS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-switch-back@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 SEE ALSO

The L<Switch::Right> module provides a kinder gentler approach
to replacing the now defunct switch and smartmatch features.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@CPAN.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2024, Damian Conway C<< <DCONWAY@CPAN.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
