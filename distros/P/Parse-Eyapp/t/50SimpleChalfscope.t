#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use Parse::Eyapp;
use Parse::Eyapp::Treeregexp;
use Test::More;

if( $] <= 5.007) { 
  plan skip_all => 'Old Perl'; 
}
else { plan tests => 9; }


my $grammar = q{
  /* 
  Scope Analysis
  TODO: Attempt to implement DAGS to represent types
  */
  %{
  use strict;
  use Data::Dumper;
  use Test::More;
  use List::Util qw(reduce);
  use Parse::Eyapp::Base qw(firstval lastval);

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
    '='  => "ASSIGN",
    '+'  => "PLUS",
    '-'  => "MINUS",
    '*'  => "TIMES",
    '/'  => "DIV",
    '%'  => "MOD",
    '|'  => "OR",
    '&'  => "AND",
    '{'  => "LEFTKEY",
    '}'  => "RIGHTKEY",
    ','  => "COMMA",
    ';'  => "SEMICOLON",
    '('  => "LEFTPARENTHESIS",
    ')'  => "RIGHTPARENTHESIS",
    '['  => "LEFTBRACKET",
    ']'  => "RIGHTBRACKET",
    '==' => "EQUAL",
    '+=' => "PLUSEQUAL",
    '-=' => "MINUSEQUAL",
    '*=' => "TIMESEQUAL",
    '/=' => "DIVEQUAL",
    '%=' => "MODEQUAL",
    '!=' => "NOTEQUAL",
    '<'  => "LESS",
    '>'  => "GREATER",
    '<=' => "LESSEQUAL",
    '>=' => "GREATEREQUAL",
    '++' => "INC",
    '--' => "DEC",
    '**' => "EXP"
  );

  sub is_duplicated {
    my ($st1, $st2) = @_;

    my $id;

      defined($id=firstval{exists $st1->{$_}} keys %$st2)
    and return "Error. Variable $id at line $st2->{$id}->{line} declared twice.\n";
    return 0;
  }

  sub build_type {
    my $bt = shift;
    my @arrayspec = shift()->children();

    my $type = '';
    for my $s (@arrayspec) {
      $type .= "A_$s->{attr}[0](";
    }
    if ($type) {
      $type = "$type$bt".(")"x@arrayspec);
    }
    else {
      $type = $bt;
    }
    return $type;
  }

  my ($tokenbegin, $tokenend);
  my %type = (
    INT  => 1,
    CHAR => 1,
  );

  my %st; # Global symbol table

  my $depth = 0;
  my @pending_blocks;

  sub build_function_scope { 
    my ($funcDef, $returntype) = @_;

    my $function_name = $funcDef->{function_name}[0];
    my @parameters = @{$funcDef->{parameters}};
    my $lst = $funcDef->{symboltable};
    my $numargs = scalar(@parameters);

    #compute type
    my $partype = "";
    if (@parameters) {
      $partype .= reduce { "$lst->{$a}{type},$lst->{$b}{type}" } @parameters;
    }
    my $type = "F(X_$numargs($partype),$returntype)";

    #insert it in the hash of types
    $type{$type} = 1;

    #insert it in the global symbol table
    die "Duplicated declaration of $function_name at line $funcDef-->{attr}[1]\n" 
      if exists($st{$function_name});
    $st{$function_name}->{type} = $type;
    $st{$function_name}->{line} = $funcDef->{function_name}[1];

    return $funcDef;
  }

  %}

  %syntactic token '=' '+=' '-=' '*=' '/=' '%=' '(' '['
  %syntactic token  '|' '&' '==' '!=' '<' '>' '>=' '<=' 
  %syntactic token '+' '-' '*' 
  %syntactic token '/' '%' '**' '++' '--' 'ELSE'
  %syntactic token RETURN BREAK CONTINUE

  %nonassoc WEAK
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
        { $tokenbegin = $tokenend = 1 }
      definition<%name PROGRAM +>.program
        { 
          $program->{symboltable} = { %st };  # creates a copy of the s.t.
          for (keys %type) {
            $type{$_} = Parse::Eyapp::Node->new($_);
          }
          $program->{depth} = 0;
          $program->{line}  = 1;
          $program->{types} = { %type };  
          $program->{lines} = $tokenend;  

          # Reset file scope variables
          %st = (); # reset symbol table
          ($tokenbegin, $tokenend) = (1, 1);
          %type = (INT => "INT", CHAR => "CHAR");
          $program;
        }
  ;

  definition:
      $funcDef 
        { 
          build_function_scope($funcDef, 'INT');
        }
    | %name FUNCTION
      $basictype $funcDef
        { 
          build_function_scope($funcDef, $basictype->type);
        }
    | declaration 
       { 
         #control duplicated declarations
         my $message;
         die $message if $message = is_duplicated(\%st, $_[1]);
         %st = (%st,  %{$_[1]}); # improve this code
         return undef; # will not be inserted in the AST
       }
  ;

  basictype:
      %name INT 
      INT
    | %name CHAR 
      CHAR
  ;

  funcDef:
      $ID '('  $params  ')' 
        $block
      {
         my $st = $block->{symboltable}; 
         my @decs = $params->children(); 
         $block->{parameters} = [];
         while (my ($bt, $id, $arrspec) = splice(@decs, 0, 3)) {
             my $bt = ref($bt); # The string 'INT', 'CHAR', etc.
             my $name = $id->{attr}[0];
             my $type = build_type($bt, $arrspec);
             $type{$type} = 1; # has too much $type for me!

             # control duplicated declarations
             die "Duplicated declaration of $name at line $id->{attr}[1]\n" if exists($st->{$name});
             $st->{$name}->{type} = $type;
             $st->{$name}->{param} = 1;
             $st->{$name}->{line} = $id->{attr}[1];
             push @{$block->{parameters}}, $name;
         }
         $block->{function_name} = $ID;
         $block->type("FUNCTION");
         return $block;
      }
  ;

  params: 
      ( basictype ID arraySpec)<%name PARAMS * ','>
        { $_[1] }
  ;

  block:
      '{'.bracket 
         { $depth++ } /* intermediate action! */
       declaration<%name DECLARATIONS *>.decs statement<%name STATEMENTS *>.sts '}'
         { 
           my %st;

           for my $lst ($decs->children) {

               # control duplicated declarations
             my $message;
             die $message if $message = is_duplicated(\%st, $lst);

             %st = (%st, %$lst);
           }
           $sts->{symboltable} = \%st;
           $sts->{line} = $bracket->[1];
           $sts->{depth} = $depth--;
           $sts->type("BLOCK");
           push @pending_blocks, $sts;
           return $sts; 
         }

  ;

  declaration:
      %name DECLARATION
      $basictype $declList ';' 
        {  
           my %st; # Symbol table local to this declaration
           my $bt = $basictype->type;
           my @decs = $declList->children(); 
           while (my ($id, $arrspec) = splice(@decs, 0, 2)) {
             my $name = $id->{attr}[0];
             my $type = build_type($bt, $arrspec);
             $type{$type} = 1; # has too much $type for me!

             # control duplicated declarations
             die "Duplicated declaration of $name at line $id->{attr}[1]\n" if exists($st{$name});
             $st{$name}->{type} = $type;
             $st{$name}->{line} = $id->{attr}[1];
           }
           return \%st;
        }
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
      ID  %prec WEAK
    | %name  VARARRAY
      ID ('[' binary ']') <%name INDEXSPEC +>
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

            die "Error. Unexpected token $ltoken\n";
          }; # do
    } # for
  }

  sub Parse::Eyapp::Node::build_blocks_tree {
    my $t = shift; # tree

    my (@b, @blocks);
    @b = @blocks = $SimpleTrans::blocks->m($t);
    while (@blocks) {     
      my $b = pop @blocks;
      my $d = $b->{depth};
      my $f = lastval { $_->{depth} < $d} @blocks; 
      last unless $f;
      $b->{fatherblock} = $f;
      #print "depth=$b->{depth}, node=$b, father= $b->{fatherblock}\n";
    }
    wantarray? @b : $t;
  }

  sub Parse::Eyapp::Node::build_blocks_tree2 {
    my $t = shift; # tree

    my @b = $SimpleTrans::blocks->m($t);
    for (@b) {
      my ($n, $d, $f, $ch) = @$_; 
      if (defined($f)) {
        $n->{fatherblock} = $f->[0];
#        print "depth=$n->{depth}, node=$n, father= $n->{fatherblock}\n";
      }
      else {
#        print "depth=$n->{depth}, node=$n, father= nofather\n";
      }
    }
    wantarray? @b : $t;
  }

  sub Parse::Eyapp::Node::build_blocks_tree3 {
    my $t = shift; # tree

    my @b = $SimpleTrans::blocks->m($t);
    $_->[0]->{fatherblock} = $_->[2][0] for (@b);
    
    return @b;
  }

  sub Parse::Eyapp::Node::build_blocks_tree_with_subtree {
    my $t = shift; # tree

    my @b = $SimpleTrans::blocks->m($t);
    $_->{node}{fatherblock} = $_->{father}{node} for (@b);
     
    return @b;
  }


  my @tests = (
  #Correct program
   << "EOICORRECT",
f() {
  int a,b[1][2],c[1][2][3];
  char d[10];
  b[0][1] = a;
}
EOICORRECT
#   << "EOI_TWICE",
#/* Duplicated declaration of a at line 2 */
#f() {
#  int a,b[1][2],a[1][2][3];
#  char d[10];
#  b[0][1] = a;
#}
#EOI_TWICE
#    << "EOI_TWICE_DIF_DEC",
#/* Duplicated declaration of a at line 3 */
#f() {
#  int a,b[1][2],c[1][2][3];
#  char d[10], b[9];
#  b[0] = a;
#}
#EOI_TWICE_DIF_DEC
#
# Correct program. Global and local decs
    << "EOI_GLOBAL_DEC",
int a,b[1][2],c[1][2][3]; 
char d,e[1][2]; 
f() {
  int a[1],b[1][2],c[1][2][3];
  char d[10], e[9];

  b[0] = a[1];
}
EOI_GLOBAL_DEC
##    << "EOI_GLOBAL_DUP",
##/* Error: duplicated global dec */
##int a,b[1][2],c[1][2][3]; 
##char d,a[1][2]; 
##f() {
##  int a,b[1][2],c[1][2][3];
##  char d[10], e[9];
##
##  b[0][1] = a;
##}
##EOI_GLOBAL_DUP
# Correct program. Parameters
    << "EOI_GLOBAL_PAR",
int a,b[1][2],c[1][2][3]; 
char d,e[1][2]; 
f(int a, char b[10]) {
  int c[1][2][3];
  char d[10], e[9];

  b[0][1] = a;
  d[5] = e[4];
}
EOI_GLOBAL_PAR
# Correct program. Only global
    << "EOI_GLOBAL",
int a,b[1][2],c[1][2][3]; 
EOI_GLOBAL
# Correct program. Return char and Parameters
    << "EOI_RETURN",
int a,b[1][2],c[1][2][3]; 
char d,e[1][2]; 
char f(int a, char b[10]) {
  int c[1][2];
  char d[10], e[9];

  return b[0];
}
EOI_RETURN
## Correct program. No parameters
    << "EOI_RETURN_NOPAR",
char d,e[1][2]; 
char f() {
  int c[2];
  char d;

  return d;
}
EOI_RETURN_NOPAR
#  << "EOIPARAMDECLTWICE",
#int a, b[1][2];
#char d, e[1][2]; 
#char f(int a, char b[10]) {
#  int c[1][2];
#  char b[10], e[9];
#
#  return b[0];
#}
#EOIPARAMDECLTWICE
# Correct program. No parameters
    << "EOI_NESTED_BLOCKS",
char d0; 
char f() {
  char d1;
  {
    char d2;
  }
  {
    char d2;
    {
      char d3;

      d3;
    }
  }
  {
    d0;
  }

  return d1;
}
EOI_NESTED_BLOCKS
# Correct program. No parameters
    << "EOI_NESTED_BLOCKS2",
char d0; 
char f() {
  {
    {}
  }
  {
    { }
  }
  {
    {{}}
  }
}
EOI_NESTED_BLOCKS2
    << "EOI_NESTED_BLOCKS3",
char d0; 
char f() {
  {
    {}
  }
  {
    { }
  }
  {
    {{}}
  }
}
g() {
 {}
 {
   {}
 }
 {}
}
EOI_NESTED_BLOCKS3
); # end of @tests

