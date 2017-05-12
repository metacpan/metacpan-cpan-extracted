#!/usr/bin/perl -w
use strict;
use Test::More tests => 5;
use_ok qw( Parse::Eyapp );
use_ok qw( Parse::Eyapp::Treeregexp );
#use Data::Dumper;

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


our (@all, $uminus);

Parse::Eyapp->new_grammar(
  input=>$translationscheme,
  classname=>'Calc', 
  firstline =>7,
  # outputfile => 'Calc.pm'
); 
my $parser = Calc->new();                # Create the parser

$parser->YYData->{INPUT} = "2*(3-3)\n";  # Set the input
my $t = $parser->Run;                    # Parse it
#print Dumper($t);                        # Show the tree

# Let us transform the tree. Define the tree-regular expressions ..
my $p = Parse::Eyapp::Treeregexp->new( STRING => q{
  {
    my %Op = (PLUS=>'+', MINUS => '-', TIMES=>'*');
  }
  constantfold: /TIMES|PLUS|MINUS/:bin(NUM($x), . , NUM($y)) 
     => { 
	  my $op = $Op{ref($_[0])};
	  $x->{attr} = eval  "$x->{attr} $op $y->{attr}";
	  $_[0] = $NUM[0]; 
	}
  uminus: UMINUS(., NUM($x)) => { $x->{attr} = -$x->{attr}; $_[0] = $NUM }
  zero_times_whatever: TIMES(NUM($x)) and { $x->{attr} == 0 } => { $_[0] = $NUM }
  whatever_times_zero: TIMES(., ., NUM($x)) and { $x->{attr} == 0 } => { $_[0] = $NUM }
  },
);
$p->generate(); # Create the tranformations
$uminus->s($t); # Transform UMINUS nodes
$t->s(@all);    # constant folding and mult. by zero
#print Dumper($t);
# Now $t holds the following tree:
# bless( {
#   'children' => [
#     bless( {
#       'children' => [
#         bless( { 'children' => [], 'attr' => 0, 'token' => 'NUM' }, 'TERMINAL' ),
#         sub { "DUMMY" }
#       ]
#     }, 'NUM' ),
#     sub { "DUMMY" }
#   ]
# }, 'EXP' );
# 
my @ch = $t->children;
my $expected_ch = bless( { 'children' => [], 'attr' => 0, 'token' => 'NUM' }, 'TERMINAL' );
is_deeply($ch[0]->child(0), $expected_ch, 'ts and treereg. Simplfying node');
is(ref($ch[0]->child(1)), 'CODE', 'ts and treereg. Code of child 0');
is(ref($ch[1]), 'CODE', 'ts and treereg. Associated code');



