#!perl -w

; use strict
; use Test::More tests => 1
; use Template::Magic

; our ( $tm
      , $char
      , $num
      , $content
      , $tmp
      )
; $tm = new Template::Magic
; $tmp = 'text before {perl_eval}$char x ($num+1){/perl_eval} text after';

; $char = 'W'
; $num = 5

; sub perl_eval
   { eval shift()->content
   }

; $content = $tm->output(\$tmp);
; is( $$content
    , 'text before WWWWWW text after'
    )


