package Mylisp::Grammar;

use Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(get_mylisp_grammar);

sub get_mylisp_grammar {
   return << 'EOF'
   
   mylisp  = ^ |_ Expr|+ $ ;

   _       = |\s+ _comm|+ ;
   _comm   = '#' ~ $$ ;

   Expr    = '(' |_ atom|+ ')' ;

   atom    = | 
               Expr Slist Array Hash
               Int Keyword Mstr Str String Char
               Aindex Arange Hkey Ocall
               Macro Oper Sub Var
             | ;

   Int     = number ;
   number  = |{'-'\d+} \d+| ;

   Keyword = \: [$^+*?\w]+ ;
   
   Mstr    = "'''" ~ "'''" ;
    
   Str     = \' |Schars Char Scalar|* \' ;
   Schars  = [^\\'$]+ ;
 
   String  = \" |Chars Char Scalar|* \" ;
   Chars   = [^\\"$]+ ;
   Char    = \\ . ;
   Scalar  = '$' [\a\-]+ ;

   Macro   = |
               :package :class :const
               :use :import :func :fn :def
               :given :else :case :if
               :while :for :my :set :end :return
             | ;
   Oper    = [\-+=><!~|&]+ ;
   Sub     = \a [\-\w:]* [!?]? ;
   Var     = [$@%] [\-\w:]+ ;

   Slist   = ':[' |\s+ Sub|+ ']' ;
   Array   = '['  |_ \, atom|* ']' ;
   Hash    = '{'  |_ \, Pair|* '}' ;
   Pair    = Keyword \s* '=>' \s* atom ;

   Aindex  = Var '[' Int ']' ;

   Arange  = Var Range ;
   Range   = '[' From? ':' To? ']' ;
   From    = |number {[$][\a\-]+}| ;
   To      = |number {[$][\a\-]+}|;
   
   Hkey    = Var '[' |Keyword Scalar| ']' ;

   Ocall   = Var \. Sub ;

EOF
}

1;
