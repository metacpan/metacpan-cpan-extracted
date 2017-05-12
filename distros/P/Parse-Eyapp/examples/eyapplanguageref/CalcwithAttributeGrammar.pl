#!/usr/bin/perl -w
use strict;
use Parse::Eyapp;
use Data::Dumper;
use Language::AttributeGrammar;

my $grammar = q{
%{
# use Data::Dumper;
%}
%right  '='
%left   '-' '+'
%left   '*' '/'
%left   NEG
%tree bypass alias

%%
line: $exp  { $_[1] } 
;

exp:      
    %name NUM   
          $NUM 
	| %name VAR  
          $VAR 
	| %name ASSIGN        
          $VAR '=' $exp 
	| %name PLUS 
          exp.left '+' exp.right 
	| %name MINUS       
          exp.left '-' exp.right 
	| %name TIMES   
          exp.left '*' exp.right 
	| %name DIV     
          exp.left '/' exp.right 
	| %no bypass UMINUS
          '-' $exp %prec NEG 
  |   '(' $exp ')'  { $_[2] } /* Let us simplify a bit the tree */
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

        $parser->YYData->{INPUT}
    or  $parser->YYData->{INPUT} = <STDIN>
    or  return('',undef);

    $parser->YYData->{INPUT}=~s/^\s+//;

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
    $self->YYParse( yylex => \&_Lexer, yyerror => \&_Error, 
		    #yydebug =>0xFF
		  );
}
}; # end grammar


$Data::Dumper::Indent = 1;
Parse::Eyapp->new_grammar(
  input=>$grammar, 
  classname=>'Rule6', 
  firstline =>7,
  outputfile => 'Calc.pm',
);
my $parser = Rule6->new();
$parser->YYData->{INPUT} = "a = -(2*3+5-1)\n";
my $t = $parser->Run;
print "\n***** Before ******\n";
print $t->str."\n";
print Dumper($t);

my $attgram = new Language::AttributeGrammar <<'EOG';

# Compute the expression
NUM:    $/.val = { $<attr> }
TIMES:  $/.val = { $<left>.val * $<right>.val }
PLUS:   $/.val = { $<left>.val + $<right>.val }
MINUS:  $/.val = { $<left>.val - $<right>.val }
UMINUS: $/.val = { -$<exp>.val }
ASSIGN: $/.val = { $<exp>.val }
EOG

my $res = $attgram->apply($t, 'val');

$Data::Dumper::Indent = 1;
print "\n***** After ******\n";
print $t->str."\n";
print Dumper($t);
print Dumper($res);
