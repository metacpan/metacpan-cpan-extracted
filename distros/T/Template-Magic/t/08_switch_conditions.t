#!perl -w

; use strict
; no strict 'refs'
; use Test::More  tests => 1
; use Template::Magic

; our ( $tm
      , $a_scalar_1
      , $a_scalar_2
      , $type
      , $content
      , $tmp
      )
; $tm = new Template::Magic
; $tmp = '{type_A}type A block with {a_scalar_1}{/type_A}{type_B}type B block with {a_scalar_2}{/type_B}{type_C}type C block with {a_scalar_1}{/type_C}{type_D}type D block with {a_scalar_2}{/type_D}';

; $a_scalar_1 = 'THE SCALAR 1';
; $a_scalar_2 = 'THE SCALAR 2';
; $type       = 'type_D';
; $$type      = {};

; $content = $tm->output(\$tmp);

; is( $$content
    , 'type D block with THE SCALAR 2'
    )
