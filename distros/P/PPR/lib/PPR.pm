package PPR;

use 5.010;
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
our $VERSION = '0.000011';
use utf8;

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
    (?<PerlDocument>
            (?>(?&PerlOWS))
        (?: (?>(?&PerlStatement)) (?&PerlOWS) )*+
    ) # End of rule

    (?<PerlStatement>
            (?: (?>(?&PerlPod))   (?&PerlOWS) )?+
        (?>
            (?: (?>(?&PerlLabel)) (?&PerlOWS) )?+
            (?: (?>(?&PerlPod))   (?&PerlOWS) )?+
            (?>
                (?&PerlKeyword)
            |
                # Inlined (?&PerlSubroutineDeclaration)...
                (?>
                    sub \b                             (?>(?&PerlOWS))
                    (?>(?&PerlOldQualifiedIdentifier))    (?&PerlOWS)
                |
                    AUTOLOAD                              (?&PerlOWS)
                |
                    DESTROY                               (?&PerlOWS)
                )
                (?:
                    (?>
                        (?&PerlParenthesesList)              # Parameter list
                    |
                        \( [^)]*+ \)                         # Prototype (
                    )                          (?&PerlOWS)
                )?+
                (?: (?>(?&PerlAttributes))     (?&PerlOWS)  )?+
                (?> ; | (?&PerlBlock) )
            |
                # Inlined (?&PerlUseStatement)...
                (?: use | no ) (?>(?&PerlNWS))
                (?>
                    (?&PerlVersionNumber)
                |
                    (?>(?&PerlQualifiedIdentifier))
                    (?: (?>(?&PerlNWS)) (?&PerlVersionNumber)
                        (?! (?>(?&PerlOWS)) (?> (?&PerlInfixBinaryOperator) | (?&PerlComma) | \? ) )
                    )?+
                    (?: (?>(?&PerlNWS)) (?&PerlPod) )?+
                    (?: (?>(?&PerlOWS)) (?&PerlExpression) )?+
                )
                (?>(?&PerlOWS)) (?> ; | (?= \} | \s*+ \z ))
            |
                # Inlined (?&PerlPackageDeclaration)...
                package
                    (?>(?&PerlNWS)) (?>(?&PerlQualifiedIdentifier))
                (?: (?>(?&PerlNWS)) (?&PerlVersionNumber) )?+
                    (?>(?&PerlOWS)) (?> ; | (?&PerlBlock) | (?= \} | \s*+ \z ))
            |
                (?&PerlControlBlock)
            |
                (?&PerlFormat)
            |
                (?>(?&PerlExpression))          (?>(?&PerlOWS))
                (?&PerlStatementModifier)?+     (?>(?&PerlOWS))
                (?> ; | (?= \} | \z ))
            |
                (?&PerlBlock)
            |
                ;
            )

        | # A yada-yada...
            \.\.\. (?>(?&PerlOWS))
            (?> ; | (?= \} | \z ))

        | # Just a Label...
            (?>(?&PerlLabel)) (?>(?&PerlOWS))
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
    ) # End of rule

    (?<PerlSubroutineDeclaration>
       (?>
           sub \b                             (?>(?&PerlOWS))
           (?>(?&PerlOldQualifiedIdentifier))    (?&PerlOWS)
       |
           AUTOLOAD
       |
           DESTROY
       )
       (?:
           (?>
               (?&PerlParenthesesList)                   # Parameter list
           |
               \( [^)]*+ \)                         # Prototype (
           )                          (?&PerlOWS)
       )?+
       (?: (?>(?&PerlAttributes))     (?&PerlOWS)  )?+
       (?> ; | (?&PerlBlock) )
    ) # End of rule

    (?<PerlUseStatement>
       (?: use | no ) (?>(?&PerlNWS))
       (?>
           (?&PerlVersionNumber)
       |
           (?>(?&PerlQualifiedIdentifier))
           (?: (?>(?&PerlNWS)) (?&PerlVersionNumber)
               (?! (?>(?&PerlOWS)) (?> (?&PerlInfixBinaryOperator) | (?&PerlComma) | \? ) )
           )?+
           (?: (?>(?&PerlNWS)) (?&PerlPod) )?+
           (?: (?>(?&PerlOWS)) (?&PerlExpression) )?+
       )
       (?>(?&PerlOWS)) (?> ; | (?= \} | \s*+ \z ))
    ) # End of rule

    (?<PerlReturnStatement>
       return \b (?: (?>(?&PerlOWS)) (?&PerlExpression) )?+
       (?>(?&PerlOWS)) (?> ; | (?= \} | \s*+ \z ))
    ) # End of rule

    (?<PerlPackageDeclaration>
       package
           (?>(?&PerlNWS)) (?>(?&PerlQualifiedIdentifier))
       (?: (?>(?&PerlNWS)) (?&PerlVersionNumber) )?+
           (?>(?&PerlOWS)) (?> ; | (?&PerlBlock) | (?= \} | \s*+ \z ))
    ) # End of rule

    (?<PerlExpression>
                            (?>(?&PerlLowPrecedenceNotExpression))
        (?: (?>(?&PerlOWS)) (?>(?&PerlLowPrecedenceInfixOperator))
            (?>(?&PerlOWS))    (?&PerlLowPrecedenceNotExpression)  )*+
    ) # End of rule


    (?<PerlLowPrecedenceNotExpression>
        (?: not \b (?&PerlOWS) )*+  (?&PerlCommaList)
    ) # End of rule

    (?<PerlCommaList>
                (?>(?&PerlAssignment))  (?>(?&PerlOWS))
        (?:
            (?: (?>(?&PerlComma))          (?&PerlOWS)   )++
                (?>(?&PerlAssignment))  (?>(?&PerlOWS))
        )*+
            (?: (?>(?&PerlComma))          (?&PerlOWS)   )*+
    ) # End of rule

    (?<PerlAssignment>
                            (?>(?&PerlConditionalExpression))
        (?:
            (?>(?&PerlOWS)) (?>(?&PerlAssignmentOperator))
            (?>(?&PerlOWS))    (?&PerlConditionalExpression)
        )*+
    ) # End of rule

    (?<PerlScalarExpr>
    (?<PerlConditionalExpression>
        (?>(?&PerlBinaryExpression))
        (?:
            (?>(?&PerlOWS)) \? (?>(?&PerlOWS)) (?>(?&PerlAssignment))
            (?>(?&PerlOWS))  : (?>(?&PerlOWS))    (?&PerlConditionalExpression)
        )?+
    ) # End of rule
    ) # End of rule

    (?<PerlBinaryExpression>
                            (?>(?&PerlPrefixPostfixTerm))
        (?: (?>(?&PerlOWS)) (?>(?&PerlInfixBinaryOperator))
            (?>(?&PerlOWS))    (?&PerlPrefixPostfixTerm) )*+
    ) # End of rule

    (?<PerlPrefixPostfixTerm>
        (?: (?>(?&PerlPrefixUnaryOperator))  (?&PerlOWS) )*+
        (?>(?&PerlTerm))
        (?:
            (?>(?&PerlOWS)) -> (?>(?&PerlOWS))
            (?>
                (?> (?&PerlQualifiedIdentifier) | (?&PerlVariableScalar) )
                (?: (?>(?&PerlOWS)) (?&PerlParenthesesList) )?+

            |   (?&PerlParenthesesList)
            |   (?&PerlArrayIndexer)
            |   (?&PerlHashIndexer)
            )

            (?:
                (?>(?&PerlOWS))
                (?>
                    ->  (?>(?&PerlOWS))
                    (?> (?&PerlQualifiedIdentifier) | (?&PerlVariableScalar) )
                    (?: (?>(?&PerlOWS)) (?&PerlParenthesesList) )?+
                |
                    (?: -> (?&PerlOWS) )?+
                    (?> (?&PerlParenthesesList)
                    |   (?&PerlArrayIndexer)
                    |   (?&PerlHashIndexer)
                    )
                )
            )*+
            (?:
                (?>(?&PerlOWS)) -> (?>(?&PerlOWS)) [\@%]
                (?> (?&PerlArrayIndexer) | (?&PerlHashIndexer) )
            )?+
        )?+
        (?: (?>(?&PerlOWS)) (?&PerlPostfixUnaryOperator) )?+
    ) # End of rule

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
    ) # End of rule

    (?<PerlTerm>
        (?>
            # Inlined (?&PerlReturnStatement)...
            return \b (?>(?&PerlOWS)) (?&PerlExpression)
        |
            # Inlined (?&PerlVariableDeclaration)...
            (?> my | state | our ) \b           (?>(?&PerlOWS))
            (?: (?&PerlQualifiedIdentifier)        (?&PerlOWS)  )?+
            (?>(?&PerlLvalue))                  (?>(?&PerlOWS))
            (?&PerlAttributes)?+
        |
            (?&PerlAnonymousSubroutine)
        |
            (?&PerlVariable)
        |
            (?>(?&PerlNullaryBuiltinFunction))  (?! (?>(?&PerlOWS)) \( )
        |
            # Inlined (?&PerlDoBlock) and (?&PerlEvalBlock)...
            (?> do | eval ) (?>(?&PerlOWS)) (?&PerlBlock)
        |
            (?&PerlCall)
        |
            (?&PerlTypeglob)
        |
            (?>(?&PerlParenthesesList))
            (?: (?>(?&PerlOWS)) (?&PerlArrayIndexer) )?+
            (?:
                (?>(?&PerlOWS))
                (?>
                    (?&PerlArrayIndexer)
                |   (?&PerlHashIndexer)
                )
            )*+
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
    ) # End of rule

    (?<PerlControlBlock>
        (?> # Conditionals...
            (?> if | unless ) \b            (?>(?&PerlOWS))
            (?>(?&PerlParenthesesList))          (?>(?&PerlOWS))
            (?>(?&PerlBlock))

            (?:
                                            (?>(?&PerlOWS))
                (?: (?>(?&PerlPod))            (?&PerlOWS)   )*+
                    elsif \b                (?>(?&PerlOWS))
                    (?>(?&PerlParenthesesList))  (?>(?&PerlOWS))
                    (?&PerlBlock)
            )*+

            (?:
                                            (?>(?&PerlOWS))
                (?: (?>(?&PerlPod))            (?&PerlOWS)  )*+
                    else \b                 (?>(?&PerlOWS))
                    (?&PerlBlock)
            )?+

        |   # Loops...
            (?>
                for(?:each)?+ \b
                (?>(?&PerlOWS))
                (?:
                    (?:
                        (?: \\ (?>(?&PerlOWS))      (?> my | our | state )?+
                        |   (?> my | our | state )  (?: (?>(?&PerlOWS)) \\ )?+
                        )?+
                        (?>(?&PerlOWS)) (?&PerlVariableScalar)
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

        | # Switches...
            (?> given | when ) \b                             (?>(?&PerlOWS))
            (?>(?&PerlParenthesesList))                            (?>(?&PerlOWS))
            (?&PerlBlock)
        |
            default                                           (?>(?&PerlOWS))
            (?&PerlBlock)
        )
    ) # End of rule

    (?<PerlFormat>
        format
        (?: (?>(?&PerlNWS))  (?&PerlQualifiedIdentifier)  )?+
            (?>(?&PerlOWS))  = [^\n]*+  \n  (??{ $PPR::_heredoc_skip{+pos()} // q{} })
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
            \n (??{ $PPR::_heredoc_skip{+pos()} // q{} })
        )*+
        \. \n
    ) # End of rule

    (?<PerlStatementModifier>
        (?> if | for(?:each)?+ | while | unless | until | when )
        \b
        (?>(?&PerlOWS))
        (?&PerlExpression)
    ) # End of rule

    (?<PerlBlock>
        \{                             (?>(?&PerlOWS))
            (?: (?>(?&PerlStatement))     (?&PerlOWS)   )*+
            (?: (?>(?&PerlPod))           (?&PerlOWS)   )?+
        \}
    ) # End of rule

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
    ) # End of rule

    (?<PerlVariableDeclaration>
        (?> my | state | our ) \b           (?>(?&PerlOWS))
        (?: (?&PerlQualifiedIdentifier)        (?&PerlOWS)  )?+
        (?>(?&PerlLvalue))                  (?>(?&PerlOWS))
        (?&PerlAttributes)?+
    ) # End of rule

    (?<PerlDoBlock>
        do (?>(?&PerlOWS)) (?&PerlBlock)
    ) # End of rule

    (?<PerlEvalBlock>
        eval (?>(?&PerlOWS)) (?&PerlBlock)
    ) # End of rule

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
    ) # End of rule

    (?<PerlList>
        (?> (?&PerlParenthesesList) | (?&PerlCommaList) )
    ) # End of rule

    (?<PerlParenthesesList>
        \(  (?>(?&PerlOWS))  (?: (?>(?&PerlExpression)) (?&PerlOWS) )?+  \)
    ) # End of rule

    (?<PerlAnonymousArray>
        \[  (?>(?&PerlOWS))  (?: (?>(?&PerlExpression)) (?&PerlOWS) )?+  \]
    ) # End of rule

    (?<PerlAnonymousHash>
        \{  (?>(?&PerlOWS))  (?: (?>(?&PerlExpression)) (?&PerlOWS) )?+ \}
    ) # End of rule

    (?<PerlArrayIndexer>
        \[                          (?>(?&PerlOWS))
            (?>(?&PerlExpression))  (?>(?&PerlOWS))
        \]
    ) # End of rule

    (?<PerlHashIndexer>
        \{  (?>(?&PerlOWS))
            (?: -?+ (?&PerlIdentifier) | (?&PerlExpression) )  # (Note: MUST allow backtracking here)
            (?>(?&PerlOWS))
        \}
    ) # End of rule

    (?<PerlDiamondOperator>
        <<>>    # Perl 5.22 "double diamond"
      |
        < (?! < )
            (?>(?&PPR_balanced_angles))
        >
        (?=
            (?>(?&PerlOWS))
            (?> \z | [,;\}\])?] | => | : (?! :)        # (
            |   (?&PerlInfixBinaryOperator) | (?&PerlLowPrecedenceInfixOperator)
            |   (?= \w) (?> for(?:each)?+ | while | if | unless | until | when )
            )
        )
    ) # End of rule

    (?<PerlComma>
        (?> , | => )
    ) # End of rule

    (?<PerlPrefixUnaryOperator>
        (?> [!\\+~] | \+\+  |  --  | - (?! (?&PPR_filetest_name) \b ) )
    ) # End of rule

    (?<PerlPostfixUnaryOperator>
        (?> \+\+  |  -- )
    ) # End of rule

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
        )
    ) # End of rule

    (?<PerlAssignmentOperator>
        (?:  [<>*&|/]{2}
          |  [-+.*/%x]
          |  [&|^][.]?+
        )?+
        =
        (?! > )
    ) # End of rule

    (?<PerlLowPrecedenceInfixOperator>
        (?> or | and | xor )
    ) # End of rule

    (?<PerlAnonymousSubroutine>
        sub \b
        (?>(?&PerlOWS))
        (?:
            (?>
                (?&PerlParenthesesList)    # Parameter list
            |
                \( [^)]*+ \)          # Prototype (
            )
            (?&PerlOWS)
        )?+
        (?: (?>(?&PerlAttributes))  (?&PerlOWS) )?+
        (?&PerlBlock)
    ) # End of rule

    (?<PerlVariable>
        (?= [\$\@%] )
        (?>
            (?&PerlScalarAccess)
        |   (?&PerlHashAccess)
        |   (?&PerlArrayAccess)
        )
    ) # End of rule

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
        (?:
            (?>(?&PerlOWS)) (?: -> (?&PerlOWS) )?+
            (?> (?&PerlArrayIndexer) | (?&PerlHashIndexer) | (?&PerlParenthesesList) )
        )*+
        (?:
            (?>(?&PerlOWS)) -> (?>(?&PerlOWS))
            [\@%]
            (?> (?&PerlArrayIndexer) | (?&PerlHashIndexer) )
        )?+
    ) # End of rule

    (?<PerlArrayAccess>
        (?>(?&PerlVariableArray))
        (?:
            (?>(?&PerlOWS)) (?: -> (?&PerlOWS) )?+
            (?> (?&PerlArrayIndexer) | (?&PerlHashIndexer) | (?&PerlParenthesesList)  )
        )*+
        (?:
            (?>(?&PerlOWS)) -> (?>(?&PerlOWS))
            [\@%]
            (?> (?&PerlArrayIndexer) | (?&PerlHashIndexer) )
        )?+
    ) # End of rule

    (?<PerlArrayAccessNoSpace>
        (?>(?&PerlVariableArrayNoSpace))
        (?:
            (?: -> )?+
            (?> (?&PerlArrayIndexer) | (?&PerlHashIndexer) | (?&PerlParenthesesList)  )
        )*+
        (?:
            ->
            [\@%]
            (?> (?&PerlArrayIndexer) | (?&PerlHashIndexer) )
        )?+
    ) # End of rule

    (?<PerlArrayAccessNoSpaceNoArrow>
        (?>(?&PerlVariableArray))
        (?:
            (?> (?&PerlArrayIndexer) | (?&PerlHashIndexer) | (?&PerlParenthesesList)  )
        )*+
    ) # End of rule

    (?<PerlHashAccess>
        (?>(?&PerlVariableHash))
        (?:
            (?>(?&PerlOWS)) (?: -> (?&PerlOWS) )?+
            (?> (?&PerlArrayIndexer) | (?&PerlHashIndexer) | (?&PerlParenthesesList) )
        )*+
        (?:
            (?>(?&PerlOWS)) -> (?>(?&PerlOWS))
            [\@%]
            (?> (?&PerlArrayIndexer) | (?&PerlHashIndexer) )
        )?+
    ) # End of rule

    (?<PerlScalarAccess>
        (?>(?&PerlVariableScalar))
        (?:
            (?>(?&PerlOWS))
            (?:
                (?:
                    (?>(?&PerlOWS))      -> (?>(?&PerlOWS))
                    (?&PerlParenthesesList)
                |
                    (?>(?&PerlOWS))  (?: ->    (?&PerlOWS)  )?+
                    (?> (?&PerlArrayIndexer) | (?&PerlHashIndexer) )
                )
                (?:
                    (?>(?&PerlOWS))  (?: ->    (?&PerlOWS)  )?+
                    (?> (?&PerlArrayIndexer) | (?&PerlHashIndexer) | (?&PerlParenthesesList) )
                )*+
            )?+
            (?:
                (?>(?&PerlOWS)) -> (?>(?&PerlOWS))
                [\@%]
                (?> (?&PerlArrayIndexer) | (?&PerlHashIndexer) )
            )?+
        )?+
    ) # End of rule

    (?<PerlScalarAccessNoSpace>
        (?>(?&PerlVariableScalarNoSpace))
        (?:
            (?:
                (?:
                    ->
                    (?&PerlParenthesesList)
                |
                    (?: -> )?+
                    (?> (?&PerlArrayIndexer) | (?&PerlHashIndexer) )
                )
                (?:
                    (?: -> )?+
                    (?> (?&PerlArrayIndexer) | (?&PerlHashIndexer) | (?&PerlParenthesesList) )
                )*+
            )?+
            (?:
                ->
                [\@%]
                (?> (?&PerlArrayIndexer) | (?&PerlHashIndexer) )
            )?+
        )?+
    ) # End of rule

    (?<PerlScalarAccessNoSpaceNoArrow>
        (?>(?&PerlVariableScalarNoSpace))
        (?:
            (?> (?&PerlArrayIndexer) | (?&PerlHashIndexer) | (?&PerlParenthesesList) )
        )*+
    ) # End of rule

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
            \{ \w++ \}
        |
            (?&PerlBlock)
        )
    |
        \$\#
    ) # End of rule

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
    ) # End of rule

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
    ) # End of rule

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
    ) # End of rule

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
    ) # End of rule

    (?<PerlLabel>
        (?! (?> [msy] | q[wrxq]?+ | tr ) \b )
        (?>(?&PerlIdentifier))
        : (?! : )
    ) # End of rule

    (?<PerlLiteral>
        (?> (?&PerlString)
        |   (?&PerlQuotelikeQR)
        |   (?&PerlQuotelikeQW)
        |   (?&PerlNumber)
        |   (?&PerlBareword)
        )
    ) # End of rule

    (?<PerlString>
        (?>
            "  [^"\\]*+  (?: \\. [^"\\]*+ )*+ "
        |
            '  [^'\\]*+  (?: \\. [^'\\]*+ )*+ '
        |
            qq \b
            (?> (?= [#] ) | (?! (?>(?&PerlOWS)) => ) )
            (?&PPR_quotelike_body_interpolated)
        |
            q \b
            (?> (?= [#] ) | (?! (?>(?&PerlOWS)) => ) )
            (?&PPR_quotelike_body)
        |
            (?&PerlHeredoc)
        |
            (?&PerlVString)
        )
    ) # End of rule

    (?<PerlQuotelike>
        (?> (?&PerlString)
        |   (?&PerlQuotelikeQR)
        |   (?&PerlQuotelikeQW)
        |   (?&PerlQuotelikeQX)
        |   (?&PerlContextualMatch)
        |   (?&PerlQuotelikeS)
        |   (?&PerlQuotelikeTR)
    )
    ) # End of rule

    (?<PerlHeredoc>
        <<
        (?<_heredoc_indented> [~]?+ )
        (?>
            \\?+   (?<_heredoc_terminator>  (?&PerlIdentifier)              )
        |
            (?>(?&PerlOWS))
            (?>
                "  (?<_heredoc_terminator>  [^"\\]*+  (?: \\. [^"\\]*+ )*+  )  "
            |
                (?<PPR_HD_nointerp> ' )
                   (?<_heredoc_terminator>  [^'\\]*+  (?: \\. [^'\\]*+ )*+  )  '
            |
                `  (?<_heredoc_terminator>  [^`\\]*+  (?: \\. [^`\\]*+ )*+  )  `
            )
        |
                   (?<_heredoc_terminator>                                  )
        )

        # Do we need to reset heredoc cache???
        (?{
            if ( ($PPR::_heredoc_origin//q{}) ne $_ ) {
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
                (?:                                          # The heredoc contents consist of...

                    (?(<PPR_HD_nointerp>)
                        [^\n]*+ \n
                    |
                        [^\n\$\@]*+
                        (?:
                            (?>
                                (?= \$ (?! \s ) )  (?&PerlScalarAccessNoSpace)
                            |
                                (?= \@ (?! \s ) )  (?&PerlArrayAccessNoSpace)
                            )
                            [^\n\$\@]*+
                        )*?
                        \n (??{ $PPR::_heredoc_skip{+pos()} // q{} })
                    )*?                                              #     A minimal number of lines

                    (?(?{ $+{_heredoc_indented} }) \h*+ )            #     An indent (if it was a <<~)
                    \g{_heredoc_terminator}                          #     The specified terminator
                    (?: \n | \z )                                    #     Followed by EOL
                )

                # Then memoize the skip for when it's subsequently needed by PerlOWS or PerlNWS...
                (?{
                    $PPR::_heredoc_skip{$^R} = "(?s:.\{" . (pos() - $^R) . "\})";
                })
            )
        )

    ) # End of rule

    (?<PerlQuotelikeQ>
        (?>
            '  [^'\\]*+  (?: \\. [^'\\]*+ )*+ '
        |
            q \b
            (?> (?= [#] ) | (?! (?>(?&PerlOWS)) => ) )
            (?&PPR_quotelike_body)
        )
    ) # End of rule

    (?<PerlQuotelikeQQ>
        (?>
            "  [^"\\]*+  (?: \\. [^"\\]*+ )*+ "
        |
            qq \b
            (?> (?= [#] ) | (?! (?>(?&PerlOWS)) => ) )
            (?&PPR_quotelike_body_interpolated)
        )
    ) # End of rule

    (?<PerlQuotelikeQW>
        (?>
            qw \b
            (?> (?= [#] ) | (?! (?>(?&PerlOWS)) => ) )
            (?&PPR_quotelike_body)
        )
    ) # End of rule

    (?<PerlQuotelikeQX>
        (?>
            `  [^`]*+  (?: \\. [^`]*+ )*+  `
        |
            qx 
                (?:
                    (?&PerlOWS) ' (?&PPR_quotelike_body) 
                |
                    \b (?> (?= [#] ) | (?! (?>(?&PerlOWS)) => ) )
                    (?&PPR_quotelike_body_interpolated)
                )
        )
    ) # End of rule

    (?<PerlQuotelikeS>
    (?<PerlSubstitution>
        s \b
        (?> (?= [#] ) | (?! (?>(?&PerlOWS)) => ) )
        (?>
            # Hashed syntax...
            (?= [#] )
            (?>(?&PPR_quotelike_body_interpolated_unclosed))
               (?&PPR_quotelike_body_interpolated)
        |
            # Bracketed syntax...
            (?= (?>(?&PerlOWS)) [\[(<\{] )      # )
            (?>(?&PPR_quotelike_body_interpolated))
            (?>(?&PerlOWS))
               (?&PPR_quotelike_body_interpolated)
        |
            # Delimited syntax...
            (?>(?&PPR_quotelike_body_interpolated_unclosed))
               (?&PPR_quotelike_body_interpolated)
        )
        [msixpodualgcer]*+
    ) # End of rule
    ) # End of rule

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
            (?= (?>(?&PerlOWS)) [\[(<\{] )      # )
            (?>(?&PPR_quotelike_body_interpolated))
            (?>(?&PerlOWS))
               (?&PPR_quotelike_body_interpolated)
        |
            # Delimited syntax...
            (?>(?&PPR_quotelike_body_interpolated_unclosed))
               (?&PPR_quotelike_body_interpolated)
        )
        [cdsr]*+
    ) # End of rule
    ) # End of rule

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
                (?&PPR_quotelike_body_interpolated)
            )
            [msixpodualgc]*+
        ) # End of rule
        ) # End of rule
        (?=
            (?>(?&PerlOWS))
            (?> \z | [,;\}\])?] | => | : (?! :)
            |   (?&PerlInfixBinaryOperator) | (?&PerlLowPrecedenceInfixOperator)
            |   (?= \w) (?> for(?:each)?+ | while | if | unless | until | when )
            )
        )
    ) # End of rule
    ) # End of rule

    (?<PerlQuotelikeQR>
        qr \b
        (?> (?= [#] ) | (?! (?>(?&PerlOWS)) => ) )
        (?>(?&PPR_quotelike_body_interpolated))
        [msixpodual]*+
    ) # End of rule

    (?<PerlRegex>
        (?>
            (?&PerlMatch)
        |
            (?&PerlQuotelikeQR)
        )
    ) # End of rule

    (?<PerlContextualRegex>
        (?>
            (?&PerlContextualMatch)
        |
            (?&PerlQuotelikeQR)
        )
    ) # End of rule


    (?<PerlBuiltinFunction>
        # Optimized to match any Perl builtin name, without backtracking...
        (?=[^\W\d]) # Skip if possible
        (?>
             s(?>e(?>t(?>(?>(?>(?>hos|ne)t|gr)en|s(?>erven|ockop))t|p(?>r(?>iority|otoent)|went|grp))|m(?>ctl|get|op)|ek(?>dir)?|lect|nd)|y(?>s(?>write|call|open|read|seek|tem)|mlink)|h(?>m(?>write|read|ctl|get)|utdown|ift)|o(?>cket(?>pair)?|rt)|p(?>li(?>ce|t)|rintf)|(?>cala|ubst)r|t(?>ate?|udy)|leep|rand|qrt|ay|in)
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
    ) # End of rule

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
    ) # End of rule

    (?<PerlVersionNumber>
        (?>
            (?&PerlVString)
        |
            (?>(?&PPR_digit_seq))
            (?: \. (?&PPR_digit_seq)?+ )*+
        )
    ) # End of rule

    (?<PerlVString>
        v  (?>(?&PPR_digit_seq))  (?: \. (?&PPR_digit_seq) )*+
    ) # End of rule

    (?<PerlNumber>
        [+-]?+
        (?>
            0  (?>  x (?&PPR_x_digit_seq)
               |    b (?&PPR_b_digit_seq)
               |      (?&PPR_o_digit_seq)
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
    ) # End of rule

    (?<PerlOldQualifiedIdentifier>
        (?> (?> :: | ' ) \w++  |  [^\W\d]\w*+ )  (?: (?> :: | ' )  \w++ )*+
    ) # End of rule

    (?<PerlQualifiedIdentifier>
        (?>     ::       \w++  |  [^\W\d]\w*+ )  (?: (?> :: | ' )  \w++ )*+
    ) # End of rule

    (?<PerlIdentifier>
                                  [^\W\d]\w*+
    ) # End of rule

    (?<PerlBareword>
        (?! (?> (?= \w )
                (?> for(?:each)?+ | while | if | unless | until | use | no | given | when | sub | return )
            |   (?&PPR_named_op)
            |   __ (?> END | DATA ) __ \n
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
    ) # End of rule

    (?<PerlKeyword>
        (?!)    # None, by default, but can be overridden in a composing regex
    ) # End of rule

    (?<PerlPod>
        ^ = [^\W\d]\w*+          # A line starting with =<identifier>
        .*?                      # Up to the first...
        ^ = cut \b [^\n]*+ $     # ...line starting with =cut
    ) # End of rule


    ##### Whitespace matching (part of API) #################################

    (?<PerlOWS>
        (?(?{ !keys %PPR::_heredoc_skip; })
            \s*+
            (?:
                (?>
                    [#] [^\n]*+ \n
                    \s*+
                |
                    __ (?> END | DATA ) __ \b .*+ \z
                )
            )*+
        |
            (?:
                \h++
            |
                \n  (??{ $PPR::_heredoc_skip{+pos()} // q{} })
            |
                [#] [^\n]*+
            |
                __ (?> END | DATA ) __ \b .*+ \z
            )*+
        )
    ) # End of rule

    (?<PerlNWS>
        (?(?{ !keys %PPR::_heredoc_skip; })
            (?= [\s#] )
            \s*+
            (?:
                (?>
                    [#] [^\n]*+ \n
                    \s*+
                |
                    __ (?> END | DATA ) __ \b .*+ \z
                )
            )*+
        |
            (?:
                \h++
            |
                \n  (??{ $PPR::_heredoc_skip{+pos()} // q{} })
            |
                [#] [^\n]*+
            |
                __ (?> END | DATA ) __ \b .*+ \z
            )++
        )
    ) # End of rule


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
    )

    (?<PPR_non_reserved_identifier>
        (?! (?>
               for(?:each)?+ | while | if | unless | until | given | when | default
            |  sub | format | use | no
            |  (?&PPR_named_op)
            |  [msy] | q[wrxq]?+ | tr
            |   __ (?> END | DATA ) __ \n
            )
            \b
        )
        (?>(?&PerlQualifiedIdentifier))
        (?! :: )
    )

    (?<PPR_three_part_list>
        \(  (?>(?&PerlOWS)) (?: (?>(?&PerlExpression)) (?&PerlOWS) )??
         ;  (?>(?&PerlOWS)) (?: (?>(?&PerlExpression)) (?&PerlOWS) )??
         ;  (?>(?&PerlOWS)) (?: (?>(?&PerlExpression)) (?&PerlOWS) )??
        \)
    )

    (?<PPR_indirect_obj>
        (?&PerlBareword)
    |
        (?>(?&PerlVariableScalar))
        (?! (?>(?&PerlOWS)) (?> [<\[\{] | -> ) )
    )

    (?<PPR_quotelike_body>
        (?>(?&PPR_quotelike_body_unclosed))
        \S   # (Note: Don't have to test that this matches; the preceding subrule already did that)
    )

    (?<PPR_balanced_parens>
        [^)(\\\n]*+
        (?:
            (?>
                \\.
            |
                \(  (?>(?&PPR_balanced_parens))  \)
            |
                \n  (??{ $PPR::_heredoc_skip{+pos()} // q{} })
            )
            [^)(\\\n]*+
        )*+
    )

    (?<PPR_balanced_curlies>
        [^\}\{\\\n]*+
        (?:
            (?>
                \\.
            |
                \{  (?>(?&PPR_balanced_curlies))  \}
            |
                \n  (??{ $PPR::_heredoc_skip{+pos()} // q{} })
            )
            [^\}\{\\\n]*+
        )*+
    )

    (?<PPR_balanced_squares>
        [^][\\\n]*+
        (?:
            (?>
                \\.
            |
                \[  (?>(?&PPR_balanced_squares))  \]
            |
                \n  (??{ $PPR::_heredoc_skip{+pos()} // q{} })
            )
            [^][\\\n]*+
        )*+
    )

    (?<PPR_balanced_angles>
        [^><\\\n]*+
        (?:
            (?>
                \\.
            |
                <  (?>(?&PPR_balanced_angles))  >
            |
                \n  (??{ $PPR::_heredoc_skip{+pos()} // q{} })
            )
            [^><\\\n]*+
        )*+
    )

    (?<PPR_quotelike_body_unclosed>
        (?>
               [#]
               [^#\\\n]*+
               (?:
                   (?: \\. | \n  (??{ $PPR::_heredoc_skip{+pos()} // q{} }) )
                   [^#\\\n]*+
               )*+
               (?= [#] )
        |
            (?>(?&PerlOWS))
            (?>
                \{  (?>(?&PPR_balanced_curlies))    (?= \} )
            |
                \[  (?>(?&PPR_balanced_squares))    (?= \] )
            |
                \(  (?>(?&PPR_balanced_parens))     (?= \) )
            |
                 <  (?>(?&PPR_balanced_angles))     (?=  > )
            |
                \\
                    [^\\\n]*+
                    (
                        \n  (??{ $PPR::_heredoc_skip{+pos()} // q{} })
                        [^\\\n]*+
                    )*+
                (?= \\ )
            |
                 /
                     [^\\/\n]*+
                 (?:
                     (?: \\. | \n  (??{ $PPR::_heredoc_skip{+pos()} // q{} }) )
                     [^\\/\n]*+
                 )*+
                 (?=  / )
            |
                (?<PPR_qldel> \S )
                    (?:
                        \\.
                    |
                        \n (??{ $PPR::_heredoc_skip{+pos()} // q{} })
                    |
                        (?! \g{PPR_qldel} ) .
                    )*+
                (?= \g{PPR_qldel} )
            )
        )
    )

    (?<PPR_quotelike_body_interpolated>
        (?>(?&PPR_quotelike_body_interpolated_unclosed))
        \S   # (Note: Don't have to test that this matches; the preceding subrule already did that)
    )

    (?<PPR_balanced_parens_interpolated>
        [^)(\\\n\$\@]*+
        (?:
            (?>
                \\.
            |
                \(  (?>(?&PPR_balanced_parens_interpolated))  \)
            |
                \n  (??{ $PPR::_heredoc_skip{+pos()} // q{} })
            |
                (?= \$ (?! [\s\)] ) )  (?&PerlScalarAccessNoSpace)
            |
                (?= \@ (?! [\s\)] ) )  (?&PerlArrayAccessNoSpace)
            |
                [\$\@]
            )
            [^)(\\\n\$\@]*+
        )*+
    )

    (?<PPR_balanced_curlies_interpolated>
        [^\}\{\\\n\$\@]*+
        (?:
            (?>
                \\.
            |
                \{  (?>(?&PPR_balanced_curlies_interpolated))  \}
            |
                \n  (??{ $PPR::_heredoc_skip{+pos()} // q{} })
            |
                (?= \$ (?! [\s\}] ) )  (?&PerlScalarAccessNoSpace)
            |
                (?= \@ (?! [\s\}] ) )  (?&PerlArrayAccessNoSpace)
            |
                [\$\@]
            )
            [^\}\{\\\n\$\@]*+
        )*+
    )

    (?<PPR_balanced_squares_interpolated>
        [^][\\\n\$\@]*+
        (?:
            (?>
                \\.
            |
                \[  (?>(?&PPR_balanced_squares_interpolated))  \]
            |
                \n  (??{ $PPR::_heredoc_skip{+pos()} // q{} })
            |
                (?= \$ (?! [\s\]] ) )  (?&PerlScalarAccessNoSpace)
            |
                (?= \@ (?! [\s\]] ) )  (?&PerlArrayAccessNoSpace)
            |
                [\$\@]
            )
            [^][\\\n\$\@]*+
        )*+
    )

    (?<PPR_balanced_angles_interpolated>
        [^><\\\n\$\@]*+
        (?:
            (?>
                \\.
            |
                <  (?>(?&PPR_balanced_angles_interpolated))  >
            |
                \n  (??{ $PPR::_heredoc_skip{+pos()} // q{} })
            |
                (?= \$ (?! [\s>] ) )  (?&PerlScalarAccessNoSpace)
            |
                (?= \@ (?! [\s>] ) )  (?&PerlArrayAccessNoSpace)
            |
                [\$\@]
            )
            [^><\\\n\$\@]*+
        )*+
    )

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
                        \n  (??{ $PPR::_heredoc_skip{+pos()} // q{} })
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
                    <  (?>(?&PPR_balanced_angles_interpolated))     (?=  > )
                |
                    \\
                        [^\\\n\$\@]*+
                        (?:
                            (?>
                                \n  (??{ $PPR::_heredoc_skip{+pos()} // q{} })
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
                                \n  (??{ $PPR::_heredoc_skip{+pos()} // q{} })
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
                            \n (??{ $PPR::_heredoc_skip{+pos()} // q{} })
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
                            \n (??{ $PPR::_heredoc_skip{+pos()} // q{} })
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
    )

    (?<PPR_filetest_name>   [ABCMORSTWXbcdefgkloprstuwxz]          )

    (?<PPR_digit_seq>               \d++ (?: _?+         \d++ )*+  )
    (?<PPR_x_digit_seq>     [\da-fA-F]++ (?: _?+ [\da-fA-F]++ )*+  )
    (?<PPR_o_digit_seq>          [0-7]++ (?: _?+      [0-7]++ )*+  )
    (?<PPR_b_digit_seq>          [0-1]++ (?: _?+      [0-1]++ )*+  )
)
}xms;

1; # Magic true value required at end of module

__END__

=head1 NAME

PPR - Pattern-based Perl Recognizer


=head1 VERSION

This document describes PPR version 0.000011


=head1 SYNOPSIS

    use PPR;

    # Define a regex that will match an entire Perl document...
    my $perl_document = qr{

        # What to match            # Install the (?&PerlDocument) rule
        \A (?&PerlDocument) \Z     $PPR::GRAMMAR

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

    $source_code =~ m{ \A (?&PerlDocument) \Z  $PPR::GRAMMAR }x;

Note that all the examples shown so far have interpolated this "grammar
variable" at the end of the regular expression. This placement is
desirable, but not necessary. Each of the following works identically:

    $source_code =~ m{ \A (?&PerlDocument) \Z  $PPR::GRAMMAR }x;

    $source_code =~ m{ $PPR::GRAMMAR  \A (?&PerlDocument) \Z }x;

    $source_code =~ m{ \A $PPR::GRAMMAR (?&PerlDocument) \Z  }x;

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

If it is set, C<$PPR::ERROR> will contain an object of type PPR::ERROR,
with the following methods:

=over

=item C<< $PPR::ERROR->origin($line, $file) >>

Returns a clone of the PPR::ERROR object that now believes that the
source code parsing failure it is reporting occurred in a code fragment
starting at the specified fline and file. If the second argument is
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
      slurp($filename) =~ m{ \A (?&PerlDocument) \Z  $PPR::GRAMMAR }x
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
                        \G (?&PerlOWS)           # to skip whitespace
                           ((?&PerlStatement))   # and keep statements,
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

Matches an entire valid Perl document, including leading or trailing
whitespace, comments, and any final C<__DATA__> or C<__END__> section.


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

The alterative name comes from the fact that anything matching is what
most people think of as a single element of a comma-separated list.


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


=head3 C<< (?&PerlLvalue) >>

Matches any variable or parenthesized list of variables that could
be assigned to.


=head3 C<< (?<PerlPackageDeclaration> >>

Matches the declaration of any package
(with or without a defining block).


=head3 C<< (?<PerlSubroutineDeclaration> >>

Matches the declaration of any named subroutine
(with or without a defining block).


=head3 C<< (?<PerlUseStatement> >>

Matches a C<< use <module name> ...; >> or C<< use <version number>; >> statement.


=head3 C<< (?<PerlReturnStatement> >>

Matches a C<< return <expression>; >> or C<< return; >> statement.


=head3 C<< (?&PerlControlBlock) >>

Matches an C<if>, C<unless>, C<while>, C<until>, C<for>, or C<foreach>
statement, including its block.


=head3 C<< (?&PerlDoBlock) >>

Matches a C<do>-block expression.


=head3 C<< (?&PerlEvalBlock) >>

Matches a C<eval>-block expression.


=head3 C<< (?&PerlStatementModifier) >>

Matches an C<if>, C<unless>, C<while>, C<until>, C<for>, or C<foreach>
modifier that could appear after a statement. Only matches the modifier, not
the preceding statement.



=head3 C<< (?&PerlFormat) >>

Matches a C<format> declaration, including its terminating "dot".



=head3 C<< (?&PerlBlock) >>

Matches a C<{>...C<}>-delimited block containing zero-or-more statements.


=head3 C<< (?&PerlCall) >>

Matches a class to a subroutine or built-in function.
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

Matches any contiguous set of POD directives,
up to the first C<=cut>.


=head3 C<< (?&PerlOWS) >>

Match zero-or-more characters of optional whitespace,
including spaces, tabs, newlines,
comments, POD, and any trailing
C<__END__> or C<__DATA__> section.


=head3 C<< (?&PerlNWS) >>

Match one-or-more characters of necessary whitespace,
including spaces, tabs, newlines,
comments, POD, and any trailing
C<__END__> or C<__DATA__> section.


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
