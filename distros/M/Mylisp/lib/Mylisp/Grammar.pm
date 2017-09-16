package Mylisp::Grammar;

use 5.012;
no warnings "experimental";

use Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(get_mylisp_grammar);

sub get_mylisp_grammar {
   return << 'EOF'
   
   mylisp = ^ |_ _pod Expr|+ $ ;

   _      = |\s+ _comm|+ ;
   _pod   = '=pod' ~ '=end' ;
   _comm  = '#' ~ $$ ;

   Expr   = '(' |_ atom|+ ')' ;

   atom   = | 
              Expr Array Hash
              Int Kstr Str String Char
              Aindex Arange Hkey Ocall Lcall Onew
              Oper Sub Var
            | ;

   Int    = number ;
   number = |{'-'\d+} \d+| ;

   Kstr   = \: [$^+*?\w:.]+ ;
   
   Str    = \' |schars char|* \' ;
   schars = [^\\']+ ;
   char   = \\ . ;
 
   String = \" |Chars Char Scalar|* \" ;
   Chars  = [^\\"$]+ ;
   Char   = \\ . ;
   Scalar = '$' [\a\-]+ ;

   Oper   = [\-+=><!~|&]+ ;
   Sub    = \a [\-\w:]* ;
   Var    = [$@%] [\-\w]+ ;

   Array  = '[' |_ \, atom|* ']' ;
   Hash   = '{' |_ \, Pair|* '}' ;
   Pair   = |Kstr Str| \s* '=>' \s* atom ;

   Aindex = Var {'[' Int ']'}+ ;

   Arange = Var Range ;
   Range  = '[' From? ':' To? ']' ;
   From   = |number {[$][\a\-]+}| ;
   To     = |number {[$][\a\-]+}|;
   
   Hkey   = Var {'[' |Kstr Scalar| ']'}+ ;
   Ocall  = Var \. Sub ;
   Lcall  = Var \: Sub ;
   Onew   = Sub \. Sub ;

EOF
}

1;
