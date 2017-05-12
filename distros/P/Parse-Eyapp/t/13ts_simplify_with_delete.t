#!/usr/bin/perl -w
# This test shows that using the method Parse::Eyapp::Node::delete we can achieve 
# the node self destruction even if its'nt a node!

use strict;
use Test::More tests => 3;
use_ok qw( Parse::Eyapp );
use_ok qw( Parse::Eyapp::Treeregexp );
#use Data::Dumper;

#my $debug = 1;
my $translationscheme = q{
%{
# head code is available at tree construction time 
#use Data::Dumper;
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

sub not_semantic {
  my $self = shift;
  return  1 if ((ref($self) eq 'TERMINAL') and ($self->{token} eq $self->{attr}));
  return 0;
}

sub show_match {
  my $self = shift;

  print "Index: $_[1]\n";
  print "node:\n",Dumper($self);
  print "Father:\n",Dumper($_[0]);
}

sub not_useful {
  my $self = shift; # tree
  my $pat = $_[2];

  # is code
  if (ref($self) eq 'CODE') {
    $pat->delete();
    return 1;
  }

  if ((ref($self) eq 'TERMINAL') and ($self->{token} eq $self->{attr})) {
    #show_match($self, @_) if $debug;
    $pat->delete();
    return 1;
  }

  return 0;
}

Parse::Eyapp->new_grammar(
  input=>$translationscheme,
  classname=>'Calc', 
  firstline =>7,
  # outputfile => 'Calc.pm'
); 
my $parser = Calc->new();                # Create the parser

$parser->YYData->{INPUT} = "2*(3-3)\n";  # Set the input
my $t = $parser->Run;                    # Parse it

#$Data::Dumper::Indent = 1;
#$Data::Dumper::Terse = 1;
#$Data::Dumper::Deepcopy  = 1;
#print Dumper($t);                        # Show the tree

# Get the AST
my $p = Parse::Eyapp::YATW->new(PATTERN => \&not_useful);
$p->s($t);
#print Dumper($t);                        # Show the tree

my $expected_tree = bless( { 'children' => [
    bless( { 'children' => [
        bless( { 'children' => [
            bless( { 'children' => [], 'attr' => '2', 'token' => 'NUM' }, 'TERMINAL' )
          ]
        }, 'NUM' ),
        bless( { 'children' => [
            bless( { 'children' => [
                bless( { 'children' => [], 'attr' => '3', 'token' => 'NUM' }, 'TERMINAL' )
              ]
            }, 'NUM' ),
            bless( { 'children' => [
                bless( { 'children' => [], 'attr' => '3', 'token' => 'NUM' }, 'TERMINAL' )
              ]
            }, 'NUM' )
          ]
        }, 'MINUS' )
      ]
    }, 'TIMES' )
  ]
}, 'EXP' );

is_deeply($t, $expected_tree, "self-destruction of nodes with delete");
