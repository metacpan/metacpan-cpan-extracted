#!perl -w

; use strict
; use Test::More tests => 1
; use Template::Magic

; our ( $tm
      , $content
      , $expected
      , $tmp
      )

; $tm = new Template::Magic

; $tmp = 'A nested loop:{my_nested_loop}|Date: {date} - Operation: {operation} - Details:{details} - {quantity} {item}{/details} - {/my_nested_loop}|';

; $expected = << '__EOS__';
my_nested_loop:
    date:
    operation:
    details:
        quantity:
        item:
    /details:
/my_nested_loop:

__EOS__

; $tm->ID_list('    ')
; $content = $tm->output(\$tmp)
; is( $$content."\n"
    , $expected)
