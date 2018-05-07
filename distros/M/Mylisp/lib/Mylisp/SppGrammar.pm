package Mylisp::SppGrammar;

use 5.012;
use experimental 'switch';

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(GetSppGrammar);

sub GetSppGrammar {
  return <<'EOF'

  door    -> |\s+ _comm Spec|+ $
  _comm   -> '#'~$$
  Spec    -> Token '->' | Blank Branch atom |+| \v $ |
  Blank   -> \h+
  atom    -> |
  Group Token Str String Kstr
  Cclass Char Chclass Sym Expr
  Assert Any Rept Till
  |
  Branch  -> '|' | \s+ _comm atom |+ '|'
  Group   -> '{' | \s+ _comm Branch atom |+ '}'
  Token   -> [\a\-]+
  Kstr    -> ':'[\a\-]+
  Str     -> \'| [^\\']+ {\\.} |+\'
  String  -> \"| [^\\"]+ {\\.} |+\"
  Cclass  -> \\[adhlsuvwxADHLSUVWX]
  Char    -> \\.
  Chclass -> \[ Flip?|\s Cclass Char Range Cchar|+ \]
  Flip    -> '^'
  Range   -> \w\-\w
  Cchar   -> [^ \s \] \# \\ ]
  Assert  -> | '^^' '$$' '^' '$' |
  Any     -> '.'
  Rept    -> [?*+]
  Till    -> '~'
  Sym     -> [@$][\a\-]+
  Sub     -> [\a\-]+
  Expr    -> '(' eatom+ ')'
  Array   -> '[' eatom* ']'
  eatom   -> | Array Sub Sym Kstr |
  
EOF
}
1;
