#!perl -w

; use strict
; use Test::More tests => 1
; use Template::Magic

; our ($tm, $content, $tmp);
; $tm = new Template::Magic
        value_handlers => [ qw| SCALAR
                                REF
                                ARRAY
                                HASH
                               |
                          ]
; $tmp = 'text before {my_sub}placeholder{/my_sub} text after'

; sub my_sub
   { 'NOT USED VALUE'
   }

; $content = $tm->output(\$tmp)
; is( $$content
    , 'text before  text after'
    )
