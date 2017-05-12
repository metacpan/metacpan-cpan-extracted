use warnings;
use strict;
use Test::More tests => 7;
use_ok qw( Parse::Eyapp );

my($parser,$grammar);
my($yapptxt);

#Test 2
$grammar=join('',<DATA>);
Parse::Eyapp->new_grammar(input=>$grammar, classname=>'Calc');
ok(!$@, "Grammar module created");

#Test 3
my $calc = Calc->new;
$calc->YYData->{INPUT}="13*2\n-(13*2)+3\n5^3+2\n";
my @outcheck=((13*2),(-(13*2)+3),(5**3+2));
my $output=$calc->YYParse(yylex => \&Calc::Lexer);

is(join(',',@$output), join(',',@outcheck), "Calc seems to work");

# Test 4
delete($calc->YYData->{LINE});
$calc->YYData->{INPUT}="5+8\n-(13*2)+3--\n3*8\n**7-3(12*55)\n12*(5-2)\n";
@outcheck=((5+8), undef, (3*8), undef, (12*(5-2)));
my @errcheck=( 2, 4);
my $nberr=2;
$output=$calc->YYParse(yylex => \&Calc::Lexer, yyerror => \&Calc::Error);

{
no warnings;
is(join(',',@$output), join(',',@outcheck), "More expressions");
}

is(join(',',@{$calc->YYData->{ERRLINES}}), join(',',@errcheck), "Checking errors");

is($calc->YYNberr, $nberr, "number of errors");

$calc->YYData->{INPUT}="a=-(13*2)+3\nb=12*(5-2)\na*b\n";
@outcheck=((-(13*2)+3), (12*(5-2)), ((-(13*2)+3)*(12*(5-2))));

$output=$calc->YYParse(yylex => \&Calc::Lexer, yyerror => \&Calc::Error);

is(join(',',@$output), join(',',@outcheck), "More expressions");

__DATA__

%right  '='
%left   '-' '+'
%left   '*' '/'
%left   NEG
%right  '^'

%%
input:  #empty
        |   input line  { push(@{$_[1]},$_[2]); $_[1] }
;

line:       '\n'                { ++$_[0]->YYData->{LINE}; $_[1] }
        |   exp '\n'            { ++$_[0]->YYData->{LINE}; $_[1] }
		|	error '\n'  { ++$_[0]->YYData->{LINE}; $_[0]->YYErrok }
;

exp:        NUM
        |   VAR                 { $_[0]->YYData->{VARS}{$_[1]} }
        |   VAR '=' exp         { $_[0]->YYData->{VARS}{$_[1]}=$_[3] }
        |   exp '+' exp         { $_[1] + $_[3] }
        |   exp '-' exp         { $_[1] - $_[3] }
        |   exp '*' exp         { $_[1] * $_[3] }
        |   exp '/' exp         { $_[1] / $_[3] }
        |   '-' exp %prec NEG   { -$_[2] }
        |   exp '^' exp         { $_[1] ** $_[3] }
        |   '(' exp ')'         { $_[2] }
;

%%

sub Error {
    my($parser)=shift;

	push(@{$parser->YYData->{ERRLINES}}, $parser->YYData->{LINE});
}

sub Lexer {
    my($parser)=shift;

        exists($parser->YYData->{LINE})
    or  $parser->YYData->{LINE}=1;

        $parser->YYData->{INPUT}
    or  return('',undef);

    $parser->YYData->{INPUT}=~s/^[ \t]//;

    for ($parser->YYData->{INPUT}) {
        s/^([0-9]+(?:\.[0-9]+)?)//
                and return('NUM',$1);
        s/^([A-Za-z][A-Za-z0-9_]*)//
                and return('VAR',$1);
        s/^(.)//s
                and return($1,$1);
    }
}

