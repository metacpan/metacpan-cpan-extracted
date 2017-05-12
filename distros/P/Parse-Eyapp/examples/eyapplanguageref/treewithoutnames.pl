#!/usr/bin/perl -w
use strict;
use Parse::Eyapp;
use Parse::Eyapp::Treeregexp;

sub TERMINAL::info { $_[0]{attr} }

my $grammar = q{
  %right  '='     # Lowest precedence
  %left   '-' '+' # + and - have more precedence than = Disambiguate a-b-c as (a-b)-c
  %left   '*' '/' # * and / have more precedence than + Disambiguate a/b/c as (a/b)/c
  %left   NEG     # Disambiguate -a-b as (-a)-b and not as -(a-b)
  %tree           # Let us build an abstract syntax tree ...

  %%
  line: exp <+ ';'>  { $_[1] } /* list of expressions separated by ';' */
  ;

  exp:
       NUM           |   VAR       | VAR '=' exp 
    | exp '+' exp    | exp '-' exp |  exp '*' exp 
    | exp '/' exp 
    | '-' exp %prec NEG 
    |   '(' exp ')'  { $_[2] }
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
  firstline=>9,      # String $grammar starts at line 9 (for error diagnostics)
  outputfile=>'treewithoutnames'
); 
my $parser = Calc->new();                # Create a parser
$parser->YYData->{INPUT} = "a=2*b\n"; # Set the input
my $t = $parser->Run;                    # Parse it!

print "\n************\n".$t->str."\n************\n";

