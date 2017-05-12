#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use Test::More tests=>3;
use_ok qw( Parse::Eyapp );

my $ts = q{
# File TSPostfix1.eyp
	%right  '='
		%left   '-' '+'
		%left   '*' '/'
		%left   NEG

		%{
			use Data::Dumper;
			$Data::Dumper::Indent = 1;
			$Data::Dumper::Deepcopy = 1;
#$Data::Dumper::Deparse = 1;
			%}

			%metatree


				%defaultaction { $lhs->{t} = "$_[1]->{t} $_[3]->{t} $_[2]->{attr}"; }

			%%
				line: $exp  { $lhs->{t} = $exp->{t} } 
			;

exp:        NUM             
	    { $lhs->{t} = $_[1]->{attr}; }
	    |   VAR              
	    { $lhs->{t} = $_[1]->{attr}; }
	    |   VAR '=' exp  
	    { $lhs->{t} = "$_[1]->{attr} $_[3]->{t} $_[2]->{attr}"; }
	    |   exp '+' exp         
		    |   exp '-' exp        
		    |   exp '*' exp       
		    |   exp '/' exp      
		    |   '-' exp %prec NEG { $_[0]->{t} = "$_[2]->{t} NEG" }
	    |   '(' exp ')' %begin { $_[2] }      
	    ;

	    %%

		    sub _Error {
			    exists $_[0]->YYData->{ERRMSG}
			    and do {
				    print $_[0]->YYData->{ERRMSG};
				    delete $_[0]->YYData->{ERRMSG};
				    return;
			    };
			    my($token)=$_[0]->YYCurval;

			    my($what)= $token ? "input: '$token'" : "end of input";

			    die "Syntax error near $what.\n";
		    }

	    our $x;
	    sub _Lexer {
		    my($parser)=shift;

		    defined($x) or  return('',undef);

		    $x =~ s/^\s+//;

		    $x =~ s/^([0-9]+(?:\.[0-9]+)?)//   and return('NUM',$1);
		    $x =~ s/^([A-Za-z][A-Za-z0-9_]*)// and return('VAR',$1);
		    $x =~ s/^(.)//s                    and return($1,$1);
	    }

}; #end translation scheme

$Data::Dumper::Indent = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Deepcopy  = 1;
Parse::Eyapp->new_grammar(input=>$ts,
  classname=>'main', 
  firstline => 7, 
  #outputfile => 'main.pm'
);
my $parser = main->new();
our $x = "a = 2*-(3+b)";
  my $t = $parser->YYParse(yylex => \&_Lexer, yyerror => \&_Error) 
or die "Syntax Error analyzing input";
$t->translation_scheme;
#print Dumper($t);
is($t->{t}, "a 2 3 b + NEG * =", "postfix translation a = 2*-(3+b)");

$x = "a = -c/-(3-b)";
  $t = $parser->YYParse(yylex => \&_Lexer, yyerror => \&_Error) 
or die "Syntax Error analyzing input";
$t->translation_scheme;
is($t->{t}, "a c NEG 3 b - NEG / =", "postfix translation a = -c/-(3-b)");
#print Dumper($t);
