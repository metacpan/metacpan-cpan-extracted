#!/usr/bin/perl -w
use strict;
#use Test::More qw(no_plan);
use Test::More tests => 3;
use_ok qw(Parse::Eyapp) or exit;
use Data::Dumper;
use_ok qw( Parse::Eyapp::Treeregexp) or exit;

my $grammar = q{
%{
use Data::Dumper;
%}
%right  '='
%left   '-' '+'
%left   '*' '/'
%left   NEG
%tree

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
    or  do {
      local $/ = undef;
      $parser->YYData->{INPUT} = <STDIN>
    }
    or  return('',undef);

    $parser->YYData->{INPUT}=~s/^\s+//;

    for ($parser->YYData->{INPUT}) {
        s/^([0-9]+(?:\.[0-9]+)?)//
                and return('NUM',$1);
        s/^while//
                and return('while', 'while');
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

our ($moveinvariant);

# $Data::Dumper::Indent = 1;
Parse::Eyapp->new_grammar(
  input=>$grammar, 
  classname=>'Rule6',
  #outputfile => 'block.pm',
  firstline=>9,
);
my $parser = Rule6->new();
$parser->YYData->{INPUT} = "a =1000; c = 1; while (a) { c = c*a; b = 5; a = a-1 }\n";
my $t = $parser->Run;
#print "\n***** Before ******\n";
#print Dumper($t);

my $p = Parse::Eyapp::Treeregexp->new( STRING => q{
  moveinvariant: BLOCK(
                   @prests, 
                   WHILE(VAR($b), BLOCK(*, ASSIGN($x, NUM($e)), *)), 
                   @possts
                 ) 
    => {
         $::condition = $b;
         $::assign = $ASSIGN;
         $::before = \@W_0;
         $::after = \@W_1;
         my $assign = $ASSIGN;
         $BLOCK[1]->delete($ASSIGN);
         $BLOCK[0]->insert_before($WHILE, $assign);
       }
  },
  #OUTPUTFILE => 'main.pm',
  FIRSTLINE => 104,
);
$p->generate();
$moveinvariant->s($t);

my $expected_result = bless( {
  'children' => [
    bless( {
      'children' => [
        bless( { 'children' => [], 'attr' => 'a', 'token' => 'VAR' }, 'TERMINAL' ),
        bless( {
          'children' => [
            bless( { 'children' => [], 'attr' => '1000', 'token' => 'NUM' }, 'TERMINAL' )
          ]
        }, 'NUM' )
      ]
    }, 'ASSIGN' ),
    bless( {
      'children' => [
        bless( { 'children' => [], 'attr' => 'c', 'token' => 'VAR' }, 'TERMINAL' ),
        bless( {
          'children' => [
            bless( { 'children' => [], 'attr' => '1', 'token' => 'NUM' }, 'TERMINAL' )
          ]
        }, 'NUM' )
      ]
    }, 'ASSIGN' ),
    bless( {
      'children' => [
        bless( { 'children' => [], 'attr' => 'b', 'token' => 'VAR' }, 'TERMINAL' ),
        bless( {
          'children' => [
            bless( { 'children' => [], 'attr' => '5', 'token' => 'NUM' }, 'TERMINAL' )
          ]
        }, 'NUM' )
      ]
    }, 'ASSIGN' ),
    bless( {
      'children' => [
        bless( {
          'children' => [
            bless( { 'children' => [], 'attr' => 'a', 'token' => 'VAR' }, 'TERMINAL' )
          ]
        }, 'VAR' ),
        bless( {
          'children' => [
            bless( {
              'children' => [
                bless( { 'children' => [], 'attr' => 'c', 'token' => 'VAR' }, 'TERMINAL' ),
                bless( {
                  'children' => [
                    bless( {
                      'children' => [
                        bless( { 'children' => [], 'attr' => 'c', 'token' => 'VAR' }, 'TERMINAL' )
                      ]
                    }, 'VAR' ),
                    bless( {
                      'children' => [
                        bless( { 'children' => [], 'attr' => 'a', 'token' => 'VAR' }, 'TERMINAL' )
                      ]
                    }, 'VAR' )
                  ]
                }, 'TIMES' )
              ]
            }, 'ASSIGN' ),
            bless( {
              'children' => [
                bless( { 'children' => [], 'attr' => 'a', 'token' => 'VAR' }, 'TERMINAL' ),
                bless( {
                  'children' => [
                    bless( {
                      'children' => [
                        bless( { 'children' => [], 'attr' => 'a', 'token' => 'VAR' }, 'TERMINAL' )
                      ]
                    }, 'VAR' ),
                    bless( {
                      'children' => [
                        bless( { 'children' => [], 'attr' => '1', 'token' => 'NUM' }, 'TERMINAL' )
                      ]
                    }, 'NUM' )
                  ]
                }, 'MINUS' )
              ]
            }, 'ASSIGN' )
          ]
        }, 'BLOCK' )
      ]
    }, 'WHILE' )
  ]
}, 'BLOCK' );

is_deeply($t, $expected_result, 'two stars');
