#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use Parse::Eyapp;

my $translationscheme = q{
  %{
  # head code is available at tree construction time 
  use Data::Dumper;
  our %sym; # symbol table
  %}

  %prefix Calc::

  %defaultaction { 
     $lhs->{n} = eval " $left->{n} $_[2]->{attr} $right->{n} " 
  }

  %metatree

  %token NUM = /([0-9]+(?:\.[0-9]+)?)/
  %token VAR = /([A-Za-z][A-Za-z0-9_]*)/

  %right   '='
  %left   '-' '+'
  %left   '*' '/'

  %%
  line:       %name EXP  
                exp <+ ';'> /* Expressions separated by semicolons */ 
                  { $lhs->{n} = $_[1]->Last_child->{n} }
  ;

  exp:    
              %name PLUS  
                exp.left '+' exp.right 
          |   %name MINUS
                exp.left '-' exp.right    
          |   %name TIMES 
                exp.left '*' exp.right  
          |   %name DIV 
                exp.left '/' exp.right  
          |   %name NUM   
                $NUM          
                  { $lhs->{n} = $NUM->{attr} }
          |   '(' $exp ')'  %begin { $exp }       
          |   %name VAR
                $VAR                 
                  { $lhs->{n} = $sym{$VAR->{attr}}->{n} }
          |   %name ASSIGN
                $VAR '=' $exp         
                  { $lhs->{n} = $sym{$VAR->{attr}}->{n} = $exp->{n} }

  ;

  %%
}; # end translation scheme

sub Calc::TERMINAL::info { $_[0]->attr }

my $p = Parse::Eyapp->new_grammar(
  input=>$translationscheme,
  classname=>'main',
  #firstline => 6,
  #outputfile => 'main.pm'
);
die $p->qtables() if $p->Warnings;
my $parser = main->new();

$parser->YYPrompt("Write a sequence of semicolon separated arithmetic expressions: ");
$parser->slurp_file( '', "\n");

my $t = $parser->YYParse() or die "Syntax Error analyzing input";

$t->translation_scheme;

$Parse::Eyapp::Node::INDENT = 2;
my $treestring = $t->str;

$Data::Dumper::Indent = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Deepcopy  = 1;
our %sym;
my $symboltable = Dumper(\%sym);

print <<"EOR";
***********Tree*************
$treestring
******Symbol table**********
$symboltable
************Result**********
$t->{n}

EOR
