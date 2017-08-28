# Copyright 2016 The Michael Song. All rights rberved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

package Spp::Rule::SppRule;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(get_spp_rule);

sub get_spp_rule {
   return << 'EOF'
spp       = ^ |_ Spec|+ $ ;

_         = |\s+ _comm|+ ;
_comm     = '//' ~ $$ ;

Spec      = Sym \s* '=' |_ Lbranch Branch rule|+ |';' $| ;
rule      = |
               Group
               Token Str String Keyword Point
               Cclass Char Chclass
               Assert Any
               Look Not Till
               Sym Expr
            | ;

Lbranch   = '||' |_ Branch rule|+ '||' ;
Branch    = '|'  |_ Lbranch rule|+ '|' ;
Group     = '{'  |_ Lbranch Branch rule|+ '}' ;

Token     = [\w\-]+  ;
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

Sym       = [$@%\a] [\w\-?!>]* ;
Expr      = '(' |_ atom|+ ')' ;
Array     = '[' |_ atom|* ']' ;
atom      = | Int Expr Array Str String Sym Keyword | ;
Int       = \d+ ;

EOF
}

1;
