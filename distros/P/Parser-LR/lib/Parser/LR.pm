#!/usr/bin/perl -I/home/phil/perl/cpan/DataNFA/lib/  -I/home/phil/perl/cpan/DataDFA/lib/
#-------------------------------------------------------------------------------
# Parser::LR - create and use an LR(1) parser.
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc., 2019
#-------------------------------------------------------------------------------
# podDocumentation
package Parser::LR;
require v5.26;
our $VERSION = 20191110;
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use Data::DFA;
use Data::NFA;

my $logFile = q(/home/phil/z/z/z/zzz.txt);                                      # Log printed results if developing

#D1 Create and use an LR(1) parser.                                             # Construct an LR(1) parser from a regular expression and use it to parse sequences of symbols.

sub parseGrammar($)                                                             #P Parse a B<$grammar>. A grammar consists of lines with comments indicated by #. Each line contains the symbol to be expanded and the symbols into which it can be expanded.  The start symbol is the first symbol defined.
 {my ($grammar) = @_;                                                           # Grammar
  my @lines = map {[split /\s+/]} split /\n/, $grammar =~ s(#.*?\n) (\n)gsr;    # Words from lines from grammar minus comments

  my @rules;                                                                    # {symbol}[rule] = a rule to expand symbol
  for my $line(@lines)                                                          # Lines of input
   {if (my ($symbol, @expansion) = @$line)                                      # Symbol to expand, expansion
     {push @rules, genHash(q(Parser::LR::Rule),                                 # A parsing rule
        symbol    => $symbol,                                                   # Symbol to expand
        expansion => [@expansion],                                              # Symbol expansion
        rule      => scalar @rules,                                             # Rule number
       );
     }
   }
  bless \@rules, q(Parser::LR::Grammar);                                        # Parsed grammar
 }

sub dfaFromGrammar($)                                                           #P Convert a B<grammar> into a L<Data::DFA>.
 {my ($grammar) = @_;                                                           # {symbol to expand => {expansion=>[]}}

  my $nfa       = bless {}, q(Data::NFA);                                       # NFA being constructed

  my $newState  = sub                                                           # Create a new state in the specified B<$nfa>
   {my $n       = scalar keys %$nfa;                                            # Current NFA size
    $$nfa{$n}   = Data::NFA::newNfaState;                                       # Create new state
    $n                                                                          # Number of state created
   };

  my $start = &$newState($nfa);                                                 # The expansions of each symbol are located from the start state by applying the symbol to be expanded
  my %symbols;                                                                  # Expansion symbols

  for my $rule(@$grammar)                                                       # For each symbol in the expansion
   {my $expansion = $rule->expansion;                                           # Expansion part of rule
    my $pos       = $start;                                                     # Start state for rule
    for my $e(@$expansion)                                                      # Transition to the next state on symbol being consumed
     {my $p = $pos;
      my $q = &$newState($nfa);
              $$nfa{$p}->jumps->{$q}++;
      my $r = $$nfa{$q}->transitions->{$e} = &$newState($nfa);
      $pos = $r;
     }
    $$nfa{$pos}->final = $rule;                                                 # Mark the final state with the sub to be called when we reduce by this rule
    $symbols{$rule->symbol}++;                                                  # Record expandable symbols
   }

  for my $i(sort keys %$nfa)                                                    # Add a jump to the symbol jump in state for each expandable symbol
   {my $state = $$nfa{$i};                                                      # Add a jump to the symbol jump in state for each expandable symbol
    my @t = sort keys $state->transitions->%*;                                  # Copy transitions because we are going to modify the transitions hash
     for my $e(@t)                                                              # Find expandable symbols being transitioned on
      {if (my $symbol = $symbols{$e})                                           # Expandable symbol
        {$state->jumps->{$start}++;                                              # Restart parse
         #$$nfa{0}->transitions->{$e} = $state->transitions->{$e};                # Continue parse
       }
     }
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

  my $startSymbol = $$grammar[0]->symbol;                                       # Locate the start symbol as the symbol expanded by the first rule

  genHash(q(Parser::LR),                                                        # LR parser produced
    grammar => $grammar,                                                        # Grammar from which the NFA was derived
    symbols =>\%symbols,                                                        # Symbols expanded by the NFA specification from which the NFA was derived
    nfa     => $nfa,                                                            # NFA from grammar
    dfa     => $dfa,                                                            # DFA from grammar
    start   => $startSymbol,                                                    # Start symbol
   );
 }

sub compileGrammar($)                                                           #S Compile a B<$grammar> defined by a set of rules
 {my ($rules) = @_;                                                             # Rules as a string
  dfaFromGrammar parseGrammar $rules;
 }

sub parseWithGrammar($@)                                                        # Parse, using a compiled B<$grammar>, an array of symbols and return an array of [Symbol, state, index in input stream or [parsed sub expression]].
 {my ($grammar, @symbols) = @_;                                                 # Compiled grammar, symbols to parse
  my $dfa = $grammar->dfa;                                                      # Dfa for grammar

  my @in;                                                                       # [symbol, state] : symbols parsed so far
  my $state = 0;                                                                # Initial state in parsing DFA

  for my $s(sort keys @symbols)                                                 # Symbols
   {my $symbol = $symbols[$s];                                                  # Symbol
    for my $t(0..1e3)                                                           # The maximum number of reductions we could hope to do
     {my $transitions = $dfa->{$state}->transitions;                            # Prevent autovivify of transitions in dfa
      if (defined(my $next = $transitions->{$symbol}))                          # Transition available on current symbol
       {push @in, [$symbol, $state = $next, $s];                                # Transition on symbol
        last;                                                                   # Continue parsing
       }
      elsif (my $rule = $dfa->{$state}->final)                                  # Reduce
       {my $e = $rule->expansion->@*;                                           # Number of items in rule expansion
        my @parsed = splice @in, -$e;                                           # Remove items recognized from the  input stack
        if (@in)
         {$state = $dfa->{$in[-1][1]}->transitions->{$rule->symbol};
         }
        else
         {$state = $dfa->{0}->transitions->{$rule->symbol};
#         $state = $dfa->{$state}->transitions->{$rule->symbol};
         }
        die dump(["Unexpected", $s, $symbol, $state]) unless $state;
        push @in, [$rule, $state, \@parsed];
       }
      else                                                                      # Unable to reduce or move
       {die dump(["Invalid input", $s, $symbol, $state]);
       }
     }
   }

  while(@in > 1)                                                                # Reduce after end of input
   {if (my $rule = $dfa->{$state}->final)
     {my @parsed = splice @in, -scalar($rule->expansion->@*);                   # Remove items recognized from the  input stack
      if (my $last = $in[-1])
       {$state = $dfa->{$$last[1]}->transitions->{$rule->symbol};
       }
      push @in, [$rule, $state, \@parsed];
     }
    elsif (@in > 1) {die dump(["Unparsed symbols remaining", @in]);}                  # Unable to parse trailing symbols
   }

  $in[0]                                                                        # Now a parse tree
 }

sub printGrammar($)                                                             # Print a B<$grammar>.
 {my ($grammar) = @_;                                                           # Grammar
  my @r;
  for my $rule($grammar->grammar->@*)                                           # Each rule
   {push @r, [$rule->rule, $rule->symbol, $rule->expansion->@*];
   }
  my $r = formatTable([@r], [qw(Rule Symbol Expansion)]);
  owf($logFile, $r) if -e $logFile;                                             # Log the result if requested
  $r
 }

sub printGrammarAsXml($;$)                                                      # Print a B<$grammar> as XML.
 {my ($grammar, $indent) = @_;                                                  # Grammar, indentation level
  my @r;
  my $space = q(  )x($indent//0);                                               # Indentation
  for my $rule($grammar->grammar->@*)                                           # Create an NFA for each rule as a choice of sequences
   {my $r = $rule->rule;
    my $s = $rule->symbol;
    push @r, qq($space  <$s id="$r">);                                          # Rule
    for my $e($rule->expansion->@*)                                             # Expansion
     {push @r, qq($space    <$e/>);
     }
    push @r, qq($space  </$s>);
   }
  my $r = join "\n", qq($space<grammar>), @r, qq($space</grammar>), '';         # Result
  owf($logFile, $r) if -e $logFile;                                             # Log the result if requested
  $r
 }

sub printParseTree($;$)                                                         # Print a parse tree produced by L<parseWithGrammar>.
 {my ($tree, $indent) = @_;                                                     # Parse tree, optional indent level
  my @r;

  my $print; $print = sub                                                       # Print sub tree
   {my ($t, $d, $i) = @_;                                                       # Tree, depth, index of non expandable symbol in input stream
    my ($rule, $state, $sub) = @$t;
    if (ref($rule) =~ m(\AParser::LR::Rule\Z)i)
     {push @r, [$rule->rule, (q(  )x$d).$rule->symbol];
      for my $s(@$sub)
       {$print->($s, $d+1);
       }
     }
    else
     {push @r, [q(), (q(  )x$d).$rule, $sub];
     }
   };

  return undef unless $tree;                                                    # Empty tree
  $print->($tree, $indent//0);
  my $r = formatTable([@r], [qw(Rule Symbol Input)]);
  $r =~ s( +\n) (\n)gs;
  owf($logFile, $r) if -e $logFile;                                             # Log the result if requested
  $r
 }

sub printParseTreeAsXml($;$)                                                    # Print a parse tree produced by L<parseWithGrammar> as XML.
 {my ($tree, $indent) = @_;                                                     # Parse tree, optional indent level
  my @r;

  my $print; $print = sub                                                       # Print sub tree
   {my ($t, $d, $i) = @_;                                                       # Tree, depth, index of non expandable symbol in input stream
    my ($rule, $state, $sub) = @$t;
    my $space      = q(  )x$d;
    if (ref($rule) =~ m(\AParser::LR::Rule\Z)i)
     {my $symbol   = $rule->symbol;
      my $r        = $rule->rule;
      push @r, qq($space<$symbol rule="$r">);
      for my $s(@$sub)
       {$print->($s, $d+1);
       }
      push @r, qq($space</$symbol>);
     }
    else
     {push @r, qq($space<$rule id="$sub"/>);
     }
   };

  return q() unless $tree;
  $print->($tree, $indent//0);
  my $r = join "\n", @r, '';
  owf($logFile, $r) if -e $logFile;                                             # Log the result if requested
  $r

 }

sub printParseTreeAndGrammarAsXml($$)                                           # Print a parse tree produced from a grammar by L<parseWithGrammar> as XML.
 {my ($tree, $grammar) = @_;                                                    # Parse tree, grammar
  my @r;

  push @r, q(<ParserLR>), q(  <parseTree>);
  push @r, printParseTreeAsXml($tree,    2).q(  </parseTree>);
  push @r, printGrammarAsXml  ($grammar, 1);
  push @r, q(</ParserLR>);
  join "\n", @r, '';
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

# Parser::LR - create and use an LR(1) parser.

=head1 Synopsis

=head1 Description



Version 20191110.


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Create and use an LR(1) parser.

Construct an LR(1) parser from a regular expression and use it to parse sequences of symbols.

=head2 compileGrammar($)

Compile a B<$grammar> defined by a set of rules

     Parameter  Description
  1  $rules     Rules as a string

B<Example:>


  if (1) {                                                                        
    my $g = 𝗰𝗼𝗺𝗽𝗶𝗹𝗲𝗚𝗿𝗮𝗺𝗺𝗮𝗿(<<END);
  A  A a
  A
  END
  
    my $t0 = parseWithGrammar($g, qw());
  
    ok !printParseTree($t0);
  
    ok !$t0;
  
    my $t1 = parseWithGrammar($g, qw(a));
  
    ok printParseTree($t1) eq <<END;
     Rule  Symbol  Input
  1     0  A
  2     1    A
  3          a         0
  END
  
    my $t3 = parseWithGrammar($g, qw(a a a));
  
    ok printParseTree($t3) eq <<END;
     Rule  Symbol   Input
  1     0  A
  2     0    A
  3     0      A
  4     1        A
  5              a      0
  6            a        1
  7          a          2
  END
  
    ok $g->dfa->print eq <<END;
     State  Final  Symbol  Target  Final
  1      0      1  A            1      0
  2      1         a            2      1
  3      2      1
  END
  
    ok $g->nfa->print eq <<END;
  Location  F  Transitions  Jumps
         0  1  undef        [1]
         1     { A => 2 }   [0]
         2     undef        [3]
         3     { a => 4 }   undef
         4  1  undef        undef
  END
  
    ok $g->printGrammar eq <<END;
     Rule  Symbol  Expansion
  1     0  A       A          a
  2     1  A
  END
   }
  

This is a static method and so should be invoked as:

  Parser::LR::compileGrammar


=head2 parseWithGrammar($@)

Parse, using a compiled B<$grammar>, an array of symbols and return an array of [Symbol, state, index in input stream or [parsed sub expression]].

     Parameter  Description
  1  $grammar   Compiled grammar
  2  @symbols   Symbols to parse

B<Example:>


  if (1) {                                                                        
    my $g = compileGrammar(<<END);
  A  a A
  A
  END
  
    my $tree = 𝗽𝗮𝗿𝘀𝗲𝗪𝗶𝘁𝗵𝗚𝗿𝗮𝗺𝗺𝗮𝗿($g, qw(a a a));
  
    ok printParseTree($tree) eq <<END;
     Rule  Symbol  Input
  1     1  A
  2          a         0
  3          a         1
  4          a         2
  END
  
    ok $g->start eq q(A);
  
    ok $g->dfa->print eq <<END;
     State  Final  Symbol  Target  Final
  1      0      1  a            1      1
  2      1      1  A            2      1
  3                a            1      1
  4      2      1
  END
  
    ok $g->nfa->print eq <<END;
  Location  F  Transitions  Jumps
         0  1  undef        [1]
         1     { a => 2 }   undef
         2     undef        [3]
         3     { A => 4 }   [0]
         4  1  undef        undef
  END
  
    ok $g->printGrammar eq <<END;
     Rule  Symbol  Expansion
  1     0  A       a          A
  2     1  A
  END
   }
  

=head2 printGrammar($)

Print a B<$grammar>.

     Parameter  Description
  1  $grammar   Grammar

B<Example:>


  if (1) {                                                                        
    my $g = compileGrammar(<<END);
  A  a A
  A  a
  END
  
    my $tree = parseWithGrammar($g, qw(a a));
  
    ok printParseTree($tree) eq <<END;
     Rule  Symbol  Input
  1     0  A
  2          a         0
  3     1    A
  4            a       1
  END
  
    ok $g->start eq q(A);
  
    ok $g->dfa->print eq <<END;
     State  Final  Symbol  Target  Final
  1      0      1  A            1      1
  2                a            0      1
  3      1      1
  END
  
    ok $g->nfa->print eq <<END;
  Location  F  Transitions  Jumps
         0     undef        [1, 5]
         1     { a => 2 }   undef
         2     undef        [3]
         3     { A => 4 }   [0]
         4  1  undef        undef
         5     { a => 6 }   undef
         6  1  undef        undef
  END
  
    ok $g->𝗽𝗿𝗶𝗻𝘁𝗚𝗿𝗮𝗺𝗺𝗮𝗿 eq <<END;
     Rule  Symbol  Expansion
  1     0  A       a          A
  2     1  A       a
  END
   }
  

=head2 printGrammarAsXml($$)

Print a B<$grammar> as XML.

     Parameter  Description
  1  $grammar   Grammar
  2  $indent    Indentation level

B<Example:>


  if (1) {                                                                        
    my $g = compileGrammar(<<END);
  A  B a
  B  B b
  B
  END
  
    my $tree = parseWithGrammar($g, qw(b b a));
  
    ok printParseTree($tree) eq <<END;
     Rule  Symbol   Input
  1     0  A
  2     1    B
  3     1      B
  4     2        B
  5              b      0
  6            b        1
  7          a          2
  END
  
  ok 𝗽𝗿𝗶𝗻𝘁𝗚𝗿𝗮𝗺𝗺𝗮𝗿𝗔𝘀𝗫𝗺𝗹($g) eq <<END;
  <grammar>
    <A id="0">
      <B/>
      <a/>
    </A>
    <B id="1">
      <B/>
      <b/>
    </B>
    <B id="2">
    </B>
  </grammar>
  END
  
    ok $g->start eq q(A);
   }
  

=head2 printParseTree($$)

Print a parse tree produced by L<parseWithGrammar>.

     Parameter  Description
  1  $tree      Parse tree
  2  $indent    Optional indent level

B<Example:>


  if (1) {                                                                        
    my $g = compileGrammar(<<END);
  A  a A b
  A  c
  END
  
    my $tree = parseWithGrammar($g, qw(a a c b b));
  
    ok 𝗽𝗿𝗶𝗻𝘁𝗣𝗮𝗿𝘀𝗲𝗧𝗿𝗲𝗲($tree) eq <<END;
     Rule  Symbol   Input
  1     0  A
  2          a          0
  3     0    A
  4            a        1
  5     1      A
  6              c      2
  7            b        3
  8          b          4
  END
  
  ok printGrammarAsXml($g) eq <<END;
  <grammar>
    <A id="0">
      <a/>
      <A/>
      <b/>
    </A>
    <A id="1">
      <c/>
    </A>
  </grammar>
  END
  
    ok $g->start eq q(A);
   }
  

=head2 printParseTreeAsXml($$)

Print a parse tree produced by L<parseWithGrammar> as XML.

     Parameter  Description
  1  $tree      Parse tree
  2  $indent    Optional indent level

B<Example:>


  if (1) {                                                                        
    my $g = compileGrammar(<<END);
  A  A a
  A  a
  END
  
    my $tree = parseWithGrammar($g, qw(a a a));
  
    ok printParseTree($tree) eq <<END;
     Rule  Symbol   Input
  1     0  A
  2     0    A
  3     1      A
  4              a      0
  5            a        1
  6          a          2
  END
  
    ok 𝗽𝗿𝗶𝗻𝘁𝗣𝗮𝗿𝘀𝗲𝗧𝗿𝗲𝗲𝗔𝘀𝗫𝗺𝗹($tree) eq <<END;
  <A rule="0">
    <A rule="0">
      <A rule="1">
        <a id="0"/>
      </A>
      <a id="1"/>
    </A>
    <a id="2"/>
  </A>
  END
  
    ok $g->start eq q(A);
  
    ok $g->dfa->print eq <<END;
     State  Final  Symbol  Target  Final
  1      0         A            1      0
  2                a            3      1
  3      1         a            2      1
  4      2      1
  5      3      1
  END
  
    ok $g->nfa->print eq <<END;
  Location  F  Transitions  Jumps
         0     undef        [1, 5]
         1     { A => 2 }   [0]
         2     undef        [3]
         3     { a => 4 }   undef
         4  1  undef        undef
         5     { a => 6 }   undef
         6  1  undef        undef
  END
  
    ok $g->printGrammar eq <<END;
     Rule  Symbol  Expansion
  1     0  A       A          a
  2     1  A       a
  END
   }
  

=head2 printParseTreeAndGrammarAsXml($$)

Print a parse tree produced from a grammar by L<parseWithGrammar> as XML.

     Parameter  Description
  1  $tree      Parse tree
  2  $grammar   Grammar


=head2 Parser::LR Definition


LR parser produced




=head3 Output fields


B<dfa> - DFA from grammar

B<grammar> - Grammar from which the NFA was derived

B<nfa> - NFA from grammar

B<start> - Start symbol

B<symbols> - Symbols expanded by the NFA specification from which the NFA was derived



=head2 Parser::LR::Rule Definition


A parsing rule




=head3 Output fields


B<expansion> - Symbol expansion

B<rule> - Rule number

B<symbol> - Symbol to expand



=head1 Private Methods

=head2 parseGrammar($)

Parse a B<$grammar>. A grammar consists of lines with comments indicated by #. Each line contains the symbol to be expanded and the symbols into which it can be expanded.  The start symbol is the first symbol defined.

     Parameter  Description
  1  $grammar   Grammar

=head2 dfaFromGrammar($)

Convert a B<grammar> into a L<Data::DFA>.

     Parameter  Description
  1  $grammar   {symbol to expand => {expansion=>[]}}


=head1 Index


1 L<compileGrammar|/compileGrammar> - Compile a B<$grammar> defined by a set of rules

2 L<dfaFromGrammar|/dfaFromGrammar> - Convert a B<grammar> into a L<Data::DFA>.

3 L<parseGrammar|/parseGrammar> - Parse a B<$grammar>.

4 L<parseWithGrammar|/parseWithGrammar> - Parse, using a compiled B<$grammar>, an array of symbols and return an array of [Symbol, state, index in input stream or [parsed sub expression]].

5 L<printGrammar|/printGrammar> - Print a B<$grammar>.

6 L<printGrammarAsXml|/printGrammarAsXml> - Print a B<$grammar> as XML.

7 L<printParseTree|/printParseTree> - Print a parse tree produced by L<parseWithGrammar>.

8 L<printParseTreeAndGrammarAsXml|/printParseTreeAndGrammarAsXml> - Print a parse tree produced from a grammar by L<parseWithGrammar> as XML.

9 L<printParseTreeAsXml|/printParseTreeAsXml> - Print a parse tree produced by L<parseWithGrammar> as XML.

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
use Test::More tests=>29;

#goto latestTest;

if (1) {                                                                        #TprintGrammar
  my $g = compileGrammar(<<END);
A  a A
A  a
END

  my $tree = parseWithGrammar($g, qw(a a));

  ok printParseTree($tree) eq <<END;
   Rule  Symbol  Input
1     0  A
2          a         0
3     1    A
4            a       1
END

  ok $g->start eq q(A);

  ok $g->dfa->print eq <<END;
   State  Final  Symbol  Target  Final
1      0      1  A            1      1
2                a            0      1
3      1      1
END

  ok $g->nfa->print eq <<END;
Location  F  Transitions  Jumps
       0     undef        [1, 5]
       1     { a => 2 }   undef
       2     undef        [3]
       3     { A => 4 }   [0]
       4  1  undef        undef
       5     { a => 6 }   undef
       6  1  undef        undef
END

  ok $g->printGrammar eq <<END;
   Rule  Symbol  Expansion
1     0  A       a          A
2     1  A       a
END
 }

if (1) {                                                                        #TparseWithGrammar
  my $g = compileGrammar(<<END);
A  a A
A
END

  my $tree = parseWithGrammar($g, qw(a a a));

  ok printParseTree($tree) eq <<END;
   Rule  Symbol  Input
1     1  A
2          a         0
3          a         1
4          a         2
END

  ok $g->start eq q(A);

  ok $g->dfa->print eq <<END;
   State  Final  Symbol  Target  Final
1      0      1  a            1      1
2      1      1  A            2      1
3                a            1      1
4      2      1
END

  ok $g->nfa->print eq <<END;
Location  F  Transitions  Jumps
       0  1  undef        [1]
       1     { a => 2 }   undef
       2     undef        [3]
       3     { A => 4 }   [0]
       4  1  undef        undef
END

  ok $g->printGrammar eq <<END;
   Rule  Symbol  Expansion
1     0  A       a          A
2     1  A
END
 }

if (1) {                                                                        #TprintParseTreeAsXml
  my $g = compileGrammar(<<END);
A  A a
A  a
END

  my $tree = parseWithGrammar($g, qw(a a a));

  ok printParseTree($tree) eq <<END;
   Rule  Symbol   Input
1     0  A
2     0    A
3     1      A
4              a      0
5            a        1
6          a          2
END

  ok printParseTreeAsXml($tree) eq <<END;
<A rule="0">
  <A rule="0">
    <A rule="1">
      <a id="0"/>
    </A>
    <a id="1"/>
  </A>
  <a id="2"/>
</A>
END

  ok $g->start eq q(A);

  ok $g->dfa->print eq <<END;
   State  Final  Symbol  Target  Final
1      0         A            1      0
2                a            3      1
3      1         a            2      1
4      2      1
5      3      1
END

  ok $g->nfa->print eq <<END;
Location  F  Transitions  Jumps
       0     undef        [1, 5]
       1     { A => 2 }   [0]
       2     undef        [3]
       3     { a => 4 }   undef
       4  1  undef        undef
       5     { a => 6 }   undef
       6  1  undef        undef
END

  ok $g->printGrammar eq <<END;
   Rule  Symbol  Expansion
1     0  A       A          a
2     1  A       a
END
 }

if (1) {                                                                        #TcompileGrammar
  my $g = compileGrammar(<<END);
A  A a
A
END

  my $t0 = parseWithGrammar($g, qw());

  ok !printParseTree($t0);

  ok !$t0;

  my $t1 = parseWithGrammar($g, qw(a));

  ok printParseTree($t1) eq <<END;
   Rule  Symbol  Input
1     0  A
2     1    A
3          a         0
END

  my $t3 = parseWithGrammar($g, qw(a a a));

  ok printParseTree($t3) eq <<END;
   Rule  Symbol   Input
1     0  A
2     0    A
3     0      A
4     1        A
5              a      0
6            a        1
7          a          2
END

  ok $g->dfa->print eq <<END;
   State  Final  Symbol  Target  Final
1      0      1  A            1      0
2      1         a            2      1
3      2      1
END

  ok $g->nfa->print eq <<END;
Location  F  Transitions  Jumps
       0  1  undef        [1]
       1     { A => 2 }   [0]
       2     undef        [3]
       3     { a => 4 }   undef
       4  1  undef        undef
END

  ok $g->printGrammar eq <<END;
   Rule  Symbol  Expansion
1     0  A       A          a
2     1  A
END
 }

if (1) {                                                                        #TprintParseTree
  my $g = compileGrammar(<<END);
A  a A b
A  c
END

  my $tree = parseWithGrammar($g, qw(a a c b b));

  ok printParseTree($tree) eq <<END;
   Rule  Symbol   Input
1     0  A
2          a          0
3     0    A
4            a        1
5     1      A
6              c      2
7            b        3
8          b          4
END

ok printGrammarAsXml($g) eq <<END;
<grammar>
  <A id="0">
    <a/>
    <A/>
    <b/>
  </A>
  <A id="1">
    <c/>
  </A>
</grammar>
END

  ok $g->start eq q(A);
 }

latestTest:;

if (1) {                                                                        #TprintGrammarAsXml
  my $g = compileGrammar(<<END);
A  B a
B  B b
B
END

  my $tree = parseWithGrammar($g, qw(b b a));

  ok printParseTree($tree) eq <<END;
   Rule  Symbol   Input
1     0  A
2     1    B
3     1      B
4     2        B
5              b      0
6            b        1
7          a          2
END

ok printGrammarAsXml($g) eq <<END;
<grammar>
  <A id="0">
    <B/>
    <a/>
  </A>
  <B id="1">
    <B/>
    <b/>
  </B>
  <B id="2">
  </B>
</grammar>
END

  ok $g->start eq q(A);
 }

done_testing;
=pod
printParseTreeAndGrammarAsXml  1
=cut
