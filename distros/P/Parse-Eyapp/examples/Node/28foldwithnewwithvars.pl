#!/usr/bin/perl -w
use strict;
use Test::More tests => 3;
use_ok qw(Parse::Eyapp) or exit;
use Data::Dumper;
use_ok qw( Parse::Eyapp::Treeregexp) or exit;

my $grammar = q{
%{
use Data::Dumper;
%}
%right  '='
%left   '-' '+'
%left   '*' '/'
%left   NEG
%tree

%%
line: exp  { $_[1] } 
;

exp:      %name NUM   
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
        |   '(' exp ')'  { $_[2] } /* Let us simplify a bit the tree */
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

our (@all, $uminus, $constantfold, $zero_times_whatever, $whatever_times_zero);

$Data::Dumper::Indent = 1;
Parse::Eyapp->new_grammar(input=>$grammar, classname=>'Rule6');
my $parser = Rule6->new();
$parser->YYData->{INPUT} = "2*3\n";
my $t = $parser->Run;
print "\n***** Before ******\n";
print Dumper($t);

my $p = Parse::Eyapp::Treeregexp->new( STRING => q{
  {
    my %Op = (PLUS=>'+', MINUS => '-', TIMES=>'*', DIV => '/');
  }
  constantfold: /TIMES|PLUS|MINUS|DIV/(NUM($x), NUM($y)) 
     => { 
	  my $op = $Op{ref($_[0])};

	  my $res = Parse::Eyapp::Node->new(
	    q{NUM(TERMINAL)},
	    sub { 
	      my ($NUM, $TERMINAL) = @_;
	      $TERMINAL->{attr} = eval "$x->{attr} $op $y->{attr}";
	      $TERMINAL->{token} = 'NUM';
	      print Dumper($NUM);
	    },
	  );
	  print "$x->{attr} * $y->{attr}\n";
	  print Dumper($res);
	  $_[0] = $res; 
	}
  },
  #OUTPUTFILE => 'main.pm',
);
$p->generate();
$constantfold->s($t);
print "\n***** After: The tree for 2*3 has been simplified to the tree for 6 ******\n";
print Dumper($t);
my $expected_result = bless( {
    'children' => [ bless( { 'children' => [], 'attr' => 6, 'token' => 'NUM' }, 'TERMINAL' ) ]
}, 'NUM' );
is_deeply($t, $expected_result, 'Simplify tree with vars and several families');

