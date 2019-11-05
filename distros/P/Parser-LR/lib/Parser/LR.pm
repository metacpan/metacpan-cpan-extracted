#!/usr/bin/perl -I/home/phil/perl/cpan/DataNFA/lib/  -I/home/phil/perl/cpan/DataDFA/lib/
#-------------------------------------------------------------------------------
# Parser::LR - create and use an LR(1) parser.
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc., 2019
#-------------------------------------------------------------------------------
# podDocumentation
package Parser::LR;
require v5.26;
our $VERSION = 20191031;
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use Data::DFA;
use Data::NFA;

#D1 Create and use an LR(1) parser.                                             # Construct an LR(1) parser from a regular expression and use it to parse sequences of symbols.

sub parseGrammar($)                                                             #P Parse a B<$grammar>. A grammar consists of lines with comments indicated by #. Each line contains the symbol to be expanded and the symbols into which it can be expanded.  The start symbol is the first symbol defined.
 {my ($grammar) = @_;                                                           # Grammar
  my @rules = map {[split /\s+/]} split /\n/, $grammar =~ s(#.*?\n) (\n)gsr;    # Words from lines from grammar minus comments
  my %rules;                                                                    # {symbol}[rule] = a rule to expand symbol
  for my $i(keys @rules)                                                        # Rules indexed
   {if (my ($symbol, @expansion) = $rules[$i]->@*)                              # Symbol to expand, expansion
     {$rules{$symbol}[$i] = genHash(q(Parser::LR::Rule),                        # A parsing rule
        symbol    => $symbol,                                                   # Symbol to expand
        expansion => [@expansion],                                              # Symbol expansion
        rule      => $i,                                                        # Rule number
       );
     }
   }
  bless \%rules, q(Parser::LR::Grammar);                                        # Parsed grammar
 }

sub dfaFromGrammar($)                                                           #P Convert a B<grammar> into a L<Data::DFA>.
 {my ($grammar) = @_;                                                           # {symbol to expand => {expansion=>[]}}

  my $nfa       = bless {}, q(Data::NFA);                                       # NFA being constructed

  my $newState  = sub                                                           # Create a new state in the specified B<$nfa>
   {my $n       = scalar keys %$nfa;                                            # Current NFA size
    $$nfa{$n}   = Data::NFA::newState;                                          # Create new state
    $n                                                                          # Number of state created
   };

  my $start = &$newState($nfa);                                                 # The expansions of each symbol are located from the start state by applying the symbol to be expanded
  my %symbols;                                                                  # Expansion symbols

  for my $symbol(sort keys %$grammar)                                           # Create an NFA for each rule as a choice of sequences
   {my $in = $$nfa{$start}->transitions->{$symbol} = &$newState($nfa);          # Jump in transition

    for my $rule($$grammar{$symbol}->@*)                                        # For each symbol in the expansion
     {my $expansion      = $rule->expansion;                                    # Expansion part of rule
      my $pos            = &$newState($nfa);                                    # Record start state for rule

      $$nfa{$in}->jumps->{$pos}++;                                              # Jump in point for symbol to the rule being expanded
      $pos = $$nfa{$pos}->transitions->{$_} = &$newState($nfa) for @$expansion; # Transition to the next state on symbol being consumed
      $$nfa{$pos}->final = $rule;                                               # Mark the final state with the sub to be called when we reduce by this rule
     }

    $symbols{$symbol}    = genHash(q(Parser::LR::Symbol),                       # Symbol definition
      in  => $in,                                                               # A state which does not consume any input and jumps to the start of all rules for this symbol
      end => (keys %$nfa) - 1,                                                  # The state in which the symbol expansion ends
     );
   }

  for my $state(values %$nfa)                                                   # Add a jump to the symbol jump in state for each expandable symbol
   {for my $e(keys $state->transitions->%*)                                     # Find expandable symbols being transitioned on
     {if (my $symbol = $symbols{$e})                                            # Expandable symbol
       {$state->jumps->{$symbol->in} = $e;                                      # Save and jump to rules for expandable symbol
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

  my $startSymbol = sub                                                         # Locate the start symbol as the symbol expanded by the first rule
   {for my $symbol(keys %$grammar)                                              # Each symbol
     {for my $rule($$grammar{$symbol}->@*)                                      # Each rule for that symbol
       {return $symbol unless $rule->rule;                                      # Symbol of first rule
       }
     }
   }->();

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
  my $state = $dfa->{0}->transitions->{$grammar->start};                        # Initial state in parsing DFA

  for my $s(keys @symbols)                                                      # Symbols
   {my $symbol = $symbols[$s];                                                  # Symbol
    for my $t(0..1e3)                                                           # The maximum number of reductions we could hope to do
     {my $transitions = $dfa->{$state}->transitions;                            # Prevent autovivify of transitions in dfa
      if (my $next = $transitions->{$symbol})                                   # Transition available on current symbol
       {push @in, [$symbol, $state = $next, $s];                                # Transition on symbol
        last;                                                                   # Continue parsing
       }
      elsif (my $rule = $dfa->{$state}->final)                                  # Reduce
       {my @parsed = splice @in, -scalar($rule->expansion->@*);                 # Remove items recognized from the  input stack
        if (@in)
         {$state = $dfa->{$in[-1][1]}->transitions->{$rule->symbol};
         }
        else
         {$state = $dfa->{0}->transitions->{$rule->symbol};
          $state = $dfa->{$state}->transitions->{$rule->symbol};
         }
        die "Invalid input" unless $state;
        push @in, [$rule->symbol, $state, \@parsed];
       }
      else                                                                      # Unable to reduce or move
       {die ["Unexpected", $symbol, $state];
       }
     }
   }

  while(@in > 1)                                                                # Reduce after end of input
   {if (my $rule = $dfa->{$state}->final)
     {my @parsed = splice @in, -scalar($rule->expansion->@*);                   # Remove items recognized from the  input stack
      if (my $last = $in[-1])
       {$state = $dfa->{$$last[1]}->transitions->{$rule->symbol};
       }
      push @in, [$rule->symbol, $state, \@parsed];
     }
    elsif (@in > 1) {die ["Unparsed symbols remaining", @in];}                  # Unable to parse trailing symbols
   }

  @in                                                                           # Now a parse tree
 }

sub printGrammar($)                                                             # Print a B<$grammar>
 {my ($grammar) = @_;                                                           # Grammar
  my @r;
  for my $symbol(sort keys $grammar->grammar->%*)                               # Create an NFA for each rule as a choice of sequences
   {for my $rule($grammar->grammar->{$symbol}->@*)                              # For each symbol in the expansion
     {push @r, [$rule->rule, $symbol, $rule->expansion->@*];
     }
   }
  formatTable([@r], [qw(Rule Symbol Expansion)]);
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



Version 20191031.


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
    my $g = 𝗰𝗼𝗺𝗽𝗶𝗹𝗲𝗚𝗿𝗮𝗺𝗺𝗮𝗿(<<END);                                                # Rule: Symbol expansion
  A  a A b
  A  c
  END
  
    my @tree = parseWithGrammar($g, qw(a a c b b));                               # Parse an array of symbols with the grammar
  
    is_deeply [@tree],                                                            # Parse tree
    [["A",          4,
       [["a",       1, 0],
        ["A",       3,
          [["a",    1, 1],
           ["A",    3,
             [["c", 5, 2]]],
           ["b",    4, 3]]],
        ["b",       4, 4],
      ],
    ]];
  
    ok $g->start eq q(A);                                                         # Start symbol
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
    my $g = compileGrammar(<<END);                                                # Rule: Symbol expansion
  A  a A b
  A  c
  END
  
    my @tree = 𝗽𝗮𝗿𝘀𝗲𝗪𝗶𝘁𝗵𝗚𝗿𝗮𝗺𝗺𝗮𝗿($g, qw(a a c b b));                               # Parse an array of symbols with the grammar
  
    is_deeply [@tree],                                                            # Parse tree
    [["A",          4,
       [["a",       1, 0],
        ["A",       3,
          [["a",    1, 1],
           ["A",    3,
             [["c", 5, 2]]],
           ["b",    4, 3]]],
        ["b",       4, 4],
      ],
    ]];
  
    ok $g->start eq q(A);                                                         # Start symbol
   }
  

=head2 printGrammar($)

Print a B<$grammar>

     Parameter  Description
  1  $grammar   Grammar


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



=head2 Parser::LR::Symbol Definition


Symbol definition




=head3 Output fields


B<end> - The state in which the symbol expansion ends

B<in> - A state which does not consume any input and jumps to the start of all rules for this symbol



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

5 L<printGrammar|/printGrammar> - Print a B<$grammar>

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
# podDocumentation
__DATA__
use Test::More tests=>18;

#goto latestTest;

if (1) {                                                                        # Right recursion
  my $g = compileGrammar(<<END);
A  a A
A  a
END

  my @tree = parseWithGrammar($g, qw(a a));
  is_deeply [@tree],
    [["A",       3,
       [["a",    1, 0],
        ["A",    3,
          [["a", 1, 1]]
        ]]
    ]];

  ok $g->start eq q(A);

  ok $g->dfa->print eq <<END;
   State  Final  Symbol  Target  Final
1      0         A            2      0
2      1      1  A            3      1
3                a            1      1
4      2         a            1      1
5      3      1
END

  ok $g->nfa->print eq <<END;
Location  F  Transitions  Jumps
       0     { A => 1 }   [1]
       1     undef        [2, 5]
       2     { a => 3 }   undef
       3     { A => 4 }   [1]
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

#latestTest:;

if (1) {                                                                        # Left recursion
  my $g = compileGrammar(<<END);
A  A a
A  a
END

  my @tree = parseWithGrammar($g, qw(a a a));
  is_deeply [@tree],
  [["A",          3,
    [["A",        2,
      [["A",      2,
        [[   "a", 4, 0]]],
          [  "a", 3, 1]]],
            ["a", 3, 2]],
  ]];


  ok $g->start eq q(A);

  ok $g->dfa->print eq <<END;
   State  Final  Symbol  Target  Final
1      0         A            1      0
2      1         A            2      0
3                a            4      1
4      2         a            3      1
5      3      1
6      4      1
END

  ok $g->nfa->print eq <<END;
Location  F  Transitions  Jumps
       0     { A => 1 }   [1]
       1     undef        [2, 5]
       2     { A => 3 }   [1]
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
latestTest:;
if (1) {                                                                        # Left recursion and nullity
  my $g = compileGrammar(<<END);
A  A a
A
END

  my @t0 = parseWithGrammar($g, qw());
  is_deeply [@t0], [];

  my @t1 = parseWithGrammar($g, qw(a));
  is_deeply [@t1],
    [["A", 3,
      [["A", 2, []],
       ["a", 3, 0]]
    ]];

  my @t3 = parseWithGrammar($g, qw(a a a));

  is_deeply [@t3],
   [["A", 3,
     [["A", 2,
       [["A", 2,
         [["A", 2, []],
        ["a", 3, 0]]],
      ["a", 3, 1]]],
    ["a", 3, 2]]
  ]];

  ok $g->dfa->print eq <<END;
   State  Final  Symbol  Target  Final
1      0         A            1      1
2      1      1  A            2      0
3      2         a            3      1
4      3      1
END

  ok $g->nfa->print eq <<END;
Location  F  Transitions  Jumps
       0     { A => 1 }   [1]
       1     undef        [2, 5]
       2     { A => 3 }   [1]
       3     { a => 4 }   undef
       4  1  undef        undef
       5  1  undef        undef
END

  ok $g->printGrammar eq <<END;
   Rule  Symbol  Expansion
1     0  A       A          a
2     1  A
END
 }

if (1) {
if (1) {                                                                        #TcompileGrammar #TparseWithGrammar
  my $g = compileGrammar(<<END);                                                # Rule: Symbol expansion
A  a A b
A  c
END

  my @tree = parseWithGrammar($g, qw(a a c b b));                               # Parse an array of symbols with the grammar

  is_deeply [@tree],                                                            # Parse tree
  [["A",          4,
     [["a",       1, 0],
      ["A",       3,
        [["a",    1, 1],
         ["A",    3,
           [["c", 5, 2]]],
         ["b",    4, 3]]],
      ["b",       4, 4],
    ],
  ]];

  ok $g->start eq q(A);                                                         # Start symbol
 }

  my $g = compileGrammar(<<END);
A  a A b
A  c
END
 }

done_testing;
