#!/usr/bin/perl -w
use strict;
#use Data::Dumper;
use Test::More tests => 2;
use_ok qw( Parse::Eyapp ) or die "can't load Parse::Eyapp";

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
    or  return('',undef);

    $parser->YYData->{INPUT}=~s/^\s*//;

    for ($parser->YYData->{INPUT}) {
        s/^([0-9]+(?:\.[0-9]+)?)//
                and return('NUM',$1);
        s/^([A-Za-z][A-Za-z0-9_]*)//
                and return('VAR',$1);
        s/^(.)//
                and return($1,$1);
        s/^\s*//;
    }
}

sub Run {
    my($self)=shift;
    return $self->YYParse( yylex => \&_Lexer, yyerror => \&_Error );
}
}; # end translation scheme

#$Data::Dumper::Indent = 1;
#$Data::Dumper::Terse = 1;
#$Data::Dumper::Deepcopy  = 1;
Parse::Eyapp->new_grammar(
  input=>$translationscheme,
  classname=>'main',
  firstline => 7,
  ); #outputfile => 'main.pm');
my $parser = main->new();
$parser->YYData->{INPUT} = "2+(3)";
my $t = $parser->Run() or die "Syntax Error analyzing input";
$t->translation_scheme;
my $expected_value = 5;
is($t->{n}, $expected_value, '%begin being tested');

print "$t->{n}\n";
#print Dumper($t);
