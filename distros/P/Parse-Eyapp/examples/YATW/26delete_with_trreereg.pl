#!/usr/bin/perl -w
use strict;
use Parse::Eyapp;
use Parse::Eyapp::Treeregexp;

my $debug = 0;
sub TERMINAL::info { $_[0]{attr} }
my $translationscheme = q{

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
    |   %name NUM   
        $NUM          
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
  use Tail2;
}; # end translation scheme

sub show_match {
  my $self = shift;

  print "Index: $_[1]\n";
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
)->generate();

Parse::Eyapp->new_grammar(
  input=>$translationscheme,
  classname=>'Calc', 
  firstline =>7,
); 
my $parser = Calc->new();                # Create the parser

my $input = "2*3\n";
print $input;
my $t = $parser->Run(\$input);
print $t->str."\n";                        # Show the tree
# Get the AST
our ($delete_tokens, $delete_code);
$t->s($delete_tokens, $delete_code);
print $t->str."\n";                        # Show the tree
our $insert_child;
$insert_child->s($t);
print $t->str."\n";                        # Show the tree
