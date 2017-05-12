#!/usr/bin/perl -w
use strict;
#use Test::More qw(no_plan);
use Test::More tests => 9;
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
  block:  exp  { $_[1] } 
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
  #print $_[0]->YYData->{ERRMSG};
          delete $_[0]->YYData->{ERRMSG};
          die;
      };
      die "Syntax error near ".(($a = $_[0]->YYCurval)?"token $a":"end of file\n");
  }

  sub _Lexer {
      my($parser)=shift;

      defined($parser->YYData->{INPUT}) or  return('',undef);

      for ($parser->YYData->{INPUT}) {
          s/^\s+//;
          s/^([0-9]+(?:\.[0-9]+)?)// and return('NUM',$1);
          s/^while// and return('while', 'while');
          s/^([A-Za-z][A-Za-z0-9_]*)// and return('VAR',$1);
          s/^(\S)//s and return($1,$1);
          return('',undef);
      }
  }

  sub Run {
      my($self)=shift;
      $self->YYParse( yylex => \&_Lexer, yyerror => \&_Error, 
          #yydebug =>0xFF
        );
  }
}; # end grammar

Parse::Eyapp::Treeregexp->new( STRING => q{
  is_bin: /TIMES|PLUS|DIV|MINUS/i($n, $m) 
  zero_times_whatever: TIMES(NUM($x), .) and { $x->{attr} == 0 } 
  whatever_times_zero: TIMES(., NUM($x)) and { $x->{attr} == 0 }
})->generate();

our ($is_bin, $zero_times_whatever, $whatever_times_zero);
our @b = ($is_bin, $zero_times_whatever, $whatever_times_zero);

sub Rule6::test {
  my $parser = shift;
  my $input = $parser->YYData->{INPUT} = shift;
  my @expected = @_;

  my $t = $parser->Run;

  #print "\n***** Matching: Array context $input ******\n";
  my @m = $t->m(@b);
  my $i = 0;
  for my $n (@m) {
    my @names = map { $b[$_]->{NAME} } @{$n->{patterns}};
    my $class = ref($n->{node});
    my @patterns = @{$n->{patterns}};
    is "$class @names @patterns", $expected[$i++], "m: array context @patterns $input";
    #print "$class @names @patterns\n";
  }

  @m = ();
#  #print "\n***** Matching: scalar context $input ******\n";
#  my $f = $t->m(@b);
#  my $n;
#  push @m, $n while $n = $f->();
#  $i = 0;
#  for my $n (@m) {
#    my @patterns = $n->patterns;
#    my @names = map { $b[$_]->{NAME} } @patterns;
#    my $class = ref($n->node);
#    #print "$class @names @patterns\n";
#    is "$class @names @patterns", $expected[$i++], "m: scalar context @patterns $input";
#  }
}

# Syntax analysis
Parse::Eyapp->new_grammar(
  input=>$grammar, 
  classname=>'Rule6',
  #outputfile => 'match.pm',
  firstline=>9,
);

my $parser = Rule6->new();
$Data::Dumper::Indent = 1;
#$Data::Dumper::Deepcopy  = 1;

my @expected= (
'TIMES is_bin whatever_times_zero 0 2',
'TIMES is_bin whatever_times_zero 0 2'
);

$parser->test('2*0*0', @expected);

@expected= (
'TIMES is_bin whatever_times_zero 0 2',
'TIMES is_bin zero_times_whatever whatever_times_zero 0 1 2'
);
$parser->test('0*0*0', @expected);

@expected= (
'PLUS is_bin 0',
'TIMES is_bin zero_times_whatever whatever_times_zero 0 1 2',
'TIMES is_bin zero_times_whatever whatever_times_zero 0 1 2'
);
$parser->test('0*0+0*0', @expected);
