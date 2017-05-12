#!/usr/bin/perl -w
use strict;
#use Test::More qw(no_plan);
use Test::More tests => 2;
use_ok qw(Parse::Eyapp) or exit;

my $grammar = q{
%{
#use Data::Dumper;
%}
%right  '='
%left   '-' '+'
%left   '*' '/'
%left   NEG
%tree

%%
line: exp  { $_[1] } 
;

exp:      %name NUM   
            NUM 
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

my %BinaryOperation = (PLUS=>'+', MINUS => '-', TIMES=>'*', DIV => '/');

sub constant_folding {
  my $left = $_[0]->child(0);
  my $right = $_[0]->child(1);

  defined $BinaryOperation{ref($_[0])}
    and $left->isa('NUM')
    and $right->isa('NUM') and do {
      my $leftnum = $left->child(0)->{attr};
      my $rightnum = $right->child(0)->{attr};
      my $op = $BinaryOperation{ref($_[0])};
      $_[0] = $left;
      $left->child(0)->{attr} = eval "$leftnum $op $rightnum";
      return 1;
    };
  return 0;
}

sub multiply_by_zero {
  return 0 unless $_[0]->isa('TIMES');
  return 1 if $_[0]->child(0)->isa('NUM') 
              and $_[0]->child(0)->child(0)->{attr} == 0
              and $_[0] = $_[0]->child(0); # action: new node is zero
  return 1 if $_[0]->child(1)->isa('NUM') 
              and $_[0]->child(1)->child(0)->{attr} == 0
              and $_[0] = $_[0]->child(1); # modify node: new node is zero
  return 0; # Is times but does not match: a *4 or a * b, etc.
}

#$Data::Dumper::Indent = 1;
Parse::Eyapp->new_grammar(input=>$grammar, classname=>'Rule6');
my $parser = new Rule6();
$parser->YYData->{INPUT} = "2*3+b*0\n";
my $t = $parser->Run;
$t->s(\&constant_folding, \&multiply_by_zero);
my $expected_result = bless( {
    'children' => [ bless( { 'children' => [], 'attr' => 6, 'token' => 'NUM' }, 'TERMINAL' ) ]
  }, 'NUM' );
is_deeply($t, $expected_result, 'hand made folding and multiply by zero');
