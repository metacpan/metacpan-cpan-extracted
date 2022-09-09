package PPR;

use 5.010;
use if $] < 5.018004, re => 'eval';

BEGIN {
    if ($] >= 5.020 && $] <= 5.021) {
        say {STDERR} <<"        END_WARNING"
        Warning: This program is running under Perl $^V and uses the PPR module.
                 Due to an unresolved issue with compilation of large regexes
                 in this version of Perl, your code is likely to compile
                 extremely slowly (i.e. it may take more than a minute).
                 PPR is being loaded at ${\join ' line ', (caller 2)[1,2]}.
        END_WARNING
    }
}
use warnings;
our $VERSION = '0.001006';
use utf8;
use List::Util qw<min max>;

# Class for $PPR::ERROR objects...
{ package PPR::ERROR;

  use overload q{""} => 'source', q{0+} => 'line', fallback => 1;

  sub new {
      my ($class, %obj) = @_;
      return bless \%obj, $class;
  }

  sub prefix { return shift->{prefix} }

  sub source { return shift->{source} }

  sub line   { my $self = shift;
               my $offset = $self->{line} // shift // 1;
               return $offset + $self->{prefix} =~ tr/\n//;
              }

  sub origin { my $self = shift;
               my $line = shift // 0;
               my $file = shift // "";
               return bless { %{$self}, line => $line, file => $file }, ref($self);
             }

  sub diagnostic { my $self = shift;
                   my $line = defined $self->{line}
                                    ? $self->{line} + $self->{prefix} =~ tr/\n//
                                    : 0;
                   my $file = $self->{file} // q{};
                   return q{} if eval "no strict;\n"
                                    . "#line $line $file\n"
                                    . "sub{ $self->{source} }";
                   my $diagnostic = $@;
                   $diagnostic =~ s{ \s*+ \bat \s++ \( eval \s++ \d++ \) \s++ line \s++ 0,
                                   | \s*+ \( eval \s++ \d++ \)
                                   | \s++ \Z
                                   }{}gx;
                   return $diagnostic;
                 }
}

