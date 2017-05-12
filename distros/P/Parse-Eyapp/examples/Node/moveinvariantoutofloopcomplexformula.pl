#!/usr/bin/perl -w
use strict;
use Parse::Eyapp;
use Parse::Eyapp::Treeregexp;

my $grammar = q{
  %right  '='
  %left   '-' '+'
  %left   '*' '/'
  %left   NEG
  %tree
  %{
  use Tail2; # See file examples/Tail2.pm in the distribution
  %}

  %%
  block:  exp <%name BLOCK + ';'> { $_[1] } 
  ;

  exp:      %name NUM   
              NUM 
          | %name WHILE
              'while'   exp  '{' block '}'
          | %name VAR  
              VAR 
          | %name ASSIGN        
              VAR '=' exp 
          | %name PLUS 
              exp '+' exp 
          | %name MINUS       
              exp '-' exp 
          | %name TIMES   
              exp '*' exp 
          | %name DIV     
              exp '/' exp 
          | %name UMINUS
              '-' exp %prec NEG 
          |   '(' exp ')'  { $_[2] } /* Let us simplify a bit the tree */
  ;

  %%
}; # end grammar

sub TERMINAL::info { $_[0]{attr} }
$Parse::Eyapp::Node::INDENT = 2;

our (@all,$moveinvariant, $condition, $assign, $before, $after);

Parse::Eyapp->new_grammar(
  input=>$grammar, 
  classname=>'Rule6',
  firstline=>7,
);
my $parser = Rule6->new();
my $program = "a =1000; c = 1; while (a) { c = c*a; b = 5; a = a-1 }\n";
my $t = $parser->Run(\$program);
my @output = split /\n/, $t->str;

my $p = Parse::Eyapp::Treeregexp->new( STRING => q{
  moveinvariant: BLOCK(
                   @prests, 
                   WHILE(VAR($b), BLOCK(@a, ASSIGN($x, NUM($e)), @c)), 
                   @possts
                 ) 
    => {
         my $assign = $ASSIGN;
         $BLOCK[1]->delete($ASSIGN);
         $BLOCK[0]->insert_before($WHILE, $assign);
       }
  },
);
$p->generate();
$moveinvariant->s($t);
my @output2 = split /\n/, $t->str; 

my ($node1, $node2);
format STDOUT_TOP =
                        PROGRAM
-------------------------------------------------------
@||||||||||||||||||||||||||||||||||||||||||||||||||||||
$program
-------------------------------------------------------
Before                     |    After
---------------------------|---------------------------
.

format STDOUT = 
@<<<<<<<<<<<<<<<<<<<<<<<<<<@|@<<<<<<<<<<<<<<<<<<<<<<<<<
$node1,                    '|',$node2
.

for (1..$#output) {
  $node1 = $output[$_];
  $node2 = $output2[$_];
  write;
}
