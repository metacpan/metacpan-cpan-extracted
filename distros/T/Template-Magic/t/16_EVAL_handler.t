#!perl -w

; use strict
; use Test::More tests => 1
; use Template::Magic

; our ( $tm
      , $indent
      , $content
      )
; $tm = new Template::Magic
            zone_handlers => '_EVAL_' ;
; $indent = 'III'
; $content = $tm->output(\*DATA)
; is ( $$content
     , "text WWWWW text III\n"
     )

__DATA__
text {_EVAL_} 'W' x 5 {/_EVAL_} text {indent}
