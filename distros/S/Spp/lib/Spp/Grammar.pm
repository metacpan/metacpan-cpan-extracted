package Spp::Grammar;

use 5.012;
no warnings "experimental";

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(get_spp_grammar);

sub get_spp_grammar {
   return << 'EOF'
spp       = ^ |_ Spec|+ $ ;

_         = |\s+ _comm|+ ;
_comm     = '//' ~ $$ ;

Spec      = Token \s* '=' |_ Branch rule|+ |';' $| ;

rule      = |
               Group
               Token Str String Kstr Point
               Cclass Char Chclass
               Sym Expr Assert Any
               Look Not Till
            | ;

Branch    = '|'  |_ rule|+ '|' ;
Group     = '{'  |_ Branch rule|+ '}' ;

Token     = [\a\-]+ ;
Kstr      = ':' [\a\-]+ ;
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

Sym       = '@' [\a\-]+ ;
Expr      = '(' |_ atom|+ ')' ;
Array     = '[' |_ atom|* ']' ;
atom      = | Int Expr Array Str String Sym Kstr | ;
Int       = \d+ ;

EOF
}

1;
