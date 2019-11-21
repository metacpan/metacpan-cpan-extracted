#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Parser::LR - Create and use an LR(1) parser.
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc., 2019
#-------------------------------------------------------------------------------
# podDocumentation
package Parser::LR;
require v5.26;
our $VERSION = 20191122;
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use Data::DFA;
use Data::NFA;
use Math::Cartesian::Product;

our $logFile = q(/home/phil/z/z/z/zzz.txt);                                      # Log printed results if developing

#D1 Create and use an LR(1) parser.                                             # Construct an LR(1) parser from a set of rules using L<compileGrammar>; use the parser produced to parse sequences of terminal symbols using L<parseWithGrammar>; print the resulting parse tree with L<printParseTree> or  L<printParseTreeAsXml>.

sub printRule($)                                                                #P Print a rule
 {my ($rule) = @_;                                                              # Rule
  my $r = $rule->rule;
  my $x = $rule->expandable;
  my $e = join ' ', $rule->expansion->@*;
  qq($r($e)$x)
 }

sub compileGrammar($%)                                                          # Compile a grammar from a set of rules expressed as a string with one rule per line. Returns a L<Parser::LR::Grammar Definition>.
 {my ($rules, %options) = @_;                                                   # Rule definitions, options

  my @lines = map {[split /\s+/]} split /\n/, $rules =~ s(#.*?\n) (\n)gsr;      # Words from lines from grammar minus comments

  my sub newRule(%)                                                             # Create a new rule
   {my (%options) = @_;                                                         # Options
    genHash(q(Parser::LR::Rule),                                                # A parsing rule
      expandable => undef,                                                      # Symbol to expand
      expansion  => undef,                                                      # Symbol expansion
      print      => \&printRule,                                                # Rule printer
      rule       => undef,                                                      # Rule number
      %options,
     );
   }

  my @rules;                                                                    # {symbol}[rule] = a rule to expand symbol

  for my $line(@lines)                                                          # Lines of input
   {if (my ($expandable, @expansion) = @$line)                                  # Symbol to expand, expansion
     {push @rules, newRule                                                      # A parsing rule
       (expandable => $expandable,                                              # Symbol to expand
        expansion  => [@expansion],                                             # Symbol expansion
        print      => \&printRule,                                              # Rule printer
        rule       => scalar @rules,                                            # Rule number
       );
     }
   }

  my $grammar     = bless \@rules, q(Parser::LR::Grammar);                      # {symbol to expand => {expansion=>[]}}
  my $startSymbol = $$grammar[0]->expandable;                                   # Locate the start symbol as the symbol expanded by the first rule

  my %expandables; my %terminals;                                               # Find the expandable and terminal symbols

  for my $rule(@rules)                                                          # Expandables
   {$expandables{$rule->expandable}++;
   }

  for my $rule(@rules)                                                          # Terminals
   {$terminals{$_}++ for grep {!$expandables{$_}} $rule->expansion->@*;
   }

  my %reducers;                                                                 # The expandables an expandable can reduce to
  for my $r(@rules)
   {my $e = $r->expandable;
    my @e = $r->expansion->@*;
    if (@e == 1)
     {$reducers{$e[0]}{$e}++;
     }
   }

   for       my $r (sort keys %reducers)                                        # Propogate reduction of expandables
    {my $n = 0;
     for     my $r1(sort keys %reducers)
      {for   my $r2(sort keys $reducers{$r1}->%*)
        {for my $r3(sort keys $reducers{$r2}->%*)
          {++$n;
           $reducers{$r1}{$r3}++;
          }
        }
      }
   }

  my %recursiveExpandables;                                                     # Find self recursive expandables
  for my $e(sort keys %reducers)
   {if ($reducers{$e}{$e})
     {$recursiveExpandables{$e}++
     }
   }

  if (keys %recursiveExpandables)                                               # Check for self recursive expandables
   {die "Recursive expandables:". dump([sort keys %recursiveExpandables]);
   }

  my %optionalExpandables;
  for my $rule(@rules)                                                          # Expandables that have empty expansions
   {my @e = $rule->expansion->@*;
    if (!@e)
     {$optionalExpandables{$rule->expandable}++;
     }
   }

  if (!$options{nosub})                                                         # Substitute rules that do not refer to themselves
   {my sub appearances($$)                                                      # How many  times an expandable appears in the expansion of a rule
     {my ($expandable, $rule) = @_;
      my $n = 0;
      for my $e($rule->expansion->@*)
       {++$n if $e eq $expandable;
       }
      $n                                                                        # Number of times this expandable appears in this rule
     } # appearances

    my sub selfRecursive($)                                                     # The number of rules the expandable is self recursive in
     {my ($expandable) = @_;
      my $n = 0;
      for my $rule(@rules)
       {if ($expandable eq $rule->expandable)                                   # A rule expanding this expandable
         {$n += appearances($expandable, $rule);
         }
       }
      $n                                                                        # Number of times this expandable appears in this rule
     } # selfRecursive

    my sub rulesForExpandable($)                                                # The rules that expand an expandable
     {my ($expandable) = @_;
      my @e;
      for my $rule(@rules)                                                      # Terminals that start any rule
       {if ($rule->expandable eq $expandable)
         {push @e, $rule;
         }
       }
      @e                                                                        # Rules for this expandable
     } # rulesForExpandable

    my sub addRulesBySubstituting($$$@)                                         # Add rules by substituting the expansions of a non self recursive expandable
     {my ($expandable, $appearances, $rule, @rules) = @_;                       # Expandable to substitute, appearances in rule to substitute into, rule to substitute into, rules to substitute from.
      my @expansions = map {$_->expansion} @rules;                              # Expansion for each rule of the expandable being substituted
      my @c; cartesian {push @c, [@_]} map {[@expansions]}  1..$appearances;    # Cartesian product of the expansion rules by the number of times it appears in the rule
      my @n;                                                                    # New rules

      for my $c(@c)                                                             # Create new rules for each element of the cartesian product
       {my @f;
        for my $e($rule->expansion->@*)
         {if ($expandable eq $e)                                                # Substitute
           {my $f = shift @$c;
            push @f, @$f;
           }
          else
           {push @f, $e;                                                        # Retain
           }
         }
        push @n, newRule(expandable => $rule->expandable, expansion => [@f]);   # Create new rule from substitution
       }
      @n                                                                        # New rules
     } # addRulesBySubstituting

    if (1)                                                                      # Substitute non self recurring expandables to create more rules with fewer expandables
     {my $changes = 1;
      for my $a(1..10)                                                          # Maximum number of expansion passes
       {next unless $changes; $changes = 0;                                     # While there were changes made
        for my $e(sort keys %expandables)                                       # Each expandable
         {if (!selfRecursive($e))                                               # Each non self recursive expandable symbol
           {my @r = rulesForExpandable($e);                                     # Rule set for the expandable being substituted
            my @n;
            for my $r(@rules)                                                   # Each rule
             {if (my $n = appearances($e, $r))                                  # Number of times this expandable is mentioned in this rule - rules where it is the expandable will be ignored because we are only processing non self recursive expandables.
               {push @n, addRulesBySubstituting($e, $n, $r, @r);
                ++$changes;
               }
              elsif ($r->expandable ne $e)                                      # Retain a rule which has no contact with the expandable being substituted
               {push @n, $r;
               }
             }
            @rules = @n;
           }
         }
       }
     }
   }

  my %startTerminals;
  for my $rule(@rules)                                                          # Terminals that start any rule
   {my @e = $rule->expansion->@*;
    if (my ($e) = $rule->expansion->@*)
     {if ($terminals{$e})
       {$startTerminals{$e}++;
       }
     }
   }

  my $longestRule = 0;
  for my $rule(@rules)                                                          # Longest rule
   {my $l = $rule->expansion->@*;
    $longestRule = max($longestRule, $l);
   }

  my $nfa       = bless {}, q(Data::NFA);                                       # NFA being constructed

  my $newState  = sub                                                           # Create a new state in the specified B<$nfa>
   {my $n       = scalar keys %$nfa;                                            # Current NFA size
    $$nfa{$n}   = Data::NFA::newNfaState;                                       # Create new state
    $n                                                                          # Number of state created
   };

  my $start = &$newState($nfa);                                                 # The expansions of each symbol are located from the start state by applying the symbol to be expanded

  for my $rule(@$grammar)                                                       # For each symbol in the expansion
   {my $expansion = $rule->expansion;                                           # Expansion part of rule
    my $pos       = $start;                                                     # Start state for rule
    for my $e(@$expansion)                                                      # Transition to the next state on symbol being consumed
     {my $p = $pos;
      my $q = &$newState($nfa);
              $$nfa{$p}->jumps->{$q}++;
      $pos  = $$nfa{$q}->transitions->{$e} = &$newState($nfa);
     }

    $$nfa{$pos}->final = $rule;                                                 # Mark the final state with the sub to be called when we reduce by this rule
   }

  my $finalState = $$nfa{$start}->transitions->{$startSymbol}=&$newState($nfa); # Transition on start symbol

  for my $i(sort keys %$nfa)                                                    # Add a jump to the symbol jump in state for each expandable symbol
   {my $state = $$nfa{$i};                                                      # State
    delete $$state{final}       unless defined $$state{final};
    delete $$state{jumps}       unless keys $$state{jumps}->%*;
    delete $$state{transitions} unless keys $$state{transitions}->%*;
   }

  my $dfa = Data::DFA::fromNfa($nfa);                                           # DFA from grammar NFA

  for my $state(values $dfa->%*)                                                # Remove irrelevant fields from each state
   {delete @$state{qw(nfaStates pump sequence state)};

    for(grep {!defined $$state{$_}} qw(final transitions))
     {delete $$state{$_};
     }
   }

  for my $state(sort keys %$dfa)                                                # Check for multiple reductions
   {if (my $final = $$dfa{$state}->final)
     {if    (@$final > 1)
       {lll $dfa->print;
        die "More than one reduction in state $state";
       }
     }
   }

  my %expansionStates;
  for my $state(sort keys %$dfa)                                                # Mark expansions states
   {for my $symbol(sort keys $$dfa{$state}->transitions->%*)
     {if ($expandables{$symbol})
       {$expansionStates{$state}++;
       }
     }
   }

  for my $i(keys @rules)                                                        # Renumber rules
   {$rules[$i]->rule = $i;
   }

  genHash(q(Parser::LR::Grammar),                                               # LR parser produced
    grammar             =>  $grammar,                                           # Grammar from which the NFA was derived
    nfa                 =>  $nfa,                                               # NFA from grammar
    dfa                 =>  $dfa,                                               # DFA from grammar
    expandables         => \%expandables,                                       # Expandable symbols
    expansionStates     => \%expansionStates,                                   # States we can expand in
    terminals           => \%terminals,                                         # Terminal symbols
    reducers            => \%reducers,                                          # The expandables an expandable can reduce to
    startSymbol         =>  $startSymbol,                                       # Start symbol
    finalState          =>  $$dfa{0}->transitions->{$startSymbol},              # Final state at end of parse
    longestRule         =>  $longestRule,                                       # Longest rule
    rules               => [@rules],                                            # Rules
    startTerminals      => \%startTerminals,                                    # Terminals that start rules
    optionalExpandables => \%optionalExpandables,                               # Expandables that can expand to nothing
   );
 } # compileGrammar

sub longestMatchingRule($@)                                                     #P Find the longest rule that completely matches the top of the stack.
 {my ($grammar, @stack) = @_;                                                   # Grammar, stack
  my $dfa = $grammar->dfa;
  my $L = $grammar->longestRule;
     $L = @stack if $L > @stack;
  my $N = @stack;
  my $S = $N-$L;
  my $F = $N-1;

  position: for my $i($S..$F)                                                   # Scan forward on stack for each possible rule
   {my $state = 0;
    symbol: for my $j($i..$F)                                                   # Scan forward from start in state 0 at selected point
     {my $symbol = $stack[$j];
      if (my $next = $$dfa{$state}->transitions->{$symbol})
       {$state = $next;
        next symbol;
       }
      next position;
     }
    my $final = $$dfa{$state}->final;
    return $final->[0] if $final;                                               # Return matching rule
   }
  undef
 }

sub partialMatch($@)                                                            #P Check whether we have a partial match with the top of the stack.
 {my ($grammar, @stack) = @_;                                                   # Grammar, stack
  my $dfa = $grammar->dfa;
  my $L = $grammar->longestRule;
     $L = @stack if $L > @stack;
  my $N = @stack;

  position: for my $i($N-$L..$N-1)                                              # Scan forward on stack from each possible position
   {my $state = 0;
    symbol: for my $j($i..@stack-1)                                             # Scan forward with this rule
     {my $symbol = $stack[$j];
      if (my $next = $$dfa{$state}->transitions->{$symbol})
       {$state = $next;
        next symbol;
       }
      next position;
     }
    return @stack-$i;                                                           # Matches this many characters
   }
  0
 }

sub reduceStackWithRule($$$)                                                    #P Reduce by the specified rule and update the stack and parse tree to match.
 {my ($rule, $stack, $tree) = @_;                                               # Rule, stack, parse tree
  my $L = $rule->expansion->@*;
  if ($L <= @$stack)                                                            # Remove expansion
   {my @r = splice(@$stack, -$L);
    push @$stack, $rule->expandable;
    my $e = $rule->expansion->@*;
    my @s = splice @$tree, -$e;
    push @$tree, bless [$rule->rule, @s], q(Parser::LR::Reduce);
   }
  else                                                                          # Stack too small
   {die "Stack too small";
   }
 }

sub parseWithGrammarAndLog($@)                                                  #P Parse, using a compiled B<$grammar>, an array of terminals and return a log of parsing actions taken.
 {my ($grammar, @terminals) = @_;                                               # Compiled grammar, terminals to parse
  my $dfa = $grammar->dfa;                                                      # Dfa for grammar
  my @stack;
  my @log;
  my @tree;

  my sub printStack{return  join ' ', @stack if @stack; q/(empty)/}             # Logging
  my sub log(@)    {my $m = join '',  @_; push @log, $m; say STDERR $m}
  my sub lll(@)    {my $m = join '',  @_;                say STDERR $m}

  lll join '', "Parse   : ", join ' ', @terminals;
  terminal: while(@terminals)                                                   # Parse the terminals
   {my $terminal = shift @terminals;
    log "Terminal: $terminal, stack: ", printStack;
    if (!@stack)                                                                # First terminal
     {push @stack, $terminal;
      push @tree,  $terminal;
      log "  Accept first terminal: $terminal to get stack: ",  printStack;
     }
    else
     {my $p = partialMatch($grammar, @stack, $terminal);
      if (partialMatch($grammar, @stack, $terminal) >= 2)                       # Fits as is
       {push @stack,  $terminal;
        push @tree,   $terminal;
        log "  Accept $terminal to get stack: ",  printStack;
       }
      else
       {if ($grammar->startTerminals->{$terminal})                              # Starting terminal = shift now and hope for a later reduction
         {push @stack, $terminal;
          push @tree,  $terminal;
          log "Accepted terminal: $terminal as is, stack: ".printStack;
          next          terminal;
         }
        else                                                                    # Not a starting terminal so we will have to reduce to fit now
         {reduction: for my $r(1..10)
           {if (my $rule = longestMatchingRule($grammar, @stack))
             {my $n = $rule->rule;
              my $e = $rule->expandable;
              reduceStackWithRule($rule, \@stack, \@tree);
              log "  Reduced by rule $n, expandable: $e, stack: ", printStack;
              my $P = partialMatch($grammar, @stack, $terminal);
              if (partialMatch($grammar, @stack, $terminal) >= 2)
               {push @stack,  $terminal;
                push @tree,   $terminal;
                log "  Accept $terminal after $r reductions to get: ", printStack;
                next           terminal;
               }
              else
               {next reduction;
               }
             }
            next terminal;
           }
          die "No match after all reductions possible for $terminal on stack "
              .printStack;
         }
       }
     }
   }

  for my $r(1..10)                                                              # Final reductions
   {if (my $rule = longestMatchingRule($grammar, @stack))
     {my $n = $rule->rule;
      my $e = $rule->expandable;
      reduceStackWithRule($rule, \@stack, \@tree);
      log "  Reduced in finals by rule $n, expandable: $e, stack: ", printStack;
      next;
     }
    last;
   }

  !@tree     and die "No parse tree";                                           # Check for single parse tree
   @tree > 1 and die "More than one parse block";

  log "  Parse tree is:\n", &printParseTree($grammar, $tree[0]) if @tree;       # Results

  my $r = join "\n", @log, ''; $r =~ s(\s+\Z) (\n)s;                            # Remove trailing new lines

  owf($logFile, $r) if -e $logFile;                                             # Log the result if requested
  $r
 } # parseWithGrammarAndLog

sub parseWithGrammar($@)                                                        # Parse, using a compiled B<$grammar>, an array of terminals and return a parse tree.
 {my ($grammar, @terminals) = @_;                                               # Compiled grammar, terminals to parse
  my $dfa = $grammar->dfa;                                                      # Dfa for grammar
  my @stack;
  my @log;
  my @tree;

  terminal: while(@terminals)                                                   # Parse the terminals
   {my $terminal = shift @terminals;
    if (!@stack)                                                                # First terminal
     {push @stack, $terminal;
      push @tree,  $terminal;
     }
    else
     {my $p = partialMatch($grammar, @stack, $terminal);
      if (partialMatch($grammar, @stack, $terminal) >= 2)                       # Fits as is
       {push @stack, $terminal;
        push @tree,  $terminal;
       }
      else
       {if ($grammar->startTerminals->{$terminal})                              # Starting terminal = shift now and hope for a later reduction
         {push @stack, $terminal;
          push @tree, $terminal;
          next terminal;
         }
        else                                                                    # Not a starting terminal so we will have to reduce to fit now
         {reduction: for my $r(1..10)
           {if (my $rule = longestMatchingRule($grammar, @stack))
             {my $n = $rule->rule;
              my $e = $rule->expandable;
              reduceStackWithRule($rule, \@stack, \@tree);
              my $P = partialMatch($grammar, @stack, $terminal);
              if (partialMatch($grammar, @stack, $terminal) >= 2)
               {push @stack, $terminal;
                push @tree,  $terminal;
                next terminal;
               }
              else
               {next reduction;
               }
             }
            next terminal;
           }
          die "No match after all reductions possible for $terminal on stack "
              .dump(\@stack). "\n";
         }
       }
     }
   }

  for my $r(1..10)                                                              # Final reductions
   {if (my $rule = longestMatchingRule($grammar, @stack))
     {my $n = $rule->rule;
      my $e = $rule->expandable;
      reduceStackWithRule($rule, \@stack, \@tree);
      next;
     }
    last;
   }

  !@tree     and die "No parse tree";                                           # Check for single parse tree
   @tree > 1 and die "More than one parse block";

  $tree[0]
 } # parseWithGrammar

sub printGrammar($)                                                             # Print a B<$grammar>.
 {my ($grammar) = @_;                                                           # Grammar
  my @r;
  for my $rule($grammar->grammar->@*)                                           # Each rule
   {push @r, [$rule->rule, $rule->expandable, $rule->expansion->@*];
   }
  my $r = formatTable([@r], [qw(Rule Expandable Expansion)]);
     $r =~ s(\s+\Z) (\n)gs;
  owf($logFile, $r) if -e $logFile;                                             # Log the result if requested
  $r
 } # printGrammar

sub printSymbolAsXml($)                                                         #P Print a symbol in a form acceptable as Xml
 {my ($symbol) = @_;                                                            # Symbol
  $symbol =~ m(\A[0-9a-z]+\Z)i ? $symbol : qq("$symbol");
 }

sub printGrammarAsXml($;$)                                                      #P Print a B<$grammar> as XML.
 {my ($grammar, $indent) = @_;                                                  # Grammar, indentation level
  my @r;
  my $space = q(  )x($indent//0);                                               # Indentation

  for my $rule($grammar->grammar->@*)                                           # Create an NFA for each rule as a choice of sequences
   {my $r = $rule->rule;
    my $s = $rule->expandable;
    my $S = printSymbolAsXml($s);
    push @r, qq(\n$space  <$S>);                                                # Rule

    for my $e($rule->expansion->@*)                                             # Expansion
     {my $E = printSymbolAsXml($e);
      push @r, qq(<$E/>);
     }
    push @r, qq(</$S>);
   }

  my $r = join "", qq($space<grammar>), @r, qq(\n$space</grammar>), "\n";       # Result
     $r =~ s(\s+\Z) (\n)gs;
  owf($logFile, $r) if -e $logFile;                                             # Log the result if requested
  $r
 } # printGrammarAsXml

sub printParseTree($$;$)                                                        # Print a parse tree.
 {my ($grammar, $tree, $indent) = @_;                                           # Grammar, parse tree, optional indent level
  my @r;
  my @rules = $grammar->rules->@*;

  my $print; $print = sub                                                       # Print sub tree
   {my ($stack, $depth) = @_;

    if (ref($stack))
     {if (defined(my ($r) = @$stack))
       {my ($rule) = $rules[$r];
        my (undef, @exp) = @$stack;
        push @r, [$rule->rule, (q(  )x$depth).$rule->expandable];
        for my $s(@exp)
         {$print->($s, $depth+1);
         }
       }
     }
    else
     {push @r, [q(), q(), $stack];
     }
   };

  return q() unless $tree;                                                      # Empty tree

  $print->($tree, $indent//0);

  my $r = formatTable([@r], [qw(Rule Expandable Terminal)]);
     $r =~ s(\s+\Z) (\n)gs;
  owf($logFile, $r) if -e $logFile;                                             # Log the result if requested
  $r
 } # printParseTree

sub printParseTreeAsBrackets($$;$)                                              # Print a parse tree as XML.
 {my ($grammar, $tree, $indent) = @_;                                           # Grammar, parse tree, optional indent level
  my @r;
  my @rules = $grammar->rules->@*;

  my $print; $print = sub                                                       # Print sub tree
   {my ($stack, $depth) = @_;
    my $s = q(  ) x $depth;

    if (ref($stack))
     {if (defined(my ($r) = @$stack))
       {my ($rule) = $rules[$r];
        my (undef, @exp) = @$stack;
        my $n = $rule->rule;
        my $e = $rule->expandable;
        my $E = printSymbolAsXml($e);
        push @r, qq(\n$s$E);
        for my $s(@exp)
         {$print->($s, $depth+1);
         }
        push @r, qq(\n$s$E);
       }
     }
    else
     {my $t = printSymbolAsXml($stack);
      push @r, $t;
     }
   };

  return q() unless $tree;                                                      # Empty tree

  $print->($tree, $indent//0);

  my $r = join ' ', @r, "\n";
     $r =~ s( +\n)  (\n)gs;
     $r =~ s(\s+\Z) (\n)gs;
     $r =~ s(\A\s+) ()gs;
  owf($logFile, $r) if -e $logFile;                                             # Log the result if requested
  $r
 } # printParseTreeAsBrackets

sub printParseTreeAsXml($$;$)                                                   # Print a parse tree as XML.
 {my ($grammar, $tree, $indent) = @_;                                           # Grammar, parse tree, optional indent level
  my @r;
  my @rules = $grammar->rules->@*;
  my $terminal = 0;

  my $print; $print = sub                                                       # Print sub tree
   {my ($stack, $depth) = @_;
    my $s = q(  ) x $depth;

    if (ref($stack))
     {if (defined(my ($r) = @$stack))
       {my ($rule) = $rules[$r];
        my (undef, @exp) = @$stack;
        my $n = $rule->rule;
        my $e = $rule->expandable;
        my $E = printSymbolAsXml($e);
        push @r, qq($s<$E rule="$n">);
        for my $s(@exp)
         {$print->($s, $depth+1);
         }
        push @r, qq($s</$E>);
       }
     }
    else
     {my $t = printSymbolAsXml($stack);
      push @r, qq($s<$t pos="$terminal"/>);
      ++$terminal;
     }
   };

  return q() unless $tree;                                                      # Empty tree

  $print->($tree, $indent//0);

  my $r = join "\n", @r, '';
     $r =~ s(\s+\Z) (\n)gs;
  owf($logFile, $r) if -e $logFile;                                             # Log the result if requested
  $r
 } # printParseTreeAsXml

sub printParseTreeAndGrammarAsXml($$)                                           #P Print a parse tree produced from a grammar by L<parseWithGrammarAndLog> as XML.
 {my ($tree, $grammar) = @_;                                                    # Parse tree, grammar
  my @r;

  push @r, q(<ParserLR>), q(  <parseTree>);
  push @r, printParseTreeAsXml($tree,    2).q(  </parseTree>);
  push @r, printGrammarAsXml  ($grammar, 1).q(</ParserLR>);
  my $r = join "\n", @r, '';
     $r =~ s(\s+\Z) (\n)gs;
  owf($logFile, $r) if -e $logFile;                                             # Log the result if requested
  $r
 }

#D0
#-------------------------------------------------------------------------------
# Export - eeee
#-------------------------------------------------------------------------------

use Exporter qw(import);

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT       = qw();
@EXPORT_OK    = qw();

%EXPORT_TAGS = (all=>[@EXPORT, @EXPORT_OK]);

#D
# podDocumentation

=pod

=encoding utf-8

=head1 Name

Parser::LR - Create and use an LR(1) parser.

=head1 Synopsis

Create an LR grammar from rules expressed one rule per line of a string.  Each
rule starts with an expandable symbol followed by one possible expansion as a
mixture of expandable and terminal symbols:

  my $grammar = compileGrammar(<<END);
  A  A + B
  A  B
  B  B * C
  B  C
  C  n
  C  D C
  D  ++
  D  --
  C  C E
  E  **
  E  //

  C  ( A )
  C  [ A ]
  C  { A }
  C  ( )
  C  [ ]
  C  { }

  C  D n
  END

Use the grammar so created to parse a string an array of terminal symbols
into a parse tree with L<parseWithGrammar>:

  my $tree = parseWithGrammar($grammar, qw{n * (  ++ -- n ** //   + -- ++  n // ** )});

Print the parse tree tree, perhaps with L<printParseTreeAsBrackets> or L<printParseTreeAsXml>:

  ok printParseTreeAsBrackets($grammar, $tree) eq <<END;
  A
    B
      B
        C n
        C
      B "*"
      C "("
        A
          A
            B
              C "++"
                C
                  C
                    C "--" n
                    C "**"
                  C "//"
                C
              C
            B
          A "+"
          B
            C "--"
              C
                C
                  C "++" n
                  C "//"
                C "**"
              C
            C
          B
        A ")"
      C
    B
  A
  END

=head1 Description

Create and use an LR(1) parser.


Version 20191121.


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Create and use an LR(1) parser.

Construct an LR(1) parser from a set of rules using L<compileGrammar>; use the parser produced to parse sequences of terminal symbols using L<parseWithGrammar>; print the resulting parse tree with L<printParseTree> or  L<printParseTreeAsXml>.

=head2 compileGrammar($%)

Compile a grammar from a set of rules expressed as a string with one rule per line. Returns a L<Parser::LR::Grammar Definition>.

     Parameter  Description
  1  $rules     Rule definitions
  2  %options   Options

B<Example:>


  if (1) {
    my $grammar = 𝗰𝗼𝗺𝗽𝗶𝗹𝗲𝗚𝗿𝗮𝗺𝗺𝗮𝗿(<<END);
  A  A + B
  A  B
  B  B * C
  B  C
  C  n
  C  ( A )
  C  [ A ]
  C  { A }
  C  ( )
  C  [ ]
  C  { }
  END

    ok printGrammar($grammar) eq <<END;
      Rule  Expandable  Expansion
   1     0  A           A          +  B
   2     1  A           B
   3     2  B           B          *  n
   4     3  B           B          *  (  A  )
   5     4  B           B          *  [  A  ]
   6     5  B           B          *  {  A  }
   7     6  B           B          *  (  )
   8     7  B           B          *  [  ]
   9     8  B           B          *  {  }
  10     9  B           n
  11    10  B           (          A  )
  12    11  B           [          A  ]
  13    12  B           {          A  }
  14    13  B           (          )
  15    14  B           [          ]
  16    15  B           {          }
  END

    my $tree = parseWithGrammar($grammar, qw/( [ { }  ]  +  [ { n }  ] ) * [ n + n ]  /);

    ok printParseTree($grammar, $tree) eq <<END;
      Rule  Expandable         Terminal
   1     1  A
   2     4    B
   3    10      B
   4                           (
   5     0        A
   6     1          A
   7    11            B
   8                           [
   9     1              A
  10    15                B
  11                           {
  12                           }
  13                           ]
  14                           +
  15    11          B
  16                           [
  17     1            A
  18    12              B
  19                           {
  20     1                A
  21     9                  B
  22                           n
  23                           }
  24                           ]
  25                           )
  26                           *
  27                           [
  28     0      A
  29     1        A
  30     9          B
  31                           n
  32                           +
  33     9        B
  34                           n
  35                           ]
  END

    ok printParseTreeAsXml($grammar, $tree) eq <<END;
  <A rule="1">
    <B rule="4">
      <B rule="10">
        <"(" pos="0"/>
        <A rule="0">
          <A rule="1">
            <B rule="11">
              <"[" pos="1"/>
              <A rule="1">
                <B rule="15">
                  <"{" pos="2"/>
                  <"}" pos="3"/>
                </B>
              </A>
              <"]" pos="4"/>
            </B>
          </A>
          <"+" pos="5"/>
          <B rule="11">
            <"[" pos="6"/>
            <A rule="1">
              <B rule="12">
                <"{" pos="7"/>
                <A rule="1">
                  <B rule="9">
                    <n pos="8"/>
                  </B>
                </A>
                <"}" pos="9"/>
              </B>
            </A>
            <"]" pos="10"/>
          </B>
        </A>
        <")" pos="11"/>
      </B>
      <"*" pos="12"/>
      <"[" pos="13"/>
      <A rule="0">
        <A rule="1">
          <B rule="9">
            <n pos="14"/>
          </B>
        </A>
        <"+" pos="15"/>
        <B rule="9">
          <n pos="16"/>
        </B>
      </A>
      <"]" pos="17"/>
    </B>
  </A>
  END

    ok printGrammarAsXml($grammar) eq <<END
  <grammar>
    <A><A/><"+"/><B/></A>
    <A><B/></A>
    <B><B/><"*"/><n/></B>
    <B><B/><"*"/><"("/><A/><")"/></B>
    <B><B/><"*"/><"["/><A/><"]"/></B>
    <B><B/><"*"/><"{"/><A/><"}"/></B>
    <B><B/><"*"/><"("/><")"/></B>
    <B><B/><"*"/><"["/><"]"/></B>
    <B><B/><"*"/><"{"/><"}"/></B>
    <B><n/></B>
    <B><"("/><A/><")"/></B>
    <B><"["/><A/><"]"/></B>
    <B><"{"/><A/><"}"/></B>
    <B><"("/><")"/></B>
    <B><"["/><"]"/></B>
    <B><"{"/><"}"/></B>
  </grammar>
  END
   }


=head2 parseWithGrammar($@)

Parse, using a compiled B<$grammar>, an array of terminals and return a parse tree.

     Parameter   Description
  1  $grammar    Compiled grammar
  2  @terminals  Terminals to parse

B<Example:>


  if (1) {
    my $grammar = compileGrammar(<<END);
  A  A + B
  A  B
  B  B * C
  B  C
  C  n
  C  ( A )
  C  [ A ]
  C  { A }
  C  ( )
  C  [ ]
  C  { }
  END

    ok printGrammar($grammar) eq <<END;
      Rule  Expandable  Expansion
   1     0  A           A          +  B
   2     1  A           B
   3     2  B           B          *  n
   4     3  B           B          *  (  A  )
   5     4  B           B          *  [  A  ]
   6     5  B           B          *  {  A  }
   7     6  B           B          *  (  )
   8     7  B           B          *  [  ]
   9     8  B           B          *  {  }
  10     9  B           n
  11    10  B           (          A  )
  12    11  B           [          A  ]
  13    12  B           {          A  }
  14    13  B           (          )
  15    14  B           [          ]
  16    15  B           {          }
  END

    my $tree = 𝗽𝗮𝗿𝘀𝗲𝗪𝗶𝘁𝗵𝗚𝗿𝗮𝗺𝗺𝗮𝗿($grammar, qw/( [ { }  ]  +  [ { n }  ] ) * [ n + n ]  /);

    ok printParseTree($grammar, $tree) eq <<END;
      Rule  Expandable         Terminal
   1     1  A
   2     4    B
   3    10      B
   4                           (
   5     0        A
   6     1          A
   7    11            B
   8                           [
   9     1              A
  10    15                B
  11                           {
  12                           }
  13                           ]
  14                           +
  15    11          B
  16                           [
  17     1            A
  18    12              B
  19                           {
  20     1                A
  21     9                  B
  22                           n
  23                           }
  24                           ]
  25                           )
  26                           *
  27                           [
  28     0      A
  29     1        A
  30     9          B
  31                           n
  32                           +
  33     9        B
  34                           n
  35                           ]
  END

    ok printParseTreeAsXml($grammar, $tree) eq <<END;
  <A rule="1">
    <B rule="4">
      <B rule="10">
        <"(" pos="0"/>
        <A rule="0">
          <A rule="1">
            <B rule="11">
              <"[" pos="1"/>
              <A rule="1">
                <B rule="15">
                  <"{" pos="2"/>
                  <"}" pos="3"/>
                </B>
              </A>
              <"]" pos="4"/>
            </B>
          </A>
          <"+" pos="5"/>
          <B rule="11">
            <"[" pos="6"/>
            <A rule="1">
              <B rule="12">
                <"{" pos="7"/>
                <A rule="1">
                  <B rule="9">
                    <n pos="8"/>
                  </B>
                </A>
                <"}" pos="9"/>
              </B>
            </A>
            <"]" pos="10"/>
          </B>
        </A>
        <")" pos="11"/>
      </B>
      <"*" pos="12"/>
      <"[" pos="13"/>
      <A rule="0">
        <A rule="1">
          <B rule="9">
            <n pos="14"/>
          </B>
        </A>
        <"+" pos="15"/>
        <B rule="9">
          <n pos="16"/>
        </B>
      </A>
      <"]" pos="17"/>
    </B>
  </A>
  END

    ok printGrammarAsXml($grammar) eq <<END
  <grammar>
    <A><A/><"+"/><B/></A>
    <A><B/></A>
    <B><B/><"*"/><n/></B>
    <B><B/><"*"/><"("/><A/><")"/></B>
    <B><B/><"*"/><"["/><A/><"]"/></B>
    <B><B/><"*"/><"{"/><A/><"}"/></B>
    <B><B/><"*"/><"("/><")"/></B>
    <B><B/><"*"/><"["/><"]"/></B>
    <B><B/><"*"/><"{"/><"}"/></B>
    <B><n/></B>
    <B><"("/><A/><")"/></B>
    <B><"["/><A/><"]"/></B>
    <B><"{"/><A/><"}"/></B>
    <B><"("/><")"/></B>
    <B><"["/><"]"/></B>
    <B><"{"/><"}"/></B>
  </grammar>
  END
   }


=head2 printGrammar($)

Print a B<$grammar>.

     Parameter  Description
  1  $grammar   Grammar

B<Example:>


  if (1) {
    my $grammar = compileGrammar(<<END);
  A  A + B
  A  B
  B  B * C
  B  C
  C  n
  C  ( A )
  C  [ A ]
  C  { A }
  C  ( )
  C  [ ]
  C  { }
  END

    ok 𝗽𝗿𝗶𝗻𝘁𝗚𝗿𝗮𝗺𝗺𝗮𝗿($grammar) eq <<END;
      Rule  Expandable  Expansion
   1     0  A           A          +  B
   2     1  A           B
   3     2  B           B          *  n
   4     3  B           B          *  (  A  )
   5     4  B           B          *  [  A  ]
   6     5  B           B          *  {  A  }
   7     6  B           B          *  (  )
   8     7  B           B          *  [  ]
   9     8  B           B          *  {  }
  10     9  B           n
  11    10  B           (          A  )
  12    11  B           [          A  ]
  13    12  B           {          A  }
  14    13  B           (          )
  15    14  B           [          ]
  16    15  B           {          }
  END

    my $tree = parseWithGrammar($grammar, qw/( [ { }  ]  +  [ { n }  ] ) * [ n + n ]  /);

    ok printParseTree($grammar, $tree) eq <<END;
      Rule  Expandable         Terminal
   1     1  A
   2     4    B
   3    10      B
   4                           (
   5     0        A
   6     1          A
   7    11            B
   8                           [
   9     1              A
  10    15                B
  11                           {
  12                           }
  13                           ]
  14                           +
  15    11          B
  16                           [
  17     1            A
  18    12              B
  19                           {
  20     1                A
  21     9                  B
  22                           n
  23                           }
  24                           ]
  25                           )
  26                           *
  27                           [
  28     0      A
  29     1        A
  30     9          B
  31                           n
  32                           +
  33     9        B
  34                           n
  35                           ]
  END

    ok printParseTreeAsXml($grammar, $tree) eq <<END;
  <A rule="1">
    <B rule="4">
      <B rule="10">
        <"(" pos="0"/>
        <A rule="0">
          <A rule="1">
            <B rule="11">
              <"[" pos="1"/>
              <A rule="1">
                <B rule="15">
                  <"{" pos="2"/>
                  <"}" pos="3"/>
                </B>
              </A>
              <"]" pos="4"/>
            </B>
          </A>
          <"+" pos="5"/>
          <B rule="11">
            <"[" pos="6"/>
            <A rule="1">
              <B rule="12">
                <"{" pos="7"/>
                <A rule="1">
                  <B rule="9">
                    <n pos="8"/>
                  </B>
                </A>
                <"}" pos="9"/>
              </B>
            </A>
            <"]" pos="10"/>
          </B>
        </A>
        <")" pos="11"/>
      </B>
      <"*" pos="12"/>
      <"[" pos="13"/>
      <A rule="0">
        <A rule="1">
          <B rule="9">
            <n pos="14"/>
          </B>
        </A>
        <"+" pos="15"/>
        <B rule="9">
          <n pos="16"/>
        </B>
      </A>
      <"]" pos="17"/>
    </B>
  </A>
  END

    ok printGrammarAsXml($grammar) eq <<END
  <grammar>
    <A><A/><"+"/><B/></A>
    <A><B/></A>
    <B><B/><"*"/><n/></B>
    <B><B/><"*"/><"("/><A/><")"/></B>
    <B><B/><"*"/><"["/><A/><"]"/></B>
    <B><B/><"*"/><"{"/><A/><"}"/></B>
    <B><B/><"*"/><"("/><")"/></B>
    <B><B/><"*"/><"["/><"]"/></B>
    <B><B/><"*"/><"{"/><"}"/></B>
    <B><n/></B>
    <B><"("/><A/><")"/></B>
    <B><"["/><A/><"]"/></B>
    <B><"{"/><A/><"}"/></B>
    <B><"("/><")"/></B>
    <B><"["/><"]"/></B>
    <B><"{"/><"}"/></B>
  </grammar>
  END
   }


=head2 printParseTree($$$)

Print a parse tree.

     Parameter  Description
  1  $grammar   Grammar
  2  $tree      Parse tree
  3  $indent    Optional indent level

B<Example:>


  if (1) {
    my $grammar = compileGrammar(<<END);
  A  A + B
  A  B
  B  B * C
  B  C
  C  n
  C  ( A )
  C  [ A ]
  C  { A }
  C  ( )
  C  [ ]
  C  { }
  END

    ok printGrammar($grammar) eq <<END;
      Rule  Expandable  Expansion
   1     0  A           A          +  B
   2     1  A           B
   3     2  B           B          *  n
   4     3  B           B          *  (  A  )
   5     4  B           B          *  [  A  ]
   6     5  B           B          *  {  A  }
   7     6  B           B          *  (  )
   8     7  B           B          *  [  ]
   9     8  B           B          *  {  }
  10     9  B           n
  11    10  B           (          A  )
  12    11  B           [          A  ]
  13    12  B           {          A  }
  14    13  B           (          )
  15    14  B           [          ]
  16    15  B           {          }
  END

    my $tree = parseWithGrammar($grammar, qw/( [ { }  ]  +  [ { n }  ] ) * [ n + n ]  /);

    ok 𝗽𝗿𝗶𝗻𝘁𝗣𝗮𝗿𝘀𝗲𝗧𝗿𝗲𝗲($grammar, $tree) eq <<END;
      Rule  Expandable         Terminal
   1     1  A
   2     4    B
   3    10      B
   4                           (
   5     0        A
   6     1          A
   7    11            B
   8                           [
   9     1              A
  10    15                B
  11                           {
  12                           }
  13                           ]
  14                           +
  15    11          B
  16                           [
  17     1            A
  18    12              B
  19                           {
  20     1                A
  21     9                  B
  22                           n
  23                           }
  24                           ]
  25                           )
  26                           *
  27                           [
  28     0      A
  29     1        A
  30     9          B
  31                           n
  32                           +
  33     9        B
  34                           n
  35                           ]
  END

    ok printParseTreeAsXml($grammar, $tree) eq <<END;
  <A rule="1">
    <B rule="4">
      <B rule="10">
        <"(" pos="0"/>
        <A rule="0">
          <A rule="1">
            <B rule="11">
              <"[" pos="1"/>
              <A rule="1">
                <B rule="15">
                  <"{" pos="2"/>
                  <"}" pos="3"/>
                </B>
              </A>
              <"]" pos="4"/>
            </B>
          </A>
          <"+" pos="5"/>
          <B rule="11">
            <"[" pos="6"/>
            <A rule="1">
              <B rule="12">
                <"{" pos="7"/>
                <A rule="1">
                  <B rule="9">
                    <n pos="8"/>
                  </B>
                </A>
                <"}" pos="9"/>
              </B>
            </A>
            <"]" pos="10"/>
          </B>
        </A>
        <")" pos="11"/>
      </B>
      <"*" pos="12"/>
      <"[" pos="13"/>
      <A rule="0">
        <A rule="1">
          <B rule="9">
            <n pos="14"/>
          </B>
        </A>
        <"+" pos="15"/>
        <B rule="9">
          <n pos="16"/>
        </B>
      </A>
      <"]" pos="17"/>
    </B>
  </A>
  END

    ok printGrammarAsXml($grammar) eq <<END
  <grammar>
    <A><A/><"+"/><B/></A>
    <A><B/></A>
    <B><B/><"*"/><n/></B>
    <B><B/><"*"/><"("/><A/><")"/></B>
    <B><B/><"*"/><"["/><A/><"]"/></B>
    <B><B/><"*"/><"{"/><A/><"}"/></B>
    <B><B/><"*"/><"("/><")"/></B>
    <B><B/><"*"/><"["/><"]"/></B>
    <B><B/><"*"/><"{"/><"}"/></B>
    <B><n/></B>
    <B><"("/><A/><")"/></B>
    <B><"["/><A/><"]"/></B>
    <B><"{"/><A/><"}"/></B>
    <B><"("/><")"/></B>
    <B><"["/><"]"/></B>
    <B><"{"/><"}"/></B>
  </grammar>
  END
   }


=head2 printParseTreeAsBrackets($$$)

Print a parse tree as XML.

     Parameter  Description
  1  $grammar   Grammar
  2  $tree      Parse tree
  3  $indent    Optional indent level

B<Example:>


  if (1) {
    my $grammar = compileGrammar(<<END);
  A  A + B
  A  B
  B  B * C
  B  C
  C  n
  C  D C
  D  ++
  D  --
  C  C E
  E  **
  E  //

  C  ( A )
  C  [ A ]
  C  { A }
  C  ( )
  C  [ ]
  C  { }

  C  D n
  END

    my $tree = parseWithGrammar($grammar, qw{n * (  ++ -- n ** //   + -- ++  n // ** )});

    ok 𝗽𝗿𝗶𝗻𝘁𝗣𝗮𝗿𝘀𝗲𝗧𝗿𝗲𝗲𝗔𝘀𝗕𝗿𝗮𝗰𝗸𝗲𝘁𝘀($grammar, $tree) eq <<END;
  A
    B
      B
        C n
        C
      B "*"
      C "("
        A
          A
            B
              C "++"
                C
                  C
                    C "--" n
                    C "**"
                  C "//"
                C
              C
            B
          A "+"
          B
            C "--"
              C
                C
                  C "++" n
                  C "//"
                C "**"
              C
            C
          B
        A ")"
      C
    B
  A
  END
   }


=head2 printParseTreeAsXml($$$)

Print a parse tree as XML.

     Parameter  Description
  1  $grammar   Grammar
  2  $tree      Parse tree
  3  $indent    Optional indent level

B<Example:>


  if (1) {
    my $grammar = compileGrammar(<<END);
  A  A + B
  A  B
  B  B * C
  B  C
  C  n
  C  ( A )
  C  [ A ]
  C  { A }
  C  ( )
  C  [ ]
  C  { }
  END

    ok printGrammar($grammar) eq <<END;
      Rule  Expandable  Expansion
   1     0  A           A          +  B
   2     1  A           B
   3     2  B           B          *  n
   4     3  B           B          *  (  A  )
   5     4  B           B          *  [  A  ]
   6     5  B           B          *  {  A  }
   7     6  B           B          *  (  )
   8     7  B           B          *  [  ]
   9     8  B           B          *  {  }
  10     9  B           n
  11    10  B           (          A  )
  12    11  B           [          A  ]
  13    12  B           {          A  }
  14    13  B           (          )
  15    14  B           [          ]
  16    15  B           {          }
  END

    my $tree = parseWithGrammar($grammar, qw/( [ { }  ]  +  [ { n }  ] ) * [ n + n ]  /);

    ok printParseTree($grammar, $tree) eq <<END;
      Rule  Expandable         Terminal
   1     1  A
   2     4    B
   3    10      B
   4                           (
   5     0        A
   6     1          A
   7    11            B
   8                           [
   9     1              A
  10    15                B
  11                           {
  12                           }
  13                           ]
  14                           +
  15    11          B
  16                           [
  17     1            A
  18    12              B
  19                           {
  20     1                A
  21     9                  B
  22                           n
  23                           }
  24                           ]
  25                           )
  26                           *
  27                           [
  28     0      A
  29     1        A
  30     9          B
  31                           n
  32                           +
  33     9        B
  34                           n
  35                           ]
  END

    ok 𝗽𝗿𝗶𝗻𝘁𝗣𝗮𝗿𝘀𝗲𝗧𝗿𝗲𝗲𝗔𝘀𝗫𝗺𝗹($grammar, $tree) eq <<END;
  <A rule="1">
    <B rule="4">
      <B rule="10">
        <"(" pos="0"/>
        <A rule="0">
          <A rule="1">
            <B rule="11">
              <"[" pos="1"/>
              <A rule="1">
                <B rule="15">
                  <"{" pos="2"/>
                  <"}" pos="3"/>
                </B>
              </A>
              <"]" pos="4"/>
            </B>
          </A>
          <"+" pos="5"/>
          <B rule="11">
            <"[" pos="6"/>
            <A rule="1">
              <B rule="12">
                <"{" pos="7"/>
                <A rule="1">
                  <B rule="9">
                    <n pos="8"/>
                  </B>
                </A>
                <"}" pos="9"/>
              </B>
            </A>
            <"]" pos="10"/>
          </B>
        </A>
        <")" pos="11"/>
      </B>
      <"*" pos="12"/>
      <"[" pos="13"/>
      <A rule="0">
        <A rule="1">
          <B rule="9">
            <n pos="14"/>
          </B>
        </A>
        <"+" pos="15"/>
        <B rule="9">
          <n pos="16"/>
        </B>
      </A>
      <"]" pos="17"/>
    </B>
  </A>
  END

    ok printGrammarAsXml($grammar) eq <<END
  <grammar>
    <A><A/><"+"/><B/></A>
    <A><B/></A>
    <B><B/><"*"/><n/></B>
    <B><B/><"*"/><"("/><A/><")"/></B>
    <B><B/><"*"/><"["/><A/><"]"/></B>
    <B><B/><"*"/><"{"/><A/><"}"/></B>
    <B><B/><"*"/><"("/><")"/></B>
    <B><B/><"*"/><"["/><"]"/></B>
    <B><B/><"*"/><"{"/><"}"/></B>
    <B><n/></B>
    <B><"("/><A/><")"/></B>
    <B><"["/><A/><"]"/></B>
    <B><"{"/><A/><"}"/></B>
    <B><"("/><")"/></B>
    <B><"["/><"]"/></B>
    <B><"{"/><"}"/></B>
  </grammar>
  END
   }



=head2 Parser::LR::Grammar Definition


LR parser produced




=head3 Output fields


B<dfa> - DFA from grammar

B<expandables> - Expandable symbols

B<expansionStates> - States we can expand in

B<finalState> - Final state at end of parse

B<grammar> - Grammar from which the NFA was derived

B<longestRule> - Longest rule

B<nfa> - NFA from grammar

B<optionalExpandables> - Expandables that can expand to nothing

B<reducers> - The expandables an expandable can reduce to

B<rules> - Rules

B<startSymbol> - Start symbol

B<startTerminals> - Terminals that start rules

B<terminals> - Terminal symbols



=head2 Parser::LR::Rule Definition


A parsing rule




=head3 Output fields


B<expandable> - Symbol to expand

B<expansion> - Symbol expansion

B<print> - Rule printer

B<rule> - Rule number



=head1 Private Methods

=head2 printRule($)

Print a rule

     Parameter  Description
  1  $rule      Rule

=head2 longestMatchingRule($@)

Find the longest rule that completely matches the top of the stack.

     Parameter  Description
  1  $grammar   Grammar
  2  @stack     Stack

=head2 partialMatch($@)

Check whether we have a partial match with the top of the stack.

     Parameter  Description
  1  $grammar   Grammar
  2  @stack     Stack

=head2 reduceStackWithRule($$$)

Reduce by the specified rule and update the stack and parse tree to match.

     Parameter  Description
  1  $rule      Rule
  2  $stack     Stack
  3  $tree      Parse tree

=head2 parseWithGrammarAndLog($@)

Parse, using a compiled B<$grammar>, an array of terminals and return a log of parsing actions taken.

     Parameter   Description
  1  $grammar    Compiled grammar
  2  @terminals  Terminals to parse

=head2 printSymbolAsXml($)

Print a symbol in a form acceptable as Xml

     Parameter  Description
  1  $symbol    Symbol

=head2 printGrammarAsXml($$)

Print a B<$grammar> as XML.

     Parameter  Description
  1  $grammar   Grammar
  2  $indent    Indentation level

=head2 printParseTreeAndGrammarAsXml($$)

Print a parse tree produced from a grammar by L<parseWithGrammarAndLog> as XML.

     Parameter  Description
  1  $tree      Parse tree
  2  $grammar   Grammar


=head1 Index


1 L<compileGrammar|/compileGrammar> - Compile a grammar from a set of rules expressed as a string with one rule per line.

2 L<longestMatchingRule|/longestMatchingRule> - Find the longest rule that completely matches the top of the stack.

3 L<parseWithGrammar|/parseWithGrammar> - Parse, using a compiled B<$grammar>, an array of terminals and return a parse tree.

4 L<parseWithGrammarAndLog|/parseWithGrammarAndLog> - Parse, using a compiled B<$grammar>, an array of terminals and return a log of parsing actions taken.

5 L<partialMatch|/partialMatch> - Check whether we have a partial match with the top of the stack.

6 L<printGrammar|/printGrammar> - Print a B<$grammar>.

7 L<printGrammarAsXml|/printGrammarAsXml> - Print a B<$grammar> as XML.

8 L<printParseTree|/printParseTree> - Print a parse tree.

9 L<printParseTreeAndGrammarAsXml|/printParseTreeAndGrammarAsXml> - Print a parse tree produced from a grammar by L<parseWithGrammarAndLog> as XML.

10 L<printParseTreeAsBrackets|/printParseTreeAsBrackets> - Print a parse tree as XML.

11 L<printParseTreeAsXml|/printParseTreeAsXml> - Print a parse tree as XML.

12 L<printRule|/printRule> - Print a rule

13 L<printSymbolAsXml|/printSymbolAsXml> - Print a symbol in a form acceptable as Xml

14 L<reduceStackWithRule|/reduceStackWithRule> - Reduce by the specified rule and update the stack and parse tree to match.

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Parser::LR

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2019 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut



# Tests and documentation

sub test
 {my $p = __PACKAGE__;
  binmode($_, ":utf8") for *STDOUT, *STDERR;
  return if eval "eof(${p}::DATA)";
  my $s = eval "join('', <${p}::DATA>)";
  $@ and die $@;
  eval $s;
  $@ and die $@;
  1
 }

test unless caller;

1;
#podDocumentation
__DATA__
use Test::More tests => 30;

if (1) {
  my $g = compileGrammar(<<END, nosub=>1);
A  A + B
A  B
B  B * C
B  C
C  n
END

  ok $g->startSymbol eq q(A), q(Parser::LR);

  my sub tlmr(@)
   {my $r = longestMatchingRule($g, @_);
    if ($r)
     {delete $r->{print} if $r;
      my %r = $r->%*;
      #say STDERR nws(dump(\%r));
      }
    $r
   }

  is_deeply tlmr(qw(n)),     {expandable=>"C", expansion=>["n"],           rule=>4};
  is_deeply tlmr(qw(n + n)), {expandable=>"C", expansion=>["n"],           rule=>4};
  is_deeply tlmr(qw(A + B)), {expandable=>"A", expansion=>["A", "+", "B"], rule=>0};
  ok !tlmr(qw(n +));

  my sub trswr($@)
   {my ($rule, @stack) = @_;
    my @tree = (q()) x @stack;
    my $r = reduceStackWithRule($g->rules->[$rule], \@stack, \@tree);
    #say STDERR nws(dump(\@stack));
    \@stack
   }

  is_deeply trswr(0, qw(A + B)),   [qw(A)];
  is_deeply trswr(0, qw(n A + B)), [qw(n A)];
  is_deeply trswr(4, qw(B * n)),   [qw(B * C)];
  is_deeply trswr(3, qw(B * n)),   [qw(B * B)];                                 # There is no check that the rule actually applies

  my sub tpm(@)
   {my (@stack) = @_;
    my $r = partialMatch($g, @stack);
    $r
   }

  ok 3 == tpm qw(A + B);
  ok 2 == tpm qw(A +);
  ok 1 == tpm qw(A);
  ok 0 == tpm qw(A -);

  my sub tpwg(@)
   {my (@stack) = @_;
    my $r = parseWithGrammarAndLog($g, @stack) =~ s(\s+\Z) (\n)gsr;;
    owf($logFile, $r) if -e $logFile;
    $r
   }

  ok tpwg(qw(n)) eq <<END;
Terminal: n, stack: (empty)
  Accept first terminal: n to get stack: n
  Reduced in finals by rule 4, expandable: C, stack: C
  Reduced in finals by rule 3, expandable: B, stack: B
  Reduced in finals by rule 1, expandable: A, stack: A
  Parse tree is:
   Rule  Expandable  Terminal
1     1  A
2     3    B
3     4      C
4                    n
END

  ok tpwg(qw(n + n)) eq <<END;
Terminal: n, stack: (empty)
  Accept first terminal: n to get stack: n
Terminal: +, stack: n
  Reduced by rule 4, expandable: C, stack: C
  Reduced by rule 3, expandable: B, stack: B
  Reduced by rule 1, expandable: A, stack: A
  Accept + after 3 reductions to get: A +
Terminal: n, stack: A +
Accepted terminal: n as is, stack: A + n
  Reduced in finals by rule 4, expandable: C, stack: A + C
  Reduced in finals by rule 3, expandable: B, stack: A + B
  Reduced in finals by rule 0, expandable: A, stack: A
  Parse tree is:
   Rule  Expandable  Terminal
1     0  A
2     1    A
3     3      B
4     4        C
5                    n
6                    +
7     3    B
8     4      C
9                    n
END

  ok tpwg(qw(n * n + n)) eq <<END;
Terminal: n, stack: (empty)
  Accept first terminal: n to get stack: n
Terminal: *, stack: n
  Reduced by rule 4, expandable: C, stack: C
  Reduced by rule 3, expandable: B, stack: B
  Accept * after 2 reductions to get: B *
Terminal: n, stack: B *
Accepted terminal: n as is, stack: B * n
Terminal: +, stack: B * n
  Reduced by rule 4, expandable: C, stack: B * C
  Reduced by rule 2, expandable: B, stack: B
  Reduced by rule 1, expandable: A, stack: A
  Accept + after 3 reductions to get: A +
Terminal: n, stack: A +
Accepted terminal: n as is, stack: A + n
  Reduced in finals by rule 4, expandable: C, stack: A + C
  Reduced in finals by rule 3, expandable: B, stack: A + B
  Reduced in finals by rule 0, expandable: A, stack: A
  Parse tree is:
    Rule  Expandable  Terminal
 1     0  A
 2     1    A
 3     2      B
 4     3        B
 5     4          C
 6                    n
 7                    *
 8     4        C
 9                    n
10                    +
11     3    B
12     4      C
13                    n
END

  ok tpwg(qw(n * n + n * n)) eq <<END;
Terminal: n, stack: (empty)
  Accept first terminal: n to get stack: n
Terminal: *, stack: n
  Reduced by rule 4, expandable: C, stack: C
  Reduced by rule 3, expandable: B, stack: B
  Accept * after 2 reductions to get: B *
Terminal: n, stack: B *
Accepted terminal: n as is, stack: B * n
Terminal: +, stack: B * n
  Reduced by rule 4, expandable: C, stack: B * C
  Reduced by rule 2, expandable: B, stack: B
  Reduced by rule 1, expandable: A, stack: A
  Accept + after 3 reductions to get: A +
Terminal: n, stack: A +
Accepted terminal: n as is, stack: A + n
Terminal: *, stack: A + n
  Reduced by rule 4, expandable: C, stack: A + C
  Reduced by rule 3, expandable: B, stack: A + B
  Accept * after 2 reductions to get: A + B *
Terminal: n, stack: A + B *
Accepted terminal: n as is, stack: A + B * n
  Reduced in finals by rule 4, expandable: C, stack: A + B * C
  Reduced in finals by rule 2, expandable: B, stack: A + B
  Reduced in finals by rule 0, expandable: A, stack: A
  Parse tree is:
    Rule  Expandable  Terminal
 1     0  A
 2     1    A
 3     2      B
 4     3        B
 5     4          C
 6                    n
 7                    *
 8     4        C
 9                    n
10                    +
11     2    B
12     3      B
13     4        C
14                    n
15                    *
16     4      C
17                    n
END

  ok tpwg(qw(n + n * n + n)) eq <<END;
Terminal: n, stack: (empty)
  Accept first terminal: n to get stack: n
Terminal: +, stack: n
  Reduced by rule 4, expandable: C, stack: C
  Reduced by rule 3, expandable: B, stack: B
  Reduced by rule 1, expandable: A, stack: A
  Accept + after 3 reductions to get: A +
Terminal: n, stack: A +
Accepted terminal: n as is, stack: A + n
Terminal: *, stack: A + n
  Reduced by rule 4, expandable: C, stack: A + C
  Reduced by rule 3, expandable: B, stack: A + B
  Accept * after 2 reductions to get: A + B *
Terminal: n, stack: A + B *
Accepted terminal: n as is, stack: A + B * n
Terminal: +, stack: A + B * n
  Reduced by rule 4, expandable: C, stack: A + B * C
  Reduced by rule 2, expandable: B, stack: A + B
  Reduced by rule 0, expandable: A, stack: A
  Accept + after 3 reductions to get: A +
Terminal: n, stack: A +
Accepted terminal: n as is, stack: A + n
  Reduced in finals by rule 4, expandable: C, stack: A + C
  Reduced in finals by rule 3, expandable: B, stack: A + B
  Reduced in finals by rule 0, expandable: A, stack: A
  Parse tree is:
    Rule  Expandable  Terminal
 1     0  A
 2     0    A
 3     1      A
 4     3        B
 5     4          C
 6                    n
 7                    +
 8     2      B
 9     3        B
10     4          C
11                    n
12                    *
13     4        C
14                    n
15                    +
16     3    B
17     4      C
18                    n
END
 }

if (1) {
  my $grammar = compileGrammar(<<END, nosub=>1);
A  A + B
A  B
B  B * C
B  C
C  n
END

  my $tree = parseWithGrammar($grammar, qw(n * n + n * n));
  ok printParseTree($grammar, $tree) eq <<END;
    Rule  Expandable  Terminal
 1     0  A
 2     1    A
 3     2      B
 4     3        B
 5     4          C
 6                    n
 7                    *
 8     4        C
 9                    n
10                    +
11     2    B
12     3      B
13     4        C
14                    n
15                    *
16     4      C
17                    n
END
 }

if (1) {
  my $grammar = compileGrammar(<<END, nosub=>1);
A  A plus B
A  B
B  B times C
B  C
C  value
END

  my $tree = parseWithGrammar($grammar, qw(value times value plus value times value));

  ok printParseTreeAsXml($grammar, $tree) eq <<END;
<A rule="0">
  <A rule="1">
    <B rule="2">
      <B rule="3">
        <C rule="4">
          <value pos="0"/>
        </C>
      </B>
      <times pos="1"/>
      <C rule="4">
        <value pos="2"/>
      </C>
    </B>
  </A>
  <plus pos="3"/>
  <B rule="2">
    <B rule="3">
      <C rule="4">
        <value pos="4"/>
      </C>
    </B>
    <times pos="5"/>
    <C rule="4">
      <value pos="6"/>
    </C>
  </B>
</A>
END
 }

if (1) {
  my $grammar = compileGrammar(<<END, nosub=>1);
A  A + B
A  B
B  B * C
B  C
C  n
C  ( A )
C  [ A ]
END

  my $tree = parseWithGrammar $grammar, qw/ n * ( n + ( n * [ n ] ) )/, subsitute=>0;

  ok printParseTree($grammar, $tree) eq <<END;
    Rule  Expandable               Terminal
 1     1  A
 2     2    B
 3     3      B
 4     4        C
 5                                 n
 6                                 *
 7     5      C
 8                                 (
 9     0        A
10     1          A
11     3            B
12     4              C
13                                 n
14                                 +
15     3          B
16     5            C
17                                 (
18     1              A
19     2                B
20     3                  B
21     4                    C
22                                 n
23                                 *
24     6                  C
25                                 [
26     1                    A
27     3                      B
28     4                        C
29                                 n
30                                 ]
31                                 )
32                                 )
END
 }

if (1) {                                                                        #TcompileGrammar  #TprintGrammar  #TparseWithGrammar #TprintParseTree #TprintParseTreeAsXml
  my $grammar = compileGrammar(<<END);
A  A + B
A  B
B  B * C
B  C
C  n
C  ( A )
C  [ A ]
C  { A }
C  ( )
C  [ ]
C  { }
END

  ok printGrammar($grammar) eq <<END;
    Rule  Expandable  Expansion
 1     0  A           A          +  B
 2     1  A           B
 3     2  B           B          *  n
 4     3  B           B          *  (  A  )
 5     4  B           B          *  [  A  ]
 6     5  B           B          *  {  A  }
 7     6  B           B          *  (  )
 8     7  B           B          *  [  ]
 9     8  B           B          *  {  }
10     9  B           n
11    10  B           (          A  )
12    11  B           [          A  ]
13    12  B           {          A  }
14    13  B           (          )
15    14  B           [          ]
16    15  B           {          }
END

  my $tree = parseWithGrammar($grammar, qw/( [ { }  ]  +  [ { n }  ] ) * [ n + n ]  /);

  ok printParseTree($grammar, $tree) eq <<END;
    Rule  Expandable         Terminal
 1     1  A
 2     4    B
 3    10      B
 4                           (
 5     0        A
 6     1          A
 7    11            B
 8                           [
 9     1              A
10    15                B
11                           {
12                           }
13                           ]
14                           +
15    11          B
16                           [
17     1            A
18    12              B
19                           {
20     1                A
21     9                  B
22                           n
23                           }
24                           ]
25                           )
26                           *
27                           [
28     0      A
29     1        A
30     9          B
31                           n
32                           +
33     9        B
34                           n
35                           ]
END

  ok printParseTreeAsXml($grammar, $tree) eq <<END;
<A rule="1">
  <B rule="4">
    <B rule="10">
      <"(" pos="0"/>
      <A rule="0">
        <A rule="1">
          <B rule="11">
            <"[" pos="1"/>
            <A rule="1">
              <B rule="15">
                <"{" pos="2"/>
                <"}" pos="3"/>
              </B>
            </A>
            <"]" pos="4"/>
          </B>
        </A>
        <"+" pos="5"/>
        <B rule="11">
          <"[" pos="6"/>
          <A rule="1">
            <B rule="12">
              <"{" pos="7"/>
              <A rule="1">
                <B rule="9">
                  <n pos="8"/>
                </B>
              </A>
              <"}" pos="9"/>
            </B>
          </A>
          <"]" pos="10"/>
        </B>
      </A>
      <")" pos="11"/>
    </B>
    <"*" pos="12"/>
    <"[" pos="13"/>
    <A rule="0">
      <A rule="1">
        <B rule="9">
          <n pos="14"/>
        </B>
      </A>
      <"+" pos="15"/>
      <B rule="9">
        <n pos="16"/>
      </B>
    </A>
    <"]" pos="17"/>
  </B>
</A>
END

  ok printGrammarAsXml($grammar) eq <<END
<grammar>
  <A><A/><"+"/><B/></A>
  <A><B/></A>
  <B><B/><"*"/><n/></B>
  <B><B/><"*"/><"("/><A/><")"/></B>
  <B><B/><"*"/><"["/><A/><"]"/></B>
  <B><B/><"*"/><"{"/><A/><"}"/></B>
  <B><B/><"*"/><"("/><")"/></B>
  <B><B/><"*"/><"["/><"]"/></B>
  <B><B/><"*"/><"{"/><"}"/></B>
  <B><n/></B>
  <B><"("/><A/><")"/></B>
  <B><"["/><A/><"]"/></B>
  <B><"{"/><A/><"}"/></B>
  <B><"("/><")"/></B>
  <B><"["/><"]"/></B>
  <B><"{"/><"}"/></B>
</grammar>
END
 }

if (1) {
  my $grammar = compileGrammar(<<END);
A  A b
A  a
END

  my $t0 = parseWithGrammar($grammar, qw(a));

  ok printParseTreeAsBrackets($grammar, $t0) eq <<END;
A a
A
END

  my $t3 = parseWithGrammar($grammar, qw(a b b b));

  ok printParseTreeAsBrackets($grammar, $t3) eq <<END;
A
  A
    A
      A a
      A b
    A b
  A b
A
END
 }

if (1) {
  my $grammar = compileGrammar(<<END);
A  b A
A  a
END

  my $t0 = parseWithGrammar($grammar, qw(a));

  ok printParseTreeAsBrackets($grammar, $t0) eq <<END;
A a
A
END

  my $t3 = parseWithGrammar($grammar, qw(b b b a));

  ok printParseTreeAsBrackets($grammar, $t3) eq <<END;
A b
  A b
    A b
      A a
      A
    A
  A
A
END
 }

if (1) {                                                                        #TprintParseTreeAsBrackets
  my $grammar = compileGrammar(<<END);
A  A + B
A  B
B  B * C
B  C
C  n
C  D C
D  ++
D  --
C  C E
E  **
E  //

C  ( A )
C  [ A ]
C  { A }
C  ( )
C  [ ]
C  { }

C  D n
END

  my $tree = parseWithGrammar($grammar, qw{n * (  ++ -- n ** //   + -- ++  n // ** )});

  ok printParseTreeAsBrackets($grammar, $tree) eq <<END;
A
  B
    B
      C n
      C
    B "*"
    C "("
      A
        A
          B
            C "++"
              C
                C
                  C "--" n
                  C "**"
                C "//"
              C
            C
          B
        A "+"
        B
          C "--"
            C
              C
                C "++" n
                C "//"
              C "**"
            C
          C
        B
      A ")"
    C
  B
A
END
 }

done_testing;
