#!/usr/bin/perl -w
use strict;
#use Test::More qw(no_plan);
use Test::More tests => 5;

#use Test::Exception;
our $test_exception_installed;
BEGIN { 
$test_exception_installed = 1;
eval { require Test::Exception };
$test_exception_installed = 0 if $@;
}

use_ok qw(Parse::Eyapp) or exit;
use Data::Dumper;
use_ok qw( Parse::Eyapp::Treeregexp) or exit;

my $translationscheme = q{
%{
# head code is available at tree construction time 
use Data::Dumper;

our %sym; # symbol table
our %Op = ( PLUS => '+', MINUS => '-', 'TIMES' => '*', DIV => '/');
%}

%defaultaction { $lhs->{n} = eval " $left->{n} $Op{$lhs->type} $right->{n} " }

%metatree

%left   '='
%left   '-' '+'
%left   '*' '/'

%%
line:       %name EXP  
              exp <+ ';'> /* Expressions separated by semicolons */ 
	        { $lhs->{n} = $_[1]->Last_child->{n} }
;

exp:    
            %name PLUS  
              exp.left '+' exp.right 
        |   %name MINUS
	      exp.left '-' exp.right    
        |   %name TIMES 
              exp.left '*' exp.right  
        |   %name DIV 
              exp.left '/' exp.right  
        |   %name NUM   $NUM          
	        { $lhs->{n} = $NUM->{attr} }
        |   '(' $exp ')'  %begin { $exp }       
        |   %name VAR
	      $VAR                 
	        { $lhs->{n} = $sym{$VAR->{attr}}->{n} }
        |   %name ASSIGN
	      $VAR '=' $exp         
	        { $lhs->{n} = $sym{$VAR->{attr}}->{n} = $exp->{n} }

;

%%
# tail code is available at tree construction time 
sub _Error {
  die "Syntax error.\n";
}

sub _Lexer {
    my($parser)=shift;

    for ($parser->YYData->{INPUT}) {
        defined($_) or  return('',undef);

        s/^\s*//;
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

$Data::Dumper::Indent = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Deepcopy  = 1;


SKIP: {
  skip "Test::Exception not installed", 1 unless $test_exception_installed;
  Test::Exception::lives_ok { Parse::Eyapp->new_grammar(
      input=>$translationscheme,
      classname=>'main',
      firstline => 6,
      #outputfile => 'main.pm'
  ) } 'No errors in input translation scheme';
}

unless ($test_exception_installed) {
  Parse::Eyapp->new_grammar(
      input=>$translationscheme,
      classname=>'main',
      firstline => 6,
      #outputfile => 'main.pm'
  ) 
}
my $parser = main->new();
#print "Write a sequence of arithmetic expressions: " if is_interactive();
$parser->YYData->{INPUT} = 'a=2*3; b= 1+a; a*b'; # <>;
my $t = $parser->Run() or die "Syntax Error analyzing input";

$t->translation_scheme;
my $treestring = Dumper($t);
our %sym;
my $symboltable = Dumper(\%sym);
my $expectedsym = { 'a' => { 'n' => 6 }, 'b' => { 'n' => 7 } };
is_deeply(\%sym, $expectedsym, "symbol tables");

my $expected_result = 42;
is($t->{n}, $expected_result, "a=2*3; b= 1+a; a*b == 42");

# print <<"EOR";
# ***********Tree*************
# $treestring
# ******Symbol table**********
# $symboltable
# ************Result**********
# $t->{n}
# 
# EOR
