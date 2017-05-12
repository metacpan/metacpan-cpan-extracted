#!perl -w
; use strict
; use Test::More tests => 1
; use  Template::Magic
                 
; our ( $scalar_test
      , $content
      , $tmp
      )
; {
; my $tm = new Template::Magic
            value_handlers => 'DEFAULT_VALUE_HANDLERS' ,
       #     options => 'no_cache'
            
; $scalar_test = 'SCALAR'

; $tmp = 'text from template {scalar_test},{simulated_area} simulated text {scalar_test} {/simulated_area} end text.'

; $content = $tm->output(\$tmp)
}

; is ( $$content
     , 'text from template SCALAR, end text.'
     )



