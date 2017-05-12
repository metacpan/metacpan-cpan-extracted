#!/usr/bin/perl -w
use strict;
#use Test::More qw(no_plan);
use Test::More tests => 3;
use_ok qw(Parse::Eyapp) or exit;
use_ok qw(Parse::Eyapp::Treeregexp) or exit;

my $grammar = q{
  %right  '='
  %left   '-' '+'
  %left   '*' '/'
  %left   NEG

  %{
    use Parse::Eyapp::Treeregexp;
    use Data::Dumper;
    $Data::Dumper::Indent = 1;
    $Data::Dumper::Deepcopy = 1;
    $Data::Dumper::Deparse = 1;
  %}

  %metatree

  %defaultaction { 
    if (@_==4) { # binary operations: 4 = lhs, left, operand, right
      $lhs->{t} = "$_[1]->{t} $_[3]->{t} $_[2]->{attr}";
      return  
    }
    die "Fatal Error. Unexpected input\n".Dumper(@_);
  }

  %%
  line: %name PROG
         exp <%name EXP + ';'> 
           { @{$lhs->{t}} = map { $_->{t}} ($lhs->child(0)->Children()); }
           
  ;

  exp:      %name NUM     NUM         { $lhs->{t} = $_[1]->{attr}; }    
          | %name VAR     VAR         { $lhs->{t} = $_[1]->{attr}; } 
          | %name ASSIGN  VAR '=' exp { $lhs->{t} = "$_[1]->{attr} $_[3]->{t} =" }
          | %name PLUS    exp '+' exp         
          | %name MINUS   exp '-' exp        
          | %name TIMES   exp '*' exp       
          | %name DIV     exp '/' exp      
          | %name UMINUS  '-' exp %prec NEG { $_[0]->{t} = "$_[2]->{t} NEG" }
          |               '(' exp ')' %begin { $_[2] } /* skip parenthesis */     
  ;

  %%

  sub _Error {
      my($token)=$_[0]->YYCurval;

      my($what)= $token ? "input: '$token'" : "end of input";
      die "Syntax error near $what.\n";
  }

  my $x; # Used for input

  sub _Lexer {
      my($parser)=shift;

      $x =~ s/^\s+//;
      return('',undef) if $x eq '';


      $x =~ s/^([0-9]+(?:\.[0-9]+)?)//   and return('NUM',$1);
      $x =~ s/^([A-Za-z][A-Za-z0-9_]*)// and return('VAR',$1);
      $x =~ s/^(.)//s                    and return($1,$1);
  }

  sub Run {
      my($self)=shift;

      $x = 'a=-2; b=2/a*-3';
      my $tree = $self->YYParse( yylex => \&_Lexer, yyerror => \&_Error,
        #yydebug => 0xFF
      );

      my $transform = Parse::Eyapp::Treeregexp->new( STRING => q{

        delete_code : CODE => { $delete_code->delete() }

        {
          sub not_semantic {
            my $self = shift;
            return  1 if $self->{token} eq $self->{attr};
            return 0;
          }
        }

        delete_tokens : TERMINAL and { not_semantic($TERMINAL) } => { $delete_tokens->delete() }

        delete = delete_code delete_tokens;

        uminus: UMINUS(., NUM($x), .) => { $x->{attr} = -$x->{attr}; $_[0] = $NUM }

        constantfold: /TIMES|PLUS|DIV|MINUS/:bin(NUM($z), ., NUM($y)) 
           => { 
          $z->{attr} = eval  "$z->{attr} $W->{attr} $y->{attr}";
          $_[0] = $NUM[0]; 
        }

        commutative_add: PLUS($x, ., $y, .)  
          => { my $t = $x; $_[0]->child(0, $y); $_[0]->child(2, $t)}

        comasocfold: TIMES(DIV(NUM($x), ., $b), ., NUM($y)) 
           => { 
          $x->{attr} = $x->{attr} * $y->{attr};
          $_[0] = $DIV; 
        }

        zero_times: TIMES(NUM($x), ., .) and { $x->{attr} == 0 } => { $_[0] = $NUM }
        times_zero: TIMES(., ., NUM($x)) and { $x->{attr} == 0 } => { $_[0] = $NUM }

        algebraic_transformations = constantfold zero_times times_zero comasocfold;

      }, 
      #OUTPUTFILE => 'main.pm',
      SEVERITY => 0,
      NUMBERS => 0,
      );

      # Create the transformer
      $transform->generate();
      # Get the AST

      our ($uminus);
      $uminus->s($tree);

      our (@algebraic_transformations);
      $tree->s(@algebraic_transformations);
      #print Dumper($tree);

      #our ($commutative_add);
      #$commutative_add->s($tree);
      #print Dumper($tree);

      $tree->translation_scheme();
      
      our (@delete);
      $tree->s(@delete);
      #print Dumper($tree);

      my $expected_tree = bless( { 'children' => [
        bless( { 'children' => [
            bless( { 'children' => [
                bless( { 'children' => [], 'attr' => 'a', 'token' => 'VAR' }, 'TERMINAL' ),
                bless( { 'children' => [
                    bless( { 'children' => [], 'attr' => -2, 'token' => 'NUM' }, 'TERMINAL' )
                  ],
                  't' => -2
                }, 'NUM' )
              ],
              't' => 'a -2 ='
            }, 'ASSIGN' ),
            bless( { 'children' => [
                bless( { 'children' => [], 'attr' => 'b', 'token' => 'VAR' }, 'TERMINAL' ),
                bless( { 'children' => [
                    bless( { 'children' => [ 
                        bless( { 'children' => [], 'attr' => -6, 'token' => 'NUM' }, 'TERMINAL' )
                      ],
                      't' => -6
                    }, 'NUM' ),
                    bless( { 'children' => [
                        bless( { 'children' => [], 'attr' => 'a', 'token' => 'VAR' }, 'TERMINAL' )
                      ],
                      't' => 'a'
                    }, 'VAR' )
                  ],
                  't' => '-6 a /'
                }, 'DIV' )
              ],
              't' => 'b -6 a / ='
            }, 'ASSIGN' )
          ]
        }, 'EXP' )
      ],
      't' => [ 'a -2 =', 'b -6 a / =' ]
    }, 'PROG' );
    is_deeply($tree, $expected_tree, "index bug");
  } #  sub Run
}; # grammar

my $p = Parse::Eyapp->new_grammar(
  input=>$grammar,
  classname=>'main',
  firstline => 9,
  #outputfile => 'main.pm'
);

die $p->Warnings."\nSolve Ambiguities. See file main.output\n"  if $p->Warnings;
my $parser = main->new();
$parser->Run();