my @expected_tree = (
'PROGRAM(FUNCTION[f](ASSIGN(VARARRAY(TERMINAL[b:4],INDEXSPEC(INUM(TERMINAL[0:4]),INUM(TERMINAL[1:4]))),VAR(TERMINAL[a:4]))))',

'PROGRAM(FUNCTION[f](ASSIGN(VARARRAY(TERMINAL[b:7],INDEXSPEC(INUM(TERMINAL[0:7]))),VARARRAY(TERMINAL[a:7],INDEXSPEC(INUM(TERMINAL[1:7]))))))',

'PROGRAM(FUNCTION[f](ASSIGN(VARARRAY(TERMINAL[b:7],INDEXSPEC(INUM(TERMINAL[0:7]),INUM(TERMINAL[1:7]))),VAR(TERMINAL[a:7])),ASSIGN(VARARRAY(TERMINAL[d:8],INDEXSPEC(INUM(TERMINAL[5:8]))),VARARRAY(TERMINAL[e:8],INDEXSPEC(INUM(TERMINAL[4:8]))))))',

'PROGRAM',

'PROGRAM(FUNCTION[f](RETURN(VARARRAY(TERMINAL[b:7],INDEXSPEC(INUM(TERMINAL[0:7]))))))',

'PROGRAM(FUNCTION[f](RETURN(VAR(TERMINAL[d:6]))))',

'PROGRAM(FUNCTION[f](BLOCK[4],BLOCK[7](BLOCK[9](VAR(TERMINAL[d3:12]))),BLOCK[15](VAR(TERMINAL[d0:16])),RETURN(VAR(TERMINAL[d1:19]))))',

'PROGRAM(FUNCTION[f](BLOCK[3](BLOCK[4]),BLOCK[6](BLOCK[7]),BLOCK[9](BLOCK[10](BLOCK[10]))))',

'PROGRAM(FUNCTION[f](BLOCK[3](BLOCK[4]),BLOCK[6](BLOCK[7]),BLOCK[9](BLOCK[10](BLOCK[10]))),FUNCTION[g](BLOCK[14],BLOCK[15](BLOCK[16]),BLOCK[18]))',
);

