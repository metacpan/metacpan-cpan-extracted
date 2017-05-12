#!/usr/bin/perl -w
use strict;
use Data::Dumper;
#use Test::More qw(no_plan);
use Test::More tests=>3;
use_ok qw(Parse::Eyapp) or exit;

$Data::Dumper::Indent = 1;

my $eyappprogram = q{
  %{
  use Data::Dumper;
  sub build_node { 
    my $self = shift;
    my @children = @_;
    my @right = $self->YYRightside();
    my $var = $self->YYLhs;
    my $rule = $self->YYRuleindex();

    for(my $i = 0; $i < @right; $i++) {
      $_ = $right[$i];
      if ($self->YYIsterm($_)) {
        $children[$i] = bless { token => $_, attr => $children[$i] }, __PACKAGE__.'::TERMINAL';
      }
    }
    bless { 
            children => \@children, 
      info => "$var -> @right"
          }, __PACKAGE__."::${var}_$rule" 
  }
  %}
  %right  '='
  %left   '-' '+'
  %left   '*' '/'
  %left   NEG
  %defaultaction { build_node(@_) }

  %%
  line:   exp '\n'   { $_[1] } 
          | error '\n' { $_[0]->YYErrok; }
  ;

  exp:        NUM    
          |   VAR   
          |   VAR '=' exp         
          |   exp '+' exp         
          |   exp '-' exp        
          |   exp '*' exp       
          |   exp '/' exp      
          |   '-' exp %prec NEG 
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

          $parser->YYData->{INPUT} ne ''
      or  return('',undef);

      $parser->YYData->{INPUT}=~s/^[ \t]//;

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
      return $self->YYParse( yylex => \&_Lexer, yyerror => \&_Error, 
                            #yydebug =>0xFF
         );
  }
}; # end of eyappprogram

Parse::Eyapp->new_grammar(
  input=>$eyappprogram, 
  classname=>'Rule3',
  #outputfile => 'block.pm',
  firstline=>9,
);
my $parser = new Rule3();
$parser->YYData->{INPUT} = "a=2*3\n";
my $t = $parser->Run;

my $expected_tree = bless( {
  'info' => 'exp -> VAR = exp',
  'children' => [
    bless( { 'attr' => 'a', 'token' => 'VAR' }, 'Rule3::TERMINAL' ),
    bless( { 'attr' => '=', 'token' => '=' }, 'Rule3::TERMINAL' ),
    bless( {
      'info' => 'exp -> exp * exp',
      'children' => [
        bless( {
          'info' => 'exp -> NUM',
          'children' => [
            bless( { 'attr' => '2', 'token' => 'NUM' }, 'Rule3::TERMINAL' )
          ]
        }, 'Rule3::exp_3' ),
        bless( { 'attr' => '*', 'token' => '*' }, 'Rule3::TERMINAL' ),
        bless( {
          'info' => 'exp -> NUM',
          'children' => [ bless( { 'attr' => '3', 'token' => 'NUM' }, 'Rule3::TERMINAL' )
          ]
        }, 'Rule3::exp_3' )
      ]
    }, 'Rule3::exp_8' )
  ]
}, 'Rule3::exp_5' );

is_deeply($t, $expected_tree, "YYRightside YYRuleindex");

$parser->YYData->{INPUT} = "a=a*(b+2)\n";
$expected_tree = bless( {
  'info' => 'exp -> VAR = exp',
  'children' => [
    bless( { 'attr' => 'a', 'token' => 'VAR' }, 'Rule3::TERMINAL' ),
    bless( { 'attr' => '=', 'token' => '=' }, 'Rule3::TERMINAL' ),
    bless( {
      'info' => 'exp -> exp * exp',
      'children' => [
        bless( {
          'info' => 'exp -> VAR',
          'children' => [
            bless( { 'attr' => 'a', 'token' => 'VAR' }, 'Rule3::TERMINAL' )
          ]
        }, 'Rule3::exp_4' ),
        bless( { 'attr' => '*', 'token' => '*' }, 'Rule3::TERMINAL' ),
        bless( {
          'info' => 'exp -> exp + exp',
          'children' => [
            bless( {
              'info' => 'exp -> VAR',
              'children' => [
                bless( { 'attr' => 'b', 'token' => 'VAR' }, 'Rule3::TERMINAL' )
              ]
            }, 'Rule3::exp_4' ),
            bless( { 'attr' => '+', 'token' => '+' }, 'Rule3::TERMINAL' ),
            bless( {
              'info' => 'exp -> NUM',
              'children' => [
                bless( { 'attr' => '2', 'token' => 'NUM' }, 'Rule3::TERMINAL' )
              ]
            }, 'Rule3::exp_3' )
          ]
        }, 'Rule3::exp_6' )
      ]
    }, 'Rule3::exp_8' )
  ]
}, 'Rule3::exp_5' );
$t = $parser->Run;
is_deeply($t, $expected_tree, "YYRightside YYRuleindex");
