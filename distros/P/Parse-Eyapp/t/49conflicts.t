#!/usr/bin/perl 
use strict;
use warnings;
#use Data::Dumper;
use Test::More;
if( $] <= 5.007) { 
  plan skip_all => 'Old Perl'; 
}
else { plan tests => 3; }
use_ok qw(Parse::Eyapp) or exit;
use_ok qw(Parse::Eyapp::Treeregexp) or exit;

#$Data::Dumper::Indent = 1;

my $eyappprogram = q{
  /*
  file: Simple1.eyp

  This grammar has conflicts. It can be solved changing the 
  implied rules as it is shown below:

  Variable:
      %name VAR
      ID  %prec WEAK
    | %name  VARARRAY
      ID ('[' binary ']')+
  ;

  Primary:
      %name INUM
      INUM
    | Variable %prec WEAK { $_[1] }
    | '(' expression ')' { $_[2] }
    | %name
      FUNCTIONCALL
      ID '(' binary <%name ARGLIST * ','> ')'
  ;
  */

  %{
  use strict;
  use Carp;

  my %reserved = (
    int => "INT",
    char => "CHAR",
    if => "IF",
    else => "ELSE",
    break => "BREAK",
    continue => "CONTINUE",
    return => "RETURN",
    while => "WHILE"
  );

  my %lexeme = (
    '='=> "ASSIGN",
    '+' => "PLUS",
    '-' => "MINUS",
    '*' => "TIMES",
    '/' => "DIV",
    '%' => "MOD",
    '|' => "OR",
    '&' => "AND",
    '{' => "LEFTKEY",
    '}' => "RIGHTKEY",
    ',' => "COMMA",
    ';' => "SEMICOLON",
    '(' => "LEFTPARENTHESIS",
    ')' => "RIGHTPARENTHESIS",
    '[' => "LEFTBRAQUET",
    ']' => "RIGHTBRAQUET",
    '==' => "EQUAL",
    '+=' => "PLUSEQUAL",
    '-=' => "MINUSEQUAL",
    '*=' => "TIMESEQUAL",
    '/=' => "DIVEQUAL",
    '%=' => "MODEQUAL",
    '!=' => "NOTEQUAL",
    '<' => "LESS",
    '>' => "GREATER",
    '<=' => "LESSEQUAL",
    '>=' => "GREATEREQUAL",
    '++' => "INC",
    '--' => "DEC",
    '**' => "EXP"
  );

  my ($tokenbegin, $tokenend) = (1, 1);

  %}

  %nonassoc '(' '['
  %right '=' '+=' '-=' '*=' '/=' '%='
  %left '|'
  %left '&'
  %left '==' '!='
  %left '<' '>' '>=' '<='
  %left '+' '-'
  %left '*' '/' '%'
  %right '**'
  %right '++' '--'
  %right 'ELSE'

  %tree

  %%
  program:
      definition %name PROGRAM + { $_[1] }
  ;

  definition:
      funcDef { $_[1]->type("INTFUNC"); $_[1] }
    | %name TYPEDFUNC
      basictype funcDef
    | declaration { $_[1] }
  ;

  basictype:
      %name INT 
      INT
    | %name CHAR 
      CHAR
  ;

  funcDef:
      %name FUNCTION
      ID '('  param <%name PARAMS * ','> ')' 
        block
  ;

  param: 
      %name PARAM
      basictype ID arraySpec
  ;

  block:
      %name BLOCK
      '{' declaration %name DECLARATIONS * statement %name STATEMENTS * '}'
  ;

  declaration:
      %name DECLARATION
      basictype declList ';'
  ;

  declList:
      (ID arraySpec) <%name VARLIST + ','> { $_[1] } 
  ;

  arraySpec:
      ( '[' INUM ']')* { $_[1]->type("ARRAYSPEC"); $_[1] }
  ;

  statement:
      expression ';' { $_[1] }
    | ';'
    | %name BREAK
      BREAK ';'
    | %name CONTINUE
       CONTINUE ';'
    | %name EMPTYRETURN
      RETURN ';'
    | %name RETURN
       RETURN expression ';'
    | block { $_[1] }
    | %name IF
      ifPrefix statement %prec '+'
    | %name IFELSE
      ifPrefix statement 'ELSE' statement
    | %name WHILE
      loopPrefix statement
  ;

  ifPrefix:
      IF '(' expression ')' { $_[3] }
  ;

  loopPrefix:
      WHILE '(' expression ')' { $_[3] }
  ;

  expression:
      binary <+ ','> 
        { 
          return $_[1]->child(0) if ($_[1]->children() == 1); 
          return $_[1];
        }
  ;

  Variable:
      %name VAR
      ID  
    | %name  VARARRAY
      ID ('[' binary ']')+
  ;

  Primary:
      %name INUM
      INUM 
    | Variable           { $_[1] }
    | '(' expression ')' { $_[2] }
    | %name 
      FUNCTIONCALL
      ID '(' binary <%name ARGLIST * ','> ')'
  ;
      
  Unary:
      '++' Variable
    | '--' Variable
    | Primary { $_[1] }
  ;

  binary:
      Unary { $_[1] }
    | %name PLUS
      binary '+' binary
    | %name MINUS
      binary '-' binary
    | binary '*' binary
    | binary '/' binary
    | binary '%' binary
    | %name LT
      binary '<' binary
    | %name GT
      binary '>' binary
    | binary '>=' binary
    | binary '<=' binary
    | binary '==' binary
    | binary '=' binary
    | binary '!=' binary
    | binary '&' binary
    | binary '**' binary
    | binary '|' binary
    | %name ASSIGN
      Variable '=' binary
    | Variable '+=' binary
    | Variable '-=' binary
    | Variable '*=' binary
    | Variable '/=' binary
    | Variable '%=' binary
  ;

  %%

  sub _Error {
    my($token)=$_[0]->YYCurval;
    my($what)= $token ? "input: '$token->[0]'" : "end of input";
    my @expected = $_[0]->YYExpect();

    die "Syntax error near $what in line $token->[1]. Expected one of these tokens: @expected\n";
  }


  sub _Lexer {
    my($parser)=shift;

    for ($parser->YYData->{INPUT}) {
        return('',undef) if !defined($_) or $_ eq '';

        #Skip blanks
        s{\A
           ((?:
                \s+       # any white space char
            |   /\*.*?\*/ # C like comments
            )+
           )
         }
         {}xs
        and do {
              my($blanks)=$1;

              #Maybe At EOF
              return('', undef) if $_ eq '';
              $tokenend += $blanks =~ tr/\n//;
          };

       $tokenbegin = $tokenend;

        s/^([0-9]+(?:\.[0-9]+)?)//
                and return('INUM',[$1, $tokenbegin]);

        s/^([A-Za-z][A-Za-z0-9_]*)//
          and do {
            my $word = $1;
            my $r;
            return ($r, [$r, $tokenbegin]) if defined($r = $reserved{$word});
            return('ID',[$word, $tokenbegin]);
        };

        s/^(\S)//
          and do {
            my $token1 = $1;
            m{^(\S)};
            my $token2 = $2;
            
            my $ltoken = defined($token2)?"$token1$token2":$token1;
            if (exists($lexeme{$ltoken})) {
              s/^.// if length($ltoken) > 1;
              return ($ltoken, [$ltoken, $tokenbegin]);
            }

            croak "Error. Unexpected token $ltoken\n";
          }; # do
    } # for
  }

  sub Run {
      my($self)=shift;
      { 
        local $/ = undef;
        $self->YYData->{INPUT} = <>;
      }
      $self->YYParse( yylex => \&_Lexer, yyerror => \&_Error, #yydebug => 0x1F 
      );
  }
};

#$Data::Dumper::Indent = 1;
my $p = Parse::Eyapp->new_grammar(
  input=>$eyappprogram, 
  classname=>'SimpleC',
  #outputfile => 'SimpleC.pm',
  firstline=>12,
);

#my $expected_warnings = q{1 shift/reduce conflict (see .output file)
#State 64: reduce by rule 54: Primary -> Variable (default action)
#State 64: shifts:  
#  to state   98 with '*=' 
#  to state   99 with '-=' 
#  to state  100 with '/=' 
#  to state  101 with '+=' 
#  to state  102 with '=' 
#  to state  103 with '%=' 
#};

my $expected_warnings = qr{1 shift/reduce conflict};
like $p->Warnings, $expected_warnings, "Shift/reduce conflicts diagnosis"; 
