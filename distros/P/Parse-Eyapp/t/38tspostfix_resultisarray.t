#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use Test::More tests=>3;
use_ok qw( Parse::Eyapp );

my $ts = q{
# File TSPostfix2.eyp
%right  '='
%left   '-' '+'
%left   '*' '/'
%left   NEG

%{
  use Data::Dumper;
  $Data::Dumper::Indent = 1;
  $Data::Dumper::Deepcopy = 1;
  #$Data::Dumper::Deparse = 1;
  #use IO::Interactive qw(interactive);
%}

%metatree


%defaultaction { 
  if (@_==4) { # binary operations: 4 = lhs, left, operand, right
    $lhs->{t} = "$_[1]->{t} $_[3]->{t} $_[2]->{attr}";
    return  
  }
  die "Fatal Error. Unexpected input\n".Dumper(@_);
}

%%
line: %name PROG
       exp <%name EXP + ';'> 
         { @{$lhs->{t}} = map { $_->{t}} ($lhs->child(0)->children()); }
         
;

exp:        NUM         { $lhs->{t} = $_[1]->{attr}; }    
        |   VAR         { $lhs->{t} = $_[1]->{attr}; } 
        |   VAR '=' exp { $lhs->{t} = "$_[1]->{attr} $_[3]->{t} $_[2]->{attr}" }
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

sub Run {
    my($self)=shift;
    $x = <>;
    my $tree = $self->YYParse( yylex => \&_Lexer, yyerror => \&_Error,
      #yydebug => 0xFF
    );

    print Dumper($tree);
    $tree->translation_scheme();
    print Dumper($tree);
    {
      local $" = ";";
      print "Translation:\n@{$tree->{t}}\n";
    }

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
our $x = 'a = -(2*-3); b = -(a+5)';
  my $t = $parser->YYParse(yylex => \&_Lexer, yyerror => \&_Error) 
or die "Syntax Error analyzing input";
$t->translation_scheme;
#print Dumper($t);
my $expected_result = [ 'a 2 3 NEG * NEG =', 'b a 5 + NEG =' ];
is_deeply($t->{t}, $expected_result, "postfix translation a = -(2*-3); b = -(a+5)");

$x = 'a=-a*b/c;b=a*-a;c=a/(a+b)';
  $t = $parser->YYParse(yylex => \&_Lexer, yyerror => \&_Error) 
or die "Syntax Error analyzing input";
$t->translation_scheme;
#print Dumper($t);
$expected_result = [ 'a a NEG b * c / =', 'b a a NEG * =', 'c a a b + / =' ];
is_deeply($t->{t}, $expected_result, "postfix translation a=-a*b/c;b=a*-a;c=a/(a+b)");

