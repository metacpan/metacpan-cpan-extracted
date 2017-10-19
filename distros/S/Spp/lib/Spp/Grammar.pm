package Spp::Grammar;

use 5.012;
no warnings 'experimental';

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(get_spp_grammar);

sub get_spp_grammar {
  return <<'EOF'


  door      = |_ Spec|+ $ ;

  _         = |\s+ _comm|+ ;
  _comm     = '//' ~ $$ ;

  Spec      = Token \s* '=' |_ Branch rule|+ |';' $| ;

  rule      = |
               Group Token Str String Kstr
               Cclass Char Chclass
               Sym Expr Assert Any
               Look Not Till
              | ;

  Branch    = '|'  |_ rule|+ '|' ;
  Group     = '{'  |_ Branch rule|+ '}' ;

  Token     = [\a\-]+ ;
  Kstr      = ':' [\a\-]+ ;

  Str       = \' |Chars Char|+ \' ;
  Chars     = [^\\']+ ;

  String    = \" |Schars Char|+ \" ;
  Schars    = [^\\"]+ ;

  Cclass    = \\ [ adhlsuvwxADHLSUVWX] ;
  Char      = \\ . ;

  Chclass   = \[ Flip? |_ Cclass Char Range Cchar|+ \] ;
  Flip      = '^' ;
  Range     = \w \- \w ;
  Cchar     = [^ \s \] \/ \\] ;

  Assert    = | '^^' '$$' '^' '$' | ;
  Any       = '.' ;

  Look      = Rept Flag? ;
  Rept      = [?*+] ;
  Flag      = '?' ;
  Not       = '!' ;
  Till      = '~' ;

  Sym       = [@$] [\a\-]+ ;
  Sub       = [\a\-]+ ;
  Expr      = '(' |_ atom|+ ')' ;
  Array     = '[' |_ atom|* ']' ;
  atom      = | Array Sub Sym Kstr | ;


EOF
}
1;
