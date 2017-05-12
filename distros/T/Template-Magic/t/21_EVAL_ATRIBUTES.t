#!perl -w

; use strict
; use Test::More tests => 1
; use Template::Magic

; our ( $id
      , $tm
      , $tmp
      , $expected
      , $content
      )
      
; $id = 15;
; $tm = new Template::Magic
            markers       => 'HTML',
            zone_handlers => '_EVAL_ATTRIBUTES_'

; $tmp = 'text <!--{my_param {a=>1,b=>2}}--> text <!--{id}--> text';

; sub my_param
   { my ($z) = @_
   ; $z->param->{a} . $z->param->{b}
   }

; $expected = 'text 12 text 15 text'

; $content = $tm->output(\$tmp)
; is ( $$content
     , $expected
     )
