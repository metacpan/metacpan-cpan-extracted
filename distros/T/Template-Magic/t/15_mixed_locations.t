#!perl -w

; use strict;
; use Test::More tests => 1
; use Template::Magic

; our( $my_hash
     , $tm
     , $scalar_test
     , $tmp
     , $content
     )
; $my_hash = { scalar_test => 'SCALAR FROM HASH'
             , P           => 'PPP'
             }
; $tm = new Template::Magic
            lookups => [ $my_hash
                       , 'main'
                       ]
                       
; $scalar_test = 'SCALAR'
; $tmp = 'text from {P} template {scalar_test} placeholder {/scalar_test},{simulated_area} simulated text {scalar_test} {/simulated_area} end text.'
; $content = $tm->output(\$tmp)
; is ( $$content
     , 'text from PPP template SCALAR FROM HASH, end text.'
     )
