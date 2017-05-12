#!/usr/bin/perl -w
use strict;
use Parse::Eyapp;
use Parse::Eyapp::Treeregexp;

sub TERMINAL::info { $_[0]{attr} }
{ no warnings; *VAR::info = *NUM::info = \&TERMINAL::info; }

my $grammar = q{
  %right  '='     # Lowest precedence
  %left   '-' '+' # + and - have more precedence than = Disambiguate a-b-c as (a-b)-c
  %left   '*' '/' # * and / have more precedence than + Disambiguate a/b/c as (a/b)/c
  %left   NEG     # Disambiguate -a-b as (-a)-b and not as -(a-b)
  %tree bypass    # Let us build an abstract syntax tree ...

  %%
  line: exp <%name EXPRESSION_LIST + ';'>  { $_[1] } /* list of expressions separated by ';' */
  ;

  /* The %name directive defines the name of the
     class to which the node being built belongs */
  exp:
      %name NUM  NUM            | %name VAR   VAR         | %name ASSIGN VAR '=' exp 
    | %name PLUS exp '+' exp    | %name MINUS exp '-' exp | %name TIMES  exp '*' exp 
    | %name DIV     exp '/' exp 
    | %no bypass UMINUS 
      '-' $exp %prec NEG 
    |   '(' exp ')'  
  ;

  %%
  sub _Error { die "Syntax error near ".($_[0]->YYCurval?$_[0]->YYCurval:"end of file")."\n" }

  sub _Lexer {
    my($parser)=shift; # The parser object

    for ($parser->YYData->{INPUT}) {
      s/^\s+//;
      $_ eq '' and return('',undef);
      s/^([0-9]+(?:\.[0-9]+)?)// and return('NUM',$1);
      s/^([A-Za-z][A-Za-z0-9_]*)// and return('VAR',$1);
      s/^(.)//s and return($1,$1);
    }
  }

  sub Run {
      my($self)=shift;
      $self->YYParse( yylex => \&_Lexer, yyerror => \&_Error, );
  }
}; # end grammar

our (@all, $uminus);

Parse::Eyapp->new_grammar( # Create the parser package/class
  input=>$grammar,    
  classname=>'Calc', # The name of the package containing the parser
  firstline=>7       # String $grammar starts at line 7 (for error diagnostics)
); 
my $parser = Calc->new();                # Create a parser
$parser->YYData->{INPUT} = "a=2*-3+b*0\n"; # Set the input
my $t = $parser->Run;                    # Parse it!

print "\n************\n".$t->str."\n************\n";

# Let us transform the tree. Define the tree-regular expressions ..
my $p = Parse::Eyapp::Treeregexp->new( STRING => q{
  { #  Example of support code
    my %Op = (PLUS=>'+', MINUS => '-', TIMES=>'*', DIV => '/');
  }
  constantfold: /TIMES|PLUS|DIV|MINUS/:bin(NUM, NUM) 
    => { 
      my $op = $Op{ref($_[0])};
      $NUM[0]->{attr} = eval  "$NUM[0]->{attr} $op $NUM[1]->{attr}";
      $_[0] = $NUM[0]; 
    }
  zero_times_whatever: TIMES(NUM, .) and { $NUM->{attr} == 0 } => { $_[0] = $NUM }
  whatever_times_zero: TIMES(., NUM) and { $NUM->{attr} == 0 } => { $_[0] = $NUM }
  uminus: UMINUS(NUM) => { $NUM->{attr} = -$NUM->{attr}; $_[0] = $NUM }
  },
  OUTPUTFILE=> 'main.pm'
);
$p->generate(); # Create the tranformations

$t->s(@all);    # constant folding and mult. by zero

print $t->str,"\n";

