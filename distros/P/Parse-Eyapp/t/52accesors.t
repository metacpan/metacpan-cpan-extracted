#!/usr/bin/perl -w

use strict;
use Test::More tests=>3;
use_ok qw(Parse::Eyapp) or exit;

my $grammar = q{
%right  '='
%left   '-' '+'
%left   '*' '/'
%left   NEG
%tree alias

%%
line: exp  { $_[1] } 
;

like_prefix:
	  %name like_prefix
	   LIKE VAR.var ':'
	| %name like_prefix_null
	;

exp:      %name NUM   
            NUM { $_[1] }
	| %name VAR  
          VAR { $_[1] }
	| %name ASSIGN        
          like_prefix.like VAR.var '=' exp.exp
	| %name PLUS 
          exp.left '+' exp.right 
	| %name MINUS       
          exp.left '-' exp.right 
	| %name TIMES   
          exp.left '*' exp.right 
	| %name DIV     
          exp.left '/' exp.right 
	| %name UMINUS
          '-' exp.exp %prec NEG 
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
          s/^(like)//i
                  and return(uc($1),uc($1));
          s/^([A-Za-z][A-Za-z0-9_]*)//
                  and return('VAR',$1);
          s/^(.)//s
                  and return($1,$1);
      }
  }

  sub parse {
    my $p = shift;
    return $p->YYParse( yylex => \&_Lexer, yyerror => \&_Error, yydebug => 0x0 );
  }
}; # end grammar

Parse::Eyapp->new_grammar(input=>$grammar, classname=>'Calc');
my $p = Calc->new();
$p->YYData->{INPUT} = "like x: y = 2\n";
my $result = $p->parse();
ok($result->can('like'), 'accessor created');
is(eval { $result->like()->var()->{'attr'} }, 'x', 'accessors ok');