# Define the grammar...
our $GRAMMAR = qr{
    (?(DEFINE)

        (?<PerlEntireDocument>
            \A
            (?&PerlDocument)
            (?:
                \Z
            |
                (?(?{ !defined $PPR::ERROR })
                    (?>(?&PerlOWSOrEND))  (?{pos()})  ([^\n]++)
                    (?{ $PPR::ERROR = PPR::ERROR->new(source => "$^N", prefix => substr($_, 0, $^R) ) })
                    (?!)
                )
            )
        ) # End of rule (?<PerlEntireDocument>)

        (?<PerlDocument>
            \x{FEFF}?+                      # Optional BOM marker
            (?&PerlStatementSequence)
            (?&PerlOWSOrEND)
        ) # End of rule (?<PerlDocument>)

        (?<PerlStatementSequence>
            (?>(?&PerlPodSequence))
            (?:
                (?&PerlStatement)
                (?&PerlPodSequence)
            )*+
        ) # End of rule (?<PerlStatementSequence>)

        (?<PerlStatement>
            (?>
                (?>(?&PerlPodSequence))
                (?: (?>(?&PerlLabel)) (?&PerlOWSOrEND) )?+
                (?>(?&PerlPodSequence))
                (?>
                    (?&PerlKeyword)
                |
                    # Inlined (?&PerlSubroutineDeclaration)
                    (?>
                        (?: (?> my | our | state ) \b      (?>(?&PerlOWS)) )?+
                        sub \b                             (?>(?&PerlOWS))
                        (?>(?&PerlOldQualifiedIdentifier))    (?&PerlOWS)
                    |
                        AUTOLOAD                              (?&PerlOWS)
                    |
                        DESTROY                               (?&PerlOWS)
                    )
                    (?:
                        # Perl pre 5.028
                        (?:
                            (?>
                                (?&PerlSignature)    # Parameter list
                            |
                                \( [^)]*+ \)         # Prototype (
                            )
                            (?&PerlOWS)
                        )?+
                        (?: (?>(?&PerlAttributes))  (?&PerlOWS) )?+
                    |
                        # Perl post 5.028
                        (?: (?>(?&PerlAttributes))  (?&PerlOWS) )?+
                        (?: (?>(?&PerlSignature))   (?&PerlOWS) )?+    # Parameter list
                    )
                    (?> ; | (?&PerlBlock) )
                    # End of inlining
                |
                    # Inlined (?&PerlUseStatement)
                    (?: use | no ) (?>(?&PerlNWS))
                    (?>
                        (?&PerlVersionNumber)
                    |
                        (?>(?&PerlQualifiedIdentifier))
                        (?: (?>(?&PerlNWS)) (?&PerlVersionNumber)
                            (?! (?>(?&PerlOWS)) (?> (?&PerlInfixBinaryOperator) | (?&PerlComma) | \? ) )
                        )?+
                        (?: (?>(?&PerlNWS)) (?&PerlPodSequence) )?+
                        (?: (?>(?&PerlOWS)) (?&PerlExpression) )?+
                    )
                    (?>(?&PerlOWSOrEND)) (?> ; | (?= \} | \z ))
                    # End of inlining
                |
                    # Inlined (?&PerlPackageDeclaration)
                    package
                        (?>(?&PerlNWS)) (?>(?&PerlQualifiedIdentifier))
                    (?: (?>(?&PerlNWS)) (?&PerlVersionNumber) )?+
                        (?>(?&PerlOWSOrEND)) (?> ; | (?&PerlBlock) | (?= \} | \z ))
                    # End of inlining
                |
                    (?&PerlControlBlock)
                |
                    (?&PerlFormat)
                |
                    (?>(?&PerlExpression))          (?>(?&PerlOWS))
                    (?&PerlStatementModifier)?+     (?>(?&PerlOWSOrEND))
                    (?> ; | (?= \} | \z ))
                |
                    (?&PerlBlock)
                |
                    ;
                )

            | # A yada-yada...
                \.\.\. (?>(?&PerlOWSOrEND))
                (?> ; | (?= \} | \z ))

            | # Just a label...
                (?>(?&PerlLabel)) (?>(?&PerlOWSOrEND))
                (?> ; | (?= \} | \z ))

            | # Just an empty statement...
                (?>(?&PerlOWS)) ;

            | # An error (report it, if it's the first)...
                (?(?{ !defined $PPR::ERROR })
                    (?> (?&PerlOWS) )
                    (?! (?: \} | \z ) )
                    (?{ pos() })
                    ( (?&PerlExpression) (?&PerlOWS) [^\n]++ | [^;\}]++ )
                    (?{ $PPR::ERROR //= PPR::ERROR->new(source => $^N, prefix => substr($_, 0, $^R) ) })
                    (?!)
                )
            )
        ) # End of rule (?<PerlStatement>)

        (?<PerlSubroutineDeclaration>
        (?>
            (?: (?> my | our | state ) \b      (?>(?&PerlOWS)) )?+
            sub \b                             (?>(?&PerlOWS))
            (?>(?&PerlOldQualifiedIdentifier))    (?&PerlOWS)
        |
            AUTOLOAD                              (?&PerlOWS)
        |
            DESTROY                               (?&PerlOWS)
        )
        (?:
            # Perl pre 5.028
            (?:
                (?>
                    (?&PerlSignature)    # Parameter list
                |
                    \( [^)]*+ \)         # Prototype (
                )
                (?&PerlOWS)
            )?+
            (?: (?>(?&PerlAttributes))  (?&PerlOWS) )?+
        |
            # Perl post 5.028
            (?: (?>(?&PerlAttributes))  (?&PerlOWS) )?+
            (?: (?>(?&PerlSignature))   (?&PerlOWS) )?+    # Parameter list
        )
        (?> ; | (?&PerlBlock) )
        ) # End of rule (?<PerlSubroutineDeclaration>)

        (?<PerlSignature>
            \(
                (?>(?&PerlOWS))
                (?&PerlParameterDeclaration)*+
            \)
        ) # End of rule (?<PerlSignature>)

        (?<PerlParameterDeclaration>
            (?:
                    \$  (?>(?&PerlOWS))
                (?: =   (?>(?&PerlOWS))  (?&PerlConditionalExpression)?+ (?>(?&PerlOWS)) )?+
            |
                (?&PerlVariableScalar) (?>(?&PerlOWS))
                (?: =   (?>(?&PerlOWS))  (?&PerlConditionalExpression)   (?>(?&PerlOWS)) )?+
            |
                (?&PerlVariableArray) (?>(?&PerlOWS))
            |
                (?&PerlVariableHash)  (?>(?&PerlOWS))
            )
            (?: , (?>(?&PerlOWS))  |  (?= \) ) )     # (
        ) # End of rule (?<PerlParameterDeclaration>)


        (?<PerlUseStatement>
        (?: use | no ) (?>(?&PerlNWS))
        (?>
            (?&PerlVersionNumber)
        |
            (?>(?&PerlQualifiedIdentifier))
            (?: (?>(?&PerlNWS)) (?&PerlVersionNumber)
                (?! (?>(?&PerlOWS)) (?> (?&PerlInfixBinaryOperator) | (?&PerlComma) | \? ) )
            )?+
            (?: (?>(?&PerlNWS)) (?&PerlPodSequence) )?+
            (?: (?>(?&PerlOWS)) (?&PerlExpression) )?+
        )
        (?>(?&PerlOWSOrEND)) (?> ; | (?= \} | \z ))
        ) # End of rule (?<PerlUseStatement>)

        (?<PerlReturnExpression>
        return \b (?: (?>(?&PerlOWS)) (?&PerlExpression) )?+
        ) # End of rule (?<PerlReturnExpression>)

        (?<PerlReturnStatement>
        return \b (?: (?>(?&PerlOWS)) (?&PerlExpression) )?+
        (?>(?&PerlOWSOrEND)) (?> ; | (?= \} | \z ))
        ) # End of rule (?<PerlReturnStatement>)

        (?<PerlPackageDeclaration>
        package
            (?>(?&PerlNWS)) (?>(?&PerlQualifiedIdentifier))
        (?: (?>(?&PerlNWS)) (?&PerlVersionNumber) )?+
            (?>(?&PerlOWSOrEND)) (?> ; | (?&PerlBlock) | (?= \} | \z ))
        ) # End of rule (?<PerlPackageDeclaration>)

        (?<PerlExpression>
                                (?>(?&PerlLowPrecedenceNotExpression))
            (?: (?>(?&PerlOWS)) (?>(?&PerlLowPrecedenceInfixOperator))
                (?>(?&PerlOWS))    (?&PerlLowPrecedenceNotExpression)  )*+
        ) # End of rule (?<PerlExpression>)

        (?<PerlLowPrecedenceNotExpression>
            (?: not \b (?&PerlOWS) )*+  (?&PerlCommaList)
        ) # End of rule (?<PerlLowPrecedenceNotExpression>)

        (?<PerlCommaList>
                    (?>(?&PerlAssignment))  (?>(?&PerlOWS))
            (?:
                (?: (?>(?&PerlComma))          (?&PerlOWS)   )++
                    (?>(?&PerlAssignment))  (?>(?&PerlOWS))
            )*+
                (?: (?>(?&PerlComma))          (?&PerlOWSOrEND)   )*+
        ) # End of rule (?<PerlCommaList>)

        (?<PerlAssignment>
                                (?>(?&PerlConditionalExpression))
            (?:
                (?>(?&PerlOWS)) (?>(?&PerlAssignmentOperator))
                (?>(?&PerlOWS))    (?&PerlConditionalExpression)
            )*+
        ) # End of rule (?<PerlAssignment>)

        (?<PerlScalarExpression>
        (?<PerlConditionalExpression>
            (?>(?&PerlBinaryExpression))
            (?:
                (?>(?&PerlOWS)) \? (?>(?&PerlOWS)) (?>(?&PerlAssignment))
                (?>(?&PerlOWS))  : (?>(?&PerlOWS))    (?&PerlConditionalExpression)
            )?+
        ) # End of rule (?<PerlConditionalExpression>)
        ) # End of rule (?<PerlScalarExpression>)

        (?<PerlBinaryExpression>
                                (?>(?&PerlPrefixPostfixTerm))
            (?: (?>(?&PerlOWS)) (?>(?&PerlInfixBinaryOperator))
                (?>(?&PerlOWS))    (?&PerlPrefixPostfixTerm) )*+
        ) # End of rule (?<PerlBinaryExpression>)

        (?<PerlPrefixPostfixTerm>
            (?: (?>(?&PerlPrefixUnaryOperator))  (?&PerlOWS) )*+
            (?>(?&PerlTerm))
            (?: (?>(?&PerlOWS)) (?&PerlPostfixUnaryOperator) )?+
        ) # End of rule (?<PerlPrefixPostfixTerm>)

        (?<PerlLvalue>
            (?>
                \\?+ [\$\@%] (?>(?&PerlOWS)) (?&PerlIdentifier)
            |
                \(                                                                     (?>(?&PerlOWS))
                    (?> \\?+ [\$\@%] (?>(?&PerlOWS)) (?&PerlIdentifier) | undef )      (?>(?&PerlOWS))
                    (?:
                        (?>(?&PerlComma))                                              (?>(?&PerlOWS))
                        (?> \\?+ [\$\@%] (?>(?&PerlOWS)) (?&PerlIdentifier) | undef )  (?>(?&PerlOWS))
                    )*+
                    (?: (?>(?&PerlComma)) (?&PerlOWS) )?+
                \)
            )
        ) # End of rule (?<PerlLvalue>)

        (?<PerlTerm>
            (?>
                # Inlined (?&PerlReturnExpression)
                return \b (?: (?>(?&PerlOWS)) (?&PerlExpression) )?+
                # End of inlining

            # The remaining alternatives can all take postfix dereferencers...
            | (?:
                    (?= \$ )  (?&PerlScalarAccess)
              |
                    (?= \@ )  (?&PerlArrayAccess)
              |
                    (?=  % )  (?&PerlHashAccess)
              |
                    (?&PerlAnonymousSubroutine)
              |
                    (?>(?&PerlNullaryBuiltinFunction))  (?! (?>(?&PerlOWS)) \( )
              |
                    # Inlined (?&PerlDoBlock) | (?&PerlEvalBlock)
                    (?> do | eval ) (?>(?&PerlOWS)) (?&PerlBlock)
                    # End of inlining
              |
                    (?&PerlCall)
              |
                    # Inlined (?&PerlVariableDeclaration)
                    (?> my | our | state ) \b           (?>(?&PerlOWS))
                    (?: (?&PerlQualifiedIdentifier)        (?&PerlOWS)  )?+
                    (?>(?&PerlLvalue))                  (?>(?&PerlOWSOrEND))
                    (?&PerlAttributes)?+
                    # End of inlining
              |
                    (?&PerlTypeglob)
              |
                    (?>(?&PerlParenthesesList))

                    # Can optionally do a [...] lookup straight after the parens,
                    # followd by any number of other look-ups
                    (?:
                        (?>(?&PerlOWS)) (?&PerlArrayIndexer)
                        (?:
                            (?>(?&PerlOWS))
                            (?>
                                (?&PerlArrayIndexer)
                            |   (?&PerlHashIndexer)
                            |   (?&PerlParenthesesList)
                            )
                        )*+
                    )?+
              |
                    (?&PerlAnonymousArray)
              |
                    (?&PerlAnonymousHash)
              |
                    (?&PerlDiamondOperator)
              |
                    (?&PerlContextualMatch)
              |
                    (?&PerlQuotelikeS)
              |
                    (?&PerlQuotelikeTR)
              |
                    (?&PerlQuotelikeQX)
              |
                    (?&PerlLiteral)
              )

              (?: (?&PerlTermPostfixDereference) )?+
            )
        ) # End of rule (?<PerlTerm>)

        (?<PerlTermPostfixDereference>
            # Must have at least one arrowed dereference...
            (?:
                (?>(?&PerlOWS)) -> (?>(?&PerlOWS))
                (?>
                    # A series of simple brackets can omit interstitial arrows...
                    (?>  (?&PerlParenthesesList) | (?&PerlArrayIndexer) | (?&PerlHashIndexer) )
                    (?:
                        (?>(?&PerlOWS))
                        (?> (?&PerlParenthesesList) | (?&PerlArrayIndexer) | (?&PerlHashIndexer) )
                    )*+

                |   # A method call...
                    (?> (?&PerlQualifiedIdentifier) | (?! \$\#\* ) (?&PerlVariableScalar) )
                    (?: (?>(?&PerlOWS)) (?&PerlParenthesesList) )?+

                |   # An array or hash slice or k/v slice
                    # (provided it's not subsequently dereferenced)
                    [\@%] (?> (?>(?&PerlArrayIndexer)) | (?>(?&PerlHashIndexer)) )
                    (?! (?>(?&PerlOWS)) -> (?>(?&PerlOWS))  [\@%]?+  [\[\{] )

                |   # An array max-index lookup...
                    \$\#\*

                |   # A scalar-, glob-, or subroutine dereference...
                    [\$*&] \*

                |   # An array dereference (provided it's not subsequently dereferenced)...
                    \@\*
                    (?! (?>(?&PerlOWS)) -> (?>(?&PerlOWS)) [\[\@] )

                |   # A hash dereference (provided it's not subsequently dereferenced)...
                    \%\*
                    (?! (?>(?&PerlOWS)) -> (?>(?&PerlOWS)) [\{%] )

                |   # A glob lookup...
                    \* (?&PerlHashIndexer)
                )
            )++
        ) # End of rule (?<PerlTermPostfixDereference>)

        (?<PerlControlBlock>
            (?> # Conditionals...
                (?> if | unless ) \b                 (?>(?&PerlOWS))
                (?>(?&PerlParenthesesList))          (?>(?&PerlOWS))
                (?>(?&PerlBlock))

                (?:
                                                    (?>(?&PerlOWS))
                    (?>(?&PerlPodSequence))
                    elsif \b                         (?>(?&PerlOWS))
                    (?>(?&PerlParenthesesList))      (?>(?&PerlOWS))
                    (?&PerlBlock)
                )*+

                (?:
                                                    (?>(?&PerlOWS))
                    (?>(?&PerlPodSequence))
                    else \b                          (?>(?&PerlOWS))
                    (?&PerlBlock)
                )?+

            |   # Loops...
                (?>
                    for(?:each)?+ \b
                    (?>(?&PerlOWS))
                    (?:
                        (?> # Explicitly aliased iterator variable...
                            (?> \\ (?>(?&PerlOWS))  (?> my | our | state )
                            |                       (?> my | our | state )  (?>(?&PerlOWS)) \\
                            )
                            (?>(?&PerlOWS))
                            (?> (?&PerlVariableScalar)
                            |   (?&PerlVariableArray)
                            |   (?&PerlVariableHash)
                            )
                        |
                            # List of scalar iterator variables...
                            my                                   (?>(?&PerlOWS))
                            \(                                   (?>(?&PerlOWS))
                                    (?>(?&PerlVariableScalar))   (?>(?&PerlOWS))
                                (?: ,                            (?>(?&PerlOWS))
                                    (?>(?&PerlVariableScalar))   (?>(?&PerlOWS))
                                )*+
                                (?: ,                            (?>(?&PerlOWS)) )?+
                            \)

                        |
                            # Implicitly aliased iterator variable...
                            (?> (?: my | our | state ) (?>(?&PerlOWS)) )?+
                            (?&PerlVariableScalar)
                        )?+
                        (?>(?&PerlOWS))
                        (?> (?&PerlParenthesesList) | (?&PerlQuotelikeQW) )
                    |
                        (?&PPR_three_part_list)
                    )
                |
                    (?> while | until) \b (?>(?&PerlOWS))
                    (?&PerlParenthesesList)
                )

                (?>(?&PerlOWS))
                (?>(?&PerlBlock))

                (?:
                    (?>(?&PerlOWS))   continue
                    (?>(?&PerlOWS))   (?&PerlBlock)
                )?+

            | # Phasers...
                (?> BEGIN | END | CHECK | INIT | UNITCHECK ) \b   (?>(?&PerlOWS))
                (?&PerlBlock)

            | # Try/catch/finallys...
                (?>(?&PerlTryCatchFinallyBlock))

            | # Defers...
                defer                                     (?>(?&PerlOWS))
                (?&PerlBlock)

            | # Switches...
                (?> given | when ) \b                     (?>(?&PerlOWS))
                (?>(?&PerlParenthesesList))               (?>(?&PerlOWS))
                (?&PerlBlock)
            |
                default                                   (?>(?&PerlOWS))
                (?&PerlBlock)
            )
        ) # End of rule (?<PerlControlBlock>)

        (?<PerlFormat>
            format
            (?: (?>(?&PerlNWS))  (?&PerlQualifiedIdentifier)  )?+
                (?>(?&PerlOWS))  = [^\n]*+
                (?&PPR_newline_and_heredoc)
            (?:
                (?! \. \n )
                [^\n\$\@]*+
                (?:
                    (?>
                        (?= \$ (?! \s ) )  (?&PerlScalarAccessNoSpace)
                    |
                        (?= \@ (?! \s ) )  (?&PerlArrayAccessNoSpace)
                    )
                    [^\n\$\@]*+
                )*+
                (?&PPR_newline_and_heredoc)
            )*+
            \. (?&PerlEndOfLine)
        ) # End of rule (?<PerlFormat>)

        (?<PerlStatementModifier>
            (?> if | for(?:each)?+ | while | unless | until | when )
            \b
            (?>(?&PerlOWS))
            (?&PerlExpression)
        ) # End of rule (?<PerlStatementModifier>)

        (?<PerlBlock>
            \{  (?>(?&PerlStatementSequence))  \}
        ) # End of rule (?<PerlBlock>)

        (?<PerlCall>
            (?>
                [&]                                    (?>(?&PerlOWS))
                (?> (?&PerlBlock)
                |   (?&PerlVariableScalar)
                |   (?&PerlQualifiedIdentifier)
                )                                      (?>(?&PerlOWS))
                (?:
                    \(                                 (?>(?&PerlOWS))
                        (?: (?>(?&PerlExpression))        (?&PerlOWS)   )?+
                    \)
                )?+
            |
                - (?>(?&PPR_filetest_name))            (?>(?&PerlOWS))
                (?&PerlPrefixPostfixTerm)?+
            |
                (?>(?&PerlBuiltinFunction))            (?>(?&PerlOWS))
                (?>
                    \(                                 (?>(?&PerlOWS))
                        (?>
                            (?= (?>(?&PPR_non_reserved_identifier))
                                (?>(?&PerlOWS))
                                (?! \( | (?&PerlComma) )
                            )
                            (?&PerlCall)
                        |
                            (?>(?&PerlBlock))          (?>(?&PerlOWS))
                            (?&PerlExpression)?+
                        |
                            (?>(?&PPR_indirect_obj))   (?>(?&PerlNWS))
                            (?&PerlExpression)
                        |
                            (?&PerlExpression)?+
                        )                              (?>(?&PerlOWS))
                    \)
                |
                        (?>
                            (?=
                                (?>(?&PPR_non_reserved_identifier))
                                (?>(?&PerlOWS))
                                (?! \( | (?&PerlComma) )
                            )
                            (?&PerlCall)
                        |
                            (?>(?&PerlBlock))          (?>(?&PerlOWS))
                            (?&PerlCommaList)?+
                        |
                            (?>(?&PPR_indirect_obj))   (?>(?&PerlNWS))
                            (?&PerlCommaList)
                        |
                            (?&PerlCommaList)?+
                        )
                )
            |
                (?>(?&PPR_non_reserved_identifier)) (?>(?&PerlOWS))
                (?>
                    \(                              (?>(?&PerlOWS))
                        (?: (?>(?&PerlExpression))     (?&PerlOWS)  )?+
                    \)
                |
                        (?>
                            (?=
                                (?>(?&PPR_non_reserved_identifier))
                                (?>(?&PerlOWS))
                                (?! \( | (?&PerlComma) )
                            )
                            (?&PerlCall)
                        |
                            (?>(?&PerlBlock))           (?>(?&PerlOWS))
                            (?&PerlCommaList)?+
                        |
                            (?>(?&PPR_indirect_obj))        (?&PerlNWS)
                            (?&PerlCommaList)
                        |
                            (?&PerlCommaList)?+
                        )
                )
            )
        ) # End of rule (?<PerlCall>)

        (?<PerlVariableDeclaration>
            (?> my | our | state ) \b           (?>(?&PerlOWS))
            (?: (?&PerlQualifiedIdentifier)        (?&PerlOWS)  )?+
            (?>(?&PerlLvalue))                  (?>(?&PerlOWS))
            (?&PerlAttributes)?+
        ) # End of rule (?<PerlVariableDeclaration>)

        (?<PerlDoBlock>
            do (?>(?&PerlOWS)) (?&PerlBlock)
        ) # End of rule (?<PerlDoBlock>)

        (?<PerlEvalBlock>
            eval (?>(?&PerlOWS)) (?&PerlBlock)
        ) # End of rule (?<PerlEvalBlock>)

        (?<PerlTryCatchFinallyBlock>

                try \b                                (?>(?&PerlOWS))
                (?>(?&PerlBlock))
                                                      (?>(?&PerlOWS))
                catch \b                              (?>(?&PerlOWS))
                \(  (?>(?&PerlVariableScalar))  \)    (?>(?&PerlOWS))
                (?>(?&PerlBlock))

            (?:
                                                      (?>(?&PerlOWS))
                finally \b                            (?>(?&PerlOWS))
                (?>(?&PerlBlock))
            )?+
        ) # End of rule (?<PerlTryCatchFinallyBlock>)

        (?<PerlAttributes>
            :
            (?>(?&PerlOWS))
            (?>(?&PerlIdentifier))
            (?:
                (?= \( ) (?&PPR_quotelike_body)
            )?+

            (?:
                (?> (?>(?&PerlOWS)) : (?&PerlOWS) | (?&PerlNWS) )
                (?>(?&PerlIdentifier))
                (?:
                    (?= \( ) (?&PPR_quotelike_body)
                )?+
            )*+
        ) # End of rule (?<PerlAttributes>)

        (?<PerlList>
            (?> (?&PerlParenthesesList) | (?&PerlCommaList) )
        ) # End of rule (?<PerlList>)

        (?<PerlParenthesesList>
            \(  (?>(?&PerlOWS))  (?: (?>(?&PerlExpression)) (?&PerlOWS) )?+  \)
        ) # End of rule (?<PerlParenthesesList>)

        (?<PerlAnonymousArray>
            \[  (?>(?&PerlOWS))  (?: (?>(?&PerlExpression)) (?&PerlOWS) )?+  \]
        ) # End of rule (?<PerlAnonymousArray>)

        (?<PerlAnonymousHash>
            \{  (?>(?&PerlOWS))  (?: (?>(?&PerlExpression)) (?&PerlOWS) )?+ \}
        ) # End of rule (?<PerlAnonymousHash>)

        (?<PerlArrayIndexer>
            \[                          (?>(?&PerlOWS))
                (?>(?&PerlExpression))  (?>(?&PerlOWS))
            \]
        ) # End of rule (?<PerlArrayIndexer>)

        (?<PerlHashIndexer>
            \{  (?>(?&PerlOWS))
                (?: -?+ (?&PerlIdentifier) | (?&PerlExpression) )  # (Note: MUST allow backtracking here)
                (?>(?&PerlOWS))
            \}
        ) # End of rule (?<PerlHashIndexer>)

        (?<PerlDiamondOperator>
            <<>>    # Perl 5.22 "double diamond"
        |
            < (?! < )
                (?>(?&PPR_balanced_angles))
            >
            (?=
                (?>(?&PerlOWSOrEND))
                (?> \z | [,;\}\])?] | => | : (?! :)        # (
                |   (?&PerlInfixBinaryOperator) | (?&PerlLowPrecedenceInfixOperator)
                |   (?= \w) (?> for(?:each)?+ | while | if | unless | until | when )
                )
            )
        ) # End of rule (?<PerlDiamondOperator>)

        (?<PerlComma>
            (?> , | => )
        ) # End of rule (?<PerlComma>)

        (?<PerlPrefixUnaryOperator>
            (?> \+\+ | -- | [!\\+~] | - (?! (?&PPR_filetest_name) \b ) )
        ) # End of rule (?<PerlPrefixUnaryOperator>)

        (?<PerlPostfixUnaryOperator>
            (?> \+\+  |  -- )
        ) # End of rule (?<PerlPostfixUnaryOperator>)

        (?<PerlInfixBinaryOperator>
            (?>  [=!][~=]
            |    cmp
            |    <= >?+
            |    >=
            |    [lg][te]
            |    eq
            |    ne
            |    [+]             (?! [+=] )
            |     -              (?! [-=] )
            |    [.]{2,3}+
            |    [.%x]           (?! [=]  )
            |    [&|^][.]        (?! [=]  )
            |    [<>*&|/]{1,2}+  (?! [=]  )
            |    \^              (?! [=]  )
            |    ~~
            |    isa
            )
        ) # End of rule (?<PerlInfixBinaryOperator>)

        (?<PerlAssignmentOperator>
            (?:  [<>*&|/]{2}
            |  [-+.*/%x]
            |  [&|^][.]?+
            )?+
            =
            (?! > )
        ) # End of rule (?<PerlAssignmentOperator>)

        (?<PerlLowPrecedenceInfixOperator>
            (?> or | and | xor )
        ) # End of rule (?<PerlLowPrecedenceInfixOperator>)

        (?<PerlAnonymousSubroutine>
            sub \b
            (?>(?&PerlOWS))
            (?:
                # Perl pre 5.028
                (?:
                    (?>
                        (?&PerlSignature)    # Parameter list
                    |
                        \( [^)]*+ \)         # Prototype (
                    )
                    (?&PerlOWS)
                )?+
                (?: (?>(?&PerlAttributes))  (?&PerlOWS) )?+
            |
                # Perl post 5.028
                (?: (?>(?&PerlAttributes))  (?&PerlOWS) )?+
                (?: (?>(?&PerlSignature))   (?&PerlOWS) )?+    # Parameter list
            )
            (?&PerlBlock)
        ) # End of rule (?<PerlAnonymousSubroutine>)

        (?<PerlVariable>
            (?= [\$\@%] )
            (?>
                (?&PerlScalarAccess)
            |   (?&PerlHashAccess)
            |   (?&PerlArrayAccess)
            )
            (?> (?&PerlTermPostfixDereference) )?+
        ) # End of rule (?<PerlVariable>)

        (?<PerlTypeglob>
            \*
            (?>
                \d++
            |
                \^ [][A-Z^_?\\]
            |
                \{ \^ [A-Z_] \w*+ \}
            |
                (?>(?&PerlOldQualifiedIdentifier))  (?: :: )?+
            |
                (?&PerlVariableScalar)
            |
                [][!"#\$%&'()*+,./:;<=>?\@\^`|~-]
            |
                (?&PerlBlock)
            )

            # Optional arrowless access(es) to begin (but can't start with a parens)...
            (?:
                (?! (?>(?&PerlOWS)) \( )
                (?:
                    (?>(?&PerlOWS))
                    (?: (?&PerlArrayIndexer) | (?&PerlHashIndexer) | (?&PerlParenthesesList) )
                )++
            )?+

            # Note: subsequent arrowed postdereferences that would follow here
            #       are handled at the <PerlTerm> level

        ) # End of rule (?<PerlTypeglob>)

        (?<PerlArrayAccess>
            (?>(?&PerlVariableArray))

            # Optional arrowless access(es) to begin (but can't start with a parens)...
            (?:
                (?! (?>(?&PerlOWS)) \( )
                (?:
                    (?>(?&PerlOWS))
                    (?: (?&PerlArrayIndexer) | (?&PerlHashIndexer) | (?&PerlParenthesesList) )
                )++
            )?+

            # Note: subsequent arrowed postdereferences that would follow here
            #       are handled at the <PerlTerm> level

        ) # End of rule (?<PerlArrayAccess>)

        (?<PerlArrayAccessNoSpace>
            (?>(?&PerlVariableArrayNoSpace))

            # Optional arrowless access(es) to begin
            (?: (?&PerlArrayIndexer) | (?&PerlHashIndexer) )*+

            # Then any number of optional arrowed accesses
            # (this is an inlined subset of (?&PerlTermPostfixDereference))...
            (?:
                ->
                (?>
                    # A series of simple brackets can omit interstitial arrows...
                    (?:  (?&PerlArrayIndexer)
                    |    (?&PerlHashIndexer)
                    )++

                |   # An array or hash slice...
                    \@ (?> (?>(?&PerlArrayIndexer)) | (?>(?&PerlHashIndexer)) )
                )
            )*+

            # Followed by at most one of these terminal arrowed dereferences...
            (?:
                ->
                (?>
                    # An array or scalar deref...
                    [\@\$] \*

                |   # An array count deref...
                    \$ \# \*
                )
            )?+
        ) # End of rule (?<PerlArrayAccessNoSpace>)

        (?<PerlArrayAccessNoSpaceNoArrow>
            (?>(?&PerlVariableArray))
            (?:
                (?: (?&PerlArrayIndexer) | (?&PerlHashIndexer) )
            )*+
        ) # End of rule (?<PerlArrayAccessNoSpaceNoArrow>)

        (?<PerlHashAccess>
            (?>(?&PerlVariableHash))

            # Optional arrowless access(es) to begin (but can't start with a parens)...
            (?:
                (?! (?>(?&PerlOWS)) \( )
                (?:
                    (?>(?&PerlOWS))
                    (?: (?&PerlArrayIndexer) | (?&PerlHashIndexer) | (?&PerlParenthesesList) )
                )++
            )?+
        ) # End of rule (?<PerlHashAccess>)

        (?<PerlScalarAccess>
            (?>(?&PerlVariableScalar))

            # Optional arrowless access(es) to begin (but can't start with a parens)...
            (?:
                (?! (?>(?&PerlOWS)) \( )
                (?:
                    (?>(?&PerlOWS))
                    (?: (?&PerlArrayIndexer) | (?&PerlHashIndexer) | (?&PerlParenthesesList) )
                )++
            )?+

            # Note: subsequent arrowed postdereferences that would follow here
            #       are handled at the <PerlTerm> level

        ) # End of rule (?<PerlScalarAccess>)

        (?<PerlScalarAccessNoSpace>
            (?>(?&PerlVariableScalarNoSpace))

            # Optional arrowless access(es) to begin...
            (?: (?&PerlArrayIndexer) | (?&PerlHashIndexer) )*+

            # Then any nuber of arrowed accesses
            # (this is an inlined subset of (?&PerlTermPostfixDereference))...
            (?:
                ->
                (?>
                    # A series of simple brackets can omit interstitial arrows...
                    (?:  (?&PerlArrayIndexer)
                    |    (?&PerlHashIndexer)
                    )++

                |   # An array or hash slice...
                    \@ (?> (?>(?&PerlArrayIndexer)) | (?>(?&PerlHashIndexer)) )
                )
            )*+

            # Followed by at most one of these terminal arrowed dereferences...
            (?:
                ->
                (?>
                    # An array or scalar deref...
                    [\@\$] \*

                |   # An array count deref...
                    \$ \# \*
                )
            )?+
        ) # End of rule (?<PerlScalarAccessNoSpace>)

        (?<PerlScalarAccessNoSpaceNoArrow>
            (?>(?&PerlVariableScalarNoSpace))

            # Optional arrowless access(es) (but parens can't be first)...
            (?:
                (?! \( )
                (?:
                    (?> (?&PerlArrayIndexer) | (?&PerlHashIndexer) | (?&PerlParenthesesList) )
                )++
            )?+
        ) # End of rule (?<PerlScalarAccessNoSpaceNoArrow>)

        (?<PerlVariableScalar>
            \$\$
            (?! [\$\{\w] )
        |
            (?:
                \$
                (?:
                    [#]
                    (?=  (?> [\$^\w\{:+] | - (?! > ) )  )
                )?+
                (?&PerlOWS)
            )++
            (?>
                \d++
            |
                \^ [][A-Z^_?\\]
            |
                \{ \^ [A-Z_] \w*+ \}
            |
                (?>(?&PerlOldQualifiedIdentifier)) (?: :: )?+
            |
                :: (?&PerlBlock)
            |
                [][!"#\$%&'()*+,.\\/:;<=>?\@\^`|~-]
            |
                \{ [!"#\$%&'()*+,.\\/:;<=>?\@\^`|~-] \}
            |
                \{ \w++ \}
            |
                (?&PerlBlock)
            )
        |
            \$\#
        ) # End of rule (?<PerlVariableScalar>)

        (?<PerlVariableScalarNoSpace>
            \$\$
            (?! [\$\{\w] )
        |
            (?:
                \$
                (?:
                    [#]
                    (?=  (?> [\$^\w\{:+] | - (?! > ) )  )
                )?+
            )++
            (?>
                \d++
            |
                \^ [][A-Z^_?\\]
            |
                \{ \^ [A-Z_] \w*+ \}
            |
                (?>(?&PerlOldQualifiedIdentifier)) (?: :: )?+
            |
                :: (?&PerlBlock)
            |
                [][!"#\$%&'()*+,.\\/:;<=>?\@\^`|~-]
            |
                \{ \w++ \}
            |
                (?&PerlBlock)
            )
        |
            \$\#
        ) # End of rule (?<PerlVariableScalarNoSpace>)

        (?<PerlVariableArray>
            \@     (?>(?&PerlOWS))
            (?: \$    (?&PerlOWS)  )*+
            (?>
                \d++
            |
                \^ [][A-Z^_?\\]
            |
                \{ \^ [A-Z_] \w*+ \}
            |
                (?>(?&PerlOldQualifiedIdentifier)) (?: :: )?+
            |
                :: (?&PerlBlock)
            |
                [][!"#\$%&'()*+,.\\/:;<=>?\@\^`|~-]
            |
                (?&PerlBlock)
            )
        ) # End of rule (?<PerlVariableArray>)

        (?<PerlVariableArrayNoSpace>
            \@
            (?: \$ )*+
            (?>
                \d++
            |
                \^ [][A-Z^_?\\]
            |
                \{ \^ [A-Z_] \w*+ \}
            |
                (?>(?&PerlOldQualifiedIdentifier)) (?: :: )?+
            |
                :: (?&PerlBlock)
            |
                [][!"#\$%&'()*+,.\\/:;<=>?\@\^`|~-]
            |
                (?&PerlBlock)
            )
        ) # End of rule (?<PerlVariableArrayNoSpace>)

        (?<PerlVariableHash>
            %      (?>(?&PerlOWS))
            (?: \$    (?&PerlOWS)  )*+
            (?>
                \d++
            |
                \^ [][A-Z^_?\\]
            |
                \{ \^ [A-Z_] \w*+ \}
            |
                (?>(?&PerlOldQualifiedIdentifier)) (?: :: )?+
            |
                :: (?&PerlBlock)?+
            |
                [][!"#\$%&'()*+,.\\/:;<=>?\@\^`|~-]
            |
                (?&PerlBlock)
            )
        ) # End of rule (?<PerlVariableHash>)

        (?<PerlLabel>
            (?! (?> [msy] | q[wrxq]?+ | tr ) \b )
            (?>(?&PerlIdentifier))
            : (?! : )
        ) # End of rule (?<PerlLabel>)

        (?<PerlLiteral>
            (?> (?&PerlString)
            |   (?&PerlQuotelikeQR)
            |   (?&PerlQuotelikeQW)
            |   (?&PerlNumber)
            |   (?&PerlBareword)
            )
        ) # End of rule (?<PerlLiteral>)

        (?<PerlString>
            (?>
                "  [^"\\]*+  (?: \\. [^"\\]*+ )*+ "
            |
                '  [^'\\]*+  (?: \\. [^'\\]*+ )*+ '
            |
                q \b
                (?> (?= [#] ) | (?! (?>(?&PerlOWS)) => ) )
                (?&PPR_quotelike_body)
            |
                qq \b
                (?> (?= [#] ) | (?! (?>(?&PerlOWS)) => ) )
                (?&PPR_quotelike_body_always_interpolated)
            |
                (?&PerlHeredoc)
            |
                (?&PerlVString)
            )
        ) # End of rule (?<PerlString>)

        (?<PerlQuotelike>
            (?> (?&PerlString)
            |   (?&PerlQuotelikeQR)
            |   (?&PerlQuotelikeQW)
            |   (?&PerlQuotelikeQX)
            |   (?&PerlContextualMatch)
            |   (?&PerlQuotelikeS)
            |   (?&PerlQuotelikeTR)
            )
        ) # End of rule (?<PerlQuotelike>)

        (?<PerlHeredoc>
            # Match the introducer...
            <<
            (?<_heredoc_indented> [~]?+ )

            # Match the terminator specification...
            (?>
                \\?+   (?<_heredoc_terminator>  (?&PerlIdentifier)              )
            |
                (?>(?&PerlOWS))
                (?>
                    "  (?<_heredoc_terminator>  [^"\\]*+  (?: \\. [^"\\]*+ )*+  )  "  #"
                |
                    (?<PPR_HD_nointerp> ' )
                    (?<_heredoc_terminator>  [^'\\]*+  (?: \\. [^'\\]*+ )*+  )  '  #'
                |
                    `  (?<_heredoc_terminator>  [^`\\]*+  (?: \\. [^`\\]*+ )*+  )  `  #`
                )
            |
                    (?<_heredoc_terminator>                                  )
            )

            # Do we need to reset the heredoc cache???
            (?{
                if ( ($PPR::_heredoc_origin // q{}) ne $_ ) {
                    %PPR::_heredoc_skip      = ();
                    %PPR::_heredoc_parsed_to = ();
                    $PPR::_heredoc_origin    = $_;
                }
            })

            # Do we need to cache content lookahead for this heredoc???
            (?(?{ my $need_to_lookahead = !$PPR::_heredoc_parsed_to{+pos()};
                $PPR::_heredoc_parsed_to{+pos()} = 1;
                $need_to_lookahead;
                })

                # Lookahead to detect and remember trailing contents of heredoc
                (?=
                    [^\n]*+ \n                                   # Go to the end of the current line
                    (?{ +pos() })                                # Remember the start of the contents
                    (??{ $PPR::_heredoc_skip{+pos()} // q{} })   # Skip earlier heredoc contents
                    (?>                                          # The heredoc contents consist of...
                        (?:
                            (?!
                                (?(?{ $+{_heredoc_indented} }) \h*+ )   # An indent (if it was a <<~)
                                \g{_heredoc_terminator}                 # The terminator
                                (?: \n | \z )                           # At an end-of-line
                            )
                            (?(<PPR_HD_nointerp>)
                                [^\n]*+ \n
                            |
                                [^\n\$\@]*+
                                (?:
                                    (?>
                                        (?{ local $PPR::_heredoc_EOL_start = $^R })
                                        (?= \$ )  (?&PerlScalarAccess)
                                        (?{ $PPR::_heredoc_EOL_start })
                                    |
                                        (?{ local $PPR::_heredoc_EOL_start = $^R })
                                        (?= \@ )  (?&PerlArrayAccess)
                                        (?{ $PPR::_heredoc_EOL_start })
                                    )
                                    [^\n\$\@]*+
                                )*+
                                \n (??{ $PPR::_heredoc_skip{+pos()} // q{} })
                            )
                        )*+

                        (?(?{ $+{_heredoc_indented} }) \h*+ )            # An indent (if it was a <<~)
                        \g{_heredoc_terminator}                          # The specified terminator
                        (?: \n | \z )                                    # Followed by EOL
                    )

                    # Then memoize the skip for when it's subsequently needed by PerlOWS or PerlNWS...
                    (?{
                        # Split .{N} repetition into multiple repetitions to avoid the 32766 limit...
                        $PPR::_heredoc_skip{$^R} = '(?s:'
                                                . ( '.{32766}' x int((pos() - $^R) / 32766) )
                                                . '.{' . (pos() - $^R) % 32766 . '})';
                    })
                )
            )

        ) # End of rule (?<PerlHeredoc>)

        (?<PerlQuotelikeQ>
            (?>
                '  [^'\\]*+  (?: \\. [^'\\]*+ )*+ '
            |
                \b q \b
                (?> (?= [#] ) | (?! (?>(?&PerlOWS)) => ) )
                (?&PPR_quotelike_body)
            )
        ) # End of rule (?<PerlQuotelikeQ>)

        (?<PerlQuotelikeQQ>
            (?>
                "  [^"\\]*+  (?: \\. [^"\\]*+ )*+ "
            |
                \b qq \b
                (?> (?= [#] ) | (?! (?>(?&PerlOWS)) => ) )
                (?&PPR_quotelike_body_always_interpolated)
            )
        ) # End of rule (?<PerlQuotelikeQQ>)

        (?<PerlQuotelikeQW>
            (?>
                qw \b
                (?> (?= [#] ) | (?! (?>(?&PerlOWS)) => ) )
                (?&PPR_quotelike_body)
            )
        ) # End of rule (?<PerlQuotelikeQW>)

        (?<PerlQuotelikeQX>
            (?>
                `  [^`]*+  (?: \\. [^`]*+ )*+  `
            |
                qx
                    (?>
                        (?= (?>(?&PerlOWS)) ' )
                        (?&PPR_quotelike_body)
                    |
                        \b (?> (?= [#] ) | (?! (?>(?&PerlOWS)) => ) )
                        (?&PPR_quotelike_body_interpolated)
                    )
            )
        ) # End of rule (?<PerlQuotelikeQX>)

        (?<PerlQuotelikeS>
        (?<PerlSubstitution>
            s \b
            (?> (?= [#] ) | (?! (?>(?&PerlOWS)) => ) )
            (?>
                # Hashed syntax...
                (?= [#] )
                (?>(?&PPR_regex_body_interpolated_unclosed))
                (?&PPR_quotelike_s_e_check)
                (?>(?&PPR_quotelike_body_interpolated))
            |
                # Bracketed syntax...
                (?= (?>(?&PerlOWS))
                    (?: [\[(<\{]                 # )
                    |   (\X) (??{ exists $PPR::_QLD_CLOSE_FOR{$^N} ? '' : '(?!)' })
                    )
                )
                (?>(?&PPR_regex_body_interpolated))
                (?>(?&PerlOWS))
                (?&PPR_quotelike_s_e_check)
                (?>(?&PPR_quotelike_body_interpolated))
            |
                # Single-quoted syntax...
                (?= (?>(?&PerlOWS)) ' )
                (?>(?&PPR_regex_body_unclosed))
                (?&PPR_quotelike_s_e_check)
                (?>(?&PPR_quotelike_body_interpolated))
            |
                # Delimited syntax...
                (?>(?&PPR_regex_body_interpolated_unclosed))
                (?&PPR_quotelike_s_e_check)
                (?>(?&PPR_quotelike_body_interpolated))
            )
            [msixpodualgcern]*+
        ) # End of rule (?<PerlSubstitution>)
        ) # End of rule (?<PerlQuotelikeS>)

        (?<PerlQuotelikeTR>
        (?<PerlTransliteration>
            (?> tr | y ) \b
            (?! (?>(?&PerlOWS)) => )
            (?>
                # Hashed syntax...
                (?= [#] )
                (?>(?&PPR_quotelike_body_interpolated_unclosed))
                (?&PPR_quotelike_body_interpolated)
            |
                # Bracketed syntax...
                (?= (?>(?&PerlOWS))
                    (?: [\[(<\{\«]                 # )]
                    |   (\X) (??{ exists $PPR::_QLD_CLOSE_FOR{$^N} ? '' : '(?!)' })
                    )
                )
                (?>(?&PPR_quotelike_body_interpolated))
                (?>(?&PerlOWS))
                (?&PPR_quotelike_body_interpolated)
            |
                # Delimited syntax...
                (?>(?&PPR_quotelike_body_interpolated_unclosed))
                (?&PPR_quotelike_body_interpolated)
            )
            [cdsr]*+
        ) # End of rule (?<PerlTransliteration>)
        ) # End of rule (?<PerlQuotelikeTR>)

        (?<PerlContextualQuotelikeM>
        (?<PerlContextualMatch>
            (?<PerlQuotelikeM>
            (?<PerlMatch>
                (?>
                    \/\/
                |
                    (?>
                        m (?= [#] )
                    |
                        m \b
                        (?! (?>(?&PerlOWS)) => )
                    |
                        (?= \/ [^/] )
                    )
                    (?&PPR_regex_body_interpolated)
                )
                [msixpodualgcn]*+
            ) # End of rule (?<PerlMatch>)
            ) # End of rule (?<PerlQuotelikeM>)
            (?=
                (?>(?&PerlOWS))
                (?> \z | [,;\}\])?] | => | : (?! :)
                |   (?&PerlInfixBinaryOperator) | (?&PerlLowPrecedenceInfixOperator)
                |   (?= \w) (?> for(?:each)?+ | while | if | unless | until | when )
                )
            )
        ) # End of rule (?<PerlContextualMatch>)
        ) # End of rule (?<PerlContextualQuotelikeM>)

        (?<PerlQuotelikeQR>
            qr \b
            (?> (?= [#] ) | (?! (?>(?&PerlOWS)) => ) )
            (?>(?&PPR_regex_body_interpolated))
            [msixpodualn]*+
        ) # End of rule (?<PerlQuotelikeQR>)

        (?<PerlRegex>
            (?>
                (?&PerlMatch)
            |
                (?&PerlQuotelikeQR)
            )
        ) # End of rule (?<PerlRegex>)

        (?<PerlContextualRegex>
            (?>
                (?&PerlContextualMatch)
            |
                (?&PerlQuotelikeQR)
            )
        ) # End of rule (?<PerlContextualRegex>)


        (?<PerlBuiltinFunction>
            # Optimized to match any Perl builtin name, without backtracking...
            (?=[^\W\d]) # Skip if possible
            (?>
                s(?>e(?>t(?>(?>(?>(?>hos|ne)t|gr)en|s(?>erven|ockop))t|p(?>r(?>iority|otoent)|went|grp))|m(?>ctl|get|op)|ek(?>dir)?|lect|nd)|y(?>s(?>write|call|open|read|seek|tem)|mlink)|h(?>m(?>write|read|ctl|get)|utdown|ift)|o(?>cket(?>pair)?|rt)|p(?>li(?>ce|t)|rintf)|(?>cala|ubst)r|t(?>at|udy)|leep|rand|qrt|ay|in)
                | g(?>et(?>p(?>r(?>oto(?>byn(?>umber|ame)|ent)|iority)|w(?>ent|nam|uid)|eername|grp|pid)|s(?>erv(?>by(?>name|port)|ent)|ock(?>name|opt))|host(?>by(?>addr|name)|ent)|net(?>by(?>addr|name)|ent)|gr(?>ent|gid|nam)|login|c)|mtime|lob|oto|rep)
                | r(?>e(?>ad(?>lin[ek]|pipe|dir)?|(?>quir|vers|nam)e|winddir|turn|set|cv|do|f)|index|mdir|and)
                | c(?>h(?>o(?>m?p|wn)|r(?>oot)?|dir|mod)|o(?>n(?>tinue|nect)|s)|lose(?>dir)?|aller|rypt)
                | e(?>nd(?>(?>hos|ne)t|p(?>roto|w)|serv|gr)ent|x(?>i(?>sts|t)|ec|p)|ach|val(?>bytes)?+|of)
                | l(?>o(?>c(?>al(?>time)?|k)|g)|i(?>sten|nk)|(?>sta|as)t|c(?>first)?|ength)
                | u(?>n(?>(?>lin|pac)k|shift|def|tie)|c(?>first)?|mask|time)
                | p(?>r(?>ototype|intf?)|ack(?>age)?|o[ps]|ipe|ush)
                | d(?>bm(?>close|open)|e(?>fined|lete)|ump|ie|o)
                | f(?>or(?>m(?>line|at)|k)|ileno|cntl|c|lock)
                | t(?>i(?>mes?|ed?)|ell(?>dir)?|runcate)
                | w(?>a(?>it(?>pid)?|ntarray|rn)|rite)
                | m(?>sg(?>ctl|get|rcv|snd)|kdir|ap)
                | b(?>in(?>mode|d)|less|reak)
                | i(?>n(?>dex|t)|mport|octl)
                | a(?>ccept|larm|tan2|bs)
                | o(?>pen(?>dir)?|ct|rd)
                | v(?>alues|ec)
                | k(?>eys|ill)
                | quotemeta
                | join
                | next
                | hex
                | _
            )
            \b
        ) # End of rule (?<PerlBuiltinFunction>)

        (?<PerlNullaryBuiltinFunction>
            # Optimized to match any Perl builtin name, without backtracking...
            (?= [^\W\d] )  # Skip if possible
            (?>
                get(?:(?:(?:hos|ne)t|serv|gr)ent|p(?:(?:roto|w)ent|pid)|login)
                | end(?:(?:hos|ne)t|p(?:roto|w)|serv|gr)ent
                | wa(?:ntarray|it)
                | times?
                | fork
                | _
            )
            \b
        ) # End of rule (?<PerlNullaryBuiltinFunction>)

        (?<PerlVersionNumber>
            (?>
                (?&PerlVString)
            |
                (?>(?&PPR_digit_seq))
                (?: \. (?&PPR_digit_seq)?+ )*+
            )
        ) # End of rule (?<PerlVersionNumber>)

        (?<PerlVString>
            v  (?>(?&PPR_digit_seq))  (?: \. (?&PPR_digit_seq) )*+
        ) # End of rule (?<PerlVString>)

        (?<PerlNumber>
            [+-]?+
            (?>
                0  (?>  x   (?&PPR_x_digit_seq)
                |       b   (?&PPR_b_digit_seq)
                |       o?  (?&PPR_o_digit_seq)
                )
            |
                (?>
                        (?>(?&PPR_digit_seq))
                    (?: \. (?&PPR_digit_seq)?+ )?+
                |
                        \. (?&PPR_digit_seq)
                )
                (?: [eE] [+-]?+ (?&PPR_digit_seq) )?+
            )
        ) # End of rule (?<PerlNumber>)

        (?<PerlOldQualifiedIdentifier>
            (?> (?> :: | ' ) \w++  |  [^\W\d]\w*+ )  (?: (?> :: | ' )  \w++ )*+
        ) # End of rule (?<PerlOldQualifiedIdentifier>)

        (?<PerlQualifiedIdentifier>
            (?>     ::       \w++  |  [^\W\d]\w*+ )  (?: (?> :: | ' )  \w++ )*+
        ) # End of rule (?<PerlQualifiedIdentifier>)

        (?<PerlIdentifier>
                                    [^\W\d]\w*+
        ) # End of rule (?<PerlIdentifier>)

        (?<PerlBareword>
            (?! (?> (?= \w )
                    (?> for(?:each)?+ | while | if      | unless | until | use | no
                    |   given         | when  | sub     | return | my    | our | state
                    |   try           | catch | finally | defer
                    )
                |   (?&PPR_named_op)
                |   __ (?> END | DATA ) __ \b
                ) \b
                (?! (?>(?&PerlOWS)) => )
            )
            (?! (?> q[qwrx]?+ | [mys] | tr ) \b
                (?> (?= [#] ) | (?! (?>(?&PerlOWS)) => ) )
            )
            (?: :: )?+
            [^\W\d]\w*+
            (?: (?: :: | ' )  [^\W\d]\w*+  )*+
            (?: :: )?+
            (?! \( )    # )
        |
            :: (?! \w | \{ )
        ) # End of rule (?<PerlBareword>)

        (?<PerlKeyword>
            (?!)    # None, by default, but can be overridden in a composing regex
        ) # End of rule (?<PerlKeyword>)

        (?<PerlPodSequence>
            (?>(?&PerlOWS))  (?: (?>(?&PerlPod))  (?&PerlOWS) )*+
        ) # End of rule (?<PerlPodSequence>)

        (?<PerlPod>
            ^ = [^\W\d]\w*+             # A line starting with =<identifier>
            .*?                         # Up to the first...
            (?>
                ^ = cut \b [^\n]*+ $    # ...line starting with =cut
            |                           # or
                \z                      # ...EOF
            )
        ) # End of rule (?<PerlPod>)


        ##### Whitespace matching (part of API) #################################

        (?<PerlOWSOrEND>
            (?:
                \h++
            |
                (?&PPR_newline_and_heredoc)
            |
                [#] [^\n]*+
            |
                __ (?> END | DATA ) __ \b .*+ \z
            )*+
        ) # End of rule (?<PerlOWSOrEnd>)

        (?<PerlOWS>
            (?:
                \h++
            |
                (?&PPR_newline_and_heredoc)
            |
                [#] [^\n]*+
            )*+
        ) # End of rule (?<PerlOWS>)

        (?<PerlNWS>
            (?:
                \h++
            |
                (?&PPR_newline_and_heredoc)
            |
                [#] [^\n]*+
            )++
        ) # End of rule (?<PerlNWS>)

        (?<PerlEndOfLine>
            \n
        ) # End of rule (?<PerlEndOfLine>)


        ###### Internal components (not part of API) ##########################

        (?<PPR_named_op>
            (?> cmp
            |   [lg][te]
            |   eq
            |   ne
            |   and
            |   or
            |   xor
            )
        ) # End of rule (?<PPR_named_op>)

        (?<PPR_non_reserved_identifier>
            (?! (?>
                   for(?:each)?+ | while   | if    | unless | until | given | when | default
                |  sub | format  | use     | no    | my     | our   | state
                |  try | catch   | finally | defer
                |  (?&PPR_named_op)
                |  [msy] | q[wrxq]?+ | tr
                |   __ (?> END | DATA ) __
                )
                \b
            )
            (?>(?&PerlQualifiedIdentifier))
            (?! :: )
        ) # End of rule (?<PPR_non_reserved_identifier>)

        (?<PPR_three_part_list>
            \(  (?>(?&PerlOWS)) (?: (?>(?&PerlExpression)) (?&PerlOWS) )??
            ;  (?>(?&PerlOWS)) (?: (?>(?&PerlExpression)) (?&PerlOWS) )??
            ;  (?>(?&PerlOWS)) (?: (?>(?&PerlExpression)) (?&PerlOWS) )??
            \)
        ) # End of rule (?<PPR_three_part_list>)

        (?<PPR_indirect_obj>
            (?&PerlBareword)
        |
            (?>(?&PerlVariableScalar))
            (?! (?>(?&PerlOWS)) (?> [<\[\{] | -> ) )
        ) # End of rule (?<PPR_indirect_obj>)

        (?<PPR_quotelike_body>
            (?>(?&PPR_quotelike_body_unclosed))
            \S   # (Note: Don't have to test that this matches; the preceding subrule already did that)
        ) # End of rule (?<PPR_quotelike_body>)

        (?<PPR_balanced_parens>
            [^)(\\\n]*+
            (?:
                (?>
                    \\.
                |
                    \(  (?>(?&PPR_balanced_parens))  \)
                |
                    (?&PPR_newline_and_heredoc)
                )
                [^)(\\\n]*+
            )*+
        ) # End of rule (?<PPR_balanced_parens>)

        (?<PPR_balanced_curlies>
            [^\}\{\\\n]*+
            (?:
                (?>
                    \\.
                |
                    \{  (?>(?&PPR_balanced_curlies))  \}
                |
                    (?&PPR_newline_and_heredoc)
                )
                [^\}\{\\\n]*+
            )*+
        ) # End of rule (?<PPR_balanced_curlies>)

        (?<PPR_balanced_squares>
            [^][\\\n]*+
            (?:
                (?>
                    \\.
                |
                    \[  (?&PPR_balanced_squares)  \]
                |
                    (?&PPR_newline_and_heredoc)
                )
                [^][\\\n]*+
            )*+
        ) # End of rule (?<PPR_balanced_squares>)

        (?<PPR_balanced_angles>
            [^><\\\n]*+
            (?:
                (?>
                    \\.
                |
                    <  (?>(?&PPR_balanced_angles))  >
                |
                    (?&PPR_newline_and_heredoc)
                )
                [^><\\\n]*+
            )*+
        ) # End of rule (?<PPR_balanced_angles>)

        (?<PPR_balanced_unicode_delims>
            (??{$PPR::_qld_not_special})
            (?:
                (?>
                    \\.
                |
                    (??{$PPR::_qld_open})
                    (?>(?&PPR_balanced_unicode_delims))
                    (??{$PPR::_qld_close})
                |
                    (?&PPR_newline_and_heredoc)
                )
                (??{$PPR::_qld_not_special})
            )*+
        ) # End of rule (?<PPR_balanced_unicode_delims>)

        (?<PPR_regex_body_unclosed>
            (?>
                [#]
                [^#\\\n]*+
                (?:
                    (?: \\. | (?&PPR_newline_and_heredoc) )
                    [^#\\\n]*+
                )*+
                (?= [#] )
            |
                (?>(?&PerlOWS))
                (?>
                    \{  (?>(?&PPR_balanced_curlies))            (?= \} )
                |
                    \[  (?>(?&PPR_balanced_squares))            (?= \] )
                |
                    \(  (?>
                            \?{1,2}+ (?= \{ )
                            (?>(?&PerlBlock))
                        |
                            (?! \?{1,2}+ \{ )
                            (?>(?&PPR_balanced_parens))
                        )                                       (?= \) )
                |
                    <  (?>(?&PPR_balanced_angles))              (?=  > )
                |
                    (\X) (??{ exists $PPR::_QLD_CLOSE_FOR{$^N} ? '' : '(?!)' })
                    (?{ local $PPR::_qld_open  = $^N;
                        local $PPR::_qld_close = $PPR::_QLD_CLOSE_FOR{$PPR::_qld_open};
                        local $PPR::_qld_not_special
                            = "[^$PPR::_qld_open$PPR::_qld_close\\\\\\n]*+";
                        local $PPR::_qld_not_special_or_sigil
                            = "[^$PPR::_qld_open$PPR::_qld_close\\\\\\n\\\$\\\@]*+";
                        local $PPR::_qld_not_special_in_regex_var
                            = "[^$PPR::_qld_open$PPR::_qld_close\\s(|)]";
                    })
                    (?>(?&PPR_balanced_unicode_delims_regex_interpolated))
                    (?=  (??{$PPR::_qld_close}) )
                |
                    \\
                        [^\\\n]*+
                        (
                            (?&PPR_newline_and_heredoc)
                            [^\\\n]*+
                        )*+
                    (?= \\ )
                |
                    /
                        [^\\/\n]*+
                    (?:
                        (?: \\. | (?&PPR_newline_and_heredoc) )
                        [^\\/\n]*+
                    )*+
                    (?=  / )
                |
                    (?<PPR_qldel> \S )
                        (?:
                            \\.
                        |
                            (?&PPR_newline_and_heredoc)
                        |
                            (?! \g{PPR_qldel} ) .
                        )*+
                    (?= \g{PPR_qldel} )
                )
            )
        ) # End of rule (?<PPR_regex_body_unclosed>)

        (?<PPR_quotelike_body_unclosed>
            (?>
                [#]
                [^#\\\n]*+
                (?:
                    (?: \\. | (?&PPR_newline_and_heredoc) )
                    [^#\\\n]*+
                )*+
                (?= [#] )
            |
                (?>(?&PerlOWS))
                (?>
                    \{  (?>(?&PPR_balanced_curlies))        (?= \} )
                |
                    \[  (?>(?&PPR_balanced_squares))        (?= \] )
                |
                    \(  (?>(?&PPR_balanced_parens))         (?= \) )
                |
                    <  (?>(?&PPR_balanced_angles))          (?=  > )
                |
                    (\X) (??{ exists $PPR::_QLD_CLOSE_FOR{$^N} ? '' : '(?!)' })
                    (?{ local $PPR::_qld_open  = $^N;
                        local $PPR::_qld_close = $PPR::_QLD_CLOSE_FOR{$PPR::_qld_open};
                        local $PPR::_qld_not_special
                            = "[^$PPR::_qld_open$PPR::_qld_close\\\\\\n]*+";
                        local $PPR::_qld_not_special_or_sigil
                            = "[^$PPR::_qld_open$PPR::_qld_close\\\\\\n\\\$\\\@]*+";
                        local $PPR::_qld_not_special_in_regex_var
                            = "[^$PPR::_qld_open$PPR::_qld_close\\s(|)]";
                    })
                    (?>(?&PPR_balanced_unicode_delims))
                    (?=  (??{$PPR::_qld_close}) )
                |
                    \\
                        [^\\\n]*+
                        (
                            (?&PPR_newline_and_heredoc)
                            [^\\\n]*+
                        )*+
                    (?= \\ )
                |
                    /
                        [^\\/\n]*+
                    (?:
                        (?: \\. | (?&PPR_newline_and_heredoc) )
                        [^\\/\n]*+
                    )*+
                    (?=  / )
                |
                    (?<PPR_qldel> \S )
                        (?:
                            \\.
                        |
                            (?&PPR_newline_and_heredoc)
                        |
                            (?! \g{PPR_qldel} ) .
                        )*+
                    (?= \g{PPR_qldel} )
                )
            )
        ) # End of rule (?<PPR_quotelike_body_unclosed>)

        (?<PPR_quotelike_body_always_interpolated>
            (?>(?&PPR_quotelike_body_always_interpolated_unclosed))
            \S   # (Note: Don't have to test that this matches; the preceding subrule already did that)
        ) # End of rule (?<PPR_quotelike_body_always_interpolated>)

        (?<PPR_quotelike_body_interpolated>
            (?>(?&PPR_quotelike_body_interpolated_unclosed))
            \S   # (Note: Don't have to test that this matches; the preceding subrule already did that)
        ) # End of rule (?<PPR_quotelike_body_interpolated>)

        (?<PPR_regex_body_interpolated>
            (?>(?&PPR_regex_body_interpolated_unclosed))
            \S   # (Note: Don't have to test that this matches; the preceding subrule already did that)
        ) # End of rule (?<PPR_regex_body_interpolated>)

        (?<PPR_balanced_parens_regex_interpolated>
            [^)(\\\n\$\@]*+
            (?:
                (?>
                    \\.
                |
                    \(  (?>(?&PPR_balanced_parens_regex_interpolated))  \)
                |
                    (?&PPR_newline_and_heredoc)
                |
                    (?= \$ (?! [\s(|)] ) )  (?&PerlScalarAccessNoSpace)
                |
                    (?= \@ (?! [\s(|)] ) )  (?&PerlArrayAccessNoSpace)
                |
                    [\$\@]
                )
                [^)(\\\n\$\@]*+
            )*+
        ) # End of rule (?<PPR_balanced_parens_regex_interpolated>)

        (?<PPR_balanced_curlies_regex_interpolated>
            [^\}\{\\\n\$\@]*+
            (?:
                (?>
                    \\.
                |
                    \{  (?>(?&PPR_balanced_curlies_regex_interpolated))  \}
                |
                    (?&PPR_newline_and_heredoc)
                |
                    (?= \$ (?! [\s\}(|)] ) )  (?&PerlScalarAccessNoSpace)
                |
                    (?= \@ (?! [\s\}(|)] ) )  (?&PerlArrayAccessNoSpace)
                |
                    [\$\@]
                )
                [^\}\{\\\n\$\@]*+
            )*+
        ) # End of rule (?<PPR_balanced_curlies_regex_interpolated>)

        (?<PPR_balanced_squares_regex_interpolated>
            [^][\\\n\$\@]*+
            (?:
                (?>
                    \\.
                |
                    \[  (?>(?&PPR_balanced_squares_regex_interpolated))  \]
                |
                    (?&PPR_newline_and_heredoc)
                |
                    (?= \$ (?! [\s\](|)] ) )  (?&PerlScalarAccessNoSpace)
                |
                    (?= \@ (?! [\s\](|)] ) )  (?&PerlArrayAccessNoSpace)
                |
                    [\$\@]
                )
                [^][\\\n\$\@]*+
            )*+
        ) # End of rule (?<PPR_balanced_squares_regex_interpolated>)

        (?<PPR_balanced_angles_regex_interpolated>
            [^><\\\n\$\@]*+
            (?:
                (?>
                    \\.
                |
                    <  (?>(?&PPR_balanced_angles_regex_interpolated))  >
                |
                    (?&PPR_newline_and_heredoc)
                |
                    (?= \$ (?! [\s>(|)] ) )  (?&PerlScalarAccessNoSpace)
                |
                    (?= \@ (?! [\s>(|)] ) )  (?&PerlArrayAccessNoSpace)
                |
                    [\$\@]
                )
                [^><\\\n\$\@]*+
            )*+
        ) # End of rule (?<PPR_balanced_angles_regex_interpolated>)


        (?<PPR_balanced_unicode_delims_regex_interpolated>
            (??{$PPR::_qld_not_special_or_sigil})
            (?:
                (?>
                    \\.
                |
                    (??{ $PPR::_qld_open })
                    (?>(?&PPR_balanced_unicode_delims_regex_interpolated))
                    (??{ $PPR::_qld_close })
                |
                    (?&PPR_newline_and_heredoc)
                |
                    (?= \$ (??{ $PPR::_qld_not_special_in_regex_var }) )
                    (?&PerlScalarAccessNoSpace)
                |
                    (?= \$ (??{ $PPR::_qld_not_special_in_regex_var }) )
                    (?&PerlArrayAccessNoSpace)
                |
                    [\$\@]
                )
                (??{$PPR::_qld_not_special_or_sigil})
            )*+
        ) # End of rule (?<PPR_balanced_unicode_delims_regex_interpolated>)


        (?<PPR_balanced_parens_interpolated>
            [^)(\\\n\$\@]*+
            (?:
                (?>
                    \\.
                |
                    \(  (?>(?&PPR_balanced_parens_interpolated))  \)
                |
                    (?&PPR_newline_and_heredoc)
                |
                    (?= \$ (?! [\s\)] ) )  (?&PerlScalarAccessNoSpace)
                |
                    (?= \@ (?! [\s\)] ) )  (?&PerlArrayAccessNoSpace)
                |
                    [\$\@]
                )
                [^)(\\\n\$\@]*+
            )*+
        ) # End of rule (?<PPR_balanced_parens_interpolated>)

        (?<PPR_balanced_curlies_interpolated>
            [^\}\{\\\n\$\@]*+
            (?:
                (?>
                    \\.
                |
                    \{  (?>(?&PPR_balanced_curlies_interpolated))  \}
                |
                    (?&PPR_newline_and_heredoc)
                |
                    (?= \$ (?! [\s\}] ) )  (?&PerlScalarAccessNoSpace)
                |
                    (?= \@ (?! [\s\}] ) )  (?&PerlArrayAccessNoSpace)
                |
                    [\$\@]
                )
                [^\}\{\\\n\$\@]*+
            )*+
        ) # End of rule (?<PPR_balanced_curlies_interpolated>)

        (?<PPR_balanced_squares_interpolated>
            [^][\\\n\$\@]*+
            (?:
                (?>
                    \\.
                |
                    \[  (?>(?&PPR_balanced_squares_interpolated))  \]
                |
                    (?&PPR_newline_and_heredoc)
                |
                    (?= \$ (?! [\s\]] ) )  (?&PerlScalarAccessNoSpace)
                |
                    (?= \@ (?! [\s\]] ) )  (?&PerlArrayAccessNoSpace)
                |
                    [\$\@]
                )
                [^][\\\n\$\@]*+
            )*+
        ) # End of rule (?<PPR_balanced_squares_interpolated>)

        (?<PPR_balanced_unicode_delims_interpolated>
            (??{$PPR::_qld_not_special_or_sigil})
            (?:
                (?>
                    \\.
                |
                    (??{$PPR::_qld_open})
                    (?>(?&PPR_balanced_unicode_delims_interpolated))
                    (??{$PPR::_qld_close})
                |
                    (?&PPR_newline_and_heredoc)
                |
                    (?= \$ (?! \s | (??{$PPR::_qld_close}) ) )  (?&PerlScalarAccessNoSpace)
                |
                    (?= \@ (?! \s | (??{$PPR::_qld_close}) ) )  (?&PerlArrayAccessNoSpace)
                |
                    [\$\@]
                )
                (??{$PPR::_qld_not_special_or_sigil})
            )*+
        ) # End of rule (?<PPR_balanced_unicode_delims_interpolated>)

        (?<PPR_balanced_angles_interpolated>
            [^><\\\n\$\@]*+
            (?:
                (?>
                    \\.
                |
                    <  (?>(?&PPR_balanced_angles_interpolated))  >
                |
                    (?&PPR_newline_and_heredoc)
                |
                    (?= \$ (?! [\s>] ) )  (?&PerlScalarAccessNoSpace)
                |
                    (?= \@ (?! [\s>] ) )  (?&PerlArrayAccessNoSpace)
                |
                    [\$\@]
                )
                [^><\\\n\$\@]*+
            )*+
        ) # End of rule (?<PPR_balanced_angles_interpolated>)

        (?<PPR_regex_body_interpolated_unclosed>
            # Start by working out where it actually ends (ignoring interpolations)...
            (?=
                (?>
                    [#]
                    [^#\\\n\$\@]*+
                    (?:
                        (?>
                            \\.
                        |
                            (?&PPR_newline_and_heredoc)
                        |
                            (?= \$ (?! [\s#|()] ) )  (?&PerlScalarAccessNoSpace)
                        |
                            (?= \@ (?! [\s#|()] ) )  (?&PerlArrayAccessNoSpace)
                        |
                            [\$\@]
                        )
                        [^#\\\n\$\@]*+
                    )*+
                    (?= [#] )
                |
                    (?>(?&PerlOWS))
                    (?>
                        \{  (?>(?&PPR_balanced_curlies_regex_interpolated))    (?= \} )
                    |
                        \[  (?>(?&PPR_balanced_squares_regex_interpolated))    (?= \] )
                    |
                        \(  (?>(?&PPR_balanced_parens_regex_interpolated))     (?= \) )
                    |
                        <   (?>(?&PPR_balanced_angles_regex_interpolated))     (?=  > )
                    |
                        (\X) (??{ exists $PPR::_QLD_CLOSE_FOR{$^N} ? '' : '(?!)' })
                        (?{ local $PPR::_qld_open  = $^N;
                            local $PPR::_qld_close = $PPR::_QLD_CLOSE_FOR{$PPR::_qld_open};
                            local $PPR::_qld_not_special
                                = "[^$PPR::_qld_open$PPR::_qld_close\\\\\\n]*+";
                            local $PPR::_qld_not_special_or_sigil
                                = "[^$PPR::_qld_open$PPR::_qld_close\\\\\\n\\\$\\\@]*+";
                            local $PPR::_qld_not_special_in_regex_var
                                = "[^$PPR::_qld_open$PPR::_qld_close\\s(|)]";
                        })
                        (?>(?&PPR_balanced_unicode_delims_regex_interpolated))
                        (?=  (??{$PPR::_qld_close}) )
                    |
                        '
                            [^'\n]*+
                            (?:
                                (?> (?&PPR_newline_and_heredoc))
                                [^'\n]*+
                            )*+
                        (?= ' )
                    |
                        \\
                            [^\\\n\$\@]*+
                            (?:
                                (?>
                                    (?&PPR_newline_and_heredoc)
                                |
                                    (?= \$ (?! [\s\\|()] ) )  (?&PerlScalarAccessNoSpace)
                                |
                                    (?= \@ (?! [\s\\|()] ) )  (?&PerlArrayAccessNoSpace)
                                |
                                    [\$\@]
                                )
                                [^\\\n\$\@]*+
                            )*+
                        (?= \\ )
                    |
                        /
                            [^\\/\n\$\@]*+
                            (?:
                                (?>
                                    \\.
                                |
                                    (?&PPR_newline_and_heredoc)
                                |
                                    (?= \$ (?! [\s/|()] ) )  (?&PerlScalarAccessNoSpace)
                                |
                                    (?= \@ (?! [\s/|()] ) )  (?&PerlArrayAccessNoSpace)
                                |
                                    [\$\@]
                                )
                                [^\\/\n\$\@]*+
                            )*+
                        (?= / )
                    |
                        -
                            (?:
                                \\.
                            |
                                (?&PPR_newline_and_heredoc)
                            |
                                (?:
                                    (?= \$ (?! [\s|()-] ) )  (?&PerlScalarAccessNoSpaceNoArrow)
                                |
                                    (?= \@ (?! [\s|()-] ) )  (?&PerlArrayAccessNoSpaceNoArrow)
                                |
                                    [^-]
                                )
                            )*+
                        (?= - )
                    |
                        (?<PPR_qldel> \S )
                            (?:
                                \\.
                            |
                                (?&PPR_newline_and_heredoc)
                            |
                                (?! \g{PPR_qldel} )
                                (?:
                                    (?= \$ (?! \g{PPR_qldel} | [\s|()] ) )  (?&PerlScalarAccessNoSpace)
                                |
                                    (?= \@ (?! \g{PPR_qldel} | [\s|()] ) )  (?&PerlArrayAccessNoSpace)
                                |
                                    .
                                )
                            )*+
                        (?= \g{PPR_qldel} )
                    )
                )
            )

            (?&PPR_regex_body_unclosed)
        ) # End of rule (?<PPR_regex_body_interpolated_unclosed>)

        (?<PPR_quotelike_body_always_interpolated_unclosed>
            # Start by working out where it actually ends (ignoring interpolations)...
            (?=
                (?>
                    [#]
                    [^#\\\n\$\@]*+
                    (?:
                        (?>
                            \\.
                        |
                            (?&PPR_newline_and_heredoc)
                        |
                            (?= \$ (?! [\s#] ) )  (?&PerlScalarAccessNoSpace)
                        |
                            (?= \@ (?! [\s#] ) )  (?&PerlArrayAccessNoSpace)
                        |
                            [\$\@]
                        )
                        [^#\\\n\$\@]*+
                    )*+
                    (?= [#] )
                |
                    (?>(?&PerlOWS))
                    (?>
                        \{  (?>(?&PPR_balanced_curlies_interpolated))    (?= \} )
                    |
                        \[  (?>(?&PPR_balanced_squares_interpolated))    (?= \] )
                    |
                        \(  (?>(?&PPR_balanced_parens_interpolated))     (?= \) )
                    |
                        <   (?>(?&PPR_balanced_angles_interpolated))     (?=  > )
                    |
                        (\X) (??{ exists $PPR::_QLD_CLOSE_FOR{$^N} ? '' : '(?!)' })
                        (?{ local $PPR::_qld_open  = $^N;
                            local $PPR::_qld_close = $PPR::_QLD_CLOSE_FOR{$PPR::_qld_open};
                            local $PPR::_qld_not_special
                                = "[^$PPR::_qld_open$PPR::_qld_close\\\\\\n]*+";
                            local $PPR::_qld_not_special_or_sigil
                                = "[^$PPR::_qld_open$PPR::_qld_close\\\\\\n\\\$\\\@]*+";
                            local $PPR::_qld_not_special_in_regex_var
                                = "[^$PPR::_qld_open$PPR::_qld_close\\s(|)]";
                        })
                        (?>(?&PPR_balanced_unicode_delims_interpolated))
                        (?=  (??{$PPR::_qld_close}) )
                    |
                        \\
                            [^\\\n\$\@]*+
                            (?:
                                (?>
                                    (?&PPR_newline_and_heredoc)
                                |
                                    (?= \$ (?! [\s\\] ) )  (?&PerlScalarAccessNoSpace)
                                |
                                    (?= \@ (?! [\s\\] ) )  (?&PerlArrayAccessNoSpace)
                                |
                                    [\$\@]
                                )
                                [^\\\n\$\@]*+
                            )*+
                        (?= \\ )
                    |
                        /
                            [^\\/\n\$\@]*+
                            (?:
                                (?>
                                    \\.
                                |
                                    (?&PPR_newline_and_heredoc)
                                |
                                    (?= \$ (?! [\s/] ) )  (?&PerlScalarAccessNoSpace)
                                |
                                    (?= \@ (?! [\s/] ) )  (?&PerlArrayAccessNoSpace)
                                |
                                    [\$\@]
                                )
                                [^\\/\n\$\@]*+
                            )*+
                        (?= / )
                    |
                        -
                            (?:
                                \\.
                            |
                                (?&PPR_newline_and_heredoc)
                            |
                                (?:
                                    (?= \$ (?! [\s-] ) )  (?&PerlScalarAccessNoSpaceNoArrow)
                                |
                                    (?= \@ (?! [\s-] ) )  (?&PerlArrayAccessNoSpaceNoArrow)
                                |
                                    [^-]
                                )
                            )*+
                        (?= - )
                    |
                        (?<PPR_qldel> \S )
                            (?:
                                \\.
                            |
                                (?&PPR_newline_and_heredoc)
                            |
                                (?! \g{PPR_qldel} )
                                (?:
                                    (?= \$ (?! \g{PPR_qldel} | \s ) )  (?&PerlScalarAccessNoSpace)
                                |
                                    (?= \@ (?! \g{PPR_qldel} | \s ) )  (?&PerlArrayAccessNoSpace)
                                |
                                    .
                                )
                            )*+
                        (?= \g{PPR_qldel} )
                    )
                )
            )

            (?&PPR_quotelike_body_unclosed)
        ) # End of rule (?<PPR_quotelike_body_always_interpolated_unclosed>)

        (?<PPR_quotelike_body_interpolated_unclosed>
            # Start by working out where it actually ends (ignoring interpolations)...
            (?=
                (?>
                    [#]
                    [^#\\\n\$\@]*+
                    (?:
                        (?>
                            \\.
                        |
                            (?&PPR_newline_and_heredoc)
                        |
                            (?= \$ (?! [\s#] ) )  (?&PerlScalarAccessNoSpace)
                        |
                            (?= \@ (?! [\s#] ) )  (?&PerlArrayAccessNoSpace)
                        |
                            [\$\@]
                        )
                        [^#\\\n\$\@]*+
                    )*+
                    (?= [#] )
                |
                    (?>(?&PerlOWS))
                    (?>
                        \{  (?>(?&PPR_balanced_curlies_interpolated))    (?= \} )
                    |
                        \[  (?>(?&PPR_balanced_squares_interpolated))    (?= \] )
                    |
                        \(  (?>(?&PPR_balanced_parens_interpolated))     (?= \) )
                    |
                        <   (?>(?&PPR_balanced_angles_interpolated))     (?=  > )
                    |
                        (\X) (??{ exists $PPR::_QLD_CLOSE_FOR{$^N} ? '' : '(?!)' })
                        (?{ local $PPR::_qld_open  = $^N;
                            local $PPR::_qld_close = $PPR::_QLD_CLOSE_FOR{$PPR::_qld_open};
                            local $PPR::_qld_not_special
                                = "[^$PPR::_qld_open$PPR::_qld_close\\\\\\n]*+";
                            local $PPR::_qld_not_special_or_sigil
                                = "[^$PPR::_qld_open$PPR::_qld_close\\\\\\n\\\$\\\@]*+";
                            local $PPR::_qld_not_special_in_regex_var
                                = "[^$PPR::_qld_open$PPR::_qld_close\\s(|)]";
                        })
                        (?>(?&PPR_balanced_unicode_delims_interpolated))
                        (?=  (??{$PPR::_qld_close}) )
                    |
                        '
                            [^'\n]*+
                            (?:
                                (?> (?&PPR_newline_and_heredoc))
                                [^'\n]*+
                            )*+
                        (?= ' )
                    |
                        \\
                            [^\\\n\$\@]*+
                            (?:
                                (?>
                                    (?&PPR_newline_and_heredoc)
                                |
                                    (?= \$ (?! [\s\\] ) )  (?&PerlScalarAccessNoSpace)
                                |
                                    (?= \@ (?! [\s\\] ) )  (?&PerlArrayAccessNoSpace)
                                |
                                    [\$\@]
                                )
                                [^\\\n\$\@]*+
                            )*+
                        (?= \\ )
                    |
                        /
                            [^\\/\n\$\@]*+
                            (?:
                                (?>
                                    \\.
                                |
                                    (?&PPR_newline_and_heredoc)
                                |
                                    (?= \$ (?! [\s/] ) )  (?&PerlScalarAccessNoSpace)
                                |
                                    (?= \@ (?! [\s/] ) )  (?&PerlArrayAccessNoSpace)
                                |
                                    [\$\@]
                                )
                                [^\\/\n\$\@]*+
                            )*+
                        (?= / )
                    |
                        -
                            (?:
                                \\.
                            |
                                (?&PPR_newline_and_heredoc)
                            |
                                (?:
                                    (?= \$ (?! [\s-] ) )  (?&PerlScalarAccessNoSpaceNoArrow)
                                |
                                    (?= \@ (?! [\s-] ) )  (?&PerlArrayAccessNoSpaceNoArrow)
                                |
                                    [^-]
                                )
                            )*+
                        (?= - )
                    |
                        (?<PPR_qldel> \S )
                            (?:
                                \\.
                            |
                                (?&PPR_newline_and_heredoc)
                            |
                                (?! \g{PPR_qldel} )
                                (?:
                                    (?= \$ (?! \g{PPR_qldel} | \s ) )  (?&PerlScalarAccessNoSpace)
                                |
                                    (?= \@ (?! \g{PPR_qldel} | \s ) )  (?&PerlArrayAccessNoSpace)
                                |
                                    .
                                )
                            )*+
                        (?= \g{PPR_qldel} )
                    )
                )
            )

            (?&PPR_quotelike_body_unclosed)
        ) # End of rule (?<PPR_quotelike_body_interpolated_unclosed>)

        (?<PPR_quotelike_s_e_check>
            (??{ local $PPR::_quotelike_s_end = -1; '' })
            (?:
                (?=
                    (?&PPR_quotelike_body_interpolated)
                    (??{ $PPR::_quotelike_s_end = +pos(); '' })
                    [msixpodualgcrn]*+ e [msixpodualgcern]*+
                )
                (?=
                    \S  # Skip the left delimiter
                    (?(?{ $PPR::_quotelike_s_end >= 0 })
                        (?>
                            (??{ +pos() && +pos() < $PPR::_quotelike_s_end ? '' : '(?!)' })
                            (?>
                                (?&PerlExpression)
                            |
                                \\?+ .
                            )
                        )*+
                    )
                )
            )?+
        ) # End of rule (?<PPR_quotelike_s_e_check>)

        (?<PPR_quotelike_s_e_check_uninterpolated>
            (??{ local $PPR::_quotelike_s_end = -1; '' })
            (?:
                (?=
                    (?&PPR_quotelike_body)
                    (??{ $PPR::_quotelike_s_end = +pos(); '' })
                    [msixpodualgcrn]*+ e [msixpodualgcern]*+
                )
                (?=
                    \S  # Skip the left delimiter
                    (?(?{ $PPR::_quotelike_s_end >= 0 })
                        (?>
                            (??{ +pos() && +pos() < $PPR::_quotelike_s_end ? '' : '(?!)' })
                            (?>
                                (?&PerlExpression)
                            |
                                \\?+ .
                            )
                        )*+
                    )
                )
            )?+
        ) # End of rule (?<PPR_quotelike_s_e_check_uninterpolated>)

        (?<PPR_filetest_name>   [ABCMORSTWXbcdefgkloprstuwxz]          )

        (?<PPR_digit_seq>               \d++ (?: _?+         \d++ )*+  )
        (?<PPR_x_digit_seq>     [\da-fA-F]++ (?: _?+ [\da-fA-F]++ )*+  )
        (?<PPR_o_digit_seq>          [0-7]++ (?: _?+      [0-7]++ )*+  )
        (?<PPR_b_digit_seq>          [0-1]++ (?: _?+      [0-1]++ )*+  )

        (?<PPR_newline_and_heredoc>
            \n (??{ ($PPR::_heredoc_origin // q{}) eq ($_//q{}) ? ($PPR::_heredoc_skip{+pos()} // q{}) : q{} })
        ) # End of rule (?<PPR_newline_and_heredoc>)
    )
    # END OF GRAMMAR
}xms;


BEGIN {
    %PPR::_QLD_CLOSE_FOR = (
#       "\x{0028}"  => "\x{0029}",   # LEFT/RIGHT PARENTHESIS
#       "\x{003C}"  => "\x{003E}",   # LESS-THAN/GREATER-THAN SIGN
#       "\x{005B}"  => "\x{005D}",   # LEFT/RIGHT SQUARE BRACKET
#       "\x{007B}"  => "\x{007D}",   # LEFT/RIGHT CURLY BRACKET
        "\x{00AB}"  => "\x{00BB}",   # LEFT/RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK
        "\x{00BB}"  => "\x{00AB}",   # RIGHT/LEFT-POINTING DOUBLE ANGLE QUOTATION MARK
        "\x{0706}"  => "\x{0707}",   # SYRIAC COLON SKEWED LEFT/RIGHT
        "\x{0F3A}"  => "\x{0F3B}",   # TIBETAN MARK GUG RTAGS GYON,  TIBETAN MARK GUG RTAGS GYAS
        "\x{0F3C}"  => "\x{0F3D}",   # TIBETAN MARK ANG KHANG GYON,  TIBETAN MARK ANG KHANG GYAS
        "\x{169B}"  => "\x{169C}",   # OGHAM FEATHER MARK,  OGHAM REVERSED FEATHER MARK
        "\x{2018}"  => "\x{2019}",   # LEFT/RIGHT SINGLE QUOTATION MARK
        "\x{2019}"  => "\x{2018}",   # RIGHT/LEFT SINGLE QUOTATION MARK
        "\x{201C}"  => "\x{201D}",   # LEFT/RIGHT DOUBLE QUOTATION MARK
        "\x{201D}"  => "\x{201C}",   # RIGHT/LEFT DOUBLE QUOTATION MARK
        "\x{2035}"  => "\x{2032}",   # REVERSED PRIME,  PRIME
        "\x{2036}"  => "\x{2033}",   # REVERSED DOUBLE PRIME,  DOUBLE PRIME
        "\x{2037}"  => "\x{2034}",   # REVERSED TRIPLE PRIME,  TRIPLE PRIME
        "\x{2039}"  => "\x{203A}",   # SINGLE LEFT/RIGHT-POINTING ANGLE QUOTATION MARK
        "\x{203A}"  => "\x{2039}",   # SINGLE RIGHT/LEFT-POINTING ANGLE QUOTATION MARK
        "\x{2045}"  => "\x{2046}",   # LEFT/RIGHT SQUARE BRACKET WITH QUILL
        "\x{204D}"  => "\x{204C}",   # BLACK RIGHT/LEFTWARDS BULLET
        "\x{207D}"  => "\x{207E}",   # SUPERSCRIPT LEFT/RIGHT PARENTHESIS
        "\x{208D}"  => "\x{208E}",   # SUBSCRIPT LEFT/RIGHT PARENTHESIS
        "\x{2192}"  => "\x{2190}",   # RIGHT/LEFTWARDS ARROW
        "\x{219B}"  => "\x{219A}",   # RIGHT/LEFTWARDS ARROW WITH STROKE
        "\x{219D}"  => "\x{219C}",   # RIGHT/LEFTWARDS WAVE ARROW
        "\x{21A0}"  => "\x{219E}",   # RIGHT/LEFTWARDS TWO HEADED ARROW
        "\x{21A3}"  => "\x{21A2}",   # RIGHT/LEFTWARDS ARROW WITH TAIL
        "\x{21A6}"  => "\x{21A4}",   # RIGHT/LEFTWARDS ARROW FROM BAR
        "\x{21AA}"  => "\x{21A9}",   # RIGHT/LEFTWARDS ARROW WITH HOOK
        "\x{21AC}"  => "\x{21AB}",   # RIGHT/LEFTWARDS ARROW WITH LOOP
        "\x{21B1}"  => "\x{21B0}",   # UPWARDS ARROW WITH TIP RIGHT/LEFTWARDS
        "\x{21B3}"  => "\x{21B2}",   # DOWNWARDS ARROW WITH TIP RIGHT/LEFTWARDS
        "\x{21C0}"  => "\x{21BC}",   # RIGHT/LEFTWARDS HARPOON WITH BARB UPWARDS
        "\x{21C1}"  => "\x{21BD}",   # RIGHT/LEFTWARDS HARPOON WITH BARB DOWNWARDS
        "\x{21C9}"  => "\x{21C7}",   # RIGHT/LEFTWARDS PAIRED ARROWS
        "\x{21CF}"  => "\x{21CD}",   # RIGHT/LEFTWARDS DOUBLE ARROW WITH STROKE
        "\x{21D2}"  => "\x{21D0}",   # RIGHT/LEFTWARDS DOUBLE ARROW
        "\x{21DB}"  => "\x{21DA}",   # RIGHT/LEFTWARDS TRIPLE ARROW
        "\x{21DD}"  => "\x{21DC}",   # RIGHT/LEFTWARDS SQUIGGLE ARROW
        "\x{21E2}"  => "\x{21E0}",   # RIGHT/LEFTWARDS DASHED ARROW
        "\x{21E5}"  => "\x{21E4}",   # RIGHT/LEFTWARDS ARROW TO BAR
        "\x{21E8}"  => "\x{21E6}",   # RIGHT/LEFTWARDS WHITE ARROW
        "\x{21F4}"  => "\x{2B30}",   # RIGHT/LEFT ARROW WITH SMALL CIRCLE
        "\x{21F6}"  => "\x{2B31}",   # THREE RIGHT/LEFTWARDS ARROWS
        "\x{21F8}"  => "\x{21F7}",   # RIGHT/LEFTWARDS ARROW WITH VERTICAL STROKE
        "\x{21FB}"  => "\x{21FA}",   # RIGHT/LEFTWARDS ARROW WITH DOUBLE VERTICAL STROKE
        "\x{21FE}"  => "\x{21FD}",   # RIGHT/LEFTWARDS OPEN-HEADED ARROW
        "\x{2208}"  => "\x{220B}",   # ELEMENT OF,  CONTAINS AS MEMBER
        "\x{2209}"  => "\x{220C}",   # NOT AN ELEMENT OF,  DOES NOT CONTAIN AS MEMBER
        "\x{220A}"  => "\x{220D}",   # SMALL ELEMENT OF,  SMALL CONTAINS AS MEMBER
        "\x{2264}"  => "\x{2265}",   # LESS-THAN/GREATER-THAN OR EQUAL TO
        "\x{2266}"  => "\x{2267}",   # LESS-THAN/GREATER-THAN OVER EQUAL TO
        "\x{2268}"  => "\x{2269}",   # LESS-THAN/GREATER-THAN BUT NOT EQUAL TO
        "\x{226A}"  => "\x{226B}",   # MUCH LESS-THAN/GREATER-THAN
        "\x{226E}"  => "\x{226F}",   # NOT LESS-THAN/GREATER-THAN
        "\x{2270}"  => "\x{2271}",   # NEITHER LESS-THAN/GREATER-THAN NOR EQUAL TO
        "\x{2272}"  => "\x{2273}",   # LESS-THAN/GREATER-THAN OR EQUIVALENT TO
        "\x{2274}"  => "\x{2275}",   # NEITHER LESS-THAN/GREATER-THAN NOR EQUIVALENT TO
        "\x{227A}"  => "\x{227B}",   # PRECEDES/SUCCEEDS
        "\x{227C}"  => "\x{227D}",   # PRECEDES/SUCCEEDS OR EQUAL TO
        "\x{227E}"  => "\x{227F}",   # PRECEDES/SUCCEEDS OR EQUIVALENT TO
        "\x{2280}"  => "\x{2281}",   # DOES NOT PRECEDE/SUCCEED
        "\x{2282}"  => "\x{2283}",   # SUBSET/SUPERSET OF
        "\x{2284}"  => "\x{2285}",   # NOT A SUBSET/SUPERSET OF
        "\x{2286}"  => "\x{2287}",   # SUBSET/SUPERSET OF OR EQUAL TO
        "\x{2288}"  => "\x{2289}",   # NEITHER A SUBSET/SUPERSET OF NOR EQUAL TO
        "\x{228A}"  => "\x{228B}",   # SUBSET/SUPERSET OF WITH NOT EQUAL TO
        "\x{22A3}"  => "\x{22A2}",   # LEFT/RIGHT TACK
        "\x{22A6}"  => "\x{2ADE}",   # ASSERTION,  SHORT LEFT TACK
        "\x{22A8}"  => "\x{2AE4}",   # TRUE,  VERTICAL BAR DOUBLE LEFT TURNSTILE
        "\x{22A9}"  => "\x{2AE3}",   # FORCES,  DOUBLE VERTICAL BAR LEFT TURNSTILE
        "\x{22B0}"  => "\x{22B1}",   # PRECEDES/SUCCEEDS UNDER RELATION
        "\x{22D0}"  => "\x{22D1}",   # DOUBLE SUBSET/SUPERSET
        "\x{22D6}"  => "\x{22D7}",   # LESS-THAN/GREATER-THAN WITH DOT
        "\x{22D8}"  => "\x{22D9}",   # VERY MUCH LESS-THAN/GREATER-THAN
        "\x{22DC}"  => "\x{22DD}",   # EQUAL TO OR LESS-THAN/GREATER-THAN
        "\x{22DE}"  => "\x{22DF}",   # EQUAL TO OR PRECEDES/SUCCEEDS
        "\x{22E0}"  => "\x{22E1}",   # DOES NOT PRECEDE/SUCCEED OR EQUAL
        "\x{22E6}"  => "\x{22E7}",   # LESS-THAN/GREATER-THAN BUT NOT EQUIVALENT TO
        "\x{22E8}"  => "\x{22E9}",   # PRECEDES/SUCCEEDS BUT NOT EQUIVALENT TO
        "\x{22F2}"  => "\x{22FA}",   # ELEMENT OF/CONTAINS WITH LONG HORIZONTAL STROKE
        "\x{22F3}"  => "\x{22FB}",   # ELEMENT OF/CONTAINS WITH VERTICAL BAR AT END OF HORIZONTAL STROKE
        "\x{22F4}"  => "\x{22FC}",   # SMALL ELEMENT OF/CONTAINS WITH VERTICAL BAR AT END OF HORIZONTAL STROKE
        "\x{22F6}"  => "\x{22FD}",   # ELEMENT OF/CONTAINS WITH OVERBAR
        "\x{22F7}"  => "\x{22FE}",   # SMALL ELEMENT OF/CONTAINS WITH OVERBAR
        "\x{2308}"  => "\x{2309}",   # LEFT/RIGHT CEILING
        "\x{230A}"  => "\x{230B}",   # LEFT/RIGHT FLOOR
        "\x{2326}"  => "\x{232B}",   # ERASE TO THE RIGHT/LEFT
        "\x{2329}"  => "\x{232A}",   # LEFT/RIGHT-POINTING ANGLE BRACKET
        "\x{2348}"  => "\x{2347}",   # APL FUNCTIONAL SYMBOL QUAD RIGHT/LEFTWARDS ARROW
        "\x{23E9}"  => "\x{23EA}",   # BLACK RIGHT/LEFT-POINTING DOUBLE TRIANGLE
        "\x{23ED}"  => "\x{23EE}",   # BLACK RIGHT/LEFT-POINTING DOUBLE TRIANGLE WITH VERTICAL BAR
        "\x{261B}"  => "\x{261A}",   # BLACK RIGHT/LEFT POINTING INDEX
        "\x{261E}"  => "\x{261C}",   # WHITE RIGHT/LEFT POINTING INDEX
        "\x{269E}"  => "\x{269F}",   # THREE LINES CONVERGING RIGHT/LEFT
        "\x{2768}"  => "\x{2769}",   # MEDIUM LEFT/RIGHT PARENTHESIS ORNAMENT
        "\x{276A}"  => "\x{276B}",   # MEDIUM FLATTENED LEFT/RIGHT PARENTHESIS ORNAMENT
        "\x{276C}"  => "\x{276D}",   # MEDIUM LEFT/RIGHT-POINTING ANGLE BRACKET ORNAMENT
        "\x{276E}"  => "\x{276F}",   # HEAVY LEFT/RIGHT-POINTING ANGLE QUOTATION MARK ORNAMENT
        "\x{2770}"  => "\x{2771}",   # HEAVY LEFT/RIGHT-POINTING ANGLE BRACKET ORNAMENT
        "\x{2772}"  => "\x{2773}",   # LIGHT LEFT/RIGHT TORTOISE SHELL BRACKET ORNAMENT
        "\x{2774}"  => "\x{2775}",   # MEDIUM LEFT/RIGHT CURLY BRACKET ORNAMENT
        "\x{27C3}"  => "\x{27C4}",   # OPEN SUBSET/SUPERSET
        "\x{27C5}"  => "\x{27C6}",   # LEFT/RIGHT S-SHAPED BAG DELIMITER
        "\x{27C8}"  => "\x{27C9}",   # REVERSE SOLIDUS PRECEDING SUBSET,  SUPERSET PRECEDING SOLIDUS
        "\x{27DE}"  => "\x{27DD}",   # LONG LEFT/RIGHT TACK
        "\x{27E6}"  => "\x{27E7}",   # MATHEMATICAL LEFT/RIGHT WHITE SQUARE BRACKET
        "\x{27E8}"  => "\x{27E9}",   # MATHEMATICAL LEFT/RIGHT ANGLE BRACKET
        "\x{27EA}"  => "\x{27EB}",   # MATHEMATICAL LEFT/RIGHT DOUBLE ANGLE BRACKET
        "\x{27EC}"  => "\x{27ED}",   # MATHEMATICAL LEFT/RIGHT WHITE TORTOISE SHELL BRACKET
        "\x{27EE}"  => "\x{27EF}",   # MATHEMATICAL LEFT/RIGHT FLATTENED PARENTHESIS
        "\x{27F4}"  => "\x{2B32}",   # RIGHT/LEFT ARROW WITH CIRCLED PLUS
        "\x{27F6}"  => "\x{27F5}",   # LONG RIGHT/LEFTWARDS ARROW
        "\x{27F9}"  => "\x{27F8}",   # LONG RIGHT/LEFTWARDS DOUBLE ARROW
        "\x{27FC}"  => "\x{27FB}",   # LONG RIGHT/LEFTWARDS ARROW FROM BAR
        "\x{27FE}"  => "\x{27FD}",   # LONG RIGHT/LEFTWARDS DOUBLE ARROW FROM BAR
        "\x{27FF}"  => "\x{2B33}",   # LONG RIGHT/LEFTWARDS SQUIGGLE ARROW
        "\x{2900}"  => "\x{2B34}",   # RIGHT/LEFTWARDS TWO-HEADED ARROW WITH VERTICAL STROKE
        "\x{2901}"  => "\x{2B35}",   # RIGHT/LEFTWARDS TWO-HEADED ARROW WITH DOUBLE VERTICAL STROKE
        "\x{2903}"  => "\x{2902}",   # RIGHT/LEFTWARDS DOUBLE ARROW WITH VERTICAL STROKE
        "\x{2905}"  => "\x{2B36}",   # RIGHT/LEFTWARDS TWO-HEADED ARROW FROM BAR
        "\x{2907}"  => "\x{2906}",   # RIGHT/LEFTWARDS DOUBLE ARROW FROM BAR
        "\x{290D}"  => "\x{290C}",   # RIGHT/LEFTWARDS DOUBLE DASH ARROW
        "\x{290F}"  => "\x{290E}",   # RIGHT/LEFTWARDS TRIPLE DASH ARROW
        "\x{2910}"  => "\x{2B37}",   # RIGHT/LEFTWARDS TWO-HEADED TRIPLE DASH ARROW
        "\x{2911}"  => "\x{2B38}",   # RIGHT/LEFTWARDS ARROW WITH DOTTED STEM
        "\x{2914}"  => "\x{2B39}",   # RIGHT/LEFTWARDS ARROW WITH TAIL WITH VERTICAL STROKE
        "\x{2915}"  => "\x{2B3A}",   # RIGHT/LEFTWARDS ARROW WITH TAIL WITH DOUBLE VERTICAL STROKE
        "\x{2916}"  => "\x{2B3B}",   # RIGHT/LEFTWARDS TWO-HEADED ARROW WITH TAIL
        "\x{2917}"  => "\x{2B3C}",   # RIGHT/LEFTWARDS TWO-HEADED ARROW WITH TAIL WITH VERTICAL STROKE
        "\x{2918}"  => "\x{2B3D}",   # RIGHT/LEFTWARDS TWO-HEADED ARROW WITH TAIL WITH DOUBLE VERTICAL STROKE
        "\x{291A}"  => "\x{2919}",   # RIGHT/LEFTWARDS ARROW-TAIL
        "\x{291C}"  => "\x{291B}",   # RIGHT/LEFTWARDS DOUBLE ARROW-TAIL
        "\x{291E}"  => "\x{291D}",   # RIGHT/LEFTWARDS ARROW TO BLACK DIAMOND
        "\x{2920}"  => "\x{291F}",   # RIGHT/LEFTWARDS ARROW FROM BAR TO BLACK DIAMOND
        "\x{2933}"  => "\x{2B3F}",   # WAVE ARROW POINTING DIRECTLY RIGHT/LEFT
        "\x{2937}"  => "\x{2936}",   # ARROW POINTING DOWNWARDS THEN CURVING RIGHT/LEFTWARDS
        "\x{2945}"  => "\x{2946}",   # RIGHT/LEFTWARDS ARROW WITH PLUS BELOW
        "\x{2947}"  => "\x{2B3E}",   # RIGHT/LEFTWARDS ARROW THROUGH X
        "\x{2953}"  => "\x{2952}",   # RIGHT/LEFTWARDS HARPOON WITH BARB UP TO BAR
        "\x{2957}"  => "\x{2956}",   # RIGHT/LEFTWARDS HARPOON WITH BARB DOWN TO BAR
        "\x{295B}"  => "\x{295A}",   # RIGHT/LEFTWARDS HARPOON WITH BARB UP FROM BAR
        "\x{295F}"  => "\x{295E}",   # RIGHT/LEFTWARDS HARPOON WITH BARB DOWN FROM BAR
        "\x{2964}"  => "\x{2962}",   # RIGHT/LEFTWARDS HARPOON WITH BARB UP ABOVE RIGHT/LEFTWARDS HARPOON WITH BARB DOWN
        "\x{296C}"  => "\x{296A}",   # RIGHT/LEFTWARDS HARPOON WITH BARB UP ABOVE LONG DASH
        "\x{296D}"  => "\x{296B}",   # RIGHT/LEFTWARDS HARPOON WITH BARB DOWN BELOW LONG DASH
        "\x{2971}"  => "\x{2B40}",   # EQUALS SIGN ABOVE RIGHT/LEFTWARDS ARROW
        "\x{2972}"  => "\x{2B41}",   # TILDE OPERATOR ABOVE RIGHTWARDS ARROW,  REVERSE TILDE OPERATOR ABOVE LEFTWARDS ARROW
        "\x{2974}"  => "\x{2B4B}",   # RIGHTWARDS ARROW ABOVE TILDE OPERATOR, LEFTWARDS ARROW ABOVE REVERSE TILDE OPERATOR
        "\x{2975}"  => "\x{2B42}",   # RIGHTWARDS ARROW ABOVE ALMOST EQUAL TO, LEFTWARDS ARROW ABOVE REVERSE ALMOST EQUAL TO
        "\x{2979}"  => "\x{297B}",   # SUBSET/SUPERSET ABOVE RIGHT/LEFTWARDS ARROW
        "\x{2983}"  => "\x{2984}",   # LEFT/RIGHT WHITE CURLY BRACKET
        "\x{2985}"  => "\x{2986}",   # LEFT/RIGHT WHITE PARENTHESIS
        "\x{2987}"  => "\x{2988}",   # Z NOTATION LEFT/RIGHT IMAGE BRACKET
        "\x{2989}"  => "\x{298A}",   # Z NOTATION LEFT/RIGHT BINDING BRACKET
        "\x{298B}"  => "\x{298C}",   # LEFT/RIGHT SQUARE BRACKET WITH UNDERBAR
        "\x{298D}"  => "\x{2990}",   # LEFT/RIGHT SQUARE BRACKET WITH TICK IN TOP CORNER
        "\x{298F}"  => "\x{298E}",   # LEFT/RIGHT SQUARE BRACKET WITH TICK IN BOTTOM CORNER
        "\x{2991}"  => "\x{2992}",   # LEFT/RIGHT ANGLE BRACKET WITH DOT
        "\x{2993}"  => "\x{2994}",   # LEFT/RIGHT ARC LESS-THAN/GREATER-THAN BRACKET
        "\x{2995}"  => "\x{2996}",   # DOUBLE LEFT/RIGHT ARC GREATER-THAN/LESS-THAN BRACKET
        "\x{2997}"  => "\x{2998}",   # LEFT/RIGHT BLACK TORTOISE SHELL BRACKET
        "\x{29A8}"  => "\x{29A9}",   # MEASURED ANGLE WITH OPEN ARM ENDING IN ARROW POINTING UP AND RIGHT/LEFT
        "\x{29AA}"  => "\x{29AB}",   # MEASURED ANGLE WITH OPEN ARM ENDING IN ARROW POINTING DOWN AND RIGHT/LEFT
        "\x{29B3}"  => "\x{29B4}",   # EMPTY SET WITH RIGHT/LEFT ARROW ABOVE
        "\x{29C0}"  => "\x{29C1}",   # CIRCLED LESS-THAN/GREATER-THAN
        "\x{29D8}"  => "\x{29D9}",   # LEFT/RIGHT WIGGLY FENCE
        "\x{29DA}"  => "\x{29DB}",   # LEFT/RIGHT DOUBLE WIGGLY FENCE
        "\x{29FC}"  => "\x{29FD}",   # LEFT/RIGHT-POINTING CURVED ANGLE BRACKET
        "\x{2A79}"  => "\x{2A7A}",   # LESS-THAN/GREATER-THAN WITH CIRCLE INSIDE
        "\x{2A7B}"  => "\x{2A7C}",   # LESS-THAN/GREATER-THAN WITH QUESTION MARK ABOVE
        "\x{2A7D}"  => "\x{2A7E}",   # LESS-THAN/GREATER-THAN OR SLANTED EQUAL TO
        "\x{2A7F}"  => "\x{2A80}",   # LESS-THAN/GREATER-THAN OR SLANTED EQUAL TO WITH DOT INSIDE
        "\x{2A81}"  => "\x{2A82}",   # LESS-THAN/GREATER-THAN OR SLANTED EQUAL TO WITH DOT ABOVE
        "\x{2A83}"  => "\x{2A84}",   # LESS-THAN/GREATER-THAN OR SLANTED EQUAL TO WITH DOT ABOVE RIGHT/LEFT
        "\x{2A85}"  => "\x{2A86}",   # LESS-THAN/GREATER-THAN OR APPROXIMATE
        "\x{2A87}"  => "\x{2A88}",   # LESS-THAN/GREATER-THAN AND SINGLE-LINE NOT EQUAL TO
        "\x{2A89}"  => "\x{2A8A}",   # LESS-THAN/GREATER-THAN AND NOT APPROXIMATE
        "\x{2A8D}"  => "\x{2A8E}",   # LESS-THAN/GREATER-THAN ABOVE SIMILAR OR EQUAL
        "\x{2A95}"  => "\x{2A96}",   # SLANTED EQUAL TO OR LESS-THAN/GREATER-THAN
        "\x{2A97}"  => "\x{2A98}",   # SLANTED EQUAL TO OR LESS-THAN/GREATER-THAN WITH DOT INSIDE
        "\x{2A99}"  => "\x{2A9A}",   # DOUBLE-LINE EQUAL TO OR LESS-THAN/GREATER-THAN
        "\x{2A9B}"  => "\x{2A9C}",   # DOUBLE-LINE SLANTED EQUAL TO OR LESS-THAN/ GREATER-THAN
        "\x{2A9D}"  => "\x{2A9E}",   # SIMILAR OR LESS-THAN/GREATER-THAN
        "\x{2A9F}"  => "\x{2AA0}",   # SIMILAR ABOVE LESS-THAN/GREATER-THAN ABOVE EQUALS SIGN
        "\x{2AA1}"  => "\x{2AA2}",   # DOUBLE NESTED LESS-THAN/GREATER-THAN
        "\x{2AA6}"  => "\x{2AA7}",   # LESS-THAN/GREATER-THAN CLOSED BY CURVE
        "\x{2AA8}"  => "\x{2AA9}",   # LESS-THAN/GREATER-THAN CLOSED BY CURVE ABOVE SLANTED EQUAL
        "\x{2AAA}"  => "\x{2AAB}",   # SMALLER THAN/LARGER THAN
        "\x{2AAC}"  => "\x{2AAD}",   # SMALLER THAN/LARGER THAN OR EQUAL TO
        "\x{2AAF}"  => "\x{2AB0}",   # PRECEDES/SUCCEEDS ABOVE SINGLE-LINE EQUALS SIGN
        "\x{2AB1}"  => "\x{2AB2}",   # PRECEDES/SUCCEEDS ABOVE SINGLE-LINE NOT EQUAL TO
        "\x{2AB3}"  => "\x{2AB4}",   # PRECEDES/SUCCEEDS ABOVE EQUALS SIGN
        "\x{2AB5}"  => "\x{2AB6}",   # PRECEDES/SUCCEEDS ABOVE NOT EQUAL TO
        "\x{2AB7}"  => "\x{2AB8}",   # PRECEDES/SUCCEEDS ABOVE ALMOST EQUAL TO
        "\x{2AB9}"  => "\x{2ABA}",   # PRECEDES/SUCCEEDS ABOVE NOT ALMOST EQUAL TO
        "\x{2ABB}"  => "\x{2ABC}",   # DOUBLE PRECEDES/SUCCEEDS
        "\x{2ABD}"  => "\x{2ABE}",   # SUBSET/SUPERSET WITH DOT
        "\x{2ABF}"  => "\x{2AC0}",   # SUBSET/SUPERSET WITH PLUS SIGN BELOW
        "\x{2AC1}"  => "\x{2AC2}",   # SUBSET/SUPERSET WITH MULTIPLICATION SIGN BELOW
        "\x{2AC3}"  => "\x{2AC4}",   # SUBSET/SUPERSET OF OR EQUAL TO WITH DOT ABOVE
        "\x{2AC5}"  => "\x{2AC6}",   # SUBSET/SUPERSET OF ABOVE EQUALS SIGN
        "\x{2AC7}"  => "\x{2AC8}",   # SUBSET/SUPERSET OF ABOVE TILDE OPERATOR
        "\x{2AC9}"  => "\x{2ACA}",   # SUBSET/SUPERSET OF ABOVE ALMOST EQUAL TO
        "\x{2ACB}"  => "\x{2ACC}",   # SUBSET/SUPERSET OF ABOVE NOT EQUAL TO
        "\x{2ACF}"  => "\x{2AD0}",   # CLOSED SUBSET/SUPERSET
        "\x{2AD1}"  => "\x{2AD2}",   # CLOSED SUBSET/SUPERSET OR EQUAL TO
        "\x{2AD5}"  => "\x{2AD6}",   # SUBSET/SUPERSET ABOVE SUBSET/SUPERSET
        "\x{2AE5}"  => "\x{22AB}",   # DOUBLE VERTICAL BAR DOUBLE LEFT/RIGHT TURNSTILE
        "\x{2AF7}"  => "\x{2AF8}",   # TRIPLE NESTED LESS-THAN/GREATER-THAN
        "\x{2AF9}"  => "\x{2AFA}",   # DOUBLE-LINE SLANTED LESS-THAN/GREATER-THAN OR EQUAL TO
        "\x{2B46}"  => "\x{2B45}",   # RIGHT/LEFTWARDS QUADRUPLE ARROW
        "\x{2B47}"  => "\x{2B49}",   # REVERSE TILDE OPERATOR ABOVE RIGHTWARDS ARROW, TILDE OPERATOR ABOVE LEFTWARDS ARROW
        "\x{2B48}"  => "\x{2B4A}",   # RIGHTWARDS ARROW ABOVE REVERSE ALMOST EQUAL TO,  LEFTWARDS ARROW ABOVE ALMOST EQUAL TO
        "\x{2B4C}"  => "\x{2973}",   # RIGHTWARDS ARROW ABOVE REVERSE TILDE OPERATOR, LEFTWARDS ARROW ABOVE TILDE OPERATOR
        "\x{2B62}"  => "\x{2B60}",   # RIGHT/LEFTWARDS TRIANGLE-HEADED ARROW
        "\x{2B6C}"  => "\x{2B6A}",   # RIGHT/LEFTWARDS TRIANGLE-HEADED DASHED ARROW
        "\x{2B72}"  => "\x{2B70}",   # RIGHT/LEFTWARDS TRIANGLE-HEADED ARROW TO BAR
        "\x{2B7C}"  => "\x{2B7A}",   # RIGHT/LEFTWARDS TRIANGLE-HEADED ARROW WITH DOUBLE VERTICAL STROKE
        "\x{2B86}"  => "\x{2B84}",   # RIGHT/LEFTWARDS TRIANGLE-HEADED PAIRED ARROWS
        "\x{2B8A}"  => "\x{2B88}",   # RIGHT/LEFTWARDS BLACK CIRCLED WHITE ARROW
        "\x{2B95}"  => "\x{2B05}",   # RIGHT/LEFTWARDS BLACK ARROW
        "\x{2B9A}"  => "\x{2B98}",   # THREE-D TOP-LIGHTED RIGHT/LEFTWARDS EQUILATERAL ARROWHEAD
        "\x{2B9E}"  => "\x{2B9C}",   # BLACK RIGHT/LEFTWARDS EQUILATERAL ARROWHEAD
        "\x{2BA1}"  => "\x{2BA0}",   # DOWNWARDS TRIANGLE-HEADED ARROW WITH LONG TIP RIGHT/LEFTWARDS
        "\x{2BA3}"  => "\x{2BA2}",   # UPWARDS TRIANGLE-HEADED ARROW WITH LONG TIP RIGHT/LEFTWARDS
        "\x{2BA9}"  => "\x{2BA8}",   # BLACK CURVED DOWNWARDS AND RIGHT/LEFTWARDS ARROW
        "\x{2BAB}"  => "\x{2BAA}",   # BLACK CURVED UPWARDS AND RIGHT/LEFTWARDS ARROW
        "\x{2BB1}"  => "\x{2BB0}",   # RIBBON ARROW DOWN RIGHT/LEFT
        "\x{2BB3}"  => "\x{2BB2}",   # RIBBON ARROW UP RIGHT/LEFT
        "\x{2BEE}"  => "\x{2BEC}",   # RIGHT/LEFTWARDS TWO-HEADED ARROW WITH TRIANGLE ARROWHEADS
        "\x{2E02}"  => "\x{2E03}",   # LEFT/RIGHT SUBSTITUTION BRACKET
        "\x{2E03}"  => "\x{2E02}",   # RIGHT/LEFT SUBSTITUTION BRACKET
        "\x{2E04}"  => "\x{2E05}",   # LEFT/RIGHT DOTTED SUBSTITUTION BRACKET
        "\x{2E05}"  => "\x{2E04}",   # RIGHT/LEFT DOTTED SUBSTITUTION BRACKET
        "\x{2E09}"  => "\x{2E0A}",   # LEFT/RIGHT TRANSPOSITION BRACKET
        "\x{2E0A}"  => "\x{2E09}",   # RIGHT/LEFT TRANSPOSITION BRACKET
        "\x{2E0C}"  => "\x{2E0D}",   # LEFT/RIGHT RAISED OMISSION BRACKET
        "\x{2E0D}"  => "\x{2E0C}",   # RIGHT/LEFT RAISED OMISSION BRACKET
        "\x{2E11}"  => "\x{2E10}",   # REVERSED FORKED PARAGRAPHOS,  FORKED PARAGRAPHOS
        "\x{2E1C}"  => "\x{2E1D}",   # LEFT/RIGHT LOW PARAPHRASE BRACKET
        "\x{2E1D}"  => "\x{2E1C}",   # RIGHT/LEFT LOW PARAPHRASE BRACKET
        "\x{2E20}"  => "\x{2E21}",   # LEFT/RIGHT VERTICAL BAR WITH QUILL
        "\x{2E21}"  => "\x{2E20}",   # RIGHT/LEFT VERTICAL BAR WITH QUILL
        "\x{2E22}"  => "\x{2E23}",   # TOP LEFT/RIGHT HALF BRACKET
        "\x{2E24}"  => "\x{2E25}",   # BOTTOM LEFT/RIGHT HALF BRACKET
        "\x{2E26}"  => "\x{2E27}",   # LEFT/RIGHT SIDEWAYS U BRACKET
        "\x{2E28}"  => "\x{2E29}",   # LEFT/RIGHT DOUBLE PARENTHESIS
        "\x{2E36}"  => "\x{2E37}",   # DAGGER WITH LEFT/RIGHT GUARD
        "\x{2E42}"  => "\x{201E}",   # DOUBLE LOW-REVERSED-9 QUOTATION MARK,  DOUBLE LOW-9 QUOTATION MARK
        "\x{2E55}"  => "\x{2E56}",   # LEFT/RIGHT SQUARE BRACKET WITH STROKE
        "\x{2E57}"  => "\x{2E58}",   # LEFT/RIGHT SQUARE BRACKET WITH DOUBLE STROKE
        "\x{2E59}"  => "\x{2E5A}",   # TOP HALF LEFT/RIGHT PARENTHESIS
        "\x{2E5B}"  => "\x{2E5C}",   # BOTTOM HALF LEFT/RIGHT PARENTHESIS
        "\x{3008}"  => "\x{3009}",   # LEFT/RIGHT ANGLE BRACKET
        "\x{300A}"  => "\x{300B}",   # LEFT/RIGHT DOUBLE ANGLE BRACKET
        "\x{300C}"  => "\x{300D}",   # LEFT/RIGHT CORNER BRACKET
        "\x{300E}"  => "\x{300F}",   # LEFT/RIGHT WHITE CORNER BRACKET
        "\x{3010}"  => "\x{3011}",   # LEFT/RIGHT BLACK LENTICULAR BRACKET
        "\x{3014}"  => "\x{3015}",   # LEFT/RIGHT TORTOISE SHELL BRACKET
        "\x{3016}"  => "\x{3017}",   # LEFT/RIGHT WHITE LENTICULAR BRACKET
        "\x{3018}"  => "\x{3019}",   # LEFT/RIGHT WHITE TORTOISE SHELL BRACKET
        "\x{301A}"  => "\x{301B}",   # LEFT/RIGHT WHITE SQUARE BRACKET
        "\x{301D}"  => "\x{301E}",   # REVERSED DOUBLE PRIME QUOTATION MARK,  DOUBLE PRIME QUOTATION MARK
        "\x{A9C1}"  => "\x{A9C2}",   # JAVANESE LEFT/RIGHT RERENGGAN
        "\x{FD3E}"  => "\x{FD3F}",   # ORNATE LEFT/RIGHT PARENTHESIS
        "\x{FE59}"  => "\x{FE5A}",   # SMALL LEFT/RIGHT PARENTHESIS
        "\x{FE5B}"  => "\x{FE5C}",   # SMALL LEFT/RIGHT CURLY BRACKET
        "\x{FE5D}"  => "\x{FE5E}",   # SMALL LEFT/RIGHT TORTOISE SHELL BRACKET
        "\x{FE64}"  => "\x{FE65}",   # SMALL LESS-THAN/GREATER-THAN SIGN
        "\x{FF08}"  => "\x{FF09}",   # FULLWIDTH LEFT/RIGHT PARENTHESIS
        "\x{FF1C}"  => "\x{FF1E}",   # FULLWIDTH LESS-THAN/GREATER-THAN SIGN
        "\x{FF3B}"  => "\x{FF3D}",   # FULLWIDTH LEFT/RIGHT SQUARE BRACKET
        "\x{FF5B}"  => "\x{FF5D}",   # FULLWIDTH LEFT/RIGHT CURLY BRACKET
        "\x{FF5F}"  => "\x{FF60}",   # FULLWIDTH LEFT/RIGHT WHITE PARENTHESIS
        "\x{FF62}"  => "\x{FF63}",   # HALFWIDTH LEFT/RIGHT CORNER BRACKET
        "\x{FFEB}"  => "\x{FFE9}",   # HALFWIDTH RIGHT/LEFTWARDS ARROW
        "\x{1D103}" => "\x{1D102}",   # MUSICAL SYMBOL REVERSE FINAL BARLINE,  MUSICAL SYMBOL FINAL BARLINE
        "\x{1D106}" => "\x{1D107}",   # MUSICAL SYMBOL LEFT/RIGHT REPEAT SIGN
        "\x{1F449}" => "\x{1F448}",   # WHITE RIGHT/LEFT POINTING BACKHAND INDEX
        "\x{1F508}" => "\x{1F568}",   # SPEAKER,  RIGHT SPEAKER
        "\x{1F509}" => "\x{1F569}",   # SPEAKER WITH ONE SOUND WAVE,  RIGHT SPEAKER WITH ONE SOUND WAVE
        "\x{1F50A}" => "\x{1F56A}",   # SPEAKER WITH THREE SOUND WAVES,  RIGHT SPEAKER WITH THREE SOUND WAVES
        "\x{1F57B}" => "\x{1F57D}",   # LEFT/RIGHT HAND TELEPHONE RECEIVER
        "\x{1F599}" => "\x{1F598}",   # SIDEWAYS WHITE RIGHT/LEFT POINTING INDEX
        "\x{1F59B}" => "\x{1F59A}",   # SIDEWAYS BLACK RIGHT/LEFT POINTING INDEX
        "\x{1F59D}" => "\x{1F59C}",   # BLACK RIGHT/LEFT POINTING BACKHAND INDEX
        "\x{1F5E6}" => "\x{1F5E7}",   # THREE RAYS LEFT/RIGHT
        "\x{1F802}" => "\x{1F800}",   # RIGHT/LEFTWARDS ARROW WITH SMALL TRIANGLE ARROWHEAD
        "\x{1F806}" => "\x{1F804}",   # RIGHT/LEFTWARDS ARROW WITH MEDIUM TRIANGLE ARROWHEAD
        "\x{1F80A}" => "\x{1F808}",   # RIGHT/LEFTWARDS ARROW WITH LARGE TRIANGLE ARROWHEAD
        "\x{1F812}" => "\x{1F810}",   # RIGHT/LEFTWARDS ARROW WITH SMALL EQUILATERAL ARROWHEAD
        "\x{1F816}" => "\x{1F814}",   # RIGHT/LEFTWARDS ARROW WITH EQUILATERAL ARROWHEAD
        "\x{1F81A}" => "\x{1F818}",   # HEAVY RIGHT/LEFTWARDS ARROW WITH EQUILATERAL ARROWHEAD
        "\x{1F81E}" => "\x{1F81C}",   # HEAVY RIGHT/LEFTWARDS ARROW WITH LARGE EQUILATERAL ARROWHEAD
        "\x{1F822}" => "\x{1F820}",   # RIGHT/LEFTWARDS TRIANGLE-HEADED ARROW WITH NARROW SHAFT
        "\x{1F826}" => "\x{1F824}",   # RIGHT/LEFTWARDS TRIANGLE-HEADED ARROW WITH MEDIUM SHAFT
        "\x{1F82A}" => "\x{1F828}",   # RIGHT/LEFTWARDS TRIANGLE-HEADED ARROW WITH BOLD SHAFT
        "\x{1F82E}" => "\x{1F82C}",   # RIGHT/LEFTWARDS TRIANGLE-HEADED ARROW WITH HEAVY SHAFT
        "\x{1F832}" => "\x{1F830}",   # RIGHT/LEFTWARDS TRIANGLE-HEADED ARROW WITH VERY HEAVY SHAFT
        "\x{1F836}" => "\x{1F834}",   # RIGHT/LEFTWARDS FINGER-POST ARROW
        "\x{1F83A}" => "\x{1F838}",   # RIGHT/LEFTWARDS SQUARED ARROW
        "\x{1F83E}" => "\x{1F83C}",   # RIGHT/LEFTWARDS COMPRESSED ARROW
        "\x{1F842}" => "\x{1F840}",   # RIGHT/LEFTWARDS HEAVY COMPRESSED ARROW
        "\x{1F846}" => "\x{1F844}",   # RIGHT/LEFTWARDS HEAVY ARROW
        "\x{1F852}" => "\x{1F850}",   # RIGHT/LEFTWARDS SANS-SERIF ARROW
        "\x{1F862}" => "\x{1F860}",   # WIDE-HEADED RIGHT/LEFTWARDS LIGHT BARB ARROW
        "\x{1F86A}" => "\x{1F868}",   # WIDE-HEADED RIGHT/LEFTWARDS BARB ARROW
        "\x{1F872}" => "\x{1F870}",   # WIDE-HEADED RIGHT/LEFTWARDS MEDIUM BARB ARROW
        "\x{1F87A}" => "\x{1F878}",   # WIDE-HEADED RIGHT/LEFTWARDS HEAVY BARB ARROW
        "\x{1F882}" => "\x{1F880}",   # WIDE-HEADED RIGHT/LEFTWARDS VERY HEAVY BARB ARROW
        "\x{1F892}" => "\x{1F890}",   # RIGHT/LEFTWARDS TRIANGLE ARROWHEAD
        "\x{1F896}" => "\x{1F894}",   # RIGHT/LEFTWARDS WHITE ARROW WITHIN TRIANGLE ARROWHEAD
        "\x{1F89A}" => "\x{1F898}",   # RIGHT/LEFTWARDS ARROW WITH NOTCHED TAIL
        "\x{1F8A1}" => "\x{1F8A0}",   # RIGHTWARDS BOTTOM SHADED WHITE ARROW, LEFTWARDS BOTTOM-SHADED WHITE ARROW
        "\x{1F8A3}" => "\x{1F8A2}",   # RIGHT/LEFTWARDS TOP SHADED WHITE ARROW
        "\x{1F8A5}" => "\x{1F8A6}",   # RIGHT/LEFTWARDS RIGHT-SHADED WHITE ARROW
        "\x{1F8A7}" => "\x{1F8A4}",   # RIGHT/LEFTWARDS LEFT-SHADED WHITE ARROW
        "\x{1F8A9}" => "\x{1F8A8}",   # RIGHT/LEFTWARDS BACK-TILTED SHADOWED WHITE ARROW
        "\x{1F8AB}" => "\x{1F8AA}",   # RIGHT/LEFTWARDS FRONT-TILTED SHADOWED WHITE ARROW
    );
}

sub decomment {
    if ($] >= 5.014 && $] < 5.016) { _croak( "PPR::decomment() does not work under Perl 5.14" )}

    my ($str) = @_;

    local %PPR::comment_len;

    # Locate comments...
    $str =~ m{  (?&PerlEntireDocument)

                (?(DEFINE)
                    (?<decomment>
                       ( (?<! [\$@%] ) [#] [^\n]*+ )
                       (?{
                            my $len = length($^N);
                            my $pos = pos() - $len;
                            $PPR::comment_len{$pos} = $len;
                       })
                    )

                    (?<PerlOWS>
                        (?:
                            \h++
                        |
                            (?&PPR_newline_and_heredoc)
                        |
                            (?&decomment)
                        |
                            __ (?> END | DATA ) __ \b .*+ \z
                        )*+
                    ) # End of rule

                    (?<PerlNWS>
                        (?:
                            \h++
                        |
                            (?&PPR_newline_and_heredoc)
                        |
                            (?&decomment)
                        |
                            __ (?> END | DATA ) __ \b .*+ \z
                        )++

                    ) # End of rule

                    (?<PerlPod>
                        (
                            ^ = [^\W\d]\w*+
                            .*?
                            (?>
                                ^ = cut \b [^\n]*+ $
                            |
                                \z
                            )
                        )
                        (?{
                            my $len = length($^N);
                            my $pos = pos() - $len;
                            $PPR::comment_len{$pos} = $len;
                        })
                    ) # End of rule

                    $PPR::GRAMMAR
                )
            }xms or return;

    # Delete the comments found...
    for my $from_pos (_uniq(sort { $b <=> $a } keys %PPR::comment_len)) {
        substr($str, $from_pos, $PPR::comment_len{$from_pos}) =~ s/.+//g;
    }

    return $str;
}

sub _uniq {
    my %seen;
    return grep {!$seen{$_}++} @_;
}

sub _croak {
    require Carp;
    Carp::croak(@_);
}

sub _report {
    state $CONTEXT_WIDTH = 20;
    state $BUFFER = q{ } x $CONTEXT_WIDTH;
    state $depth = 0;
    my ($msg, $increment) = @_;
    $depth++ if $increment;
    my $at = pos();
    my $str = $BUFFER . $_ . $BUFFER;
    my $pre  = substr($str, $at,                $CONTEXT_WIDTH);
    my $post = substr($str, $at+$CONTEXT_WIDTH, $CONTEXT_WIDTH);
    tr/\n/ / for $pre, $post;
    no warnings 'utf8';
    warn sprintf("%05d ⎜%*s⎜%-*s⎜  %s%s\n",
        $at, $CONTEXT_WIDTH, $pre, $CONTEXT_WIDTH, $post, q{ } x $depth, $msg);
    $depth-- if !$increment;
}

1; # Magic true value required at end of module

__END__

=head1 NAME

PPR - Pattern-based Perl Recognizer


=head1 VERSION

This document describes PPR version 0.001006


=head1 SYNOPSIS

    use PPR;

    # Define a regex that will match an entire Perl document...
    my $perl_document = qr{

        # What to match            # Install the (?&PerlDocument) rule
        (?&PerlEntireDocument)     $PPR::GRAMMAR

    }x;


    # Define a regex that will match a single Perl block...
    my $perl_block = qr{

        # What to match...         # Install the (?&PerlBlock) rule...
        (?&PerlBlock)              $PPR::GRAMMAR
    }x;


    # Define a regex that will match a simple Perl extension...
    my $perl_coroutine = qr{

        # What to match...
        coro                                           (?&PerlOWS)
        (?<coro_name>  (?&PerlQualifiedIdentifier)  )  (?&PerlOWS)
        (?<coro_code>  (?&PerlBlock)                )

        # Install the necessary subrules...
        $PPR::GRAMMAR
    }x;


    # Define a regex that will match an integrated Perl extension...
    my $perl_with_classes = qr{

        # What to match...
        \A
            (?&PerlOWS)       # Optional whitespace (including comments)
            (?&PerlDocument)  # A full Perl document
            (?&PerlOWS)       # More optional whitespace
        \Z

        # Add a 'class' keyword into the syntax that PPR understands...
        (?(DEFINE)
            (?<PerlKeyword>

                    class                              (?&PerlOWS)
                    (?&PerlQualifiedIdentifier)        (?&PerlOWS)
                (?: is (?&PerlNWS) (?&PerlIdentifier)  (?&PerlOWS) )*+
                    (?&PerlBlock)
            )

            (?<kw_balanced_parens>
                \( (?: [^()]++ | (?&kw_balanced_parens) )*+ \)
            )
        )

        # Install the necessary standard subrules...
        $PPR::GRAMMAR
    }x;


=head1 DESCRIPTION

The PPR module provides a single regular expression that defines a set
of independent subpatterns suitable for matching entire Perl documents,
as well as a wide range of individual syntactic components of Perl
(i.e. statements, expressions, control blocks, variables, etc.)

The regex does not "parse" Perl (that is, it does not build a syntax
tree, like the PPI module does). Instead it simply "recognizes" standard
Perl constructs, or new syntaxes composed from Perl constructs.

Its features and capabilities therefore complement those of the PPI
module, rather than replacing them. See L<"Comparison with PPI">.


=head1 INTERFACE

=head2 Importing and using the Perl grammar regex

The PPR module exports no subroutines or variables,
and provides no methods. Instead, it defines a single
package variable, C<$PPR::GRAMMAR>, which can be
interpolated into regexes to add rules that permit
Perl constructs to be parsed:

    $source_code =~ m{ (?&PerlEntireDocument)  $PPR::GRAMMAR }x;

Note that all the examples shown so far have interpolated this "grammar
variable" at the end of the regular expression. This placement is
desirable, but not necessary. Both of the following work identically:

    $source_code =~ m{ (?&PerlEntireDocument)   $PPR::GRAMMAR }x;

    $source_code =~ m{ $PPR::GRAMMAR   (?&PerlEntireDocument) }x;


However, if the grammar is to be L<extended|"Extending the Perl syntax with keywords">,
then the extensions must be specified B<I<before>> the base grammar
(i.e. before the interpolation of C<$PPR::GRAMMAR>). Placing the grammar
variable at the end of a regex ensures that will be the case, and has
the added advantage of "front-loading" the regex with the most important
information: what is actually going to be matched.

Note too that, because the PPR grammar internally uses capture groups,
placing C<$PPR::GRAMMAR> anywhere other than the very end of your regex
may change the numbering of any explicit capture groups in your regex.
For complete safety, regexes that use the PPR grammar should probably
use named captures, instead of numbered captures.


=head2 Error reporting

Regex-based parsing is all-or-nothing: either your regex matches
(and returns any captures you requested), or it fails to match
(and returns nothing).

This can make it difficult to detect I<why> a PPR-based match failed;
to work out what the "bad source code" was that prevented your regex
from matching.

So the module provides a special variable that attempts to detect the
source code that prevented any call to the C<(?&PerlStatement)> subpattern
from matching. That variable is: C<$PPR::ERROR>

C<$PPR::ERROR> is only set if it is undefined at the point where an
error is detected, and will only be set to the first such error that
is encountered during parsing.

Note that errors are only detected when matching context-sensitive components
(for example in the middle of a C<(?&PerlStatement), as part of a
C<(?&PerlContextualRegex)>, or at the end of a C<(?&PerlEntireDocument>)>.
Errors, especially errors at the end of otherwise valid code, will often
not be detected in context-free components (for example, at the end of a
C<(?&PerlStatementSequence), as part of a C<(?&PerlRegex)>, or at the
end of a C<(?&PerlDocument>)>.

A common mistake in this area is to attempt to match an entire Perl document
using:

    m{ \A (?&PerlDocument) \Z   $PPR::GRAMMAR }x

instead of:

    m{ (?&PerlEntireDocument)   $PPR::GRAMMAR }x

Only the second approach will be able to successfully detect an unclosed
curly bracket at the end of the document.


=head3 C<PPR::ERROR> interface

If it is set, C<$PPR::ERROR> will contain an object of type PPR::ERROR,
with the following methods:

=over

=item C<< $PPR::ERROR->origin($line, $file) >>

Returns a clone of the PPR::ERROR object that now believes that the
source code parsing failure it is reporting occurred in a code fragment
starting at the specified line and file. If the second argument is
omitted, the file name is not reported in any diagnostic.

=item C<< $PPR::ERROR->source() >>

Returns a string containing the specific source code that could not be
parsed as a Perl statement.

=item C<< $PPR::ERROR->prefix() >>

Returns a string containing all the source code preceding the
code that could not be parsed. That is: the valid code that is
the preceding context of the unparsable code.

=item C<< $PPR::ERROR->line( $opt_offset ) >>

Returns an integer which is the line number at which the unparsable
code was encountered. If the optional "offset" argument is provided,
it will be added to the line number returned. Note that the offset
is ignored if the PPR::ERROR object originates from a prior call to
C<< $PPR::ERROR->origin >> (because in that case you will have already
specified the correct offset).

=item C<< $PPR::ERROR->diagnostic() >>

Returns a string containing the diagnostic that would be returned
by C<perl -c> if the source code were compiled.

B<I<Warning:>> The diagnostic is obtained by partially eval'ing
the source code. This means that run-time code will not be executed,
but C<BEGIN> and C<CHECK> blocks will run. Do B<I<not>> call this method
if the source code that created this error might also have non-trivial
compile-time side-effects.

=back

A typical use might therefore be:

    # Make sure it's undefined, and will only be locally modified...
    local $PPR::ERROR;

    # Process the matched block...
    if ($source_code =~ m{ (?<Block> (?&PerlBlock) )  $PPR::GRAMMAR }x) {
        process( $+{Block} );
    }

    # Or report the offending code that stopped it being a valid block...
    else {
        die "Invalid Perl block: " . $PPR::ERROR->source . "\n",
            $PPR::ERROR->origin($linenum, $filename)->diagnostic . "\n";
    }


=head2 Decommenting code with C<PPR::decomment()>

The module provides (but does not export) a C<decomment()>
subroutine that can remove any comments and/or POD from source code.

It takes a single argument: a string containing the course code.
It returns a single value: a string containing the decommented source code.

For example:

    $decommented_code = PPR::decomment( $commented_code );

The subroutine will fail if the argument wasn't valid Perl code,
in which case it returns C<undef> and sets C<$PPR::ERROR> to indicate
where the invalid source code was encountered.

Note that, due to separate bugs in the regex engine in Perl 5.14 and
5.20, the C<decomment()> subroutine is not available when running under
these releases.


=head2 Examples

I<Note:> In each of the following examples, the subroutine C<slurp()> is
used to acquire the source code from a file whose name is passed as its
argument. The C<slurp()> subroutine is just:

    sub slurp { local (*ARGV, $/); @ARGV = shift; readline; }

or, for the less twisty-minded:

    sub slurp {
        my ($filename) = @_;
        open my $filehandle, '<', $filename or die $!;
        local $/;
        return readline($filehandle);
    }


=head3 Validating source code

  # "Valid" if source code matches a Perl document under the Perl grammar
  printf(
      "$filename %s a valid Perl file\n",
      slurp($filename) =~ m{ (?&PerlEntireDocument)  $PPR::GRAMMAR }x
          ? "is"
          : "is not"
  );


=head3 Counting statements

  printf(                                        # Output
      "$filename contains %d statements\n",      # a report of
      scalar                                     # the count of
          grep {defined}                         # defined matches
              slurp($filename)                   # from the source code,
                  =~ m{
                        \G (?&PerlOWS)           # skipping whitespace
                           ((?&PerlStatement))   # and keeping statements,
                        $PPR::GRAMMAR            # using the Perl grammar
                      }gcx;                      # incrementally
  );


=head3 Stripping comments and POD from source code

  my $source = slurp($filename);                    # Get the source
  $source =~ s{ (?&PerlNWS)  $PPR::GRAMMAR }{ }gx;  # Compact whitespace
  print $source;                                    # Print the result


=head3 Stripping comments and POD from source code (in Perl v5.14 or later)

  # Print  the source code,  having compacted whitespace...
    print  slurp($filename)  =~ s{ (?&PerlNWS)  $PPR::GRAMMAR }{ }gxr;


=head3 Stripping everything C<except> comments and POD from source code

  say                                         # Output
      grep {defined}                          # defined matches
          slurp($filename)                    # from the source code,
              =~ m{ \G ((?&PerlOWS))          # keeping whitespace,
                       (?&PerlStatement)?     # skipping statements,
                    $PPR::GRAMMAR             # using the Perl grammar
                  }gcx;                       # incrementally


=head2 Available rules

Interpolating C<$PPR::GRAMMAR> in a regex makes all of the following
rules available within that regex.

Note that other rules not listed here may also be added, but these are
all considered strictly internal to the PPR module and are not
guaranteed to continue to exist in future releases. All such
"internal-use-only" rules have names that start with C<PPR_>...


=head3 C<< (?&PerlDocument) >>

Matches a valid Perl document, including leading or trailing
whitespace, comments, and any final C<__DATA__> or C<__END__> section.

This rule is context-free, so it can be embedded in a larger regex.
For example, to match an embedded chunk of Perl code, delimited by
C<<<< <<< >>>>...C<<<< >>> >>>>:

    $src = m{ <<< (?&PerlDocument) >>>   $PPR::GRAMMAR }x;


=head3 C<< (?&PerlEntireDocument) >>

Matches an entire valid Perl document, including leading or trailing
whitespace, comments, and any final C<__DATA__> or C<__END__> section.

This rule is I<not> context-free. It has an internal C<\A> at the beginning
and C<\Z> at the end, so a regex containing C<(?&PerlEntireDocument)>
will only match if:

=over

=item (a)

the C<(?&PerlEntireDocument)> is the sole top-level element of the regex
(or, at least the sole element of a single top-level C<|>-branch of the regex),

=item B<I<and>>


=item (b)

the entire string being matched contains only a single valid Perl document.

=back

In general, if you want to check that a string consists entirely of
a single valid sequence of Perl code, use:

    $str =~ m{ (?&PerlEntireDocument)  $PPR::GRAMMAR }

If you want to check that a string I<contains> at least one valid sequence
of Perl code at some point, possibly embedded in other text, use:

    $str =~ m{ (?&PerlDocument)  $PPR::GRAMMAR }


=head3 C<< (?&PerlStatementSequence) >>

Matches zero-or-more valid Perl statements, separated by optional
POD sequences.


=head3 C<< (?&PerlStatement) >>

Matches a single valid Perl statement, including: control structures;
C<BEGIN>, C<CHECK>, C<UNITCHECK>, C<INIT>, C<END>, C<DESTROY>, or
C<AUTOLOAD> blocks; variable declarations, C<use> statements, etc.


=head3 C<< (?&PerlExpression) >>

Matches a single valid Perl expression involving operators of any
precedence, but not any kind of block (i.e. not control structures,
C<BEGIN> blocks, etc.) nor any trailing statement modifier (e.g.
not a postfix C<if>, C<while>, or C<for>).


=head3 C<< (?&PerlLowPrecedenceNotExpression) >>

Matches an expression at the precedence of the C<not> operator.
That is, a single valid Perl expression that involves operators above
the precedence of C<and>.


=head3 C<< (?&PerlAssignment) >>

Matches an assignment expression.
That is, a single valid Perl expression involving operators above the
precedence of comma (C<,> or C<< => >>).


=head3 C<< (?&PerlConditionalExpression) >> or C<< (?&PerlScalarExpression) >>

Matches a conditional expression that uses the C<?>...C<:> ternary operator.
That is, a single valid Perl expression involving operators above the
precedence of assignment.

The alterative name comes from the fact that anything matching this rule
is what most people think of as a single element of a comma-separated list.


=head3 C<< (?&PerlBinaryExpression) >>

Matches an expression that uses any high-precedence binary operators.
That is, a single valid Perl expression involving operators above the
precedence of the ternary operator.


=head3 C<< (?&PerlPrefixPostfixTerm) >>

Matches a term with optional prefix and/or postfix unary operators
and/or a trailing sequence of C<< -> >> dereferences.
That is, a single valid Perl expression involving operators above the
precedence of exponentiation (C<**>).


=head3 C<< (?&PerlTerm) >>

Matches a simple high-precedence term within a Perl expression.
That is: a subroutine or builtin function call; a variable declaration;
a variable or typeglob lookup; an anonymous array, hash, or subroutine
constructor; a quotelike or numeric literal; a regex match; a
substitution; a transliteration; a C<do> or C<eval> block; or any other
expression in surrounding parentheses.


=head3 C<< (?&PerlTermPostfixDereference) >>

Matches a sequence of array- or hash-lookup brackets, or subroutine call
parentheses, or a postfix dereferencer (e.g. C<< ->$* >>), with
explicit or implicit intervening C<< -> >>, such as might appear after a term.


=head3 C<< (?&PerlLvalue) >>

Matches any variable or parenthesized list of variables that could
be assigned to.


=head3 C<< (?&PerlPackageDeclaration) >>

Matches the declaration of any package
(with or without a defining block).


=head3 C<< (?&PerlSubroutineDeclaration) >>

Matches the declaration of any named subroutine
(with or without a defining block).


=head3 C<< (?&PerlUseStatement) >>

Matches a C<< use <module name> ...; >> or C<< use <version number>; >> statement.


=head3 C<< (?&PerlReturnStatement) >>

Matches a C<< return <expression>; >> or C<< return; >> statement.


=head3 C<< (?&PerlReturnExpression) >>

Matches a C<< return <expression> >>
as an expression without trailing end-of-statement markers.


=head3 C<< (?&PerlControlBlock) >>

Matches an C<if>, C<unless>, C<while>, C<until>, C<for>, or C<foreach>
statement, including its block.


=head3 C<< (?&PerlDoBlock) >>

Matches a C<do>-block expression.


=head3 C<< (?&PerlEvalBlock) >>

Matches a C<eval>-block expression.


=head3 C<< (?&PerlTryCatchFinallyBlock) >>

Matches an C<try> block, followed by an option C<catch> block,
followed by an optional C<finally> block, using the built-in
syntax introduced in Perl v5.34 and v5.36.

Note that if your code uses one of the many CPAN modules
(such as C<Try::Tiny> or C<TryCatch>) that provided try/catch behaviours
prior to Perl v5.34, then you will most likely need to override
this subrule to match the alternate C<try>/C<catch> syntax
provided by your preferred module.

For example, if your code uses the C<TryCatch> module, you would
need to alter the PPR parser by explicitly redefining the subrule
for C<try> blocks, with something like:

    my $MATCH_A_PERL_DOCUMENT = qr{

        \A (?&PerlEntireDocument) \Z

        (?(DEFINE)
            # Redefine this subrule to match TryCatch syntax...
            (?<PerlTryCatchFinallyBlock>
                    try                                  (?>(?&PerlOWS))
                    (?>(?&PerlBlock))
                (?:                                      (?>(?&PerlOWS))
                    catch                                (?>(?&PerlOWS))
                (?: \( (?>(?&PPR_balanced_parens)) \)    (?>(?&PerlOWS))  )?+
                    (?>(?&PerlBlock))
                )*+
            )
        )

        $PPR::GRAMMAR
    }xms;

Note that the popular C<Try::Tiny> module actually implements C<try>/C<catch>
as a normally parsed Perl subroutine call expression, rather than a statement.
This means that the unmodified PPR grammar can successfully parse all the
module's constructs.

However, the unmodified PPR grammar may misclassify some C<Try::Tiny> usages
as being built-in Perl v5.36 C<try> blocks followed by an unrelated call to
the C<catch> subroutine, rather than identifying the C<try> and C<catch> as
a single expression containing two subroutine calls.

If that difference in interpretation matters to you, you can deactivate
the built-in Perl v5.36 C<try>/C<catch> syntax entirely, like so:

    my $MATCH_A_PERL_DOCUMENT = qr{
        \A (?&PerlEntireDocument) \Z

        (?(DEFINE)
            # Turn off built-in try/catch syntax...
            (?<PerlTryCatchFinallyBlock>   (?!)  )

            # Decanonize 'try' and 'catch' as reserved words ineligible for sub names...
            (?<PPR_X_non_reserved_identifier>
                (?! (?> for(?:each)?+ | while   | if    | unless | until | given | when   | default
                    |   sub | format  | use     | no    | my     | our   | state  | defer | finally
                    # Note: Removed 'try' and 'catch' which appear here in the original subrule
                    |   (?&PPR_X_named_op)
                    |   [msy] | q[wrxq]?+ | tr
                    |   __ (?> END | DATA ) __
                    )
                    \b
                )
                (?>(?&PerlQualifiedIdentifier))
                (?! :: )
            )

        )

        $PPR::GRAMMAR
    }xms;

For more details and options for modifying PPR grammars in this way,
see also the documentation of the C<PPR::X> module.


=head3 C<< (?&PerlStatementModifier) >>

Matches an C<if>, C<unless>, C<while>, C<until>, C<for>, or C<foreach>
modifier that could appear after a statement. Only matches the modifier, not
the preceding statement.



=head3 C<< (?&PerlFormat) >>

Matches a C<format> declaration, including its terminating "dot".



=head3 C<< (?&PerlBlock) >>

Matches a C<{>...C<}>-delimited block containing zero-or-more statements.


=head3 C<< (?&PerlCall) >>

Matches a call to a subroutine or built-in function.
Accepts all valid call syntaxes,
either via a literal names or a reference,
with or without a leading C<&>,
with or without arguments,
with or without parentheses on any argument list.


=head3 C<< (?&PerlAttributes) >>

Matches a list of colon-preceded attributes, such as might be specified
on the declaration of a subroutine or a variable.


=head3 C<< (?&PerlCommaList) >>

Matches a list of zero-or-more comma-separated subexpressions.
That is, a single valid Perl expression that involves operators above the
precedence of C<not>.


=head3 C<< (?&PerlParenthesesList) >>

Matches a list of zero-or-more comma-separated subexpressions inside
a set of parentheses.


=head3 C<< (?&PerlList) >>

Matches either a parenthesized or unparenthesized list of
comma-separated subexpressions. That is, matches anything that either of
the two preceding rules would match.


=head3 C<< (?&PerlAnonymousArray) >>

Matches an anonymous array constructor.
That is: a list of zero-or-more subexpressions inside square brackets.

=head3 C<< (?&PerlAnonymousHash) >>

Matches an anonymous hash constructor.
That is: a list of zero-or-more subexpressions inside curly brackets.


=head3 C<< (?&PerlArrayIndexer) >>

Matches a valid indexer that could be applied to look up elements of a array.
That is: a list of or one-or-more subexpressions inside square brackets.

=head3 C<< (?&PerlHashIndexer) >>

Matches a valid indexer that could be applied to look up entries of a hash.
That is: a list of or one-or-more subexpressions inside curly brackets,
or a simple bareword indentifier inside curley brackets.


=head3 C<< (?&PerlDiamondOperator) >>

Matches anything in angle brackets.
That is: any "diamond" readline (e.g. C<< <$filehandle> >>
or file-grep operation (e.g. C<< <*.pl> >>).


=head3 C<< (?&PerlComma) >>

Matches a short (C<,>) or long (C<< => >>) comma.


=head3 C<< (?&PerlPrefixUnaryOperator) >>

Matches any high-precedence prefix unary operator.


=head3 C<< (?&PerlPostfixUnaryOperator) >>

Matches any high-precedence postfix unary operator.


=head3 C<< (?&PerlInfixBinaryOperator) >>

Matches any infix binary operator
whose precedence is between C<..> and C<**>.


=head3 C<< (?&PerlAssignmentOperator) >>

Matches any assignment operator,
including all I<op>C<=> variants.


=head3 C<< (?&PerlLowPrecedenceInfixOperator) >>

Matches C<and>, <or>, or C<xor>.


=head3 C<< (?&PerlAnonymousSubroutine) >>

Matches an anonymous subroutine.


=head3 C<< (?&PerlVariable) >>

Matches any type of access on any scalar, array, or hash
variable.


=head3 C<< (?&PerlVariableScalar) >>

Matches any scalar variable,
including fully qualified package variables,
punctuation variables, scalar dereferences,
and the C<$#array> syntax.


=head3 C<< (?&PerlVariableArray) >>

Matches any array variable,
including fully qualified package variables,
punctuation variables, and array dereferences.


=head3 C<< (?&PerlVariableHash) >>

Matches any hash variable,
including fully qualified package variables,
punctuation variables, and hash dereferences.


=head3 C<< (?&PerlTypeglob) >>

Matches a typeglob.


=head3 C<< (?&PerlScalarAccess) >>

Matches any kind of variable access
beginning with a C<$>,
including fully qualified package variables,
punctuation variables, scalar dereferences,
the C<$#array> syntax, and single-value
array or hash look-ups.


=head3 C<< (?&PerlScalarAccessNoSpace) >>

Matches any kind of variable access beginning with a C<$>, including
fully qualified package variables, punctuation variables, scalar
dereferences, the C<$#array> syntax, and single-value array or hash
look-ups.
But does not allow spaces between the components of the
variable access (i.e. imposes the same constraint as within an
interpolating quotelike).


=head3 C<< (?&PerlScalarAccessNoSpaceNoArrow) >>

Matches any kind of variable access beginning with a C<$>, including
fully qualified package variables, punctuation variables, scalar
dereferences, the C<$#array> syntax, and single-value array or hash
look-ups.
But does not allow spaces or arrows between the components of the
variable access (i.e. imposes the same constraint as within a
C<< <...> >>-delimited interpolating quotelike).


=head3 C<< (?&PerlArrayAccess) >>

Matches any kind of variable access
beginning with a C<@>,
including arrays, array dereferences,
and list slices of arrays or hashes.


=head3 C<< (?&PerlArrayAccessNoSpace) >>

Matches any kind of variable access
beginning with a C<@>,
including arrays, array dereferences,
and list slices of arrays or hashes.
But does not allow spaces between the components of the
variable access (i.e. imposes the same constraint as within an
interpolating quotelike).


=head3 C<< (?&PerlArrayAccessNoSpaceNoArrow) >>

Matches any kind of variable access
beginning with a C<@>,
including arrays, array dereferences,
and list slices of arrays or hashes.
But does not allow spaces or arrows between the components of the
variable access (i.e. imposes the same constraint as within a
C<< <...> >>-delimited interpolating quotelike).


=head3 C<< (?&PerlHashAccess) >>

Matches any kind of variable access
beginning with a C<%>,
including hashes, hash dereferences,
and kv-slices of hashes or arrays.


=head3 C<< (?&PerlLabel) >>

Matches a colon-terminated label.


=head3 C<< (?&PerlLiteral) >>

Matches a literal value.
That is: a number, a C<qr> or C<qw>
quotelike, a string, or a bareword.


=head3 C<< (?&PerlString) >>

Matches a string literal.
That is: a single- or double-quoted string,
a C<q> or C<qq> string, a heredoc, or a
version string.


=head3 C<< (?&PerlQuotelike) >>

Matches any form of quotelike operator.
That is: a single- or double-quoted string,
a C<q> or C<qq> string, a heredoc, a
version string, a C<qr>, a C<qw>, a C<qx>,
a C</.../> or C<m/.../> regex,
a substitution, or a transliteration.


=head3 C<< (?&PerlHeredoc) >>

Matches a heredoc specifier.
That is: just the initial C<< <<TERMINATOR> >> component,
I<not> the actual contents of the heredoc on the
subsequent lines.

This rule only matches a heredoc specifier if that specifier
is correctly followed on the next line by any heredoc contents
and then the correct terminator.

However, if the heredoc specifier I<is> correctly matched, subsequent
calls to either of the whitespace-matching rules (C<(?&PerlOWS)> or
C<(?&PerlNWS)>) will also consume the trailing heredoc contents and
the terminator.

So, for example, to correctly match a heredoc plus its contents
you could use something like:

    m/ (?&PerlHeredoc) (?&PerlOWS)  $PPR::GRAMMAR /x

or, if there may be trailing items on the same line as the heredoc
specifier:

    m/ (?&PerlHeredoc)
       (?<trailing_items> [^\n]* )
       (?&PerlOWS)

       $PPR::GRAMMAR
    /x

Note that the saeme limitations apply to other constructs that
match heredocs, such a C<< (?&PerlQuotelike) >> or C<< (?&PerlString) >>.


=head3 C<< (?&PerlQuotelikeQ) >>

Matches a single-quoted string,
either a C<'...'>
or a C<q/.../> (with any valid delimiters).


=head3 C<< (?&PerlQuotelikeQQ) >>

Matches a double-quoted string,
either a C<"...">
or a C<qq/.../> (with any valid delimiters).


=head3 C<< (?&PerlQuotelikeQW) >>

Matches a "quotewords" list.
That is a C<qw/ list of words />
(with any valid delimiters).


=head3 C<< (?&PerlQuotelikeQX) >>

Matches a C<qx> system call,
either a C<`...`>
or a C<qx/.../> (with any valid delimiters)


=head3 C<< (?&PerlQuotelikeS) >> or C<< (?&PerlSubstitution) >>

Matches a substitution operation.
That is: C<s/.../.../>
(with any valid delimiters and any valid trailing modifiers).


=head3 C<< (?&PerlQuotelikeTR) >> or C<< (?&PerlTransliteration) >>

Matches a transliteration operation.
That is: C<tr/.../.../> or C<y/.../.../>
(with any valid delimiters and any valid trailing modifiers).


=head3 C<< (?&PerlContextualQuotelikeM) >> or C<< (?&PerContextuallMatch) >>

Matches a regex-match operation in any context where it would
be allowed in valid Perl.
That is: C</.../> or C<m/.../>
(with any valid delimiters and any valid trailing modifiers).


=head3 C<< (?&PerlQuotelikeM) >> or C<< (?&PerlMatch) >>

Matches a regex-match operation.
That is: C</.../> or C<m/.../>
(with any valid delimiters and any valid trailing modifiers)
in any context (i.e. even in places where it would not normally
be allowed within a valid piece of Perl code).


=head3 C<< (?&PerlQuotelikeQR) >>

Matches a C<qr> regex constructor
(with any valid delimiters and any valid trailing modifiers).


=head3 C<< (?&PerlContextualRegex) >>

Matches a C<qr> regex constructor or a C</.../> or C<m/.../> regex-match
operation (with any valid delimiters and any valid trailing modifiers)
anywhere where either would be allowed in valid Perl.

In other words: anything capable of matching within valid Perl code.


=head3 C<< (?&PerlRegex) >>

Matches a C<qr> regex constructor or a C</.../> or C<m/.../> regex-match
operation in any context (i.e. even in places where it would not normally
be allowed within a valid piece of Perl code).

In other words: anything capable of matching.


=head3 C<< (?&PerlBuiltinFunction) >>

Matches the I<name> of any builtin function.

To match an actual call to a built-in function, use:

    m/
        (?= (?&PerlBuiltinFunction) )
        (?&PerlCall)
    /x


=head3 C<< (?&PerlNullaryBuiltinFunction) >>

Matches the name of any builtin function that never
takes arguments.

To match an actual call to a built-in function that
never takes arguments, use:

    m/
        (?= (?&PerlNullaryBuiltinFunction) )
        (?&PerlCall)
    /x


=head3 C<< (?&PerlVersionNumber) >>

Matches any number or version-string that can be
used as a version number within a C<use>, C<no>,
or C<package> statement.


=head3 C<< (?&PerlVString) >>

Matches a version-string (a.k.a v-string).


=head3 C<< (?&PerlNumber) >>

Matches a valid number,
including binary, octal, decimal and hexadecimal integers,
and floating-point numbers with or without an exponent.


=head3 C<< (?&PerlIdentifier) >>

Matches a simple, unqualified identifier.


=head3 C<< (?&PerlQualifiedIdentifier) >>

Matches a qualified or unqualified identifier,
which may use either C<::> or C<'> as internal
separators, but only C<::> as initial or terminal
separators.


=head3 C<< (?&PerlOldQualifiedIdentifier) >>

Matches a qualified or unqualified identifier,
which may use either C<::> or C<'> as both
internal and external separators.


=head3 C<< (?&PerlBareword) >>

Matches a valid bareword.

Note that this is not the same as an simple identifier,
nor the same as a qualified identifier.

=head3 C<< (?&PerlPod) >>

Matches a single POD section containing any contiguous set of POD
directives, up to the first C<=cut> or end-of-file.


=head3 C<< (?&PerlPodSequence) >>

Matches any sequence of POD sections,
separated and /or surrounded by optional whitespace.


=head3 C<< (?&PerlNWS) >>

Match one-or-more characters of necessary whitespace,
including spaces, tabs, newlines, comments, and POD.


=head3 C<< (?&PerlOWS) >>

Match zero-or-more characters of optional whitespace,
including spaces, tabs, newlines, comments, and POD.


=head3 C<< (?&PerlOWSOrEND) >>

Match zero-or-more characters of optional whitespace,
including spaces, tabs, newlines, comments, POD,
and any trailing C<__END__> or C<__DATA__> section.


=head3 C<< (?&PerlEndOfLine) >>

Matches a single newline (C<\n>) character.

This is provided mainly to allow newlines to
be "hooked" by redefining C<< (?<PerlEndOfLine>) >>
(for example, to count lines during a parse).


=head3 C<< (?&PerlKeyword) >>

Match a pluggable keyword.

Note that there are no pluggable keywords
in the default PPR regex;
they must be added by the end-user.
See the following section for details.


=head2 Extending the Perl syntax with keywords

In Perl 5.12 and later, it's possible to add new types
of statements to the language using a mechanism called
"pluggable keywords".

This mechanism (best accessed via CPAN modules such as
C<Keyword::Simple> or C<Keyword::Declare>) acts like a limited macro
facility. It detects when a statement begins with a particular,
pre-specified keyword, passes the trailing text to an associated keyword
handler, and replaces the trailing source code with whatever the keyword
handler produces.

For example, the L<Dios> module uses this mechanism to add keywords such
as C<class>, C<method>, and C<has> to Perl 5, providing a declarative
OO syntax. And the L<Object::Result> module uses pluggable keywords to
add a C<result> statement that simplifies returning an ad hoc object from a
subroutine.

Unfortunately, because such modules effectively extend the standard Perl
syntax, by default PPR has no way of successfully parsing them.

However, when setting up a regex using C<$PPR::GRAMMAR> it is possible to
extend that grammar to deal with new keywords...by defining a rule named
C<< (?<PerlKeyword>...) >>.

This rule is always tested as the first option within the standard
C<(?&PerlStatement)> rule, so any syntax declared within effectively
becomes a new kind of statement. Note that each alternative within
the rule must begin with a valid "keyword" (that is: a simple
identifier of some kind).

For example, to support the three keywords from L<Dios>:

    $Dios::GRAMMAR = qr{

        # Add a keyword rule to support Dios...
        (?(DEFINE)
            (?<PerlKeyword>

                    class                              (?&PerlOWS)
                    (?&PerlQualifiedIdentifier)        (?&PerlOWS)
                (?: is (?&PerlNWS) (?&PerlIdentifier)  (?&PerlOWS) )*+
                    (?&PerlBlock)
            |
                    method                             (?&PerlOWS)
                    (?&PerlIdentifier)                 (?&PerlOWS)
                (?: (?&kw_balanced_parens)             (?&PerlOWS) )?+
                (?: (?&PerlAttributes)                 (?&PerlOWS) )?+
                    (?&PerlBlock)
            |
                    has                                (?&PerlOWS)
                (?: (?&PerlQualifiedIdentifier)        (?&PerlOWS) )?+
                    [\@\$%][.!]?(?&PerlIdentifier)     (?&PerlOWS)
                (?: (?&PerlAttributes)                 (?&PerlOWS) )?+
                (?: (?: // )?+ =                       (?&PerlOWS)
                    (?&PerlExpression)                 (?&PerlOWS) )?+
                (?> ; | (?= \} ) | \z )
            )

            (?<kw_balanced_parens>
                \( (?: [^()]++ | (?&kw_balanced_parens) )*+ \)
            )
        )

        # Add all the standard PPR rules...
        $PPR::GRAMMAR
    }x;

    # Then parse with it...

    $source_code =~ m{ \A (?&PerlDocument) \Z  $Dios::GRAMMAR }x;


Or, to support the C<result> statement from C<Object::Result>:

    my $ORK_GRAMMAR = qr{

        # Add a keyword rule to support Object::Result...
        (?(DEFINE)
            (?<PerlKeyword>
                result                        (?&PerlOWS)
                \{                            (?&PerlOWS)
                (?: (?> (?&PerlIdentifier)
                    |   < [[:upper:]]++ >
                    )                         (?&PerlOWS)
                    (?&PerlParenthesesList)?+      (?&PerlOWS)
                    (?&PerlBlock)             (?&PerlOWS)
                )*+
                \}
            )
        )

        # Add all the standard PPR rules...
        $PPR::GRAMMAR
    }x;

    # Then parse with it...

    $source_code =~ m{ \A (?&PerlDocument) \Z  $ORK_GRAMMAR }x;

Note that, although pluggable keywords are only available from Perl
5.12 onwards, PPR will still accept C<(&?PerlKeyword)> extensions under
Perl 5.10.


=head2 Extending the Perl syntax in other ways

Other modules (such as C<Devel::Declare> and C<Filter::Simple>)
make it possible to extend Perl syntax in even more flexible ways.
The L<< PPR::X >> module provides support for syntactic extensions more
general than pluggable keywords.

=begin PPR::X

PPR::X allows I<any> of its public rules to be redefined in a
particular regex. For example, to create a regex that matches
standard Perl syntax, but which allows the keyword C<fun> as
a synonym for C<sub>:

    my $FUN_GRAMMAR = qr{

        # Extend the subroutine-matching rules...
        (?(DEFINE)
            (?<PerlStatement>
                # Try the standard syntax...
                (?&PerlStdStatement)
            |
                # Try the new syntax...
                fun                               (?&PerlOWS)
                (?&PerlOldQualifiedIdentifier)    (?&PerlOWS)
                (?: \( [^)]*+ \) )?+              (?&PerlOWS)
                (?: (?&PerlAttributes)            (?&PerlOWS) )?+
                (?> ; | (?&PerlBlock) )
            )

            (?<PerlAnonymousSubroutine>
                # Try the standard syntax
                (?&PerlStdAnonymousSubroutine)
            |
                # Try the new syntax
                fun                               (?&PerlOWS)
                (?: \( [^)]*+ \) )?+              (?&PerlOWS)
                (?: (?&PerlAttributes)            (?&PerlOWS) )?+
                (?> ; | (?&PerlBlock) )
            )
        )

        $PPR::X::GRAMMAR
    }x;

Note first that any redefinitions of the various rules have to be
specified before the interpolation of the standard rules (so that the
new rules take syntactic precedence over the originals).

The structure of each redefinition is essentially identical.
First try the original rule, which is still accessible as C<(?&PerlStd...)>
(instead of C<(?&Perl...)>). Otherwise, try the new alternative, which
may be constructed out of other rules.
    original rule.

There is no absolute requirement to try the original rule as part of the
new rule, but if you don't then you are I<replacing> the rule, rather
than extending it. For example, to replace the low-precedence boolean
operators (C<and>, C<or>, C<xor>, and C<not>) with their Latin equivalents:

    my $GRAMMATICA = qr{

        # Verbum sapienti satis est...
        (?(DEFINE)

            # Iunctiones...
            (?<PerlLowPrecedenceInfixOperator>
                atque | vel | aut
            )

            # Contradicetur...
            (?<PerlLowPrecedenceNotExpression>
                (?: non  (?&PerlOWS) )*+  (?&PerlCommaList)
            )
        )

        $PPR::X::GRAMMAR
    }x;

Or to maintain a line count within the parse:

    my $COUNTED_GRAMMAR = qr{

        (?(DEFINE)

            (?<PerlEndOfLine>
                # Try the standard syntax
                (?&PerlStdEndOfLine)

                # Then count the line (must localize, to handle backtracking)...
                (?{ local $linenum = $linenum + 1; })
            )
        )

        $PPR::X::GRAMMAR
    }x;


=end PPR::X

=head2 Comparison with PPI

The PPI and PPR modules can both identify valid Perl code,
but they do so in very different ways, and are optimal for
different purposes.

PPI scans an entire Perl document and builds a hierarchical
representation of the various components. It is therefore suitable for
recognition, validation, partial extraction, and in-place transformation
of Perl code.

PPR matches only as much of a Perl document as specified by the regex
you create, and does not build any hierarchical representation of the
various components it matches. It is therefore suitable for recognition
and validation of Perl code. However, unless great care is taken, PPR is
not as reliable as PPI for extractions or transformations of components
smaller than a single statement.

On the other hand, PPI always has to parse its entire input, and
build a complete non-trivial nested data structure for it, before it
can be used to recognize or validate any component. So it is almost
always significantly slower and more complicated than PPR for those
kinds of tasks.

For example, to determine whether an input string begins with a valid
Perl block, PPI requires something like:

    if (my $document = PPI::Document->new(\$input_string) ) {
        my $block = $document->schild(0)->schild(0);
        if ($block->isa('PPI::Structure::Block')) {
            $block->remove;
            process_block($block);
            process_extra($document);
        }
    }

whereas PPR needs just:

    if ($input_string =~ m{ \A (?&PerlOWS) ((?&PerlBlock)) (.*) }xs) {
        process_block($1);
        process_extra($2);
    }

Moreover, the PPR version will be at least twice as fast at recognizing that
leading block (and usually four to seven times faster)...mainly because it
doesn't have to parse the trailing code at all, nor build any representation
of its hierarchical structure.

As a simple rule of thumb, when you only need to quickly detect, identify,
or confirm valid Perl (or just a single valid Perl component), use PPR.
When you need to examine, traverse, or manipulate the internal structure
or component relationships within an entire Perl document, use PPI.


=head1 DIAGNOSTICS

=over

=item C<Warning: This program is running under Perl 5.20...>

Due to an unsolved issue with that particular release of Perl, the
single regex in the PPR module takes a ridiculously long time
to compile under Perl 5.20 (i.e. minutes, not milliseconds).

The code will work correctly when it eventually does compile,
but the start-up delay is so extreme that the module issues
this warning, to reassure users the something is actually
happening, and explain why it's happening so slowly.

The only remedy at present is to use an older or newer version
of Perl.

For all the gory details, see:
L<https://rt.perl.org/Public/Bug/Display.html?id=122283>
L<https://rt.perl.org/Public/Bug/Display.html?id=122890>


=item C<< PPR::decomment() does not work under Perl 5.14 >>

There is a separate bug in the Perl 5.14 regex engine that prevents
the C<decomment()> subroutine from correctly detecting the location
of comments.

The subroutine throws an exception if you attempt to call it
when running under Perl 5.14 specifically.

=back

The module has no other diagnostics, apart from those Perl
provides for all regular expressions.

The commonest error is to forget to add C<$PPR::GRAMMAR>
to a regex, in which case you will get a standard Perl
error message such as:

    Reference to nonexistent named group in regex;
    marked by <-- HERE in m/

        (?&PerlDocument <-- HERE )

    / at example.pl line 42.

Adding C<$PPR::GRAMMAR> at the end of the regex solves the problem.



=head1 CONFIGURATION AND ENVIRONMENT

PPR requires no configuration files or environment variables.


=head1 DEPENDENCIES

Requires Perl 5.10 or later.


=head1 INCOMPATIBILITIES

None reported.


=head1 LIMITATIONS

This module works under all versions of Perl from 5.10 onwards.

However, the lastest release of Perl 5.20 seems to have significant
difficulties compiling large regular expressions, and typically requires
over a minute to build any regex that incorporates the C<$PPR::GRAMMAR> rule
definitions.

The problem does not occur in Perl 5.10 to 5.18, nor in Perl 5.22 or later,
though the parser is still measurably slower in all Perl versions
greater than 5.20 (presumably because I<most> regexes are measurably
slower in more modern versions of Perl; such is the price of full
re-entrancy and safe lexical scoping).

The C<decomment()> subroutine trips a separate regex engine bug in Perl
5.14 only and will not run under that version.

There was a lingering bug in regex re-interpolation between Perl 5.18 and 5.28,
which means that interpolating a PPR grammar (or any other precompiled regex
that uses the C<(??{...})> construct) into another regex sometimes does not work.
In these cases, the spurious error message generated is usually:
S<I<Sequence (?_...) not recognized>>. This problem is unlikely ever to be
resolved, as those versions of Perl are no longer being maintained. The
only known workaround is to upgrade to Perl 5.30 or later.

There are also constructs in Perl 5 which cannot be parsed without
actually executing some code...which the regex does not attempt to
do, for obvious reasons.


=head1 BUGS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-ppr@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@CPAN.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2017, Damian Conway C<< <DCONWAY@CPAN.org> >>. All rights reserved.

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
