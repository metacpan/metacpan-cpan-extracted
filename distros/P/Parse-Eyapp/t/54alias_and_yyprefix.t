#!/usr/bin/perl -w
use strict;
use Test::More tests=>8;
use_ok qw(Parse::Eyapp) or exit;

use Data::Dumper;

my $grammar = q{
  %prefix R::S::

  %right  '='
  %left   '-' '+'
  %left   '*' '/'
  %left   NEG
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

  sub _Error {
          exists $_[0]->YYData->{ERRMSG}
      and do {
          print $_[0]->YYData->{ERRMSG};
          delete $_[0]->YYData->{ERRMSG};
          return;
      };
      print "Syntax error.\n";
  }

  sub _Lexer {
      my($parser)=shift;

          $parser->YYData->{INPUT}
      or  $parser->YYData->{INPUT} = <STDIN>
      or  return('',undef);

      $parser->YYData->{INPUT}=~s/^\s+//;

      for ($parser->YYData->{INPUT}) {
          s/^([0-9]+(?:\.[0-9]+)?)//
                  and return('NUM',$1);
          s/^([A-Za-z][A-Za-z0-9_]*)//
                  and return('VAR',$1);
          s/^(.)//s
                  and return($1,$1);
      }
  }

  sub Run {
      my($self)=shift;
      $self->YYParse( yylex => \&_Lexer, yyerror => \&_Error, 
          #yydebug =>0xFF
        );
  }
}; # end grammar


Parse::Eyapp->new_grammar(
  input=>$grammar, 
  classname=>'Alias', 
  #firstline =>7,
  #outputfile => 'main',
);

my $parser = Alias->new();
$parser->YYData->{INPUT} = "a = -(2*3+5-1)\n";
my $t = $parser->Run;
can_ok('R::S::ASSIGN', 'VAR', 'exp');
can_ok('R::S::PLUS', 'left', 'right');
can_ok('R::S::MINUS', 'left', 'right');
can_ok('R::S::TIMES', 'left', 'right');
can_ok('R::S::DIV', 'left', 'right');


is($t->VAR->attr, 'a', 'alias accessor ok');
# $t is 
# R::S::ASSIGN(
#   R::S::TERMINAL,
#   R::S::UMINUS(
#      R::S::MINUS(
#         R::S::PLUS(R::S::TIMES(R::S::NUM,R::S::NUM),R::S::NUM),
#         R::S::NUM)))   

my $expected = bless( {
                 'children' => [
                                 bless( {
                                          'children' => [
                                                          bless( {
                                                                   'children' => [],
                                                                   'attr' => '2',
                                                                   'token' => 'NUM'
                                                                 }, 'R::S::NUM' ),
                                                          bless( {
                                                                   'children' => [],
                                                                   'attr' => '3',
                                                                   'token' => 'NUM'
                                                                 }, 'R::S::NUM' )
                                                        ]
                                        }, 'R::S::TIMES' ),
                                 bless( {
                                          'children' => [],
                                          'attr' => '5',
                                          'token' => 'NUM'
                                        }, 'R::S::NUM' )
                               ]
               }, 'R::S::PLUS' );

is_deeply($t->exp->exp->left, $expected, 'alias accessor ok');
#print $t->exp->exp->right->str."\n"; # 1
