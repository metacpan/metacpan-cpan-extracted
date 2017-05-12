#!perl -w

; use strict
; use Test::More tests => 1
; use Template::Magic

; our ( $tm
      , $zero_string
      , $tmp
      , $content
      )
; $tm = new Template::Magic
; $zero_string = '0'

; sub sub_zero_string
   { '0'
   }
   
; $tmp = 'text from template {zero_string} placeholder {/zero_string}{zero_string} end text.'
; $content = $tm->output(\$tmp)
; is ( $$content
     , 'text from template 00 end text.'
     )


