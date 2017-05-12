#!/usr/bin/perl -w
# Test clean_tree
use strict;
use Test::More tests => 3;
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

sub is_syntactic_terminal {
  my $self = shift;

  return (ref($self) eq 'TERMINAL') and exists($self->{token}) and exists($self->{attr})
  and ($self->{token} eq $self->{attr});
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
$t->clean_tree(sub { (ref($_[0]) eq 'CODE') or is_syntactic_terminal($_[0]) });
#print Dumper($t);                        # Show the tree
my $expected_tree = bless( {
  'children' => [
    bless( {
      'children' => [
        bless( { 'children' => [] }, 'NUM' ),
        bless( { 'children' => [
            bless( { 'children' => [] }, 'NUM' ),
            bless( { 'children' => [] }, 'NUM' )
          ]
        }, 'MINUS' )
      ]
    }, 'TIMES' )
  ]
}, 'EXP' );
is_deeply($t, $expected_tree, "clean_tree");
