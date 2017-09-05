package Spp::Grammar;

use Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(get_spp_grammar);

sub get_spp_grammar {
   return << 'EOF'
spp       = ^ |_ Spec|+ $ ;

_         = |\s+ _comm|+ ;
_comm     = '//' ~ $$ ;

Spec      = Token \s* '=' |_ Lbranch Branch rule|+ |';' $| ;
rule      = |
               Group
               Token Str String Keyword Point
               Cclass Char Chclass
               Sym Expr Assert Any
               Look Not Till
            | ;

Lbranch   = '||' |_ Branch rule|+ '||' ;
Branch    = '|'  |_ Lbranch rule|+ '|' ;
Group     = '{'  |_ Lbranch Branch rule|+ '}' ;

Token     = [\a\-]+ ;
Keyword   = ':' \S+ ;
Point     = '0x' \x+ ;

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

Assert    = | '^^' '$$' '$' '^' | ;
Any       = '.' ;

Look      = Rept Flag? ;
Rept      = [?*+] ;
Flag      = '?' ;
Not       = '!' ;
Till      = '~' ;

Sym       = [$@%] [\a\-?!>]+ ;
Expr      = '(' |_ atom|+ ')' ;
Array     = '[' |_ atom|* ']' ;
atom      = | Int Expr Array Str String Sym Keyword | ;
Int       = \d+ ;

EOF
}

1;
