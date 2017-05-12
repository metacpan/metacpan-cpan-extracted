#!/usr/bin/perl -I../lib -w
use strict;
use Remote::Use
  host => 'http://orion.pcg.ull.es/~casiano/cpan',
  prefix => '/tmp/perl5lib/',
  command => 'wget -o /tmp/wget.log',
  commandoptions => '-O',
  cachefile => '/tmp/perl5lib/.orionhttp.installed.modules',
  #wgetoptions => '-q',
;
use Parse::Eyapp;
use Parse::Eyapp::Treeregexp;

sub TERMINAL::info {
  $_[0]{attr}
}

my $grammar = q{
  %right  '='     # Lowest precedence
  %left   '-' '+' # + and - have more precedence than = Disambiguate a-b-c as (a-b)-c
  %left   '*' '/' # * and / have more precedence than + Disambiguate a/b/c as (a/b)/c
  %left   NEG     # Disambiguate -a-b as (-a)-b and not as -(a-b)
  %tree           # Let us build an abstract syntax tree ...

  %%
  line: 
      exp <%name EXPRESION_LIST + ';'>  
        { $_[1] } /* list of expressions separated by ';' */
  ;

  /* The %name directive defines the name of the class to which the node being built belongs */
  exp:
      %name NUM  
      NUM            
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
    | '(' exp ')'  
        { $_[2] }  /* Let us simplify a bit the tree */
  ;

  %%
  sub _Error { die "Syntax error near ".($_[0]->YYCurval?$_[0]->YYCurval:"end of file")."\n" }

  sub _Lexer {
    my($parser)=shift; # The parser object

    for ($parser->YYData->{INPUT}) { # Topicalize
      m{\G\s+}gc;
      $_ eq '' and return('',undef);
      m{\G([0-9]+(?:\.[0-9]+)?)}gc and return('NUM',$1);
      m{\G([A-Za-z][A-Za-z0-9_]*)}gc and return('VAR',$1);
      m{\G(.)}gcs and return($1,$1);
    }
    return('',undef);
  }

  sub Run {
      my($self)=shift;
      $self->YYParse( yylex => \&_Lexer, yyerror => \&_Error, );
  }
}; # end grammar

our (@all, $uminus);

Parse::Eyapp->new_grammar( # Create the parser package/class
  input=>$grammar,    
  classname=>'Calc', # The name of the package containing the parser
  firstline=>7       # String $grammar starts at line 7 (for error diagnostics)
); 
my $parser = Calc->new();                # Create a parser
$parser->YYData->{INPUT} = "2*-3+b*0;--2\n"; # Set the input
my $t = $parser->Run;                    # Parse it!
local $Parse::Eyapp::Node::INDENT=2;
print "Syntax Tree:",$t->str;

# Let us transform the tree. Define the tree-regular expressions ..
my $p = Parse::Eyapp::Treeregexp->new( STRING => q{
    { #  Example of support code
      my %Op = (PLUS=>'+', MINUS => '-', TIMES=>'*', DIV => '/');
    }
    constantfold: /TIMES|PLUS|DIV|MINUS/:bin(NUM($x), NUM($y)) 
      => { 
        my $op = $Op{ref($bin)};
        $x->{attr} = eval  "$x->{attr} $op $y->{attr}";
        $_[0] = $NUM[0]; 
      }
    uminus: UMINUS(NUM($x)) => { $x->{attr} = -$x->{attr}; $_[0] = $NUM }
    zero_times_whatever: TIMES(NUM($x), .) and { $x->{attr} == 0 } => { $_[0] = $NUM }
    whatever_times_zero: TIMES(., NUM($x)) and { $x->{attr} == 0 } => { $_[0] = $NUM }
  },
  #OUTPUTFILE=> 'main.pm'
);
$p->generate(); # Create the tranformations

$t->s($uminus); # Transform UMINUS nodes
$t->s(@all);    # constant folding and mult. by zero

local $Parse::Eyapp::Node::INDENT=0;
print "\nSyntax Tree after transformations:\n",$t->str,"\n";
