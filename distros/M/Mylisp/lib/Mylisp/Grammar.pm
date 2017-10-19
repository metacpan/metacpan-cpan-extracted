package Mylisp::Grammar;

use 5.012;
no warnings 'experimental';

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(get_my_grammar);

sub get_my_grammar {
  return <<'EOF'

   door   = ^ |_ _pod Expr|+ $ ;

   _      = |\s+ _comm|+ ;
   _pod   = '=pod' ~ '=end' ;
   _comm  = '#' ~ $$ ;

   Expr   = '(' |_ atom|+ ')' ;

   atom   = | 
              Expr Array Hash
              Int Kstr Lstr Str String Char
              Aindex Arange Ocall
              Oper Ns Arg Var Sub
            | ;

   Array  = '[' |_ \, atom|+ ']' ;
   Hash   = '{' |_ \, Pair|+ '}' ;
   Pair   = |Kstr Str Sub| \s* '=>' \s* atom ;

   Int    = \-? \d+ ;

   Kstr   = \: [\w\-:]+ ;
   Lstr   = \'\'\' ~ { \'\'\' } ;
   
   Str    = \' |schars char|+ \' ;
   schars = [^\\']+ ;
   char   = \\ . ;
 
   String = \" |Chars Char Scalar|+ \" ;
   Chars  = [^\\"$]+ ;
   Char   = \\ . ;
   Scalar = '$' [\a\-]+ ;

   Aindex = Var {'[' |Int Kstr Scalar| ']'}+ ;

   Arange = Var '[' |Int Scalar| ':' |Int Scalar|? ']' ;
   
   Ocall  = Var \. Sub ;

   Oper   = [\-+=><!~|&]+ ;
   Ns     = name {'::' name}+ ;
   Arg    = [$@%] name ':' type ;
   Sub    = name ;
   Var    = [$@%] name ;
   name   = [\a\-]+ ;
   type   = [\a\-?+]+ ;

EOF
}
1;
