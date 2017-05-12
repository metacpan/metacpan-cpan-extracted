#!/usr/bin/perl -w
# This test shows that using the method Parse::Eyapp::Node::delete we can achieve 
# the node self destruction even if its'nt a node!
# Furthermore we use treeregexp

use strict;
use Test::More tests => 3;
use_ok qw( Parse::Eyapp );
#use Parse::Eyapp;
use_ok qw( Parse::Eyapp::Treeregexp );
#use Parse::Eyapp::Treeregexp;
# use Data::Dumper;

my $debug = 0;
my $translationscheme = q{
%{
# head code is available at tree construction time 
# #use Data::Dumper;
%}

%defaultaction  { $lhs->{n} = $_[1]->{n} }
%metatree

%left   '-' '+'
%left   '*' 
%left   NEG

%%
line:       %name EXP  
              exp  
;

exp:    
            %name PLUS  
              exp.left '+'  exp.right 
	        { $lhs->{n} .= $left->{n} + $right->{n} }
        |   %name TIMES 
              exp.left '*' exp.right  
	        { $lhs->{n} = $left->{n} * $right->{n} }
        |   %name NUM   $NUM          
	        { $lhs->{n} = $NUM->{attr} }
        |   '(' $exp ')'  %begin { $exp }       
        |   %name MINUS
	      exp.left '-' exp.right    
	        { $lhs->{n} = $left->{n} - $right->{n} }

        |   %name UMINUS 
	      '-' $exp %prec NEG        
	        { $lhs->{n} = -$exp->{n} }
;

%%
# tail code is available at tree construction time 
sub _Error { die "Syntax error.\n"; }

sub _Lexer {
    my($parser)=shift;

    $parser->YYData->{INPUT} or  return('',undef);

    $parser->YYData->{INPUT}=~s/^\s*//;

    for ($parser->YYData->{INPUT}) {
        s/^([0-9]+(?:\.[0-9]+)?)// and return('NUM',$1);
        s/^([A-Za-z][A-Za-z0-9_]*)// and return('VAR',$1);
        s/^(.)// and return($1,$1);
        s/^\s*//;
    }
}

sub Run {
    my($self)=shift;
    return $self->YYParse( yylex => \&_Lexer, yyerror => \&_Error );
}
}; # end translation scheme

sub show_match {
  my $self = shift;

  print "Index: $_[1]\n";
#   print "node:\n",Dumper($self);
#   print "Father:\n",Dumper($_[0]);
}

my $transform = Parse::Eyapp::Treeregexp->new( STRING => q{

  delete_code : CODE => { $delete_code->delete() }

  {
    sub not_semantic {
      my $self = shift;
      return  1 if ((ref($self) eq 'TERMINAL') and ($self->{token} eq $self->{attr}));
      return 0;
    }
  }

  delete_tokens : TERMINAL and { not_semantic($TERMINAL) } => { 
    $delete_tokens->delete();
  }
  insert_child : TIMES(NUM(TERMINAL), NUM(TERMINAL)) => {
    my $b = Parse::Eyapp::Node->new( 'UMINUS(TERMINAL)', 
			       sub { $_[1]->{attr} = '4.5' });

    $insert_child->unshift($b);
  }
},
#OUTPUTFILE => 'main.pm'
)->generate();

Parse::Eyapp->new_grammar(
  input=>$translationscheme,
  classname=>'Calc', 
  firstline =>7,
  #outputfile => 'Calc.pm'
); 
my $parser = Calc->new();                # Create the parser

$parser->YYData->{INPUT} = "2*3\n";  # Set the input
my $t = $parser->Run;                # Parse it

# $Data::Dumper::Indent = 1;
# $Data::Dumper::Terse = 1;
# $Data::Dumper::Deepcopy  = 1;
# print Dumper($t);                        # Show the tree

# Get the AST
our ($delete_tokens, $delete_code);
$t->s($delete_tokens, $delete_code);

our $insert_child;
$insert_child->s($t);
# print Dumper($t);                        # Show the tree
my $expectedtree = bless( {
  'children' => [
    bless( { 'children' => [
        bless( { 'children' => [], 'attr' => '4.5' }, 'TERMINAL' )
      ]
    }, 'UMINUS' ),
    bless( { 'children' => [
        bless( { 'children' => [
            bless( { 'children' => [], 'attr' => '2', 'token' => 'NUM' }, 'TERMINAL' )
          ]
        }, 'NUM' ),
        bless( { 'children' => [
            bless( { 'children' => [], 'attr' => '3', 'token' => 'NUM' }, 'TERMINAL' )
          ]
        }, 'NUM' )
      ]
    }, 'TIMES' )
  ]
}, 'EXP' );

is_deeply($t, $expectedtree, "unshift in myself");