my @expected_error = (
qr{Duplicated declaration of a at line},
qr{Error. Variable b at line 4 declared twice},
);

  sub Run {
   my($self)=shift;

   my ($forest, $t);
   my ($k, $e) = (0, 0);

   for  (@tests) {
     $self->YYData->{INPUT} = $_;
#     print "****************\n$_";
     eval {
       $t = $self->YYParse( yylex => \&_Lexer, yyerror => \&_Error, #yydebug => 0x1F 
       );
     };
     if ($@) {
#       print "\n$@";
       like($@, $expected_error[$e++],"Simple4 error $e");
     }
     else {
#       print $t->str."\n";
       is($t->str, $expected_tree[$k++], "Simple scope tree $k");
       my @blocks = $SimpleTrans::blocks->m($t);
       $_->node->{fatherblock} = $_->father->{node} for (@blocks[1..$#blocks]);
       $Data::Dumper::Deepcopy = 1;
       #print Dumper $t;
#       print $_->str."\n" for @blocks;
       push @$forest, $t;
     }
   }
   return $forest;
  }

  sub TERMINAL::info { 
    my @a = join ':', @{$_[0]->{attr}}; 
    return "@a"
  }

  sub FUNCTION::info { 
    return $_[0]->{function_name}[0] 
  }

  sub BLOCK::info {
    return $_[0]->{line}
  }
};

######### main ##############
$Data::Dumper::Indent = 1;

Parse::Eyapp::Treeregexp->new( STRING => q{
    blocks:  /BLOCK|FUNCTION|PROGRAM/
  },
  PACKAGE => 'SimpleTrans'
)->generate();


# Syntax analysis
Parse::Eyapp->new_grammar(
  input=>$grammar, 
  classname=>'Rule6',
  #outputfile => 'match.pm',
  firstline=>9,
);

my $parser = Rule6->new();

my $t = $parser->Run;
