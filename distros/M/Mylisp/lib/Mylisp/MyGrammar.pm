package Mylisp::MyGrammar;

use 5.012;
use experimental 'switch';

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(GetMyGrammar);

sub GetMyGrammar {
  return <<'EOF'

   door   -> |_comm \s+ Expr|+ $
   _comm  -> '#'~$$
   Expr   -> '(' atom+ ')'
   atom   -> |\s+ _comm Expr Array Hash Int Kstr
             Lstr Str String Char
             Aindex Arange Ocall Oper Arg Var Sub|
   Array  -> '[' atom+ ']'
   Hash   -> '{' |\s+ Pair|+ '}'
   Pair   -> Kstr '=>' |Kstr Var Sub Int|
   Int    -> \-?\d+
   Char   -> \\.
   Kstr   -> \:[\w\-:]+
   Lstr   -> \'\'\'~{\'\'\'}
   Str    -> \'| [^\\']+ {\\.} |+\'
   String -> \"| [^\\"]+ {\\.} |+\"
   Aindex -> Var{'['| Int Kstr Str Var |']'}+
   Arange -> Var'['| Int Var | ':' | Int Var |?']'
   Ocall  -> Var\.Sub
   Oper   -> [\-+=><!~|&]+
   Arg    -> [$@]name[:][\a\-?+|]+
   Var    -> [$@]name
   Sub    -> name{'::'name}*
   name   -> [\a\-]+

EOF
}
1;
