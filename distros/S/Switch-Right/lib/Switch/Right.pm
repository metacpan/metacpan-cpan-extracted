package Switch::Right;

use 5.036;
our $VERSION = '0.000003';

use experimental qw< builtin refaliasing try >;
use builtin      qw< true false is_bool blessed created_as_number reftype >;
use Scalar::Util qw < looks_like_number >;
use overload;

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
my $FLIP_FLOP;
BEGIN { $FLIP_FLOP
    = qr{ \A (?&FlipFlop) \z
          (?(DEFINE)
              (?<FlipFlop>
                    \( (?>(?&PerlOWS)) (?&FlipFlop) (?>(?&PerlOWS)) \)
              |
                    (?>(?&PerlBinaryExpression)) (?>(?&PerlOWS))
                     \.\.\.?                       (?>(?&PerlOWS))
                     (?>(?&PerlBinaryExpression))
              )
              (?<PerlInfixBinaryOperator>
                    (?>  [=!][~=] |    <= >?+ |    >=
                    |    cmp |    [lg][te] |    eq |    ne
                    |    [+]             (?! [+=] )
                    |     -              (?! [-=] )
                    |    [.%x]           (?! [=]  )
                    |    [&|^][.]        (?! [=]  )
                    |    [<>*&|/]{1,2}+  (?! [=]  )
                    |    \^              (?! [=]  )
                    |    ~~ | isa
                    )
              )
          )
          $PPR::GRAMMAR
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

sub _pure_given_impl { my ($source) = @_;

    # Recognize a valid "pure" given block (i.e. containing only when and default blocks)...
    state @pure_statements;
    @pure_statements = ();
    state $VALIDATE_PURE_GIVEN = qr{
        \A  given (?<GIVEN> $OWS  \(
                (?<JUNC> (?: $OWS (?> any | all | none )  $OWS  => )?+ )
                             $OWS (?>(?<EXPR> (?&PerlExpression)))
                             $OWS \)
                             $OWS (?>(?<BLOCK>  (?&PureBlock)  ))
            )
            (?>(?<TRAILING_CODE>  .*  ))

            (?(DEFINE)
                (?<PureBlock>    # Distinguish "when", "default", and "given" from other statements...
                    \{  $OWS
                    (?:
                        when $OWS \(
                            (?<WHENJUNC> (?: $OWS (?> any | all | none ) $OWS => )?+ )
                                             $OWS (?<WHENEXPR> (?>(?&PerlExpression)))
                             $OWS \) $OWS (?>(?<WHENBLOCK> (?&PerlBlock) ))  $OWS
                        (?{ push @pure_statements, { TYPE => 'when', %+ }; })
                    |
                        default $OWS (?>(?<DEFBLOCK> (?&PerlBlock) ))  $OWS
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
                        (?! when \b | default \b )
                        (?>(?<STATEMENT> (?&PerlStatement) ))  $OWS
                        (?{ push @pure_statements, { TYPE => 'other', %+ }; })
                    )*+
                    \}
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
        my $GIVEN_EXPR = _apply_term_magic($matched{EXPR});
        return
              "if (1) { local *_ = \\scalar($GIVEN_EXPR); if(0){}"
            . join("\n", map {
                my $PREFIX = $after_a_statement ? 'if(0){}' : q{};
                if ($_->{TYPE} eq 'when') {
                    $after_a_statement = 0;
                      "$PREFIX elsif (smartmatch($matched{JUNC} \$_, $_->{WHENJUNC} scalar("
                    . _apply_term_magic($_->{WHENEXPR}) . "))) $_->{WHENBLOCK}"
                }
                elsif ($_->{TYPE} eq 'default') {
                    $after_a_statement = 0;
                    "$PREFIX elsif (1) $_->{DEFBLOCK}"
                }
                elsif ($_->{TYPE} eq 'given') {
                    use Data::Dump 'ddx'; ddx $_;
                    my $nested = _pure_given_impl($_->{NESTEDGIVEN});
                    use Data::Dump 'ddx'; ddx $nested;
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
        state $VALIDATE_GIVEN = qr{
            \A  (?<GIVEN> $OWS  \(
                    (?<JUNC> (?: $OWS (?> any | all | none )  $OWS  => )?+ )
                                $OWS (?>(?<EXPR> (?&PerlExpression)))
                                $OWS \)
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
            my ($GIVEN, $JUNC, $EXPR, $BLOCK, $TRAILING_CODE)
                = @result{qw< GIVEN JUNC EXPR BLOCK TRAILING_CODE >};

            # Augment the block with control flow and other necessary components...
            $BLOCK = _augment_block(given => "$BLOCK", $JUNC);

            # Topicalize the "given" argument...
            $EXPR = _apply_term_magic($EXPR);
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
                         (  \(
                               (?<JUNC> (?: $OWS (?> any | all | none ) $OWS => )?+ )
                                            $OWS (?<EXPR> (?&PerlExpression))
                                            $OWS
                            \)
                             $OWS (?>(?<BLOCK> (?&PerlBlock) )
                                  | (?<INVALID_BLOCK>)
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
        my ($WHEN, $JUNC, $EXPR, $BLOCK, $TRAILING_CODE)
            = @matched{qw< WHEN JUNC EXPR BLOCK TRAILING_CODE>};

        # Adjust when's expression appropriately...
        $EXPR = _apply_term_magic($EXPR);

        # Augment the block with control flow and other necessary components...
        $BLOCK = _augment_block(when => "$BLOCK");

        # Is the current "given" junctive???
        my $given_junc = $^H{'Switch::Right/GivenJunctive'} // q{};

        # Implement the "when" as an "if"...
        $REPLACEMENT_CODE = qq{if(1)\{local \$Switch::Right::when_value = }
                          . qq{smartmatch($given_junc \$_, $JUNC scalar($EXPR));}
                          . qq{if(1){if (\$Switch::Right::when_value) $BLOCK }\}};

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
    my $AFTERWHEN = (caller 0)[10]{'Switch::Right/Afterwhen'};

    # Jump out of it, if possible...
    no warnings;
    eval { goto $AFTERWHEN };

    # If not possible, that's fatal...
    croak q{Can't "continue" outside a "when" or "default"};
}

# Implement the "break" command...
sub break () {
    # Which "given" block are we in???
    my $AFTERGIVEN = (caller 0)[10]{'Switch::Right/Aftergiven'};

    # Jump out of it, if possible...
    no warnings;
    eval { goto $AFTERGIVEN };

    # If we weren't in a "given", can we jump out of a surrounding loop???
    eval { next };

    # Otherwise, the "break" was illegal and must be punished...
    croak q{Can't "break" outside a "given"};
}


# Insert unique identifying information into a "given"/"when"/"default" source code block...
sub _augment_block ($TYPE, $BLOCK, $JUNC = q{}) {
        # Unique identifiers for each type of block...
        state %ID;

        # Who and what is this block???
        my $KIND = $TYPE eq 'default' ? "when" : $TYPE;
        my $NAME = "After$KIND";
        my $ID   = $NAME . ++$ID{$KIND};

        # Give each block a unique name (uses refaliasing to create a lexical constant)...
        substr($BLOCK, 1,0)
            = qq{ BEGIN { \$^H{'Switch::Right/$NAME'} = '$ID'; } };

        # A when block auto-breaks at the end of its block...
        if ($KIND eq 'when') {
            my $AFTERGIVEN = $^H{'Switch::Right/Aftergiven'};
            substr($BLOCK,-1,0)
                = ';'
                . (defined($AFTERGIVEN) ? qq{eval { no warnings; goto $AFTERGIVEN } || } : q{})
                . qq{eval { no warnings; next } || die q{Can't "$TYPE" outside a topicalizer} };
        }

        elsif ($KIND eq 'given') {
            # Remember whether (and how) given was junctive...
            substr($BLOCK, 1,0) = qq{ BEGIN { \$^H{'Switch::Right/GivenJunctive'} = '$JUNC'; } };

            # Given blocks must to pre-convert postfix "when" modifiers (which can't be keyworded)...
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
        state $JUNCTIVE_EXPR = qr{
            $OWS  (?>(?<JUNC> (?: any | all | none ) $OWS => $OWS | ))  (?<EXPR> .* )
            $PPR::GRAMMAR
        }xms;

        # Unpack and enchant the "when" expression...
        my ($JUNCTIVE, $MOD_EXPR) = (q{}, $pos->{mod});
        if ($MOD_EXPR =~ $JUNCTIVE_EXPR) {
            ($JUNCTIVE, $MOD_EXPR) = ( $+{JUNC}, _apply_term_magic($+{EXPR}) );
        }

        # Convert postfix "when" to a postfix "if" (preserving Afterwhen info for continue())...
        substr($BLOCK, $pos->{from}, $pos->{len})
            = "BEGIN { \$^H{'Switch::Right/Afterwhenprev'} = \$^H{'Switch::Right/Afterwhen'};"
            . "        \$^H{'Switch::Right/Afterwhen'} = 'Afterpostfixwhen$ID'; }"
            . "$pos->{expr}, break if smartmatch(\$_, $JUNCTIVE scalar($MOD_EXPR))"
            . ";Afterpostfixwhen$ID:"
            . "BEGIN { \$^H{'Switch::Right/Afterwhen'} = \$^H{'Switch::Right/Afterwhenprev'}; }"
            . $pos->{end};
    }

    return $BLOCK;
}

# Change the target expression of a "when" to implement all the magic behaviours...
sub _apply_term_magic ($EXPR) {

    # Apply compile-time expression folding...
    $EXPR = _simplify_expr($EXPR);

    # Adjust flip..flips to canonical booleans...
    if ($EXPR =~ /\.\./ && $EXPR =~ $FLIP_FLOP) {
        return "!!($EXPR)";
    }

    # An @array or %hash gets enreferenced and then smartmatched.
    # An @array[@slice] or %kv[@slice] gets appropriately wrapped and then smartmatched.
    # Anything else is evaluated as-is...
    return ($EXPR =~ /[\@%]/ && $EXPR =~ $CONTAINER_VARIABLE) ? "\\$EXPR"
         : ($EXPR =~ /[\@]/  && $EXPR =~ $ARRAY_SLICE)        ?  "[$EXPR]"
         : ($EXPR =~ /[\%]/  && $EXPR =~ $HASH_SLICE)         ?  "{$EXPR}"
         :                                                         $EXPR;
}


# Reduce a compile-time expression to what the compiler actually sees...
# (Essential because that's what when() actually sees and how it decides
#  whether or not smartmatch is magically distributive over a boolean expression)...
sub _simplify_expr ($code) {
    no warnings;
    use B::Deparse;
    use builtin qw<true false>;
    state $deparse = B::Deparse->new;
    return $deparse->coderef2text(eval qq{no strict; sub{ANSWER( scalar($code) );DONE()}})
                =~ s{.* ANSWER \( \s* scalar \s* (.*) \) \s* ; \s* DONE() .* \z}{$1}gxmsr;
}


# Implement the new simpler, but shinier smartmatch operator...
# (Every one of the following four variants could each have been a set of multiple variants,
#  but this way is currently still significantly faster)...

multi smartmatch ($left, $right) {
    # The standard error message for args that are objects (and which shouldn't be)...
    state $OBJ_ARG = "Smartmatching an object breaks encapsulation";

    # Track "use integer" status in original caller (passing it down to nested smartmatches)...
    local $Switch::Right::_use_integer = $Switch::Right::_use_integer // (caller 0)[8] & 0x1;

    # RHS undef only matches LHS undef...
    return !defined $left if !defined $right;

    # RHS distinguished boolean always returns RHS value...
    return $right if is_bool($right);

    # RHS objects use their SMARTMATCH method (if they have one)...
    my $right_type  = reftype($right) // 'VAL';
    if ($right_type ne 'REGEXP' && blessed $right) {
        try          { return $right->SMARTMATCH($left) }
        catch ($ERR) { croak "$OBJ_ARG ($ERR)"          }
    }

    # Otherwise, branch to the appropriate comparator (if any)...
    my $left_type   = reftype($left)  // 'VAL';
    my $left_is_obj = $left_type ne 'REGEXP' && blessed($left);
    eval { goto ($left_is_obj ? 'OBJECT' : $left_type) . $right_type };

    # Otherwise, a RHS subref (with any non-subref LHS) acts like a boolean-returning test...
    return $right->($left) if $right_type eq 'CODE';

    # At thi spoint, no other combination of arguments will ever match...
    return false;

    # Objects can be used as LHS when matching an RHS value, but must be preprocessed...
    OBJECTVAL:
        if (created_as_number($right) ) {
            croak $OBJ_ARG if !overload::Method($left, '0+');
            $left = 0+$left;
        }
        else {
            croak $OBJ_ARG if !overload::Method($left, q{""});
            $left = "$left";
        }

    # Compare two scalar values (or a suitably overloaded LHS object and an RHS value)...
    VALVAL:
        # 1. undef doesn't match a number or a string...
        return false if !defined $left;

        # 2. Match primordial RHS numbers using == (respecting any ambient "use integer")...
        if (created_as_number($right) ) {
            if    (!looks_like_number($left))    {              return false;           }
            elsif ($Switch::Right::_use_integer) { use integer; return $left == $right; }
            else                                 {              return $left == $right; }
        }

        # 3. Otherwise just use string equality...
        return $left eq $right;

    # RHS regexes match any defined non-ref value via =~ pattern-matching...
    VALREGEXP:
        return defined($left) && $left =~ $right;

    # Compare two refs of the same type...
    CODECODE:
        return $left == $right;

    REGEXPREGEXP:
        return $left == $right || $left eq $right;

    ARRAYARRAY:
        return true  if $left == $right;        # ...they're the same array
        return false if @{$left} != @{$right};  # ...different lengths so their contents can't match

        # Handle non-identical self-referential structures...
        local %Sm4r7m4tCh::seen = %Sm4r7m4tCh::seen;
        return false if $Sm4r7m4tCh::seen{"L$left"}++ || $Sm4r7m4tCh::seen{"R$right"}++;

        # Otherwise, corresponding pairs of array elements must all smartmatch...
        for my $n (keys @{$right}) {
            return false if !smartmatch($left->[$n], $right->[$n]);
        }
        return true;

    HASHHASH:
        return true if $left == $right;                    # ...they're the same hash
        return false if keys %{$left} != keys %{$right};   # ...different numbers of keys, can't match

        # Handle non-identical self-referential structures...
        local %Sm4r7m4tCh::seen = %Sm4r7m4tCh::seen;
        return false if $Sm4r7m4tCh::seen{"L$left"}++ || $Sm4r7m4tCh::seen{"R$right"}++;

        # Otherwise, are they identical is structure???
        for my $key (keys %{$left}) {
            return false if !exists $right->{$key}                       # ...must have same keys
                         || !smartmatch($left->{$key}, $right->{$key});  # ...every value must match
        }
        return true;

    # Every other REF/REF comparison, just checks for the same address..
    FORMATFORMAT:;
    IOIO:;
    SCALARSCALAR:;
    VSTRINGVSTRING:;
    REFREF:;
    GLOBGLOB:;
    LVALUELVALUE:;
        return $left == $right;
}

# Junctive smartmatching of the RHS list...
multi smartmatch ($left, $junction =~ /^(?:any|all|none)$/, \@right) {

    # Track "use integer" status in original caller (passing it down to nested smartmatches)...
    local $Switch::Right::_use_integer = $Switch::Right::_use_integer // (caller 0)[8] & 0x1;

    # Select junctive behaviour...
    goto $junction;

    # Disjunction...
    any: for my $rval (@right) {
            return true if smartmatch($left, $rval);
         }
         return false;

    # Conjunction...
    all: for my $rval (@right) {
            return false if !smartmatch($left, $rval);
         }
         return true;

    # Injunction...
    none: for my $rval (@right) {
            return false if smartmatch($left, $rval);
          }
          return true;
}

# Junctive smartmatching of the LHS list...
multi smartmatch ($junction =~ /^(?:any|all|none)$/, \@left, $right) {
    # Track "use integer" status in original caller (passing it down to nested smartmatches)...
    local $Switch::Right::_use_integer = $Switch::Right::_use_integer // (caller 0)[8] & 0x1;

    # Dispatch on junctive type...
    goto $junction;

    # Disjunction...
    any: for my $lval (@left) {
            return true if smartmatch($lval, $right);
         }
         return false;

    # Conjunction...
    all: for my $lval (@left) {
            return false if !smartmatch($lval, $right);
         }
         return true;

    # Injunction:
    none: for my $lval (@left) {
            return false if smartmatch($lval, $right);
          }
          return true;
}


# Junctive smartmatching of both LHS and RHS lists...
multi smartmatch (
            $ljunction =~ m/^(?:any|all|none)$/, \@left,
            $rjunction =~ m/^(?:any|all|none)$/, \@right
) {
    # Track "use integer" status in original caller (passing it down to nested smartmatches)...
    local $Switch::Right::_use_integer = $Switch::Right::_use_integer // (caller 0)[8] & 0x1;

    # Dispatch according to the combination of junctive types...
    goto "$ljunction$rjunction";

    # The nine combinations...
    anyany: for my $lval (@left)  {
            for my $rval (@right) {
                return true if smartmatch($lval, $rval);   # ...because any match is sufficient
            }}
            return false;  # ...because no LHS value matched any RHS value

    anyall: for my $lval (@left)  {
                for my $rval (@right) {
                    next anyall if !smartmatch($lval, $rval);  # ...because not all RHS vals match LHS
                }
                return true;  # ...because all RHS values have matched some LHS value
            }
            return false;  # ...because no LHS value matched all RHS values

    nonenone:; # This one's tricky: it means there isn't an LHS elem that matches no RHS elem,
               # which is the same as all LHS elems matching at least one (i.e. any) RHS elem
               # so we just fall through to...

    allany: for my $lval (@left)  {
                for my $rval (@right) {
                    next allany if smartmatch($lval, $rval);  # ...because at least 1 RHS value matched
                }
                return false;  # ...because no RHS value matched the current LHS value
            }
            return true;  # ...because every RHS value matched at least one RHS value

    allall: for my $lval (@left)  {
            for my $rval (@right) {
                return false if !smartmatch($lval, $rval);  # ...because a single mismatch is failure
            }}
            return true;  # ...because every possible LHS/RHS combination matched

    noneany: for my $lval (@left)  {
             for my $rval (@right) {
                 return false if smartmatch($lval, $rval);  # ...because a single match is failure
             }}
             return true;  # ...because every LHS value failed to match any RHS value

    noneall: for my $lval (@left)  {
                 for my $rval (@right) {
                     # This left elem is okay if it doesn't match at least one right elem...
                     next noneall if !smartmatch($lval, $rval);
                     # ...because every LHS value must mismatch at least one RHS value
                 }
                 return false;  # ...because an LHS value did match all RHS values
             }
             return true;  # ...because every LHS value failed to match at least one RHS value

    anynone: for my $lval (@left)  {
                 for my $rval (@right) {
                     next anynone if smartmatch($lval, $rval);
                     # ...because this left elem matched an RHS value, so it can't be the chosen one
                 }
                 return true;  # ...because an LHS did match none of the RHS values
             }
             return false;  # ...because we didn''t find an LHS value that matched no RHS value

    allnone: for my $lval (@left)  {
             for my $rval (@right) {
                return false if smartmatch($lval, $rval);  # ...because any match is disqualifying
             }}
             return true;  # ...because every LHS/RHS combination has now failed to match
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Switch::Right -  Switch and smartmatch done right this time


=head1 VERSION

This document describes Switch::Right version 0.000003


=head1 SYNOPSIS

    use Switch::Right;

    given ($value) {
        when (undef)    { say 'an undefined value'                         }
        when (1)        { say 'the number 1'                               }
        when ('two')    { say 'the string "two"'                           }
        when (\@array)  { say 'an identical arrayref'                      }
        when (\%hash)   { say 'an identical hashref (keys AND values)'     }
        when (qr/pat/)  { say 'a non-reference that matched the pattern'   }
        when (\&foo)    { say 'foo($value) returned true'                  }

        when ( /pat/)   { say 'a non-ref that matched the pattern'         }
        when (!/pat/)   { say 'a non-ref that didn't match the pattern'    }

        when (0 <= $_ <= 9)                { say 'a singe digit'           }
        when (defined && length > 0)       { say 'a non-empty string'      }
        when (-r || -w)                    { say 'an accessible file'      }
        when (exists $hash{$_})            { say 'a key of the hash'       }

        when ( any => [keys %hash])        { say 'a key of the hash'       }
        when ( any => [0..9])              { say 'a single-digit number'   }
        when ( all => [qr/foo/, qr/bar/])  { say 'matched /foo/ and /bar/' }
        when (none => \@prohibited)        { say 'not a prohibited value'  }

        default  { say 'none of the above'; }
    }


=head1 DESCRIPTION

After 17 years as a core feature of Perl,
C<'given'>/C<'when'> and smartmatching are going away.

And for some very good reasons! Smartmatching is just too damn clever
for most people (including its inventor!) to be able to easily remember
L<all the rules|https://perldoc.perl.org/5.40.0/perlop#Smartmatch-Operator>
about what matched what.

And the weird extra-special special-case behaviour of some (but not all) boolean expressions
in a C<when> only makes things even worse.

Hindsight is supposedly 20/20 and E<mdash> in hindsight E<mdash> smartmatching
should have been a lot simpler, a lot more explicit, and a lot easier to remember/predict.

That's what this module attempts to accomplish: to redesign the smartmatching
and the C<given>/C<when> mechanisms so that they're easier to use and easier
to understand.

It implements a version of smartmatching with only six rules to remember,
eliminates all of that magical auto-distributivity of C<when> expressions,
and provides clearer and more explicit ways to specify all those complicated
and hard-to-remember special-case I<"match any of..."> and I<"match all of...">
behaviours.

You could think of it as the C<'switch'> feature from an alternate timeline,
Or you can think of it as a second chance: switch re-imagined...and done right this time.

Above all, this module is supposed to be I<useful>. Once you're using Perl v5.42
you won't be able to write the old standard C<given>/C<when> blocks any more,
but you'll still be able to write these new C<given>/C<when> blocks,
with simpler semantics and clearer syntax.


=head1 INTERFACE

=head2 C<given>/C<when> redesigned

This module aims to greatly simplify the way that C<given>/C<when> switches operate.
Mostly by L<greatly simplifying the smartmatching behaviours|"Smartmatching re-imagined">
that a switch employs to select which C<when> to execute within its C<given>.

The C<given>/C<when>/C<default> syntax itself has not been significantly changed,
with only one major addition: L<explicit junctives|"Junctive smartmatching">,
which replace most of the previous complex magic of smartmatching.

The C<given> block still takes a single argument, which is evaluated in scalar context,
and then aliased to a localized C<$_> in the scope of the C<given>'s block.
The argument to the C<given> is still simplified at compile-time. If the argument
is an array, an array slice, a hash, or a kv-slice, it is still automatically
converted to a reference (i.e. rather than to a count).

A C<when> block still takes a single argument, which is still compile-time
folded and auto-enreferenced. The argument is still evaluated in scalar context,
and then smartmatched against C<$_> (but now using the L<new simplified
smartmatch semantics|"Smartmatching re-imagined">). If the C<when>'s argument
successfully smartmatches then its block is executed. At the end of that block,
control then immediately jumps out of the surrounding C<given> or C<for>.

A C<default> block still takes a no argument and unconditionally executes its block,
after which control then immediately jumps out of the surrounding C<given> or C<for>.

A call to the C<break> function immediately jumps out of the surrounding C<given> block.

A call to the C<continue> function immediately jumps out of the surrounding C<when> block
and moves on to the following statement within the current C<given> or C<for>.

=head3 Differences from the old built-in C<given>/C<when>

=head4 Junctive C<given>/C<when> arguments

Apart from the major changes in L<how C<given>/C<when> smartmatches|"Smartmatching re-imagined">,
the most significant difference in this new approach is that some arguments
passed to a C<given> or to a C<when> can now be optionally qualified with a junctive
indicator: C<any>, C<all>, or C<none>.

For example:

    for (readline()) {
        chomp;
        when (any  => ["quit", "exit"])                  { exit }
        when (all  => ["", @history == 0])               { warn "Can't repeat last input" }
        when (all  => ["", @history != 0])               { $input = $history[-1]; continue }
        when (none => ["", qr/$old_format|$new_format/]) { warn "Unknown format" }
        default                                          { push @history, $input // $_ }
    }

    given (any => @history) {
        when (undef)    { die  "Internal error: undefined input"  }
        when (-1)       { die  "Old-style -1 terminator detected" }
        when ($_ > 99)  { warn "Big values ($_) may be slow"      }
    }

These work more-or-less as you'd expect. The junctive keyword must always be
followed by an array or an array reference. A S<C<< when (any => @LIST) >>>
or S<C<< when (any => ['ref', 'to', 'array']) >>> succeeds
if I<any> of the elements of the array smartmatch against C<$_>. Likewise a
S<C<< when (all => @LIST) >>> or S<C<< when (all => $ARRAYREF) >>> only succeeds
if I<all> the array elements smartmatch against C<$_>,
and a S<C<< when (none => @LIST) >>> or S<C<< when (none => \@LIST) >>>
only succeeds if I<none> of the array elements smartmatch.

A S<C<< given (any => @LIST) >>> or S<C<< given (any => \@LIST) >>> modifies
the subsequent smartmatching behaviour of the entire C<given> block,
so that every C<when> within that block will succeed if I<any>
of the C<given>'s array values matches the C<when> expression. Likewise,
S<C<< given (all => @LIST) >>>,  and S<C<< given (none => @LIST) >>> cause each
nested C<when> to match only if that C<when>'s expression smartmatches I<all>/I<none>
of the C<given>'s list of values.

You can also use the junctive forms in any postfix C<when> statement modifier
(so long as they're in a C<given>):

    for (readline()) {
        chomp;
        given ($_) {
            exit                             when any  => ["quit", "exit"];
            warn "Can't repeat last input"   when all  => ["", @history == 0];
            $input = $history[-1], continue  when all  => ["", @history != 0];
            warn "Unknown format"            when none => ["", qr/$old_format|$new_format/];
            push @history, $input // $_;
        }
    }

This mechanism is designed to replace (and extend) the previous complex "vector"
matching behaviours that the built-in C<given>/C<when> used to provide. And which
very few people could ever remember how to use. Instead of a large number of
(somewhat inconsistent) rules for smartmatching against a list of alternatives,
you now just indicate explicitly that I<any> match is sufficient, or I<all> matches
are necessary, or that I<none> of them are permitted.

Note that the syntax for these junctive arguments to C<given> and C<when> is currently
hard-coded and evaluated at compile-time. You must literally write S<C<< any => >>>,
S<C<< all => >>>, and S<C<< none => >>> with the arrow syntax (not a comma),
and no quoting on the C<all>/C<any>/C<none>, in order to correctly specify them.

So you can't, for example, use equivalent forms like S<C<< 'any', >>>
or S<C<< qw<all> => >>> or S<C<< $NONE => >>>. Note that this restriction
I<might> be relaxed in future releases of the module.

=head4 Non-distributive C<given>/C<when> arguments

Another change in the behaviour of a C<when> block is that, if the argument
is a boolean expression involving C<and>, or C<or>, C<&&>, or C<||>, that
expression no longer has its smartmatching behaviour (sometimes)
L<distributed across the components of the expression|https://perldoc.perl.org/5.40.0/perlsyn#Experimental-Details-on-given-and-when>.

That is, whereas the former built-in C<when> preprocessed such boolean
expressions using a complex set of rules:

    when (/^\d+$/ && $_ < 75     )  # means: if ($_ =~ /^\d+$/ && $_ < 75           )
    when ([qw(foo bar)] && /baz/ )  # means: if ($_ ~~ [qw(foo bar)] && $_ ~~ /baz/ )
    when ([qw(foo bar)] || /^baz/)  # means: if ($_ ~~ [qw(foo bar)] || $_ ~~ /^baz/)
    when (/^baz/ || [qw(foo bar)])  # means: if ($_ =~ /^baz/ || [qw(foo bar)]      )
    when ("foo" or "bar"         )  # means: if ($_ ~~ "foo"                        )

...this module B<always> treats the contents of the parens as an expression
to be compile-time simplified and then passed directly to C<smartmatch()>.
No magical recomposition of the boolean expression is ever attempted.
Hence, under this module those same C<when> expressions now mean:

    when (/^\d+$/ && $_ < 75     )  # means: if (smartmatch($_, /^\d+$/ && $_ < 75)     )
    when ([qw(foo bar)] && /baz/ )  # means: if (smartmatch($_, [qw(foo bar)])          )
    when ([qw(foo bar)] || /^baz/)  # means: if (smartmatch($_, [qw(foo bar)])          )
    when (/^baz/ || [qw(foo bar)])  # means: if (smartmatch($_, /^baz/ || [qw(foo bar)]))
    when ("foo" or "bar"         )  # means: if (smartmatch($_, "foo")                  )

Only the first of those will actually do what was probably intended.
Whenever you would previously have used a "magic boolean expression" in a C<when>,
you almost certainly will now want to use an explicit junctive:

    when (all => [ /^\d+$/, $_ < 75 ]    )  # means: when $_ smartmatches both
    when (all => [ /foo|bar/, /baz/ ]    )  # means: when $_ smartmatches both
    when (any => [ qw(foo bar), /^baz/ ] )  # means: when $_ smartmatches either
    when (any => [ /^baz/, qw(foo bar) ] )  # means: when $_ smartmatches either
    when (any => [ "foo", "bar" ]        )  # means: when $_ smartmatches either

If you previously needed to use very complex distributed expressions in a C<when>,
it's likely that the new semantics will no longer support that directly.
In such cases, you can always factor the test out into a subroutine.
For example, instead of:

    when (\&prime || 0 and length == 1 || q/2/) { say "found: $_" }

...which won't work under this module I<(and which didn't actually work
as most people might have expected under the former built-in feature!)>,
you could write:

    sub is_special ($n) {
        is_prime($n) || $n==0 and length($n) == 1 || $n =~ qr/2/;
    }

    # and later...

    when (\&is_special) { say "found $_" }

The version of C<given>/C<when> provided by this module is otherwise identical
in design to the former built-in constructs, though entirely different
in its implementation. That difference leads to several additional limitations
on its usage. See L<"LIMITATIONS"> for more details of these restrictions.


=head2 Smartmatching re-imagined

The heart of this module is a near-complete change in the way smartmatching works.
Rather than L<the 23 rules of the former built-in C<~~> operator|https://perldoc.perl.org/5.40.0/perlop#Smartmatch-Operator>,
this module provides a two-argument C<smartmatch()> subroutine with a single meta-rule
(I<that the right-hand argument always determines the kind of matching used>)
and only six core rules for what kind of matching that right-hand argument selects:

=over

=item 1. A boolean: match by returning that arg (ignoring the left arg)

=item 2. A ref or C<undef>: match if left arg has the same type/contents

=item 3. A subroutine ref: match by calling the sub, passing the left arg

=item 4. A C<qr> regex: match a non-reference left arg by pattern matching

=item 5. A numeric value: match using numeric equality

=item 6. Any other value: match using string equality

=back

Or, as a table:

    Any          true        always true  (ignores left arg)
    Any          false       always false (ignores left arg)

    undef        undef       always true

    CODE         CODE        same reference
    Any          CODE        result of calling sub, passing left arg

    REGEXP       REGEXP      same reference or identical contents
    NonRef       REGEXP      stringify left arg and pattern-match

    ARRAY        ARRAY       recursively smartmatch each pair of elements

    HASH         HASH        same keys and all corresponding values smartmatch

    OtherRef     OtherRef    referential equality  (LEFT == RIGHT)

    Numlike      Number      numeric equality      (LEFT == RIGHT)

    NonRef       NonRef      string equality       (LEFT eq RIGHT)

    Other        Other       always false

Note that the type of the right-hand argument is determined as follows:

    true        builtin::is_bool( $RIGHT )  &&  $RIGHT
    false       builtin::is_bool( $RIGHT )  && !$RIGHT

    undef       !defined( $RIGHT )

    Ref         builtin::reftype( $RIGHT )
    NonRef      !builtin::reftype( $RIGHT )

    Number      builtin::created_as_number( $RIGHT )
    String      builtin::created_as_string( $RIGHT )



=head3 Differences from the C<~~> operator

The smartmatching behaviours described in the preceding section
are obviously very different from the former C<~~> operator.
In particular...

=head4 The arguments being smartmatched are no longer auto-enreferenced

The former C<~~> operator allowed you to pass two container variables as arguments,
and have them automatically converted to references (rather than flattening them
or converting them to element counts in the operator's scalar context).

    @A1 ~~ @A2     # same as:  \@ARRAY ~~ \@ARRAY
    %H1 ~~ %H2     # same as:  \%HASH  ~~ \%HASH

However, the C<smartmatch()> subroutine is just an ordinary Perl subroutine,
so it can't perform the same magical auto-conversion. Instead, it does what
every other plain subroutine does: it evaluates its argument list in list
context, which causes any array argument to flatten to a list of the
array's values, and any hash argument to flatten to a key/value list of the
hash's entries:

    smartmatch(@A1, @A2)   # same as:  smartmatch($A1[0], $A1[1],...,$A2[0], $A2[1],...)
    smartmatch(%H1, %H2)   # same as:  smartmatch(k=>$H1{k}, l=>$H1{l},...,x=>$H2{x}, y=>$H2{y},...)

This will usually result in a run-time error indicating that there is no
suitable variant of C<smartmatch()> that can handle 17 arguments (or however
many args your two containers happened to flatten down to).

To smartmatch two container variables, pass a reference to each of them instead:

    smartmatch(\@A1, \@A2)
    smartmatch(\%H1, \%H2)

=head4 Arrays no longer act like disjunctions

The C<~~> operator treated most (but not all) array and arrayref operands
as a disjunction of their values:

   %HASH    ~~ @ARRAY      any array elements exist as hash keys
   /REGEXP/ ~~ @ARRAY      any array elements pattern match regex
    undef   ~~ @ARRAY      any array element is undefined
   $VALUE   ~~ @ARRAY      any array element smartmatches value
   @ARRAY   ~~ %HASH       any array elements exist as hash keys
   @ARRAY   ~~ /REGEXP/    any array elements pattern match regex

The new C<smartmatch()> subroutine B<doesn't> treat an array or arrayref
as a list of alternatives. In fact, none of the following
equivalent formulations matches at all:

   smartmatch(  \%HASH,    \@ARRAY   )
   smartmatch( qr/REGEXP/, \@ARRAY   )
   smartmatch(    undef,   \@ARRAY   )
   smartmatch(   $VALUE,   \@ARRAY   )
   smartmatch(  \@ARRAY,   \%HASH    )
   smartmatch(  \@ARRAY,  qr/REGEXP/ )

See L<"How to get the missing C<~~> behaviours back">
for creating equivalents to these matches under the new mechanism.

=head4 Hashes no longer act like a set of their own keys

In a similar way, the C<~~> operator mostly treated hash and hashref arguments
as a set containing the hash's keys:

   @ARRAY   ~~  %HASH      set of keys contains any of the array elements
   /REGEXP/ ~~  %HASH      set of keys has an element that pattern-matches regex
    undef   ~~  %HASH      set of keys contains undef (always false)
   $VALUE   ~~  %HASH      set of keys contains the value
   %HASH    ~~  @ARRAY     set of keys contains any of the array elements
   %HASH    ~~ /REGEXP/    set of keys contains an element that pattern-matches regex

Once again, the corresponding calls to C<smartmatch()> never match for any of these
combinations of arguments. And, once again, see L<"How to get the missing C<~~> behaviours back">
for creating new equivalents to these matches.

=head4 Arrays and hashes no longer occasionally act like conjunctions

One of the complications of the former C<~~> operator was that
array and hash arguments to C<~~> didn't B<always> match I<any of...>;
in two particular cases they matched I<all of...> instead:

    @ARRAY ~~ \&SUB    sub always returns true when called separately on each element
    %HASH  ~~ \&SUB    sub always returns true when called separately on each key

The corresponding C<smartmatch()> calls don't do that:

    smartmatch( \@ARRAY, \&SUB )   sub returns true when called once on entire arrayref
    smartmatch( \%HASH,  \&SUB )   sub returns true when called once on entire hashref

=head4 References match in far fewer ways

As the preceding sections imply, whereas C<~~> defined complex and vaguely inconsistent
matching behaviours for numerous combinations of two reference arguments,
the C<smartmatch()> subroutine provided by this module fails to match
when passed most combinations of two references.

Under this module, two references only smartmatch if:

=over

=item * The two references are identical: they are of the same type
        (e.g. two globrefs, two IOrefs, two regexrefs, two arrayrefs,
              two subrefs, two scalarrefs, etc.) and their addresses are the same; or

=item * The two references are of the same container type (e.g. two arrayrefs or two hashrefs)
        and their contents recursively smartmatch; or

=item * The two references are both regexrefs and those two regexes contain identical patterns; or

=item * The right-hand reference is a subref, which returns true when passed the left-hand reference.

=back


=head4 Numeric matching is stricter

The former C<~~> operator attempted to match numerically whenever its right-hand argument
was an actual number, B<or> whenever its left-hand argument was an actual number I<and>
its right-hand argument was a string that looks like a number.

In contrast, C<smartmatch()> only uses numeric comparison if its
right-hand argument is an actual number. If its right-hand argument is a number-like string, it
uses string comparison. If you need to ensure numeric comparison when the right-hand argument
is a number-like string, add 0 to it:

    my $input_num = readline;   # for example: "42.000";

    smartmatch( 42,   $input_num )   # compares using "eq" --> fails to match
    smartmatch( 42, 0+$input_num )   # compares using "==" --> matches


=head4 String and pattern matching no longer stringifies references

When passed an unblessed reference as its left-hand argument, the C<~~> operator
would convert the reference to a string before attempting to pattern- or string-match it.

The C<smartmatch()> subroutine does not do this; it simply fails to match. If
you want to smartmatch against a left-hand reference in those ways, you must
explicitly stringify it first:

    smartmatch(  $SOMEREF,  qr/CODE|GLOB/ )   # always fails
    smartmatch( "$SOMEREF", qr/CODE|GLOB/ )   # matches if left arg is a subref or globref


=head3 Junctive smartmatching

As the preceding sections imply, the new matching behaviour of C<smartmatch()>
removes all of the complex implicit recursive I<any of...> and I<all of...> special cases
when matching arrays and hashes.

This makes the approach much easier to understand and remember. But also much
less convenient, because those complex implicit recursive I<any of...> and I<all of...>
behaviours were amongst the most useful features of the C<~~> operator. In
particular, it was extremely handy to be able to use C<~~> to test for list membership
and key-set membership, and also to be able to test values against multiple distinct criteria
in a single expression.

So this module reintroduces most of those abilities, but in a simpler and much
easier-to-remember way: by adding one or two extra arguments to C<smartmatch()>.
Those arguments tell the subroutine to recursively smartmatch I<all of> a list of
values, or I<any of> a list of values, or I<none of> a list of values.
Unsurprisingly, those extra arguments are the strings C<"any">, C<"all">, and C<"none">.
For example:

    smartmatch( $N, any => [2,3,5,7] )

...is exactly the same as:

    smartmatch($N, 2) || smartmatch($N, 3) || smartmatch($N, 5) || smartmatch($N, 7)

Likewise:

    smartmatch( $N, all => [qr/\d/, \&is_prime] )

...is identical to:

    smartmatch($N, qr/\d/) && smartmatch($N, \&is_prime)

And:

    smartmatch( $N, none => [qr/\d/, \&is_prime] )

...is identical to:

    !smartmatch($N, qr/\d/) && !smartmatch($N, \&is_prime)

The C<"any">, C<"all">, or C<"none"> can be placed before the first argument as well:

    smartmatch(  any => \@numbers,  \&is_prime )    # At least one number is prime
    smartmatch(  all => \@numbers,  qr/7/      )    # Every number has a 7 in it
    smartmatch( none => \@numbers,  42         )    # The number list doesn't include 42

And, of course, you can also place an C<"any">, C<"all">, or C<"none"> on in front of I<both>
arguments:

    smartmatch(  any => \@numbers,   all => [qr/\d/, \&is_prime] )
    smartmatch(  all => \@numbers,  none => [qr/\d/, \&is_prime] )
    smartmatch( none => \@numbers,   any => \@previous_numbers   )

As the preceding examples illustrate, if C<smartmatch()> is called with either
one or two of these "junctive" modifiers, then the argument immediately
after the C<"any">, C<"all">, or C<"none"> must be an array reference containing
the list of values to be tested against the other argument.

The individual tests in such junctive smartmatches still use the core six rules;
they simply distribute the tests over the list(s) of values and then apply
C<||>, C<&&>, or C<!...&&> between the results, short-circuiting as soon as
a guaranteed true or false result is detected.


=head3 How to get the missing C<~~> behaviours back

The availability of junctive versions of C<smartmatch()> makes it
straightforward to use that subroutine to produce most of the
disjunctive and conjunctive comparisons that the former C<~~> operator
provided.

Here is a table of just those old C<~~> behaviours that I<differ> from
the behaviour of C<smartmatch()>, and the new (mostly junctive) syntaxes
needed to get C<smartmatch()> to match in the old ways.

Note that all other forms of C<$LEFT ~~ $RIGHT> could simply be
converted directly to S<C<smartmatch($LEFT, $RIGHT)>> and would work identically.

    undef    ~~ @ARRAY     --->   smartmatch( undef,  any => $ARRAY        )
    undef    ~~ %HASH      --->   smartmatch( undef,  any => [keys %$HASH] )

    %HASH    ~~ @ARRAY     --->   smartmatch( any => [keys %HASH], any => \@ARRAY  )
    /REGEXP/ ~~ @ARRAY     --->   smartmatch( any => \@ARRAY,           qr/REGEXP/ )
    $VALUE   ~~ @ARRAY     --->   smartmatch(         $VALUE,      any => \@ARRAY  )

    %HASH1   ~~ %HASH2     --->   smartmatch( [sort keys %HASH1],  [sort keys %HASH2]  )
    @ARRAY   ~~ %HASH      --->   smartmatch( any => \@ARRAY,      any => [keys %HASH] )
    /REGEXP/ ~~ %HASH      --->   smartmatch( any => [keys %HASH], qr/REGEXP/          )
    $VALUE   ~~ %HASH      --->   smartmatch(        $VALUE,       any => [keys %HASH] )

    @ARRAY   ~~ \&SUB      --->   smartmatch( all => \@ARRAY,      \&SUB )
    %HASH    ~~ \&SUB      --->   smartmatch( all => [keys %HASH], \&SUB )

    @ARRAY   ~~ /REGEXP/   --->   smartmatch( any => \@ARRAY,      qr/REGEXP/ )
    %HASH    ~~ /REGEXP/   --->   smartmatch( any => [keys %HASH], qr/REGEXP/ )
    $REF     ~~ /REGEXP/   --->   smartmatch(        "$REF",       qr/REGEXP/ )

    $NUM     ~~ $NUMLIKE   --->   smartmatch( $NUM, 0 + $NUMLIKE )

    $REF     ~~ $STRING    --->   smartmatch( "$REF", $STRING )

These new formulations have the obvious disadvantage of being considerably more
verbose (i.e. harder to write), but they also have the obvious advantage of being
considerably more verbose (i.e. easier to read, more self-documenting, less likely
to accidentally be used incorrectly, no need to remember all 23 rules of C<~~> matching).

Many of the changes in usage stem from the fact that hashes are now treated as full hashes,
rather than as mere key-sets. The most common situation this alters is the use of smartmatching
to ensure that a set of named arguments contains all the required keys (and no others):

    my %REQUIRED_ARGS = ( name => 1, age => 1, addr => 1, status => 1 );

    sub register (%named_args) {
        croak "Incorrect named args in call to register()"
            unless %named_args ~~ %REQUIRED_ARGS;      # All the keys match
        ...
    }

This particular usage is still possible under the new smartmatch rules,
even though two hashes must now match keys I<and> values. It's possible
because the corresponding values are I<smartmatched>, and we can now use
the I<"always matches"> behaviour of a C<true> on the right-hand side
to create a C<%REQUIRED_ARGS> where the values always match, no matter what:

    # Values of "true" will always smartmatch any other value...
    my %REQUIRED_ARGS = ( name => true, age => true, addr => true, status => true );

    sub register (%named_args) {
        croak "Incorrect named args in call to register()"
            unless smartmatch(\%named_args, \%REQUIRED_ARGS);
        ...
    }

Better still, we could use the values of C<%REQUIRED_ARGS> to test the
values of C<%named_args> in various useful ways:

    my %REQUIRED_ARGS = (
        name   => qr/\S/,                  # Name can't be empty
        age    => sub ($a) { $a > 18 },    # Must be an adult
        addr   => true,                    # Address can be anything
        status => ['member', 'guest'],     # Only two statuses allowed
    );

    sub register (%named_args) {
        croak "Incorrect named args in call to register()"
            unless smartmatch(\%named_args, \%REQUIRED_ARGS);
        ...
    }

We could also use C<smartmatch()> to test that C<%named_args> contains
only valid keys, but without requiring that it contain B<every> valid key:

    my @PERMITTED_ARGS = qw( name age addr status location shoesize );

    sub update_details (%named_args) {
        croak "Unknown named arg in call to update_details()"
            unless smartmatch(all=> [keys %named_args], any => \@PERMITTED_ARGS);
        ...
    }

Overall, the goal of this reformulation of smartmatching is to continue to
provide all of the capacities of the format C<~~> operator, but without
imposing all of that former operator's often-inscrutable complexity.


=head3 Overloading C<smartmatch()> globally via the C<SMARTMATCH()> method

Yet another way that this module's version of smartmatching differs from the
former built-in mechanism is that the C<smartmatch()> function can no
longer be extended to handle new types of objects by overloading their
classes' C<~~> operators. Because, of course, with the demise of the
built-in mechanism, there is no longer any C<~~> operator to overload.

So, by default, C<smartmatch()> does not accept any object as its right-hand argument,
and immediately throws an exception if you attempt to pass one.

However, this module allows you to change that default behaviour...by defining
a special C<SMARTMATCH()> method in your class. Subsequently, when an object of
the class is passed to C<smartmatch()> as its right-hand argument
I<(and B<only> when it's the right-hand argument)>, then C<smartmatch()> matches
by attempting to call the C<SMARTMATCH()> method of the right-hand object,
passing its own left-hand argument to that method call.

In other words, S<C<smartmatch($left_arg, $right_obj)>> simply returns
the result of S<C<< $right_obj->SMARTMATCH( $left_arg ) >>>.

For example, suppose you wanted to be able to smartmatch against an
C<ID::Validator> object. In particular, suppose that, when an C<ID::Validator>
object is passed as the right-hand argument of C<smartmatch()> you need it
to call the object's C<validate()> method. You could extend the behaviour of
C<smartmatch()> in that way simply by defining a suitable C<SMARTMATCH()> method
in the C<ID::Validator> class:

    class ID::Validator {
        ...
        method SMARTMATCH ($left_arg) {
            return $self->validate( $left_arg );
        }
    }

    # Now ID::Validator objects can be passed as the right-hand arg of smartmatch()
    # (which also means they can be used as the target expression of a when block)...

    state $VALID_ID = ID::Validator->new();

    given ($id) {
        when ($VALID_ID) { say 'valid ID' }     # Same as: if ($VALID_ID->validate($_)) {...}
        default          { die 'invalid ID' }
    }

In a similar way, you could allow any C<Type::Tiny> instance to be used
as the right-hand argument of C<smartmatch()> (and therefore as the match target
of a C<when>), by injecting a C<SMARTMATCH()> method into the base class
of the framework's many type objects:

    sub Type::Tiny::SMARTMATCH ($type_obj, $test_value) {
        return $type_obj->check($test_value);
    }

    # and thereafter...

    use Types::Standard ':all';

    given ($data) {
        when (Int)         { $count += $data                    }
        when (ArrayRef)    { $count += sum @{data}              }
        when (HashRef)     { $count += sum keys %{$data}        }
        when (FileHandle)  { $count += $data->input_line_number }
        when (Object)      { $count += $data->get_count         }
    }

Note that, when an object is passed as the B<left-hand> argument to C<smartmatch()>,
that object's C<SMARTMATCH()> method is B<I<never>> invoked. The smartmatch may still,
however, invoke I<other> methods on the left-hand object (e.g. its C<q{0+}> or C<q{""}>
operator overloadings to convert it for an C<==> or C<eq> match when the right-hand
argument is a number or string).


=head3 Overloading C<smartmatch()> locally via multisubs

Because the C<smartmatch()> subroutine provided by this module is actually
a I<multisub>, implemented via the L<Multi::Dispatch> module,
C<smartmatch()> can also easily be extended locally (i.e. within a given package)
to allow it to match between additional types of arguments.

This kind of overloading is much more flexible that
L<C<SMARTMATCH()> overloading|"Overloading C<smartmatch()> globally via the C<SMARTMATCH()> method">
because you can add or modify matching behaviours for any combination of the
multisub's two arguments, rather than just adding behaviours when a particular
class of object is the right-hand argument.

Suppose that, as in the preceding section, you wanted to be able to smartmatch
against an C<ID::Validator> object. But suppose you don't control that class's code,
and you're not comfortable violating its encapsulation by offhandedly injecting
an unsanctioned C<SMARTMATCH()> method into the class
(like we did in the C<Type::Tiny> example in the previous section).

To avoid that, you could extend the behaviour of C<smartmatch()> I<locally> in your own code,
by defining a suitable additional package-scoped variant in the current scope:

    use Multi::Dispatch;  # ...so we can define a new smartmatch() variant here

    # Define new smartmatching behaviour on ID::Validator objects...
    multi smartmatch ($value, ID::Validator $obj) {
        return $obj->validate( $value );
    }

    # Now ID::Validator objects can be passed as the right-hand arg of smartmatch()
    # (which also means they can be used as the target expression of a when block)...

    state $VALID_ID = ID::Validator->new();

    given ($id) {
        when ($VALID_ID) { say 'valid ID' }     # Same as: if ($VALID_ID->validate($_)) {...}
        default          { die 'invalid ID' }
    }

Likewise, you could permit smartmatching against L<Type::Tiny> objects,
without messing about with the framework's internals, with:

    multi smartmatch ($value, Type::Tiny $type) {
        return $type->check( $value );
    }

More generally, if you wanted to allow any object to be passed as the right-hand
argument to C<smartmatch()>, provided that object has a stringification or numerification
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

You can also I<change> the existing behaviours of C<smartmatch()> by providing
local variants for one or more specific cases that the multisub already handles:

    use Multi::Dispatch;

    # Change how smartmatch() compares a hash and an array
    # The standard behaviour is to always fail to match (because a hash isn't an array).
    # But here we change it so that it uses the weird old C<~~> behaviour,
    # which was to match if any hash key matched any value in the array...

    multi smartmatch (HASH $href, ARRAY $aref) {
        return smartmatch(any => [keys %{$href}], any => $aref);
    }

For further details on the numerous features and capabilities of the C<multi> keyword,
see the L<Multi::Dispatch> module.



=head1 LIMITATIONS

The re-implementation of C<given>/C<when> provided by this module aims to
provide all the capabilities of the former built-in C<given>/C<when> construct
(albeit, via a vastly simplified set of rules for smartmatching, combined with
the three junctive extensions)

However, it currently fails to meet that goal in several ways:

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
and the file F<t/given_when_noncompatible.t> for examples the will not work
(currently, or probably ever).


=head2 Limitation 2. You can't ever use a C<when> modifier outside a C<given>

The former built-in mechanism allowed a postfix C<when> modifier to be used
within a C<for> loop, like so:

    for (@data) {
        say when $TARGET_VALUE
    }

This module does not allow C<when> to be used as a statement modifier
anywhere except inside a C<given> block. The above code would therefore have to
be rewritten to either:

    for (@data) {
        given ($) {
            say when $TARGET_VALUE;
        }
    }

Or, because the module does allow full C<when> blocks in a C<for> loop,
you could also rewrite it to:

    for (@data) {
        when ($TARGET_VALUE) { say }
    }


=head2 Limitation 3. Scoping anomalies with C<when> modifiers

The behaviour of obscure usages such as:

    my $x = 0;
    given (my $x = 1) {
        my $x = 2, continue when 1;
        say $x;
    }

...differs between the former built-in C<given>/C<when> and this module's reinvention of it.
Under the built-in feature, C<$x> would contain C<undef> at the S<C<say $x>> line;
under the module, C<$x> will contain 2.

As neither result seems to make much sense, or be particularly useful,
it is unlikely that this incompatibility will be much of a issue for most users.


=head1 DIAGNOSTICS

The module may produce the following exceptions or warnings...

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
somewhere else. That never worked with the old built-in syntax, and it doesn't
work with this module either.

Move your block inside a C<given> or a C<for> loop.


=item C<< Can't specify postfix "when" modifier outside a "given" >>

It is a limitation of this module that you can only use the C<EXPR when EXPR>
syntax inside a C<given> (not inside a C<for> loop).

If your postfix C<when> modifier is inside a loop, convert it to a C<when> block instead.
Or else wrap a S<C<< given ($_) { ... } >>> around the postfix C<when>.


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

The new smartmatching behaviour provided by this module
does not, by default, support the smartmatching of objects
in most cases.

If you want to use an object in a C<given> or C<when>, you will need
to provide it with either a C<SMARTMATCH()> method or a local variant
of C<smartmatch()> that handles that kind of object.

See L<"Overloading C<smartmatch()> globally via the C<SMARTMATCH()> method">
and L<"Overloading C<smartmatch()> locally via multisubs"> for details of
these two different approaches for supporting objects in switches.


=item C<< Useless use of a constant in void context >>

Apart from the many other unrelated reasons your code may produced this error,
if the constant it is uselessly using is inside a C<when> block that is supposed
to feed a surrounding C<do> block, this error probably indicates that your
C<given>/C<when> is not one that this module can rewrite for that purpose.

See L<"Limitation 1. You can't always use a C<given> inside a C<do> block">
for details of this issue, and how to work around it.

=back


=head1 CONFIGURATION AND ENVIRONMENT

Switch::Right requires no configuration files or environment variables.


=head1 DEPENDENCIES

This module requires the L<B::Deparse>, L<Keyword::Simple>, L<Multi::Dispatch>,
L<Object::Pad>, L<PPR>, L<Test2::V0>, and L<Type::Tiny> modules.

The module only works under Perl v5.36 and later.


=head1 INCOMPATIBILITIES

This module uses the Perl keyword mechanism to (re)extend the Perl syntax
to include new versions of the C<given>/C<when>/C<default> blocks.
Hence it is likely to be incompatible with other modules that add
other keywords to the language.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-switch-right@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 SEE ALSO

The L<Switch::Back> module provides a (nearly) fully backwards-compatible
alternative to this module, which restores (almost) all of the syntax,
behaviour, and idiosyncrasies of former switch and smartmatch features.


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
