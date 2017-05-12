#!perl -w

; use strict
; use Test::More tests => 2
; use Template::Magic
; BEGIN
   { chdir './t'
   }
   
; my %hash1 = ( var1 => 1
              , var2 => 2
              )
; my %hash2 = ( var1 => 3
              , var2 => 4
              )



; our $mt = new Template::Magic

               

; my $out = ${$mt->output('25_tmpl', \%hash1)}

 
; $out .= ${$mt->output('25_tmpl', \%hash2)}

; is( $out
    , 'text 1, text 2. text 3, text 4. '
    )



;  $mt = new Template::Magic
                lookups => \%hash1
               

;  $out = ${$mt->output('25_tmpl')}

; $mt = new Template::Magic
            lookups => \%hash2


; $out .= ${$mt->output('25_tmpl')}

; is( $out
    , 'text 1, text 2. text 3, text 4. '
    )











