#!/usr/bin/env perl
use warnings;
use strict;
use Parse::Eyapp;

my $grammar = q{
  %prefix R::S::

  %right  '='
  %left   '-' '+'
  %left   '*' '/'
  %left   NEG

  %lexer {
    s/^\s+//;

    s/^([0-9]+(?:\.[0-9]+)?)// and return('NUM',$1);
    s/^([A-Za-z][A-Za-z0-9_]*)// and return('VAR',$1);
    s/^(.)// and return($1,$1);
  }

  %tree bypass alias

  %%
  line: $exp  { $_[1] } 
  ;

  exp:      
      %name NUM   
            $NUM 
    | %name VAR  
            $VAR 
    | %name ASSIGN        
            $VAR '=' $exp 
    | %name PLUS 
            exp.left '+' exp.right 
    | %name MINUS       
            exp.left '-' exp.right 
    | %name TIMES   
            exp.left '*' exp.right 
    | %name DIV     
            exp.left '/' exp.right 
    | %no bypass UMINUS
            '-' $exp %prec NEG 
    |   '(' exp ')'  { $_[2] } /* Let us simplify a bit the tree */
  ;

  %%
}; # end grammar

Parse::Eyapp->new_grammar(
  input=>$grammar, 
  classname=>'Alias', 
  firstline =>7,
  outputfile => 'main',
);
my $parser = Alias->new();
my $input = shift || "a = -(2*3+5-1)\n";
$parser->input(\$input);
my $t = $parser->YYParse();

exit(1) if $parser->YYNberr > 0;

$Parse::Eyapp::Node::INDENT=0;
print $t->VAR->str."\n";             # a 
print "***************\n";
print $t->exp->exp->left->str."\n";  # 2*3+5
print "***************\n";
print $t->exp->exp->right->str."\n"; # 1
