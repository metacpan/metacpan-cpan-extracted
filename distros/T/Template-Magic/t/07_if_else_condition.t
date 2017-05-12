#!perl -w

; use strict
; use Test::More tests => 1
; use Template::Magic

; our ( $tm
      , $scalar_test
      , $content
      , $tmp
      , $OK
      , $OK_condition
      , $NO_condition
      )
; $tm = new Template::Magic
; $scalar_test = 'SCALAR'
; $tmp = '{OK_condition}This is the OK block, containig {scalar_test}{/OK_condition}{NO_condition}This is the NO block{/NO_condition}'
; $OK++
; $OK
  ? $OK_condition={}
  : $NO_condition={}

; $content = $tm->output(\$tmp)

; is( $$content
    , 'This is the OK block, containig SCALAR'
    )
