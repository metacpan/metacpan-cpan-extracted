#!/usr/bin/perl -w
# Test YATW s
use strict;
use Parse::Eyapp;
use Parse::Eyapp::Treeregexp;

my $translationscheme = q{
  %token NUM = /([0-9]+(?:\.[0-9]+)?)/
  %token VAR = /([A-Za-z][A-Za-z0-9_]*)/

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
}; # end translation scheme

sub is_code {
  my $self = shift; # tree

  # $_[0] is the father, $_[1] the index
  if ((ref($self) eq 'CODE')) {
    splice(@{$_[0]->{children}}, $_[1], 1);
    return 1;
  }
  return 0;
}

Parse::Eyapp->new_grammar(
  input=>$translationscheme,
  classname=>'Calc', 
  firstline =>7,
); 
my $parser = Calc->new();                # Create the parser

$parser->YYPrompt("Give an expression (like -2*3): ");
$parser->slurp_file('', "\n");
print ${$parser->input}; # Set the input

my $t = $parser->YYParse;                # Parse it

exit(1) if $parser->YYNberr > 0;

print $t->str."\n";
my $p = Parse::Eyapp::YATW->new(PATTERN => \&is_code);
$p->s($t);

{ no warnings; # make attr info available only for this display
  local *TERMINAL::info = sub { $_[0]{attr} };
  print $t->str."\n";
}
