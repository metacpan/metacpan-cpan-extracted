#!/usr/bin/perl 
use strict;
use warnings;
#use Data::Dumper;
use Test::More tests=>4;
#use Test::More qw(no_plan);
use_ok qw(Parse::Eyapp) or exit;
use_ok qw(Parse::Eyapp::Treeregexp) or exit;

#$Data::Dumper::Indent = 1;

my $eyappprogram = q{
  %{
  #use Data::Dumper;
  %}

  %semantic token '=' '-' '+' '*' '/' 

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

  sub Error {
          exists $_[0]->YYData->{ERRMSG}
      and do {
          print $_[0]->YYData->{ERRMSG};
          delete $_[0]->YYData->{ERRMSG};
          return;
      };
      print "Syntax error.\n";
  }

  sub Lexer {
      my($parser)=shift;

      for ($parser->YYData->{INPUT}) {
          return('',undef) if $_ eq '';
          s/^\s+//;

          s/^([0-9]+(?:\.[0-9]+)?)//
                  and return('NUM',$1);
          s/^([A-Za-z][A-Za-z0-9_]*)//
                  and return('VAR',$1);
          s/^(\S)//s
                  and return($1,$1);
      }
      return('',undef) if $_ eq '';
  }

  sub Run {
      my($self)=shift;
      $self->YYParse( yylex => \&_Lexer, yyerror => \&_Error, 
          #yydebug =>0xFF
        );
  }
};

my $transformations = q{
  fold: /TIMES|PLUS|DIV|MINUS/(NUM($n), $op, NUM($m)) 
    => { 
      $op = $op->{attr};
      $n->{attr} = eval  "$n->{attr} $op $m->{attr}";
      $_[0] = $NUM[0]; # return true value
    }
  zero_times_whatever: TIMES(NUM($x), ., .) and { $x->{attr} == 0 } => { $_[0] = $NUM }
  whatever_times_zero: TIMES(., ., NUM($x)) and { $x->{attr} == 0 } => { $_[0] = $NUM }

  /* rules related with times */
  times_zero = zero_times_whatever whatever_times_zero;
};


#$Data::Dumper::Indent = 1;
Parse::Eyapp->new_grammar(
  input=>$eyappprogram, 
  classname=>'Rule9',
  #outputfile => 'Rule9.pm',
  firstline=>11,
);
my $parser = new Rule9(yyprefix => "Rule9::");
$parser->YYData->{INPUT} = "2*3+b*0";
my $t = $parser->YYParse( yylex => \&Rule9::Lexer, yyerror => \&Rule9::Error, 
		    #yydebug =>0xFF
		  );
#print "\n***** Before ******\n";
#print Dumper($t);

my $expected_tree = bless( {
  'children' => [
    bless( {
      'children' => [
        bless( {
          'children' => [
            bless( { 'children' => [], 'attr' => '2', 'token' => 'NUM' }, 'Rule9::TERMINAL' )
          ]
        }, 'Rule9::NUM' ),
        bless( { 'children' => [], 'attr' => '*', 'token' => '*' }, 'Rule9::TERMINAL' ),
        bless( {
          'children' => [
            bless( { 'children' => [], 'attr' => '3', 'token' => 'NUM' }, 'Rule9::TERMINAL' )
          ]
        }, 'Rule9::NUM' )
      ]
    }, 'Rule9::TIMES' ),
    bless( { 'children' => [], 'attr' => '+', 'token' => '+' }, 'Rule9::TERMINAL' ),
    bless( {
      'children' => [
        bless( {
          'children' => [
            bless( { 'children' => [], 'attr' => 'b', 'token' => 'VAR' }, 'Rule9::TERMINAL' )
          ]
        }, 'Rule9::VAR' ),
        bless( { 'children' => [], 'attr' => '*', 'token' => '*' }, 'Rule9::TERMINAL' ),
        bless( {
          'children' => [
            bless( { 'children' => [], 'attr' => '0', 'token' => 'NUM' }, 'Rule9::TERMINAL' )
          ]
        }, 'Rule9::NUM' )
      ]
    }, 'Rule9::TIMES' )
  ]
}, 'Rule9::PLUS' );
is_deeply($t, $expected_tree, "transformations with yyprefix and PREFIX");


my $p = Parse::Eyapp::Treeregexp->new( 
  STRING => $transformations,
  PACKAGE => "Transform4",
  #OUTPUTFILE => 'transformations.pm',
  PREFIX => "Rule9::",
  FIRSTLINE => 86,
)->generate();
{ 
  no warnings;
  $t->s(@Transform4::all);
}
#print "\n***** After ******\n";
#print Dumper($t);
$expected_tree = bless( { 'children' => [
      bless( { 'children' => [], 'attr' => 6, 'token' => 'NUM' }, 'Rule9::TERMINAL' ) ]
}, 'Rule9::NUM' );
is_deeply($t, $expected_tree, "tarnsformations with yyprefix and PREFIX");
