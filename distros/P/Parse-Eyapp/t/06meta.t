#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use Test::More tests => 3;
use_ok qw(Parse::Eyapp) or exit;

my $translationscheme = q{
%{
#use Data::Dumper;
%}

%metatree

%left   '-' '+'
%left   '*' 
%left   NEG

%%
line:       %name EXP  
              $exp 
                { $_[0]->{s} = $exp->{s}."\n"; $_[0]->{n} = $exp->{n}; }
;

exp:    
            %name PLUS  
              exp.left 
                      { 
                        $_[0]->{s} = "PLUS ". $left->{n}."\n" 
                      } 
              '+'    
                      { $_[0]->{s} .= "after plus ".$left->{n}."\n" } 
              exp.right         
                      { 
                        $_[0]->{s} .= $left->{s} . $right->{s};
                        $_[0]->{n} .= $left->{n} + $right->{n} 
                      }
        |   %name TIMES 
              exp.left '*' exp.right         
                { 
                  $_[0]->{n} = $left->{n} * $right->{n} 
                }
        |   %name NUM   $NUM                 
              { 
                $_[0]->{s} = $NUM->{attr}." "; 
                $_[0]->{n} = $NUM->{attr} 
              }
        |   %name PAREN  '(' $exp ')'        
              { 
                $_[0]->{s} = " ( $exp->{s} )"; 
                $_[0]->{n} = $exp->{n} 
              }
        |   exp.left '-' exp.right         
              { $_[0]->{n} = $left->{n} - $right->{n} }

        |   '-' $exp %prec NEG   
              { $_[0]->{n} = -$exp->{n} }
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

$Data::Dumper::Indent = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Deepcopy  = 1;
Parse::Eyapp->new_grammar(input=>$translationscheme,
  classname=>'main', 
  firstline => 7, 
  ); #outputfile => 'main.pm');
my $parser = main->new();
$parser->YYData->{INPUT} = "2+(3)";
my $t = $parser->Run() or die "Syntax Error analyzing input";
$t->translation_scheme;
#print Dumper($t);
my $expected_result =<<"ENDOFEXPECTED";
PLUS 2
after plus 2
2  ( 3  )
ENDOFEXPECTED
is($t->{s},$expected_result, "intermediate actions");
is($t->{n}, 5, "plus");
#print "Resultado $t->{s}\n";
